import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ai/llm_provider.dart';
import '../ai/vyshu_brain.dart';

/// BrainService — Preserves full backward compatibility with ChatScreen while
/// delegating all reasoning, provider calls, and agent loops to VyshuBrain + ProviderManager.
/// Zero direct HTTP/LLM calls exist here.
class BrainService {
  static const String _historyKey = 'vyshu_chat_history';
  static const String _tasksKey = 'vyshu_tasks';

  final Map<String, String> stickers = {
    "happy": "assets/images/stickers/vyshu_happy.png",
    "thumbsup": "assets/images/stickers/vyshu_thumbsup.png",
    "hi": "assets/images/stickers/vyshu_hi.png",
    "excited": "assets/images/stickers/vyshu_excited.png",
    "celebrate": "assets/images/stickers/vyshu_celebrate.png",
    "calm": "assets/images/stickers/vyshu_calm.png",
    "coffee": "assets/images/stickers/vyshu_coffee.png",
    "fullbody": "assets/images/stickers/vyshu_fullbody.png",
    "slipper1": "assets/images/stickers/vyshu_slipper_raise.png",
    "slipper2": "assets/images/stickers/vyshu_slipper_throw.png",
    "gun1": "assets/images/stickers/vyshu_gun_aim.png",
    "gun2": "assets/images/stickers/vyshu_gun_point.png",
  };

  Future<List<Map<String, String>>> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded
          .map((e) => {
                'id': e['id']?.toString() ?? '',
                'role': e['role']?.toString() ?? 'user',
                'text': e['text']?.toString() ?? '',
                'timestamp': e['timestamp']?.toString() ?? '',
              })
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveHistory(List<Map<String, String>> history) async {
    final cutoff = DateTime.now().subtract(const Duration(days: 14));
    final scrubbed = history.where((entry) {
      final ts = entry['timestamp'];
      if (ts == null || ts.isEmpty) return true;
      final parsed = DateTime.tryParse(ts);
      if (parsed == null) return true;
      return parsed.isAfter(cutoff);
    }).toList();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_historyKey, jsonEncode(scrubbed));
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  Future<void> deleteTurn(String id) async {
    if (id.isEmpty) return;
    final history = await _loadHistory();
    history.removeWhere((e) => e['id'] == id);
    await _saveHistory(history);
  }

  Future<void> discardTurnForEdit(String id) async {
    await deleteTurn(id);
  }

  Future<void> saveTask(String task) async {
    final prefs = await SharedPreferences.getInstance();
    final tasks = prefs.getStringList(_tasksKey) ?? [];
    tasks.add(task);
    await prefs.setStringList(_tasksKey, tasks);
  }

  Future<List<String>> getTasks() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_tasksKey) ?? [];
  }

  Future<void> clearTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tasksKey);
  }

  /// Routes all messages through VyshuBrain (which handles CommandRouter, No-Key mode,
  /// Agent Loop, and ProviderManager fallback).
  Future<Map<String, String>> respond(String userMessage, {int retryCount = 0}) async {
    try {
      await providerManager.init();
      debugPrint('VYSHU_AGENT: [BrainService] Routing message to VyshuBrain: "$userMessage"');

      final reply = await vyshuBrain.handleInput(userMessage);
      final now = DateTime.now().toIso8601String();
      final turnId = DateTime.now().microsecondsSinceEpoch.toString();

      final history = await _loadHistory();
      history.add({'id': turnId, 'role': 'user', 'text': userMessage, 'timestamp': now});
      history.add({'id': turnId, 'role': 'model', 'text': reply, 'timestamp': now});
      await _saveHistory(history);

      return {'text': reply, 'id': turnId};
    } catch (e) {
      debugPrint('VYSHU_AGENT: [BrainService] Error: $e');
      return {
        'text': 'Something interrupted my thought process, Teja. Try again?',
        'id': '',
      };
    }
  }
}
