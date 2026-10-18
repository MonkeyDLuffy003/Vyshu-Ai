import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// VyshuMemory — Local On-Device Memory Manager (Hive)
///
/// Manages three persistent stores across provider switches:
/// 1. Long-term Chat History (14-day rolling retention)
/// 2. User Facts & Learned Shortcuts (persistent preferences, contacts, app habits)
/// 3. Agent Task Logs (goal, steps taken, final outcome)
class VyshuMemory {
  static const String boxName = 'vyshu_memory_box';
  static const String factsBoxName = 'vyshu_facts_box';
  static const String taskLogsBoxName = 'vyshu_task_logs_box';
  static const int retentionDays = 14;

  static Box? _box;
  static Box? _factsBox;
  static Box? _taskLogsBox;

  // Short-term working memory for the active agent loop
  static final List<Map<String, dynamic>> currentTaskShortTermMemory = [];

  /// Initializes Hive and opens the Vyshu memory boxes.
  static Future<void> init() async {
    try {
      await Hive.initFlutter();
      _box = await Hive.openBox(boxName);
      _factsBox = await Hive.openBox(factsBoxName);
      _taskLogsBox = await Hive.openBox(taskLogsBoxName);
      await cleanOldMemories();
      debugPrint('VYSHU_AGENT: [VyshuMemory] Initialized 14d chat, facts, and task logs.');
    } catch (e) {
      debugPrint('VYSHU_AGENT: [VyshuMemory] Initialization error: $e');
    }
  }

  static Future<Box> _getBox() async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox(boxName);
    return _box!;
  }

  static Future<Box> _getFactsBox() async {
    if (_factsBox != null && _factsBox!.isOpen) return _factsBox!;
    _factsBox = await Hive.openBox(factsBoxName);
    return _factsBox!;
  }

  static Future<Box> _getTaskLogsBox() async {
    if (_taskLogsBox != null && _taskLogsBox!.isOpen) return _taskLogsBox!;
    _taskLogsBox = await Hive.openBox(taskLogsBoxName);
    return _taskLogsBox!;
  }

  static Future<void> saveInteraction(
    String prompt,
    String response, [
    Map<String, dynamic>? metadata,
  ]) async {
    await saveMemory(prompt: prompt, response: response, metadata: metadata);
    _extractAndSaveUserFacts(prompt);
  }

  static Future<List<Map<String, dynamic>>> getHistory({int limit = 50}) async {
    return getRecentMemories(limit: limit);
  }

  static Future<void> saveMemory({
    required String prompt,
    required String response,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final box = await _getBox();
      final now = DateTime.now();
      final key = 'turn_${now.millisecondsSinceEpoch}';

      final record = {
        'id': key,
        'prompt': prompt,
        'response': response,
        'timestamp': now.toIso8601String(),
        'metadata': metadata ?? {},
      };

      await box.put(key, record);
      await cleanOldMemories();
    } catch (e) {
      debugPrint('VYSHU_AGENT: [VyshuMemory] Failed to save memory turn: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getRecentMemories({int limit = 20}) async {
    try {
      final box = await _getBox();
      final List<Map<String, dynamic>> memories = [];

      for (var key in box.keys) {
        final val = box.get(key);
        if (val is Map) {
          memories.add(Map<String, dynamic>.from(val));
        }
      }

      memories.sort((a, b) {
        final aTime = DateTime.tryParse(a['timestamp']?.toString() ?? '') ?? DateTime(1970);
        final bTime = DateTime.tryParse(b['timestamp']?.toString() ?? '') ?? DateTime(1970);
        return bTime.compareTo(aTime);
      });

      if (memories.length > limit) {
        return memories.sublist(0, limit);
      }
      return memories;
    } catch (e) {
      debugPrint('VYSHU_AGENT: [VyshuMemory] Failed to retrieve memories: $e');
      return [];
    }
  }

  static Future<void> cleanOldMemories() async {
    try {
      final box = await _getBox();
      final cutoff = DateTime.now().subtract(const Duration(days: retentionDays));
      final keysToDelete = <dynamic>[];

      for (var key in box.keys) {
        final val = box.get(key);
        if (val is Map) {
          final tsStr = val['timestamp']?.toString();
          if (tsStr != null) {
            final ts = DateTime.tryParse(tsStr);
            if (ts != null && ts.isBefore(cutoff)) {
              keysToDelete.add(key);
            }
          }
        }
      }

      if (keysToDelete.isNotEmpty) {
        await box.deleteAll(keysToDelete);
      }
    } catch (e) {
      debugPrint('VYSHU_AGENT: [VyshuMemory] Error cleaning old memories: $e');
    }
  }

  static Future<void> clearAll() async {
    try {
      final box = await _getBox();
      await box.clear();
    } catch (e) {
      debugPrint('VYSHU_AGENT: [VyshuMemory] Error clearing memory box: $e');
    }
  }

  // --- USER FACTS & LEARNED SHORTCUTS ---

  static Future<void> saveUserFact(String key, String value) async {
    try {
      final box = await _getFactsBox();
      await box.put(key, value);
    } catch (e) {
      debugPrint('VYSHU_AGENT: [VyshuMemory] Failed to save fact: $e');
    }
  }

  static Future<Map<String, String>> getAllUserFacts() async {
    try {
      final box = await _getFactsBox();
      final Map<String, String> result = {};
      for (final k in box.keys) {
        result[k.toString()] = box.get(k)?.toString() ?? '';
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  static void _extractAndSaveUserFacts(String prompt) {
    final lower = prompt.toLowerCase();
    if (lower.contains('remember that ') || lower.contains('my favorite ')) {
      saveUserFact('note_${DateTime.now().millisecondsSinceEpoch}', prompt.trim());
    }
  }

  // --- AGENT TASK LOGS ---

  static Future<void> logAgentTask({
    required String goal,
    required List<Map<String, dynamic>> steps,
    required String outcome,
    required bool success,
  }) async {
    try {
      final box = await _getTaskLogsBox();
      final now = DateTime.now();
      final key = 'task_${now.millisecondsSinceEpoch}';
      await box.put(key, {
        'id': key,
        'goal': goal,
        'stepsCount': steps.length,
        'steps': jsonEncode(steps),
        'outcome': outcome,
        'success': success,
        'timestamp': now.toIso8601String(),
      });
    } catch (e) {
      debugPrint('VYSHU_AGENT: [VyshuMemory] Error saving task log: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getRecentTaskLogs({int limit = 15}) async {
    try {
      final box = await _getTaskLogsBox();
      final List<Map<String, dynamic>> list = [];
      for (final k in box.keys) {
        final v = box.get(k);
        if (v is Map) list.add(Map<String, dynamic>.from(v));
      }
      list.sort((a, b) => (b['timestamp']?.toString() ?? '').compareTo(a['timestamp']?.toString() ?? ''));
      return list.take(limit).toList();
    } catch (_) {
      return [];
    }
  }
}
