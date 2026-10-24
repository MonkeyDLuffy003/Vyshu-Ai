import 'package:flutter/foundation.dart';
import '../../services/output_policy_service.dart';
import '../vyshu_brain.dart';

/// Supported language specification
class CoachLanguage {
  final String code;
  final String name;
  final String nativeName;
  final String script;

  const CoachLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.script,
  });
}

/// LanguageCoachAgent — Feature Agent 3
/// Provides natural conversational language learning, grammar coaching, and pronunciation tips
/// across 18 supported Indian and global languages.
class LanguageCoachAgent {
  static final LanguageCoachAgent instance = LanguageCoachAgent._internal();
  factory LanguageCoachAgent() => instance;
  LanguageCoachAgent._internal();

  /// 18 Supported Languages
  static const List<CoachLanguage> supportedLanguages = [
    CoachLanguage(code: 'te', name: 'Telugu', nativeName: 'తెలుగు', script: 'Telugu'),
    CoachLanguage(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी', script: 'Devanagari'),
    CoachLanguage(code: 'en', name: 'English', nativeName: 'English', script: 'Latin'),
    CoachLanguage(code: 'ta', name: 'Tamil', nativeName: 'தமிழ்', script: 'Tamil'),
    CoachLanguage(code: 'kn', name: 'Kannada', nativeName: 'ಕನ್ನಡ', script: 'Kannada'),
    CoachLanguage(code: 'ml', name: 'Malayalam', nativeName: 'മലയാളം', script: 'Malayalam'),
    CoachLanguage(code: 'mr', name: 'Marathi', nativeName: 'मराठी', script: 'Devanagari'),
    CoachLanguage(code: 'bn', name: 'Bengali', nativeName: 'বাংলা', script: 'Bengali'),
    CoachLanguage(code: 'gu', name: 'Gujarati', nativeName: 'ગુજરાતી', script: 'Gujarati'),
    CoachLanguage(code: 'pa', name: 'Punjabi', nativeName: 'ਪੰਜਾਬੀ', script: 'Gurmukhi'),
    CoachLanguage(code: 'or', name: 'Odia', nativeName: 'ଓଡ଼ିଆ', script: 'Odia'),
    CoachLanguage(code: 'es', name: 'Spanish', nativeName: 'Español', script: 'Latin'),
    CoachLanguage(code: 'fr', name: 'French', nativeName: 'Français', script: 'Latin'),
    CoachLanguage(code: 'de', name: 'German', nativeName: 'Deutsch', script: 'Latin'),
    CoachLanguage(code: 'ja', name: 'Japanese', nativeName: '日本語', script: 'Kanji/Kana'),
    CoachLanguage(code: 'ko', name: 'Korean', nativeName: '한국어', script: 'Hangul'),
    CoachLanguage(code: 'zh', name: 'Mandarin Chinese', nativeName: '中文', script: 'Simplified Chinese'),
    CoachLanguage(code: 'ru', name: 'Russian', nativeName: 'Русский', script: 'Cyrillic'),
  ];

  CoachLanguage? findLanguage(String nameOrCode) {
    final lower = nameOrCode.toLowerCase().trim();
    for (final lang in supportedLanguages) {
      if (lang.code.toLowerCase() == lower ||
          lang.name.toLowerCase() == lower ||
          lang.nativeName.toLowerCase() == lower) {
        return lang;
      }
    }
    return null;
  }

  /// Evaluates a user phrase or conversational turn in the target language.
  /// Returns friendly feedback, grammar correction, vocabulary expansion, and next prompt.
  Future<String> evaluateTurn({
    required String userText,
    required String languageName,
  }) async {
    final lang = findLanguage(languageName) ?? supportedLanguages[0];

    final prompt =
        'You are Vyshu acting as a warm, encouraging personal Language Coach for ${lang.name} (${lang.nativeName}).\n'
        'User input: "$userText"\n\n'
        'Respond with:\n'
        '1. Meaning & Accuracy (Is it correct and natural?)\n'
        '2. Polished Alternative (How a native speaker would say it)\n'
        '3. Vocabulary / Grammar breakdown (1-2 quick points)\n'
        '4. Next question or phrase for the user to try in ${lang.name}.\n'
        'Keep tone encouraging, concise and friendly.';

    try {
      final response = await vyshuBrain.ask(prompt);
      final isSleep = outputPolicyService.isSleepModeActive;
      if (isSleep) {
        return '🌙 [Sleep Mode Active — Silent Coach Mode]\n\n$response';
      }
      return response;
    } catch (e) {
      return 'Great effort in ${lang.name}! Let\'s practice: try saying "Hello, how are you today?" in ${lang.name}.';
    }
  }

  /// Generates a quick 3-word vocabulary drill
  Future<String> getDailyDrill({required String languageName}) async {
    final lang = findLanguage(languageName) ?? supportedLanguages[0];
    final prompt = 'Provide 3 high-frequency words or conversational phrases in ${lang.name} (${lang.nativeName}) '
        'with phonetic pronunciation and English meaning, formatted cleanly.';
    try {
      return await vyshuBrain.ask(prompt);
    } catch (_) {
      return 'Today\'s ${lang.name} drill:\n1. Namaste / Namaskaram (Greetings)\n2. Dhanyavadalu / Shukriya (Thank you)\n3. Ela unnaru? / Kaise ho? (How are you?)';
    }
  }
}

final languageCoachAgent = LanguageCoachAgent.instance;
