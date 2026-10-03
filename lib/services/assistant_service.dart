import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ScheduledTaskItem {
  final String id;
  String title;
  String scheduledDate;
  String startTime;
  String priority;
  String status;
  int postponedCount;
  String? originalTime;

  ScheduledTaskItem({
    required this.id,
    required this.title,
    required this.scheduledDate,
    required this.startTime,
    this.priority = 'medium',
    this.status = 'pending',
    this.postponedCount = 0,
    this.originalTime,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'scheduledDate': scheduledDate,
        'startTime': startTime,
        'priority': priority,
        'status': status,
        'postponedCount': postponedCount,
        'originalTime': originalTime,
      };

  factory ScheduledTaskItem.fromJson(Map<String, dynamic> j) => ScheduledTaskItem(
        id: j['id'] ?? '',
        title: j['title'] ?? '',
        scheduledDate: j['scheduledDate'] ?? '',
        startTime: j['startTime'] ?? '12:00',
        priority: j['priority'] ?? 'medium',
        status: j['status'] ?? 'pending',
        postponedCount: j['postponedCount'] ?? 0,
        originalTime: j['originalTime'],
      );
}

class AssistantService {
  static const String _tasksKey = 'vyshu_scheduled_tasks_v2';
  static const String _modeKey = 'vyshu_active_mode_v2';
  static const String _memKey = 'vyshu_memories_v2';

  // 1. Mode Management
  Future<String> getMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_modeKey) ?? 'HOME';
  }

  Future<void> setMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, mode);
  }

  // 2. Schedule Management
  Future<List<ScheduledTaskItem>> getTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_tasksKey);
    if (raw == null || raw.isEmpty) {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final defaults = [
        ScheduledTaskItem(
          id: '1',
          title: 'Professional Work & Standup',
          scheduledDate: today,
          startTime: '09:00',
          priority: 'high',
          status: 'completed',
        ),
        ScheduledTaskItem(
          id: '2',
          title: 'V3 Testing & Architecture Review',
          scheduledDate: today,
          startTime: '16:00',
          priority: 'high',
          status: 'pending',
          postponedCount: 1,
          originalTime: '11:00',
        ),
        ScheduledTaskItem(
          id: '3',
          title: 'Creator Task & Video Sync',
          scheduledDate: today,
          startTime: '20:30',
          priority: 'medium',
          status: 'pending',
        ),
      ];
      await saveTasks(defaults);
      return defaults;
    }

    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => ScheduledTaskItem.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveTasks(List<ScheduledTaskItem> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tasksKey, jsonEncode(tasks.map((t) => t.toJson()).toList()));
  }

  Future<bool> rescheduleTask(String query, String newTime, {String? newDate}) async {
    final tasks = await getTasks();
    final lower = query.toLowerCase().trim();
    final task = tasks.firstWhere(
      (t) => t.title.toLowerCase().contains(lower),
      orElse: () => ScheduledTaskItem(id: '', title: '', scheduledDate: '', startTime: ''),
    );

    if (task.id.isEmpty) return false;

    task.originalTime = task.startTime;
    task.startTime = newTime;
    if (newDate != null) task.scheduledDate = newDate;
    task.postponedCount += 1;
    task.status = 'postponed';

    await saveTasks(tasks);
    return true;
  }

  Future<String> getScheduleSummary() async {
    final tasks = await getTasks();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final pending = tasks.where((t) => t.scheduledDate == today && t.status != 'completed').toList();

    if (pending.isEmpty) return "No remaining scheduled tasks for today. You are caught up.";

    final lines = pending.map((t) => "- [${t.startTime}] ${t.title} (${t.priority.toUpperCase()})").join("\n");
    return "Remaining tasks today:\n$lines";
  }
}

final assistantService = AssistantService();
