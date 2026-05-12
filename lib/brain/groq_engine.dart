import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

class GroqEngine {

  static String getOwnerName(String mode) {
    return mode.toUpperCase() == "OFFICE"
        ? VyshuConfig.ownerFormal
        : VyshuConfig.ownerName;
  }

  static Future<String> _call(String prompt) async {
    final prefs = await SharedPreferences.getInstance();
    final key   = prefs.getString(VyshuConfig.kGroqKey) ?? "";
    if (key.isEmpty) return "";

    try {
      final response = await http.post(
        Uri.parse(VyshuConfig.groqUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $key",
        },
        body: jsonEncode({
          "model": VyshuConfig.groqModel,
          "messages": [
            {"role": "user", "content": prompt}
          ],
          "max_tokens": 200,
          "temperature": 0.1,
        }),
      ).timeout(Duration(seconds: VyshuConfig.requestTimeout));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["choices"][0]["message"]["content"].toString().trim();
      }
    } catch (_) {}
    return "";
  }

  static Future<String> detectLanguage(String text) async {
    if (_isLikelyEnglish(text)) return "en";
    final result = await _call(
      "Detect the language of this text. "
      "Return ONLY the ISO 639-1 code from: "
      "en,te,hi,ta,kn,ml,bn,mr,id,ja,zh-cn,vi,th,ko,tl,es,fr,ne. "
      "Romanized Telugu=te, Romanized Hindi=hi, Romanized Tamil=ta. "
      "Return ONLY the code.\n\nText: $text",
    );
    final code       = result.toLowerCase().trim();
    final validCodes = VyshuConfig.languageCodes.values.toSet();
    return validCodes.contains(code) ? code : "en";
  }

  static Future<String> translate({
    required String text,
    required String fromLang,
    required String toLang,
  }) async {
    if (fromLang == toLang) return text;
    if (fromLang == "en" && toLang == "en") return text;
    final result = await _call(
      "Translate from $fromLang to $toLang. "
      "Return ONLY translated text.\n\nText: $text",
    );
    return result.isNotEmpty ? result : text;
  }

  static Future<Map<String,String>> detectAndTranslate(String text) async {
    final langCode = await detectLanguage(text);
    if (langCode == "en") {
      return {"original":text,"detected_lang":"en","english_text":text};
    }
    final englishText = await translate(
      text: text, fromLang: langCode, toLang: "en");
    return {
      "original":      text,
      "detected_lang": langCode,
      "english_text":  englishText,
    };
  }

  static Future<String> detectIntent(String text) async {
    final lower = text.toLowerCase().trim();

    const yesWords = [
      "yes","yeah","yep","yup","sure","okay","ok","of course",
      "let's do it","let's go","haan","go","start","begin",
      "do it","fine","alright","absolutely","ready","done",
    ];
    if (yesWords.any((w) => lower.contains(w))) return "YES";

    const noWords = [
      "no","nope","nah","not now","wait","later","busy",
      "stop","cancel","pause","hold","not yet","skip","chill",
    ];
    if (noWords.any((w) => lower.contains(w))) return "DELAY";

    const greetWords = [
      "hi","hello","hey","good morning","good night","morning","night",
    ];
    if (greetWords.any((w) => lower.contains(w))) return "GREETING";

    if (lower.contains("schedule") || lower.contains("today") ||
        lower.contains("meeting") || lower.contains("plan") ||
        lower.contains("agenda")) return "SHOW_SCHEDULE";

    if (lower.contains("remind") || lower.contains("reminder") ||
        lower.contains("don't forget")) return "ADD_REMINDER";

    if (lower.contains("remember") || lower.contains("note") ||
        lower.contains("save this")) return "SAVE_NOTE";

    if (lower.contains("generate image") || lower.contains("create image") ||
        lower.contains("make image")) return "IMAGE_GEN";

    if (lower.contains("research") || lower.contains("search web") ||
        lower.contains("find info")) return "WEB_SEARCH";

    if (lower.contains("make pdf") || lower.contains("build resume") ||
        lower.contains("make resume")) return "MAKE_PDF";

    if (lower.contains("write essay") || lower.contains("write article"))
      return "WRITE_ESSAY";

    if (lower.contains("generate prompt") || lower.contains("prompt for"))
      return "GENERATE_PROMPT";

    final result = await _call(
      "Classify intent into ONE of: "
      "YES,DELAY,GREETING,SHOW_SCHEDULE,ADD_REMINDER,SAVE_NOTE,"
      "IMAGE_GEN,WEB_SEARCH,MAKE_PDF,WRITE_ESSAY,GENERATE_PROMPT,"
      "MOBILE_CONTROL,GENERAL_CHAT. "
      "Return ONLY the word.\n\nMessage: $text",
    );
    return result.isNotEmpty ? result.toUpperCase() : "GENERAL_CHAT";
  }

  static Future<String> detectEmotion(String text) async {
    final lower = text.toLowerCase();
    if (lower.contains("happy") || lower.contains("great") ||
        lower.contains("awesome") || lower.contains("yes")) return "HAPPY";
    if (lower.contains("tired") || lower.contains("sleep") ||
        lower.contains("night") || lower.contains("bye")) return "CALM";
    if (lower.contains("busy") || lower.contains("work") ||
        lower.contains("meeting") || lower.contains("office")) return "FOCUSED";
    if (lower.contains("sad") || lower.contains("bad") ||
        lower.contains("problem") || lower.contains("failed")) return "CARING";
    return "NEUTRAL";
  }

  static bool _isLikelyEnglish(String text) {
    final words = text.toLowerCase().split(' ');
    if (words.isEmpty) return true;
    const common = {
      'the','a','an','is','are','was','i','you','he','she','it',
      'we','they','my','your','hi','hello','hey','ok','okay','yes',
      'no','what','how','when','where','can','will','do','have',
      'get','make','go','want','need','let','please','thanks','good',
    };
    int count = words.where((w) => common.contains(w)).length;
    return (count / words.length) > 0.25;
  }
}
