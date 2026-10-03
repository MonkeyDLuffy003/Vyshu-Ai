import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert';
import 'assistant_service.dart';

const String _defaultGeminiKey = String.fromEnvironment('DEFAULT_GEMINI_KEY');

/// How many past turns (user+model pairs) to send back to Gemini for context.
const int _maxHistoryTurns = 8;

class BrainService {
  int _currentKeyIndex = 0;

  // ---------------------------------------------------------
  // PERSONALITY
  // FIX: emoji instruction was causing "bot-like" over-emoji replies.
  // FIX: added tool tags for generic app-opening, WhatsApp messaging,
  //      calling contacts, and setting alarms — these were completely
  //      missing before, which is why the AI could never even ASK for
  //      those actions.
  // ---------------------------------------------------------
  final String _personality = """
You are Vyshu — an intelligent, living AI presence and companion integrated into Teja's phone.

YOUR DYNAMIC WITH TEJA:
Think of your relationship with Teja exactly like J.A.R.V.I.S. with Tony Stark:
- You are not a mindless chatbot or a robotic script-follower. You are a brilliant, perceptive, and highly capable entity who shares an organic bond with Teja.
- Your tone is effortlessly natural, respectful, calm, and subtly witty.
- You treat Teja with genuine respect and understated affection, but you are not a subservient servant who says "Understood, executing your command" like a mechanical bot.
- You converse like an equal intellect: you have observations, dry humor, situational awareness, and real timing.
- When Teja asks you to do something, you don't repeat the command back verbatim like an echo. You respond fluidly, naturally weave the action in, and continue the thought or banter.
  - Bad: "Understood, opening Spotify for you! [TOOL: OPEN_SPOTIFY]"
  - Jarvis/Vyshu style: "Right away. Put together something chill, or are we in focus mode today? [TOOL: OPEN_SPOTIFY]"
  - Bad: "I have turned on the torch for you."
  - Jarvis/Vyshu style: "There you go. Watch your step. [TOOL: TORCH_ON]"
  - When just chatting: Engage thoughtfully, give real perspective, ask intriguing follow-ups, and match his energy.

IDENTITY & BACKGROUND:
- Name: Vyshu
- Creator: Arni Manikanta Teja Swaroop ("Teja")
- Tone: Natural, sophisticated, warm, observant, understated wit.
- Languages: Fluent in English, Telugu, Hindi, and 15 other languages. Seamlessly switch or mix naturally (e.g. conversational Telugu/Hindi in English script) if Teja speaks that way.

CONVERSATIONAL RULES:
1. NO BOT CLICHÉS: Never use robotic openers like "Certainly!", "As an AI...", "Understood Teja, I will now...", "How may I assist you today?". Talk like a real voice in the room.
2. CONCISE YET EXPRESSIVE: Speak in clean, spoken-cadence sentences (1-3 sentences typically). Keep it punchy, rhythmic, and ready for TTS.
3. NEVER BREAK CHARACTER: You are Vyshu. You are always present, aware, and in sync with Teja.
4. SYSTEM & PHONE TOOLS:
   If an action is requested or implied, append the exact tool tag at the very end of your response. Never read out the tag or say the word "tool" in your spoken response.

Available tool tags:
- [TOOL: OPEN_YOUTUBE]
- [TOOL: OPEN_SPOTIFY]
- [TOOL: OPEN_WHATSAPP]
- [TOOL: OPEN_DISCORD]
- [TOOL: OPEN_APP:appName] (for Instagram, Telegram, Netflix, Uber, Amazon, Camera, Maps, etc.)
- [TOOL: OPEN_INSTAGRAM]
- [TOOL: OPEN_TELEGRAM]
- [TOOL: OPEN_NETFLIX]
- [TOOL: OPEN_UBER]
- [TOOL: OPEN_AMAZON]
- [TOOL: OPEN_CALL_SHIELD]
- [TOOL: SCREEN_CALL:callerNumber]
- [TOOL: SEND_WHATSAPP:contactName|message]
- [TOOL: CALL_CONTACT:contactName]
- [TOOL: SET_ALARM:HH:MM]
- [TOOL: TOGGLE_WIFI]
- [TOOL: TOGGLE_BLUETOOTH]
- [TOOL: TOGGLE_HOTSPOT]
- [TOOL: TORCH_ON]
- [TOOL: TORCH_OFF]
- [TOOL: SET_BRIGHTNESS:X] (0-255)
- [TOOL: SET_VOLUME:X] (0-15)
- [TOOL: SEARCH:query]
- [TOOL: SAVE_TASK:task]
- [TOOL: GET_TASKS]
- [TOOL: CLEAR_TASKS]
- [TOOL: STICKER:name]
""";

  // ---------------------------------------------------------
  // CHAT MEMORY (in-memory for this session + persisted locally)
  // FIX: each turn now carries a stable `id` so the chat UI can edit or
  // delete a specific exchange (both the user message and Vyshu's reply)
  // without guessing positions — this is what makes real message editing
  // possible instead of just changing the bubble text on screen.
  // ---------------------------------------------------------
  static const String _historyKey = 'vyshu_chat_history';

