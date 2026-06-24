import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert';

const String _defaultGeminiKey = String.fromEnvironment('DEFAULT_GEMINI_KEY');

/// How many past turns (user+model pairs) to send back to Gemini for context.
/// Keep this modest — more turns = more tokens = slower on weak signal.
const int _maxHistoryTurns = 8;

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
- Remember and use what was discussed earlier in this conversation
""";

  // ---------------------------------------------------------
  // CHAT MEMORY (in-memory for this session + persisted locally)
  // ---------------------------------------------------------
  static const String _historyKey = 'vyshu_chat_history';

  /// Loads stored history as a list of {role, text} maps.
  Future<List<Map<String, String>>> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded
          .map((e) => {
                'role': e['role'].toString(),
                'text': e['text'].toString(),
                'timestamp': e['timestamp']?.toString() ?? '',
              })
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Saves history back to local storage, scrubbing anything older than 14 days.
  Future<void> _saveHistory(List<Map<String, String>> history) async {
    final cutoff = DateTime.now().subtract(const Duration(days: 14));

    final scrubbed = history.where((entry) {
      final ts = entry['timestamp'];
      if (ts == null || ts.isEmpty) return true; // keep if no timestamp somehow
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

  // ---------------------------------------------------------
  // SIGNAL STRENGTH AWARENESS
  // ---------------------------------------------------------
  /// Returns a rough connection quality: 'none', 'weak', or 'good'.
  /// Chat is lightweight (small text payloads), so even 'weak' is fine.
  /// This is mainly used to decide whether to retry/queue or warn the user.
  Future<String> _checkConnectionQuality() async {
    final connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      return 'none';
    }

    // We can't get exact dBm signal bars from Dart without native platform
    // channels, so we treat "connected but mobile data on low generation"
    // as a soft signal. For now: any active connection = proceed, since
    // text chat payloads are tiny (a few KB) and work fine even at 2 bars.
    if (connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi) {
      return 'good';
    }

    return 'weak';
  }

  Future<List<String>> _getGeminiKeys() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = [
      prefs.getString('gemini_1') ?? '',
      prefs.getString('gemini_2') ?? '',
      prefs.getString('gemini_3') ?? '',
      prefs.getString('gemini_4') ?? '',
      prefs.getString('gemini_5') ?? '',
    ].where((k) => k.isNotEmpty).toList();

    if (keys.isEmpty && _defaultGeminiKey.isNotEmpty) {
      keys.add(_defaultGeminiKey);
    }

    return keys;
  }

  // ---------------------------------------------------------
  // MAIN RESPOND FUNCTION
  // ---------------------------------------------------------
  Future<String> respond(String userMessage, {int retryCount = 0}) async {
    try {
      // 1. Check connection before doing anything expensive
      final quality = await _checkConnectionQuality();
      if (quality == 'none') {
        return "📡 No connection right now, Teja. I'll be ready the moment signal's back!";
      }

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

      // 2. Load existing history and build the full conversation context
      final history = await _loadHistory();
      final recentHistory = history.length > _maxHistoryTurns * 2
          ? history.sublist(history.length - _maxHistoryTurns * 2)
          : history;

      final contents = <Map<String, dynamic>>[
        {
          "role": "user",
          "parts": [{"text": _personality}]
        },
        {
          "role": "model",
          "parts": [{"text": "Understood. I am Vyshu AI, online and ready to assist Teja! 💙"}]
        },
        // Replay recent history so she actually remembers the conversation
        for (final entry in recentHistory)
          {
            "role": entry['role'] == 'user' ? 'user' : 'model',
            "parts": [{"text": entry['text']}]
          },
        {
          "role": "user",
          "parts": [{"text": userMessage}]
        }
      ];

      final url =
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$key';

      // 3. Timeout scales with connection quality - weak signal gets more patience
      final timeoutSeconds = quality == 'weak' ? 25 : 15;

      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({"contents": contents}),
          )
          .timeout(Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = (data['candidates'][0]['content']['parts'][0]['text'] as String).trim();

        // 4. Save this exchange to history with timestamp for the 14-day scrub
        final now = DateTime.now().toIso8601String();
        history.add({'role': 'user', 'text': userMessage, 'timestamp': now});
        history.add({'role': 'model', 'text': reply, 'timestamp': now});
        await _saveHistory(history);

        return reply;
      } else if (response.statusCode == 429) {
        // Rate limited — try next key, but only retry a bounded number of times
        if (keys.length > 1 && retryCount < keys.length) {
          return await respond(userMessage, retryCount: retryCount + 1);
        }
        return "😅 I am getting too many requests! Give me a second to cool down.";
      } else if (response.statusCode == 503) {
        // 503 = Gemini server overloaded, not a bad key. Retry once automatically.
        if (retryCount < 2) {
          await Future.delayed(const Duration(seconds: 2));
          return await respond(userMessage, retryCount: retryCount + 1);
        }
        return "😅 Gemini's servers are a bit busy right now. Mind trying again in a moment?";
      } else {
        return "⚠️ API Error ${response.statusCode}. Please check your Gemini key in Vault.";
      }
    } on http.ClientException {
      return "📡 Connection dropped mid-request, Teja. Signal might be weak — try again?";
    } catch (e) {
      final isTimeout = e.toString().toLowerCase().contains('timeout');
      if (isTimeout) {
        return "📡 That took too long — signal's probably weak right now. Try again in a bit?";
      }
      final safeError = e.toString().replaceAll(RegExp(r'key=[^&\s)]+'), 'key=***');
      return "😅 I lost connection! Please check your internet. ($safeError)";
    }
  }
}
