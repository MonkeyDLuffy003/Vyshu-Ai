import 'package:flutter/foundation.dart';
import 'action_library.dart';
import 'llm_provider.dart';

enum RouteIntent {
  directCommand, // (a) Zero LLM rule-based immediate device command
  agentGoal, // (b) Complex multi-step UI goal -> Observe-Plan-Act-Verify loop
  conversationalChat, // (c) Conversational query through VyshuBrain
}

class RouteDecision {
  final RouteIntent intent;
  final String? directAction;
  final Map<String, dynamic> directArgs;
  final String? immediateReply;

  const RouteDecision({
    required this.intent,
    this.directAction,
    this.directArgs = const {},
    this.immediateReply,
  });
}

/// CommandRouter — Decides per request:
/// (a) Zero-LLM direct rule command (torch, volume, brightness, alarm, open single app, call, time)
/// (b) Autonomous multi-step Agent Loop ("open YouTube and play lo-fi for 1 hour", "message Ravi on WhatsApp I'm late")
/// (c) Normal conversational chat through VyshuBrain (with No-Key notice if Vault is empty)
class CommandRouter {
  /// Classifies a user utterance or typed goal
  static RouteDecision classify(String input) {
    final text = input.trim();
    final lower = text.toLowerCase();

    // 1. Check if it's a multi-step compound goal ("and", "then", "play ... for ... hour", "message ... on whatsapp")
    final isCompoundAgentGoal = (lower.contains(' and ') &&
            (lower.contains('open ') ||
                lower.contains('play ') ||
                lower.contains('search ') ||
                lower.contains('tap ') ||
                lower.contains('send ') ||
                lower.contains('type '))) ||
        RegExp(r'(?:message|whatsapp|text)\s+(.+?)\s+(?:on whatsapp\s+)?(?:that|saying|i am|i' "'" r'm)\s+(.+)',
                caseSensitive: false)
            .hasMatch(lower) ||
        RegExp(r'play\s+(.+?)\s+for\s+(\d+)\s*(hour|hr|minute|min)', caseSensitive: false).hasMatch(lower) ||
        lower.startsWith('agent:') ||
        lower.contains('step by step');

    if (isCompoundAgentGoal) {
      debugPrint('VYSHU_AGENT: [CommandRouter] Classified as AGENT_GOAL: "$text"');
      return const RouteDecision(intent: RouteIntent.agentGoal);
    }

    // 2. Direct Rule Commands (Zero LLM latency — works in No-Key mode!)

    // Time / Date query
    if (lower == 'what time is it' ||
        lower == 'what is the time' ||
        lower == 'current time' ||
        lower == 'tell me the time' ||
        lower == 'time') {
      final now = DateTime.now();
      final hh = now.hour.toString().padLeft(2, '0');
      final mm = now.minute.toString().padLeft(2, '0');
      return RouteDecision(
        intent: RouteIntent.directCommand,
        directAction: 'finish',
        directArgs: {'summary': 'It is $hh:$mm right now, Teja.'},
        immediateReply: 'It is $hh:$mm right now, Teja.',
      );
    }

    // Torch / Flashlight
    if (lower.contains('torch on') ||
        lower.contains('turn on torch') ||
        lower.contains('turn on the torch') ||
        lower.contains('flashlight on') ||
        lower.contains('turn on flashlight')) {
      return const RouteDecision(
        intent: RouteIntent.directCommand,
        directAction: 'set_toggle',
        directArgs: {'toggle': 'torch', 'on': true},
        immediateReply: 'There you go. Torch is on.',
      );
    }
    if (lower.contains('torch off') ||
        lower.contains('turn off torch') ||
        lower.contains('turn off the torch') ||
        lower.contains('flashlight off') ||
        lower.contains('turn off flashlight')) {
      return const RouteDecision(
        intent: RouteIntent.directCommand,
        directAction: 'set_toggle',
        directArgs: {'toggle': 'torch', 'on': false},
        immediateReply: 'Torch turned off.',
      );
    }

    // Volume
    final volMatch = RegExp(r'(?:set\s+)?volume\s+(?:to\s+)?(\d{1,2})').firstMatch(lower);
    if (volMatch != null) {
      final level = int.tryParse(volMatch.group(1)!) ?? 7;
      return RouteDecision(
        intent: RouteIntent.directCommand,
        directAction: 'set_toggle',
        directArgs: {'toggle': 'volume', 'value': level.clamp(0, 15)},
        immediateReply: 'Media volume set to $level.',
      );
    }

    // Brightness
    final brightMatch = RegExp(r'(?:set\s+)?brightness\s+(?:to\s+)?(\d{1,3})').firstMatch(lower);
    if (brightMatch != null) {
      final val = int.tryParse(brightMatch.group(1)!) ?? 160;
      return RouteDecision(
        intent: RouteIntent.directCommand,
        directAction: 'set_toggle',
        directArgs: {'toggle': 'brightness', 'value': val.clamp(0, 255)},
        immediateReply: 'Display brightness set to $val.',
      );
    }

    // Sleep Mode activation / deactivation commands
    if (lower.contains('sleep mode on') ||
        lower.contains('turn on sleep mode') ||
        lower.contains('activate sleep mode') ||
        lower.contains('enable sleep mode') ||
        lower == 'good night' ||
        lower == 'goodnight vyshu') {
      return const RouteDecision(
        intent: RouteIntent.directCommand,
        directAction: 'set_sleep_mode',
        directArgs: {'enabled': true},
        immediateReply: 'Sleep Mode activated. Good night, Teja. I will keep responses quiet and text-only.',
      );
    }

    if (lower.contains('sleep mode off') ||
        lower.contains('turn off sleep mode') ||
        lower.contains('deactivate sleep mode') ||
        lower.contains('disable sleep mode') ||
        lower == 'good morning' ||
        lower == 'wake up vyshu') {
      return const RouteDecision(
        intent: RouteIntent.directCommand,
        directAction: 'set_sleep_mode',
        directArgs: {'enabled': false},
        immediateReply: 'Sleep Mode deactivated. Good morning, Teja! Normal voice output restored.',
      );
    }

    // Alarm: "set alarm for 6:30" or "set an alarm at 07:15"
    final alarmMatch = RegExp(r'alarm\s+(?:for|at)\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?').firstMatch(lower);
    if (alarmMatch != null) {
      int hour = int.tryParse(alarmMatch.group(1)!) ?? 7;
      final int minute = int.tryParse(alarmMatch.group(2) ?? '0') ?? 0;
      final ampm = alarmMatch.group(3);
      if (ampm == 'pm' && hour < 12) hour += 12;
      if (ampm == 'am' && hour == 12) hour = 0;

      return RouteDecision(
        intent: RouteIntent.directCommand,
        directAction: 'set_alarm',
        directArgs: {'hour': hour, 'minute': minute, 'label': 'Vyshu Alarm'},
        immediateReply:
            'Alarm set for ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}, Teja.',
      );
    }

    // Simple Call: "call Mom" / "call Ravi"
    final callMatch = RegExp(r'^call\s+([a-zA-Z0-9\s]+)$').firstMatch(text);
    if (callMatch != null) {
      final contact = callMatch.group(1)!.trim();
      return RouteDecision(
        intent: RouteIntent.directCommand,
        directAction: 'call_contact',
        directArgs: {'contact': contact},
        immediateReply: 'Calling $contact.',
      );
    }

    // Simple Open App: "open YouTube", "open Spotify", "open Instagram"
    final openMatch = RegExp(r'^(?:open|launch)\s+([a-zA-Z0-9\s]+)$', caseSensitive: false).firstMatch(text);
    if (openMatch != null) {
      final appName = openMatch.group(1)!.trim();
      return RouteDecision(
        intent: RouteIntent.directCommand,
        directAction: 'launch_app',
        directArgs: {'app_name': appName},
        immediateReply: 'Opening $appName right away.',
      );
    }

    // Sub-agent direct trigger: "play songs in Vaani for 1 hour"
    final vaaniMatch =
        RegExp(r'vaani.*for\s+(\d+)\s*(hour|hr|minute|min)', caseSensitive: false).firstMatch(lower);
    if (vaaniMatch != null) {
      final numVal = int.tryParse(vaaniMatch.group(1)!) ?? 1;
      final unit = vaaniMatch.group(2)!.toLowerCase();
      final minutes = unit.startsWith('h') ? numVal * 60 : numVal;
      return RouteDecision(
        intent: RouteIntent.directCommand,
        directAction: 'dispatch_sub_agent',
        directArgs: {'agent': 'Vaani', 'task': text, 'duration': minutes},
        immediateReply: 'Dispatched to Vaani for $minutes minutes with auto-stop active.',
      );
    }

    // Focus Agent direct command: "start focus mode for 30 minutes"
    final focusMatch =
        RegExp(r'(?:start\s+)?focus(?:\s+mode|\s+session)?(?:\s+for\s+(\d+)\s*(?:min|minutes))?', caseSensitive: false)
            .firstMatch(lower);
    if (focusMatch != null && !lower.contains('stop')) {
      final mins = int.tryParse(focusMatch.group(1) ?? '25') ?? 25;
      return RouteDecision(
        intent: RouteIntent.directCommand,
        directAction: 'start_focus',
        directArgs: {'minutes': mins, 'goal': 'Deep Work'},
        immediateReply: 'Focus session started for $mins minutes. Distracting apps are now blocked.',
      );
    }

    // Samsung TV direct command: "turn on tv" / "turn off tv" / "play ... on tv"
    if (lower == 'turn on tv' || lower == 'tv on' || lower == 'turn on samsung tv') {
      return const RouteDecision(
        intent: RouteIntent.directCommand,
        directAction: 'control_tv',
        directArgs: {'command': 'power_on'},
        immediateReply: 'Turning on your Samsung Smart TV.',
      );
    }
    if (lower == 'turn off tv' || lower == 'tv off' || lower == 'turn off samsung tv') {
      return const RouteDecision(
        intent: RouteIntent.directCommand,
        directAction: 'control_tv',
        directArgs: {'command': 'power_off'},
        immediateReply: 'Turning off your Samsung Smart TV.',
      );
    }

    // News Express direct command: "tell me the news", "latest tech news", "ai news"
    if (lower.startsWith('news') ||
        lower.contains('tell me the news') ||
        lower.contains('latest news') ||
        lower.contains('news briefing') ||
        lower.endsWith('news')) {
      return RouteDecision(
        intent: RouteIntent.directCommand,
        directAction: 'get_news',
        directArgs: {'topic': text},
        immediateReply: null,
      );
    }

    // Language Coach drill: "drill telugu", "teach me hindi", "spanish drill"
    final drillMatch =
        RegExp(r'(?:drill|teach me|practice)\s+([a-zA-Z]+)(?:\s+drill|\s+words)?', caseSensitive: false)
            .firstMatch(lower);
    if (drillMatch != null) {
      final lang = drillMatch.group(1)!;
      return RouteDecision(
        intent: RouteIntent.directCommand,
        directAction: 'coach_language',
        directArgs: {'language': lang, 'drill': true},
        immediateReply: null,
      );
    }

    // 3. Default to Conversational Chat through VyshuBrain
    debugPrint('VYSHU_AGENT: [CommandRouter] Classified as CONVERSATIONAL_CHAT: "$text"');
    return const RouteDecision(intent: RouteIntent.conversationalChat);
  }

  /// Executes a direct rule command without needing any LLM key.
  static Future<String> executeDirectRule(RouteDecision decision) async {
    if (decision.directAction == null) {
      return decision.immediateReply ?? 'Done.';
    }
    final outcome = await ActionLibrary.execute(decision.directAction!, decision.directArgs);
    final baseReply = decision.immediateReply ?? outcome.detail;
    if (!providerManager.hasAnyUsableKey) {
      return '$baseReply\n\n(Add an API key in Vault to unlock full intelligence.)';
    }
    return baseReply;
  }
}