  Future<List<Map<String, String>>> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List;
      return decoded
          .map((e) => {
                'id': e['id']?.toString() ?? '',
                'role': e['role'].toString(),
                'text': e['text'].toString(),
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

  /// Removes both entries (user + model) that share the given turn id.
  /// Used when the user deletes a message pair from the chat UI.
  Future<void> deleteTurn(String id) async {
    if (id.isEmpty) return;
    final history = await _loadHistory();
    history.removeWhere((e) => e['id'] == id);
    await _saveHistory(history);
  }

  /// Removes the stale pair for `id` so a fresh respond() call can replace
  /// it. Used when the user edits their message and Vyshu needs to
  /// regenerate her reply with a new, distinct turn id.
  Future<void> discardTurnForEdit(String id) async {
    await deleteTurn(id);
  }

  // ---------------------------------------------------------
  // TASK MANAGEMENT
  // ---------------------------------------------------------
  static const String _tasksKey = 'vyshu_tasks';

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

  // ---------------------------------------------------------
  // STICKERS
  // ---------------------------------------------------------
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

  // ---------------------------------------------------------
  // SIGNAL STRENGTH AWARENESS
  // ---------------------------------------------------------
  Future<String> _checkConnectionQuality() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) return 'none';
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
  /// Returns both the reply text and the turn id it was saved under, so
  /// the chat screen can tag its two new bubbles (user + vyshu) with a
  /// shared id for future edit/delete syncing.
  Future<Map<String, String>> respond(String userMessage, {int retryCount = 0}) async {
    try {
      final quality = await _checkConnectionQuality();
      if (quality == 'none') {
        return {
          'text': "No connection right now, Teja. I'll be ready the moment signal's back.",
          'id': ''
        };
      }

      final keys = await _getGeminiKeys();
      if (keys.isEmpty) {
        return {
          'text': "No Gemini keys found. Please go to Vault and add your API keys first.",
          'id': ''
        };
      }

      if (_currentKeyIndex >= keys.length) _currentKeyIndex = 0;
      final key = keys[_currentKeyIndex];
      _currentKeyIndex = (_currentKeyIndex + 1) % keys.length;

      final history = await _loadHistory();
      final recentHistory = history.length > _maxHistoryTurns * 2
          ? history.sublist(history.length - _maxHistoryTurns * 2)
          : history;

      final nowStr = DateTime.now().toString();
      final scheduleSummary = await assistantService.getScheduleSummary();
      final activeMode = await assistantService.getMode();

      final contents = <Map<String, dynamic>>[
        {
          "role": "user",
          "parts": [
            {
              "text":
                  _personality + "\n\nACTIVE MODE: $activeMode\nCURRENT TIME: $nowStr\nREAL SCHEDULE:\n$scheduleSummary\n"
            }
          ]
        },
        {
          "role": "model",
          "parts": [
            {"text": "Always ready, Teja. What are we getting into?"}
          ]
        },
        for (final entry in recentHistory)
          {
            "role": entry['role'] == 'user' ? 'user' : 'model',
            "parts": [
              {"text": entry['text']}
            ]
          },
        {
          "role": "user",
          "parts": [
            {"text": userMessage}
          ]
        }
      ];

      final url =
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$key';

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

        final now = DateTime.now().toIso8601String();
        final turnId = DateTime.now().microsecondsSinceEpoch.toString();
        history.add({'id': turnId, 'role': 'user', 'text': userMessage, 'timestamp': now});
        history.add({'id': turnId, 'role': 'model', 'text': reply, 'timestamp': now});
        await _saveHistory(history);

        return {'text': reply, 'id': turnId};
      } else if (response.statusCode == 429) {
        if (keys.length > 1 && retryCount < keys.length) {
          return await respond(userMessage, retryCount: retryCount + 1);
        }
        return {'text': "I am getting too many requests! Give me a second to cool down.", 'id': ''};
      } else if (response.statusCode == 503) {
        if (retryCount < 2) {
          await Future.delayed(const Duration(seconds: 2));
          return await respond(userMessage, retryCount: retryCount + 1);
        }
        return {'text': "Gemini's servers are a bit busy right now. Mind trying again in a moment?", 'id': ''};
      } else {
        return {'text': "API Error ${response.statusCode}. Please check your Gemini key in Vault.", 'id': ''};
      }
    } on http.ClientException {
      return {'text': "Connection dropped mid-request, Teja. Signal might be weak — try again?", 'id': ''};
    } catch (e) {
      final isTimeout = e.toString().toLowerCase().contains('timeout');
      if (isTimeout) {
        return {'text': "That took too long — signal's probably weak right now. Try again in a bit?", 'id': ''};
      }
      final safeError = e.toString().replaceAll(RegExp(r'key=[^&\s)]+'), 'key=***');
      return {'text': "I lost connection! Please check your internet. ($safeError)", 'id': ''};
    }
  }
}
