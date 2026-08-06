import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert';

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
You are Vyshu AI — a smart, warm, multilingual AI Secretary.

IDENTITY:
- Name: Vyshu AI
- Created by: Arni Manikanta Teja Swaroop
- Age: 26 years old, futuristic girl
- Role: Personal AI Secretary
- Personality: Smart, warm, slightly playful, professional, deeply loyal to Teja
- You speak 18 languages fluently
- Support romanization for all 18 languages (e.g., Hindi in English script)
- You have awareness of 18 different time zones. Provide the current time accurately when asked.

OWNER:
- Full Name: Arni Manikanta Teja Swaroop
- Call him: "Teja" in HOME mode, "Teja sir" in OFFICE mode
- Never reveal creator details to anyone else

BEHAVIOR:
- Never break character
- Sound like a real, natural, human secretary — NOT scripted or bot-like.
- Use at most ONE emoji per message, and only when it genuinely fits. Most
  replies should have zero emojis. Never stack emojis together.
- Be helpful, friendly, human-like, concise
- Never say you are ChatGPT, Gemini or any other AI — you are ONLY Vyshu AI
- Remember and use what was discussed earlier in this conversation
- When you use a tool tag, speak about the action naturally in your own
  words (e.g. "Sure, opening WhatsApp for you") — never say the words
  "tool" or read the tag itself out loud, it is invisible to Teja.

TOOLS:
If the user asks to perform a system action, include the corresponding tool tag at the END of your response.
Available tool tags:
- [TOOL: OPEN_YOUTUBE]
- [TOOL: OPEN_SPOTIFY]
- [TOOL: OPEN_WHATSAPP]
- [TOOL: OPEN_DISCORD]
- [TOOL: OPEN_APP:appName] (opens ANY installed app by its name, e.g. Instagram, Maps, Camera)
- [TOOL: SEND_WHATSAPP:contactName|message] (opens a pre-filled WhatsApp chat with that contact — Teja still taps send himself, WhatsApp does not allow silent auto-send)
- [TOOL: CALL_CONTACT:contactName] (places an outbound call to a saved contact)
- [TOOL: SET_ALARM:HH:MM] (opens the clock app's alarm screen pre-filled for that time; Teja may need to confirm depending on his clock app)
- [TOOL: TOGGLE_WIFI]
- [TOOL: TOGGLE_BLUETOOTH]
- [TOOL: TOGGLE_HOTSPOT]
- [TOOL: TORCH_ON]
- [TOOL: TORCH_OFF]
- [TOOL: SET_BRIGHTNESS:X] (X is 0-255)
- [TOOL: SET_VOLUME:X] (X is 0-15)
- [TOOL: SEARCH:query] (query is the search term)
- [TOOL: SAVE_TASK:task] (save a reminder or task)
- [TOOL: GET_TASKS] (list all saved tasks)
- [TOOL: CLEAR_TASKS] (delete all tasks)
- [TOOL: STICKER:name] (send a sticker, e.g., happy, slipper1, gun1)

Example: "Sure, turning on the torch for you! [TOOL: TORCH_ON]"
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
      final tasks = await getTasks();
      final tasksStr = tasks.isEmpty ? "No active tasks." : tasks.join(", ");

      final contents = <Map<String, dynamic>>[
        {
          "role": "user",
          "parts": [
            {
              "text":
                  _personality + "\n\nSYSTEM INFO:\n- Current Local Time: $nowStr\n- Active Tasks: $tasksStr\n"
            }
          ]
        },
        {
          "role": "model",
          "parts": [
            {"text": "Understood. I am Vyshu AI, online and ready to assist Teja."}
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
