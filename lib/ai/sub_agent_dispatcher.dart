import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../services/vyshu_accessibility_bridge.dart';

/// Contract for Sub-Agent Task Dispatch: {agent, task, duration, status}
class SubAgentTask {
  final String id;
  final String agent; // Vaani (music), Nisha, Garuda, Veda
  final String task;
  final int durationMinutes;
  String status; // 'running' | 'completed' | 'stopped' | 'failed'
  final DateTime startedAt;
  Timer? _autoStopTimer;

  SubAgentTask({
    required this.id,
    required this.agent,
    required this.task,
    required this.durationMinutes,
    this.status = 'running',
    DateTime? startedAt,
  }) : startedAt = startedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'agent': agent,
        'task': task,
        'duration': durationMinutes,
        'status': status,
        'startedAt': startedAt.toIso8601String(),
      };

  String toJsonString() => jsonEncode(toJson());
}

/// SubAgentDispatcher — Clean interface so Vyshu can dispatch tasks to
/// Vaani (music), Nisha, Garuda, and Veda with timed auto-stop support.
class SubAgentDispatcher extends ChangeNotifier {
  static final SubAgentDispatcher instance = SubAgentDispatcher._internal();
  factory SubAgentDispatcher() => instance;
  SubAgentDispatcher._internal();

  static const Set<String> registeredSubAgents = {
    'Vaani',
    'Nisha',
    'Garuda',
    'Veda',
  };

  final List<SubAgentTask> _activeTasks = [];
  List<SubAgentTask> get activeTasks => List.unmodifiable(_activeTasks);

  /// Dispatches a task to a named sub-agent and schedules auto-stop if duration > 0.
  Future<SubAgentTask> dispatch({
    required String agent,
    required String task,
    int durationMinutes = 0,
  }) async {
    final normalizedAgent = registeredSubAgents.firstWhere(
      (a) => a.toLowerCase() == agent.trim().toLowerCase(),
      orElse: () => 'Vaani',
    );

    final subTask = SubAgentTask(
      id: 'sub_${DateTime.now().millisecondsSinceEpoch}',
      agent: normalizedAgent,
      task: task,
      durationMinutes: durationMinutes,
      status: 'running',
    );

    _activeTasks.insert(0, subTask);
    debugPrint('VYSHU_AGENT: [SubAgentDispatcher] Dispatched ${subTask.toJsonString()}');

    // Execute real underlying device action for Vaani music or stub for others
    if (normalizedAgent == 'Vaani') {
      await VyshuAccessibilityBridge.openApp('Vaani');
    }

    if (durationMinutes > 0) {
      subTask._autoStopTimer = Timer(Duration(minutes: durationMinutes), () async {
        await stopTask(subTask.id, reason: 'Timed duration ($durationMinutes min) completed');
      });
    }

    notifyListeners();
    return subTask;
  }

  /// Stops a running sub-agent task immediately (or when timer expires).
  Future<void> stopTask(String id, {String reason = 'Manual stop'}) async {
    final idx = _activeTasks.indexWhere((t) => t.id == id);
    if (idx == -1) return;

    final task = _activeTasks[idx];
    task._autoStopTimer?.cancel();
    task.status = 'stopped';
    debugPrint('VYSHU_AGENT: [SubAgentDispatcher] Stopped ${task.agent} task ($id): $reason');

    if (task.agent == 'Vaani') {
      // Pause media / return home when timed music session ends
      await VyshuAccessibilityBridge.pressHome();
    }
    notifyListeners();
  }

  Future<void> stopAll() async {
    for (final t in _activeTasks) {
      t._autoStopTimer?.cancel();
      t.status = 'stopped';
    }
    notifyListeners();
  }
}

final subAgentDispatcher = SubAgentDispatcher.instance;
