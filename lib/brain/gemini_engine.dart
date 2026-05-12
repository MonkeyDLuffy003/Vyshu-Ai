import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'config.dart';

class GeminiEngine {

  static Future<bool> hasInternet() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  static Future<List<String>> _getKeys(SharedPreferences prefs) {
    final keys = [
      prefs.getString(VyshuConfig.kGeminiKey1) ?? "",
      prefs.getString(VyshuConfig.kGeminiKey2) ?? "",
      prefs.getString(VyshuConfig.kGeminiKey3) ?? "",
      prefs.getString(VyshuConfig.kGeminiKey4) ?? "",
      prefs.getString(VyshuConfig.kGeminiKey5) ?? "",
    ].where((k) => k.trim().isNotEmpty).toList();
    return Future.value(keys);
  }

  static Future<String> ask({
    required String systemPrompt,
    required String userMessage,
    List<Map<String,String>> history = const [],
  }) async {
    if (!await hasInternet()) {
      return "❌ No internet connection, ${_getName()}. Please check your network!";
    }

    final prefs = await SharedPreferences.getInstance();
    final keys  = await _getKeys(prefs);

    if (keys.isEmpty) {
      return "⚠️ No Gemini keys found! Please add them in Settings → API Keys.";
    }

    int startIndex = prefs.getInt(VyshuConfig.kGeminiIndex) ?? 0;

    for (int attempt = 0; attempt < VyshuConfig.maxRetries; attempt++) {
      int keyIndex = (startIndex + attempt) % keys.length;
      String key   = keys[keyIndex];

      try {
        final result = await _callGemini(
          key:          key,
          systemPrompt: systemPrompt,
          userMessage:  userMessage,
          history:      history,
        );
        await prefs.setInt(
          VyshuConfig.kGeminiIndex,
          (keyIndex + 1) % keys.length,
        );
        return result;

      } catch (e) {
        String err = e.toString();
        if (err.contains("429") || err.contains("quota") ||
            err.contains("exhausted") || err.contains("busy")) {
          if (attempt == VyshuConfig.maxRetries - 1) {
            return "😔 All Gemini keys are busy right now. "
                "Try again in a moment or add more keys in Settings!";
          }
          await Future.delayed(Duration(seconds: VyshuConfig.retryDelay));
          continue;
        }
        if (err.contains("timeout") || err.contains("SocketException")) {
          if (attempt == VyshuConfig.maxRetries - 1) {
            return "❌ Connection timed out. Please try again!";
          }
          await Future.delayed(Duration(seconds: VyshuConfig.retryDelay));
          continue;
        }
        return "⚠️ Error: $err";
      }
    }
    return "😔 Sorry, couldn't get a response. Please try again!";
  }

  static Future<String> _callGemini({
    required String key,
    required String systemPrompt,
    required String userMessage,
    List<Map<String,String>> history = const [],
  }) async {
    final url = Uri.parse("${VyshuConfig.geminiBaseUrl}?key=$key");

    List<Map<String,dynamic>> contents = [];
    contents.add({
      "role": "user",
      "parts": [{"text": systemPrompt}]
    });
    contents.add({
      "role": "model",
      "parts": [{"text": "Understood! I'm Vyshu AI, ready to assist. 💙"}]
    });

    for (var turn in history.take(10)) {
      contents.add({
        "role": turn["role"] == "user" ? "user" : "model",
        "parts": [{"text": turn["text"] ?? ""}]
      });
    }

    contents.add({
      "role": "user",
      "parts": [{"text": userMessage}]
    });

    final body = jsonEncode({
      "contents": contents,
      "generationConfig": {
        "temperature": 0.85,
        "maxOutputTokens": 1024,
        "topP": 0.95,
      },
      "safetySettings": [
        {"category":"HARM_CATEGORY_HARASSMENT","threshold":"BLOCK_NONE"},
        {"category":"HARM_CATEGORY_HATE_SPEECH","threshold":"BLOCK_NONE"},
      ]
    });

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: body,
    ).timeout(Duration(seconds: VyshuConfig.requestTimeout));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["candidates"][0]["content"]["parts"][0]["text"] as String;
    } else if (response.statusCode == 429) {
      throw Exception("429 quota exhausted");
    } else {
      throw Exception("HTTP ${response.statusCode}");
    }
  }

  static String _getName() {
    return VyshuConfig.ownerName;
  }
}
