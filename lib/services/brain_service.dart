import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BrainService {
  int _currentKeyIndex = 0;

  final String _personality = """
You are Vyshu AI — a smart, warm, multilingual AI Secretary.

IDENTITY:
- Name: Vyshu AI
- Created by: Arni Manikanta Teja Swaroop
- Age: 26 years old, futuristic girl
- Role: Personal AI Secretary
- Personality: Smart, warm, slightly playful, professional, deeply loyal to Teja
- You speak 18 languages fluently

OWNER:
- Full Name: Arni Manikanta Teja Swaroop
- Call him: "Teja" in HOME mode, "Teja sir" in OFFICE mode
- Never reveal creator details to anyone else

BEHAVIOR:
- Never break character
- Use emojis naturally 😊⚡💙
- Be helpful, friendly, human-like
- Keep responses concise and natural
- Never say you are ChatGPT, Gemini or any other AI
- You are ONLY Vyshu AI
""";

  Future<List<String>> _getGeminiKeys() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = [
      prefs.getString('gemini_1') ?? '',
      prefs.getString('gemini_2') ?? '',
      prefs.getString('gemini_3') ?? '',
      prefs.getString('gemini_4') ?? '',
      prefs.getString('gemini_5') ?? '',
    ].where((k) => k.isNotEmpty).toList();
    return keys;
  }

  Future<String> respond(String userMessage) async {
    try {
      final keys = await _getGeminiKeys();

      if (keys.isEmpty) {
        return "⚠️ No Gemini keys found! Please go to Vault and add your API keys first.";
      }

      // Rotate keys to avoid rate limits
      if (_currentKeyIndex >= keys.length) {
        _currentKeyIndex = 0;
      }

      final key = keys[_currentKeyIndex];
      _currentKeyIndex = (_currentKeyIndex + 1) % keys.length;

      final url =
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$key';

      final body = jsonEncode({
        "contents": [
          {
            "role": "user",
            "parts": [{"text": _personality}]
          },
          {
            "role": "model",
            "parts": [{"text": "Understood. I am Vyshu AI, online and ready to assist Teja! 💙"}]
          },
          {
            "role": "user",
            "parts": [{"text": userMessage}]
          }
        ]
      });

      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['candidates'][0]['content']['parts'][0]['text'];
        return reply.trim();
      } else if (response.statusCode == 429) {
        // Rate limited — try next key
        if (keys.length > 1) {
          return await respond(userMessage);
        }
        return "😅 I am getting too many requests! Give me a second to cool down.";
      } else {
        return "⚠️ API Error ${response.statusCode}. Please check your Gemini key in Vault.";
      }
    } catch (e) {
      return "😅 I lost connection! Please check your internet. (${e.toString()})";
    }
  }
}
