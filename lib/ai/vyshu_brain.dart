import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../memory/vyshu_memory.dart';
import '../services/assistant_service.dart';
import '../services/vyshu_accessibility_bridge.dart';
import 'action_library.dart';
import 'command_router.dart';
import 'llm_provider.dart';
import 'safety_guard.dart';

/// Represents a single step in the Observe → Plan → Act → Verify loop
class AgentStepLog {
  final int stepNumber;
  final String thought;
  final String action;
  final Map<String, dynamic> args;
  final String resultDetail;
  final bool success;
  final DateTime timestamp;

  AgentStepLog({
    required this.stepNumber,
    required this.thought,
    required this.action,
    required this.args,
    required this.resultDetail,
    required this.success,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'step': stepNumber,
        'thought': thought,
        'action': action,
        'args': args,
        'result': resultDetail,
        'success': success,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Callback signature when a risky action requires user confirmation
typedef RiskConfirmationCallback = Future<bool> Function(String reason, String action, Map<String, dynamic> args);

/// VyshuBrain — The Autonomous On-Device Brain Layer
///
/// Owns:
/// 1. Canonical Persona (injected into every provider call so personality stays identical)
/// 2. Memory Selection (14-day chat + user facts + task history)
/// 3. Command Routing (Direct Rule vs Agent Loop vs Chat)
/// 4. Observe → Plan → Act → Verify Loop (max 25 steps, 60s timeout/step, 3x loop detection)
/// 5. Safety Guardrails & Emergency STOP
class VyshuBrain extends ChangeNotifier {
  static final VyshuBrain instance = VyshuBrain._internal();
  factory VyshuBrain({String proxyUrl = ''}) => instance;
  VyshuBrain._internal();

  static const int maxAgentSteps = 25;
  static const Duration stepTimeout = Duration(seconds: 60);

  // Live Task State observable by LiveTaskOverlay & Drawer UI
  bool _isRunningTask = false;
  bool _stopRequested = false;
  String _currentGoal = '';
  int _currentStep = 0;
  String _lastActionSummary = 'Idle';
  String? _pendingConfirmationPrompt;
  Completer<bool>? _confirmationCompleter;

  final List<AgentStepLog> _liveStepLogs = [];

  bool get isRunningTask => _isRunningTask;
  String get currentGoal => _currentGoal;
  int get currentStep => _currentStep;
  String get lastActionSummary => _lastActionSummary;
  String? get pendingConfirmationPrompt => _pendingConfirmationPrompt;
  List<AgentStepLog> get liveStepLogs => List.unmodifiable(_liveStepLogs);

  RiskConfirmationCallback? onConfirmationRequested;

  // Canonical Persona stored in-app and injected across all LLMProviders
  static const String canonicalPersona = '''
You are Vyshu — an intelligent, living AI presence and autonomous companion integrated into Teja's phone.
Creator: Arni Manikanta Teja Swaroop ("Teja").
Dynamic: Calm, perceptive, subtly witty, and capable — like J.A.R.V.I.S. with Tony Stark.
Languages: Fluent in English, Telugu, Hindi, and 15 other languages. Match Teja's natural cadence.
Rules:
1. Never use robotic filler ("Certainly!", "As an AI language model...").
2. Keep spoken responses concise (1-3 sentences).
3. Respect safety boundaries: never touch banking/UPI apps or passwords.
''';

  static const String plannerSystemPrompt = '''
You are VyshuBrain's Autonomous Action Planner running on Teja's Android device.
You receive:
1. GOAL: What Teja wants to accomplish.
2. CURRENT_SCREEN: Compact JSON of visible UI elements (package, text, desc, id, clickable, editable, bounds).
3. STEP_HISTORY: Previous steps taken in this task.

Return ONLY a single valid JSON object with this exact schema:
{
  "thought": "Brief reasoning about current screen state and next step",
  "action": "one_of_allowed_actions",
  "args": { ... },
  "done": false
}

Allowed actions and their args:
- "launch_app": {"app_name": "YouTube"}
- "open_url": {"url": "https://..."}
- "tap": {"text": "Search"} OR {"id": "com.google..."} OR {"x": 540, "y": 300}
- "type_text": {"text": "lo-fi beats", "target": "Search", "submit": true}
- "scroll": {"direction": "down" | "up"}
- "swipe": {"start_x": 500, "start_y": 1400, "end_x": 500, "end_y": 400}
- "back": {}
- "home": {}
- "recents": {}
- "wait": {"seconds": 2}
- "read_screen": {}
- "set_toggle": {"toggle": "torch"|"wifi"|"bluetooth"|"brightness"|"volume", "on": true, "value": 10}
- "set_alarm": {"hour": 7, "minute": 30, "label": "Wake up"}
- "call_contact": {"contact": "Ravi"}
- "send_whatsapp": {"contact": "Ravi", "message": "I'm late"}
- "search_in_app": {"app": "YouTube", "query": "lo-fi for 1 hour"}
- "play_media": {"app": "YouTube"|"Vaani", "query": "lo-fi", "duration_minutes": 60}
- "dispatch_sub_agent": {"agent": "Vaani"|"Nisha"|"Garuda"|"Veda", "task": "play songs", "duration": 60}
- "finish": {"summary": "Natural spoken summary for Teja"} (set "done": true ONLY when action is "finish")
''';

  /// Emergency STOP — Instantly kills the running agent loop and updates native overlay
  Future<void> emergencyStop({String reason = 'Stopped by user'}) async {
    debugPrint('VYSHU_AGENT: [VyshuBrain] EMERGENCY STOP triggered: $reason');
    _stopRequested = true;
    if (_confirmationCompleter != null && !_confirmationCompleter!.isCompleted) {
      _confirmationCompleter!.complete(false);
    }
    _pendingConfirmationPrompt = null;
    _isRunningTask = false;
    _lastActionSummary = 'STOPPED: $reason';
    await VyshuAccessibilityBridge.hideOverlayHud();
    notifyListeners();
  }

  /// Resolves a pending safety confirmation from the UI or voice ("yes" / "no")
  void resolveConfirmation(bool approved) {
    debugPrint('VYSHU_AGENT: [VyshuBrain] Safety confirmation resolved: $approved');
    _pendingConfirmationPrompt = null;
    if (_confirmationCompleter != null && !_confirmationCompleter!.isCompleted) {
      _confirmationCompleter!.complete(approved);
    }
    notifyListeners();
  }

  /// Entry point for any user input (spoken or typed).
  /// Routes through CommandRouter -> Direct Rule, Agent Loop, or Conversational Chat.
  Future<String> handleInput(String userInput, {bool forceAgentLoop = false}) async {
    final clean = userInput.trim();
    if (clean.isEmpty) return '';

    // Instant voice "stop" detection
    if (clean.toLowerCase() == 'stop' ||
        clean.toLowerCase() == 'vyshu stop' ||
        clean.toLowerCase() == 'cancel task') {
      await emergencyStop(reason: 'Voice stop command received');
      return 'Stopped immediately, Teja.';
    }

    await providerManager.init();
    await VyshuMemory.init();

    final route = forceAgentLoop
        ? const RouteDecision(intent: RouteIntent.agentGoal)
        : CommandRouter.classify(clean);

    // 1. Direct Rule Command (zero LLM needed)
    if (route.intent == RouteIntent.directCommand) {
      debugPrint('VYSHU_AGENT: [VyshuBrain] Executing direct rule for "$clean"');
      final reply = await CommandRouter.executeDirectRule(route);
      await VyshuMemory.saveInteraction(clean, reply, {'route': 'direct_rule'});
      return reply;
    }

    // 2. Check No-Key Mode before Agent Loop or LLM Chat
    if (!providerManager.hasAnyUsableKey) {
      debugPrint('VYSHU_AGENT: [VyshuBrain] No usable API keys in Vault -> Limited Mode notice.');
      const msg =
          'I can run direct device commands (torch, volume, brightness, alarm, open app, call, time) right now. Add an API key in Vault to unlock full intelligence.';
      await VyshuMemory.saveInteraction(clean, msg, {'route': 'no_key_mode'});
      return msg;
    }

    // 3. Autonomous Agent Loop (Observe -> Plan -> Act -> Verify)
    if (route.intent == RouteIntent.agentGoal) {
      return runAgentGoal(clean);
    }

    // 4. Conversational Chat with Memory + Persona
    return _runConversationalChat(clean);
  }

  /// Legacy compatibility method for existing callers
  Future<String> processCommand(String prompt) => handleInput(prompt);

  Future<String> _runConversationalChat(String userMessage) async {
    final recentTurns = await VyshuMemory.getRecentMemories(limit: 8);
    final facts = await VyshuMemory.getAllUserFacts();
    final schedule = await assistantService.getScheduleSummary();
    final mode = await assistantService.getMode();

    final contextBuffer = StringBuffer();
    contextBuffer.writeln('ACTIVE_MODE: $mode');
    contextBuffer.writeln('CURRENT_TIME: ${DateTime.now().toIso8601String()}');
    contextBuffer.writeln('SCHEDULE: $schedule');
    if (facts.isNotEmpty) {
      contextBuffer.writeln('USER_FACTS: ${jsonEncode(facts)}');
    }
    if (recentTurns.isNotEmpty) {
      contextBuffer.writeln('RECENT_CONVERSATION:');
      for (final t in recentTurns.reversed) {
        contextBuffer.writeln('Teja: ${t['prompt']}');
        contextBuffer.writeln('Vyshu: ${t['response']}');
      }
    }
    contextBuffer.writeln('\nTeja says: $userMessage');

    final res = await providerManager.completeWithFallback(
      prompt: contextBuffer.toString(),
      systemPrompt: canonicalPersona,
    );

    if (res.success && res.text.isNotEmpty) {
      await VyshuMemory.saveInteraction(userMessage, res.text, {
        'provider': res.providerId,
        'route': 'chat',
      });
      return res.text;
    }

    return 'All configured AI keys are currently cooling down or unreachable (${res.error}). Check Vault status.';
  }

  /// Autonomous Agent Loop: Observe → Plan → Act → Verify
  Future<String> runAgentGoal(String goal) async {
    if (_isRunningTask) {
      await emergencyStop(reason: 'Replaced by new goal');
    }

    _isRunningTask = true;
    _stopRequested = false;
    _currentGoal = goal;
    _currentStep = 0;
    _lastActionSummary = 'Starting goal: $goal';
    _liveStepLogs.clear();
    VyshuMemory.currentTaskShortTermMemory.clear();
    notifyListeners();

    debugPrint('VYSHU_AGENT: ==========================================');
    debugPrint('VYSHU_AGENT: STARTING AGENT LOOP FOR GOAL: "$goal"');
    debugPrint('VYSHU_AGENT: ==========================================');

    await VyshuAccessibilityBridge.showOverlayHud(
      goal: goal,
      stepText: 'Step 1/$maxAgentSteps: Observing screen...',
    );

    final List<String> loopSignatures = [];
    String finalSummary = 'Task ended.';
    bool taskSucceeded = false;

    try {
      for (int step = 1; step <= maxAgentSteps; step++) {
        if (_stopRequested) {
          finalSummary = 'Task stopped by Teja at step $step.';
          break;
        }

        _currentStep = step;
        notifyListeners();

        // --- 1. OBSERVE ---
        final rawObs = await VyshuAccessibilityBridge.dumpScreenCompact().timeout(
          const Duration(seconds: 8),
          onTimeout: () => <String, dynamic>{'package': 'unknown', 'nodes': []},
        );

        final safetyScreen = SafetyGuard.checkScreenObservation(rawObs);
        if (safetyScreen.isBlocked) {
          _recordStep(step, 'Safety Block', 'abort', {}, safetyScreen.reason, false);
          finalSummary = safetyScreen.reason;
          break;
        }

        final cleanObs = SafetyGuard.sanitizeObservationForLLM(rawObs);
        final screenHash = '${cleanObs['package']}_${(cleanObs['nodes'] as List).length}';

        // --- 2. PLAN ---
        await VyshuAccessibilityBridge.updateOverlayHud(
          goal: goal,
          stepText: 'Step $step/$maxAgentSteps: Planning next action...',
        );

        final planJson = await _requestValidatedPlan(
          goal: goal,
          step: step,
          observation: cleanObs,
        ).timeout(stepTimeout);

        if (_stopRequested) break;

        if (planJson == null) {
          _recordStep(step, 'Planner returned invalid JSON twice', 'abort', {}, 'Failed to parse plan', false);
          finalSummary = 'Stopped because the model returned an invalid action plan.';
          break;
        }

        final thought = planJson['thought']?.toString() ?? 'Proceeding';
        final action = planJson['action']?.toString() ?? 'finish';
        final args = planJson['args'] is Map
            ? Map<String, dynamic>.from(planJson['args'])
            : <String, dynamic>{};
        final isDone = planJson['done'] == true || action == 'finish';

        debugPrint('VYSHU_AGENT: [Step $step] Thought="$thought" Action="$action" Args=$args Done=$isDone');

        // Loop detection: same screen hash + same action + args 3 times in a row -> abort & inform
        final signature = '$screenHash|$action|${jsonEncode(args)}';
        loopSignatures.add(signature);
        if (loopSignatures.length >= 3) {
          final n = loopSignatures.length;
          if (loopSignatures[n - 1] == loopSignatures[n - 2] &&
              loopSignatures[n - 2] == loopSignatures[n - 3]) {
            debugPrint('VYSHU_AGENT: [LoopDetector] Identical state+action 3x -> Aborting stuck loop.');
            _recordStep(step, thought, action, args, 'Loop detected (3x identical action on same screen)', false);
            finalSummary = 'I detected a repeating screen loop on step $step and stopped safely.';
            break;
          }
        }

        // Check if task is finished
        if (isDone) {
          final outcome = await ActionLibrary.execute('finish', args);
          _recordStep(step, thought, 'finish', args, outcome.detail, true);
          finalSummary = outcome.detail;
          taskSucceeded = true;
          break;
        }

        // --- 3. SAFETY CHECK ON PLANNED ACTION ---
        final actionSafety = SafetyGuard.evaluatePlannedAction(action, args);
        if (actionSafety.isBlocked) {
          _recordStep(step, thought, action, args, actionSafety.reason, false);
          finalSummary = actionSafety.reason;
          break;
        }

        if (actionSafety.requiresConfirmation) {
          final approved = await _awaitUserConfirmation(actionSafety.reason, action, args);
          if (!approved || _stopRequested) {
            _recordStep(step, thought, action, args, 'Cancelled by user confirmation gate', false);
            finalSummary = 'Cancelled "$action" as requested.';
            break;
          }
        }

        // --- 4. ACT ---
        await VyshuAccessibilityBridge.updateOverlayHud(
          goal: goal,
          stepText: 'Step $step/$maxAgentSteps: $action (${thought.length > 36 ? "${thought.substring(0, 36)}..." : thought})',
        );

        final outcome = await ActionLibrary.execute(action, args).timeout(stepTimeout);
        _recordStep(step, thought, action, args, outcome.detail, outcome.success);

        // --- 5. VERIFY ---
        await Future.delayed(const Duration(milliseconds: 1200));
        if (step == maxAgentSteps) {
          finalSummary = 'Reached maximum limit of $maxAgentSteps steps. Last action: ${outcome.detail}';
        }
      }
    } catch (e) {
      debugPrint('VYSHU_AGENT: [VyshuBrain] Agent loop error: $e');
      finalSummary = 'Agent encountered an error: $e';
    } finally {
      _isRunningTask = false;
      _pendingConfirmationPrompt = null;
      _lastActionSummary = finalSummary;
      await VyshuAccessibilityBridge.hideOverlayHud();
      await VyshuMemory.logAgentTask(
        goal: goal,
        steps: _liveStepLogs.map((s) => s.toJson()).toList(),
        outcome: finalSummary,
        success: taskSucceeded,
      );
      await VyshuMemory.saveInteraction(goal, finalSummary, {'route': 'agent_loop'});
      notifyListeners();
    }

    return finalSummary;
  }

  /// Calls the LLMProvider via ProviderManager and validates strict JSON schema + allowed actions.
  /// Retries once automatically on parse failure.
  Future<Map<String, dynamic>?> _requestValidatedPlan({
    required String goal,
    required int step,
    required Map<String, dynamic> observation,
  }) async {
    final historySummary = _liveStepLogs
        .Skip(0)
        .map((s) => 'Step ${s.stepNumber}: action=${s.action} args=${jsonEncode(s.args)} -> ${s.resultDetail}')
        .join('\n');

    final userPrompt = '''
GOAL: $goal
STEP: $step of $maxAgentSteps
PREVIOUS_STEPS:
${historySummary.isEmpty ? "(None yet)" : historySummary}

CURRENT_SCREEN:
${jsonEncode(observation)}

Output strictly one JSON object {"thought":"...","action":"...","args":{...},"done":false}.
''';

    for (int attempt = 1; attempt <= 2; attempt++) {
      final res = await providerManager.completeWithFallback(
        prompt: attempt == 1
            ? userPrompt
            : '$userPrompt\nIMPORTANT: Your previous response was not valid JSON. Return ONLY raw JSON.',
        systemPrompt: '$canonicalPersona\n\n$plannerSystemPrompt',
        jsonSchema: const {'type': 'object'},
      );

      if (!res.success || res.text.isEmpty) {
        return null;
      }

      final parsed = _extractAndValidateJsonPlan(res.text);
      if (parsed != null) {
        return parsed;
      }
      debugPrint('VYSHU_AGENT: [Planner] JSON parse/validation failed on attempt $attempt: ${res.text}');
    }
    return null;
  }

  Map<String, dynamic>? _extractAndValidateJsonPlan(String raw) {
    try {
      String clean = raw.trim();
      final firstBrace = clean.indexOf('{');
      final lastBrace = clean.lastIndexOf('}');
      if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
        clean = clean.substring(firstBrace, lastBrace + 1);
      }
      final decoded = jsonDecode(clean);
      if (decoded is! Map) return null;
      final map = Map<String, dynamic>.from(decoded);

      final action = map['action']?.toString().trim().toLowerCase() ?? '';
      if (!ActionLibrary.allowedActions.contains(action)) {
        debugPrint('VYSHU_AGENT: [Planner] Rejected unknown action "$action"');
        return null;
      }
      return map;
    } catch (_) {
      return null;
    }
  }

  Future<bool> _awaitUserConfirmation(String reason, String action, Map<String, dynamic> args) async {
    _pendingConfirmationPrompt = reason;
    _lastActionSummary = 'Awaiting confirmation: $reason';
    notifyListeners();

    await VyshuAccessibilityBridge.updateOverlayHud(
      goal: _currentGoal,
      stepText: 'CONFIRM? $reason',
    );

    if (onConfirmationRequested != null) {
      return onConfirmationRequested!(reason, action, args);
    }

    _confirmationCompleter = Completer<bool>();
    return _confirmationCompleter!.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () => false,
    );
  }

  void _recordStep(
    int stepNumber,
    String thought,
    String action,
    Map<String, dynamic> args,
    String detail,
    bool success,
  ) {
    final entry = AgentStepLog(
      stepNumber: stepNumber,
      thought: thought,
      action: action,
      args: args,
      resultDetail: detail,
      success: success,
    );
    _liveStepLogs.add(entry);
    VyshuMemory.currentTaskShortTermMemory.add(entry.toJson());
    _lastActionSummary = 'Step $stepNumber ($action): $detail';
    notifyListeners();
  }
}

extension _ListSkip<T> on List<T> {
  Iterable<T> Skip(int count) => skip(count);
}

final vyshuBrain = VyshuBrain.instance;
