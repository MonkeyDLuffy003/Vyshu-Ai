import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// VyshuMemory — 14-Day Local On-Device Memory Manager
/// 
/// Stores conversation history, prompts, and contextual memory turns locally in Hive.
/// Automatically cleans up memories older than 14 days to preserve phone storage
/// and respect Android device memory limits.
class VyshuMemory {
  static const String boxName = 'vyshu_memory_box';
  static const int retentionDays = 14;

  static Box? _box;

  /// Initializes Hive and opens the Vyshu memory box.
  static Future<void> init() async {
    try {
      await Hive.initFlutter();
      _box = await Hive.openBox(boxName);
      await cleanOldMemories();
    } catch (e) {
      debugPrint('[VyshuMemory] Initialization error: $e');
    }
  }

  /// Get active memory box instance, opening it if not already open.
  static Future<Box> _getBox() async {
    if (_box != null && _box!.isOpen) {
      return _box!;
    }
    _box = await Hive.openBox(boxName);
    return _box!;
  }

  /// Save interaction turn into 14-day memory box
  static Future<void> saveInteraction(String prompt, String response, [Map<String, dynamic>? metadata]) async {
    await saveMemory(prompt: prompt, response: response, metadata: metadata);
  }

  /// Get interaction history within 14 days
  static Future<List<Map<String, dynamic>>> getHistory({int limit = 50}) async {
    return getRecentMemories(limit: limit);
  }

  /// Save a prompt and response pair along with a timestamp.
  /// 
  /// Structure stored in Hive:
  /// {
  ///   "prompt": prompt,
  ///   "response": response,
  ///   "timestamp": DateTime.now().toIso8601String(),
  ///   "metadata": metadata ?? {},
  /// }
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

      // Periodically clean up old entries older than 14 days
      await cleanOldMemories();
    } catch (e) {
      debugPrint('[VyshuMemory] Failed to save memory turn: $e');
    }
  }

  /// Retrieves all memories within the 14-day retention window, ordered chronologically.
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

      // Sort by timestamp descending
      memories.sort((a, b) {
        final aTime = DateTime.tryParse(a['timestamp'] ?? '') ?? DateTime(1970);
        final bTime = DateTime.tryParse(b['timestamp'] ?? '') ?? DateTime(1970);
        return bTime.compareTo(aTime);
      });

      return memories.take(limit).toList();
    } catch (e) {
      debugPrint('[VyshuMemory] Error getting recent memories: $e');
      return [];
    }
  }

  /// Deletes any Hive keys older than 14 days to preserve phone storage.
  static Future<void> cleanOldMemories() async {
    try {
      final box = await _getBox();
      final cutoffDate = DateTime.now().subtract(const Duration(days: retentionDays));
      final keysToDelete = <dynamic>[];

      for (var key in box.keys) {
        final item = box.get(key);
        if (item is Map) {
          final timestampStr = item['timestamp'] as String?;
          if (timestampStr != null) {
            final itemDate = DateTime.tryParse(timestampStr);
            if (itemDate != null && itemDate.isBefore(cutoffDate)) {
              keysToDelete.add(key);
            }
          }
        }
      }

      if (keysToDelete.isNotEmpty) {
        await box.deleteAll(keysToDelete);
        debugPrint('[VyshuMemory] Cleaned ${keysToDelete.length} memories older than 14 days.');
      }
    } catch (e) {
      debugPrint('[VyshuMemory] Error cleaning old memories: $e');
    }
  }

  /// Clear all memories (for privacy or reset).
  static Future<void> clearAll() async {
    try {
      final box = await _getBox();
      await box.clear();
    } catch (e) {
      debugPrint('[VyshuMemory] Error clearing memories: $e');
    }
  }
}
