class VyshuConfig {
  static const String ownerName     = "Teja";
  static const String ownerFormal   = "Teja sir";
  static const String ownerFull     = "Arni Manikanta Teja Swaroop";
  static const String discordHandle = "kakarot_003";

  static const String kGeminiKey1    = "gemini_key_1";
  static const String kGeminiKey2    = "gemini_key_2";
  static const String kGeminiKey3    = "gemini_key_3";
  static const String kGeminiKey4    = "gemini_key_4";
  static const String kGeminiKey5    = "gemini_key_5";
  static const String kGroqKey       = "groq_api_key";
  static const String kTogetherKey   = "together_api_key";
  static const String kTavilyKey     = "tavily_api_key";
  static const String kLinkedInToken = "linkedin_token";
  static const String kGmailAddress  = "gmail_address";
  static const String kGmailAppPwd   = "gmail_app_password";

  static const String kCurrentMode   = "current_mode";
  static const String kAdaptiveRoom  = "adaptive_room";
  static const String kFontSize      = "font_size";
  static const String kVoiceEnabled  = "voice_enabled";
  static const String kTimezone      = "user_timezone";
  static const String kGeminiIndex   = "gemini_key_index";

  static const String geminiBaseUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent";
  static const String groqUrl   =
      "https://api.groq.com/openai/v1/chat/completions";
  static const String groqModel = "llama-3.1-8b-instant";
  static const String togetherUrl =
      "https://api.together.xyz/v1/images/generations";
  static const String tavilyUrl =
      "https://api.tavily.com/search";

  static const int requestTimeout   = 15;
  static const int maxRetries       = 3;
  static const int retryDelay       = 2;

  static const String memoryFileName  = "vyshu_memory_v4.json";
  static const String profileFileName = "vyshu_profile.json";
  static const String plannerFileName = "vyshu_planner.json";
  static const int    memoryExpiryDays = 14;

  static const List<String> protectedCategories = [
    "reminders","schedules","projects","important_notes"
  ];
  static const List<String> expirableCategories = [
    "process_logs","research","temp_notes","chat_history"
  ];

  static const Map<String,String> roomBackgrounds = {
    "home":       "assets/rooms/room_home.jpg",
    "office":     "assets/rooms/room_office.jpg",
    "park":       "assets/rooms/room_park.jpg",
    "tajmahal":   "assets/rooms/room_tajmahal.jpg",
    "restaurant": "assets/rooms/room_restaurant.jpg",
    "cinema":     "assets/rooms/room_cinema.jpg",
    "shopping":   "assets/rooms/room_shopping.jpg",
    "beach":      "assets/rooms/room_beach.jpg",
    "space":      "assets/rooms/room_space.jpg",
  };

  static const List<String> adaptiveRooms = [
    "park","tajmahal","restaurant","cinema","shopping","beach","space"
  ];

  static const Map<String,String> roomEmojis = {
    "home":"🏠","office":"💼","park":"🌳","tajmahal":"🕌",
    "restaurant":"🍽️","cinema":"🎬","shopping":"🛍️",
    "beach":"🏖️","space":"🚀",
  };

  static const Map<String,String> languageCodes = {
    "english":"en","telugu":"te","hindi":"hi","tamil":"ta",
    "kannada":"kn","malayalam":"ml","bengali":"bn","marathi":"mr",
    "indonesian":"id","japanese":"ja","chinese":"zh-cn",
    "vietnamese":"vi","thai":"th","korean":"ko","filipino":"tl",
    "spanish":"es","french":"fr","nepali":"ne",
  };
}

class VyshuColors {
  static const int bgBlack      = 0xFF000000;
  static const int surfaceNavy  = 0xFF0A1628;
  static const int cardDark     = 0xFF0F1F38;
  static const int primaryBlue  = 0xFF00B4FF;
  static const int accentCyan   = 0xFF00FFFF;
  static const int textWhite    = 0xFFFFFFFF;
  static const int textSoftBlue = 0xFF7EC8E3;
  static const int onGlow       = 0xFF00D4FF;
  static const int offMuted     = 0xFF1A2A3A;
  static const int borderGlow   = 0x3300B4FF;
}
