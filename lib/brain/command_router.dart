import 'gemini_engine.dart';
import 'groq_engine.dart';
import 'personality.dart';
import 'memory_service.dart';
import '../skills/image_gen.dart';
import '../skills/web_research.dart';
import '../skills/planner.dart';
import '../skills/pdf_maker.dart';
import '../skills/prompt_gen.dart';

class CommandRouter {

  static Future<RouterResult> route(String userMessage) async {
    final mode   = await VyshuPersonality.getMode();
    final intent = await GroqEngine.detectIntent(userMessage);
    final lower  = userMessage.toLowerCase().trim();
    final name   = VyshuPersonality.getName(mode);

    // ── MEMORY ────────────────────────────────────────────────
    if (intent == "SAVE_NOTE" ||
        lower.startsWith("remember ") ||
        lower.startsWith("note:") ||
        lower.startsWith("save:")) {
      final text = userMessage
          .replaceAll(RegExp(
              r'^(remember|note:|save:)\s*',
              caseSensitive: false), '')
          .trim();
      await MemoryService.addNote(text);
      return RouterResult(
        reply:  "Got it $name! Saved 📝\n\"$text\"",
        action: "SAVE_NOTE",
      );
    }

    if (lower == "show memory" ||
        lower == "my memory" ||
        lower == "what do you remember") {
      final summary = await MemoryService.showMemory();
      return RouterResult(reply: summary, action: "SHOW_MEMORY");
    }

    if (lower == "show expired" ||
        lower == "expired memory") {
      final summary = await MemoryService.showExpired();
      return RouterResult(reply: summary, action: "SHOW_EXPIRED");
    }

    if (lower == "archive to gmail" ||
        lower == "archive memory") {
      final result = await MemoryService.archiveToGmail();
      return RouterResult(reply: result, action: "ARCHIVE_GMAIL");
    }

    // ── SCHEDULE ──────────────────────────────────────────────
    if (intent == "SHOW_SCHEDULE" ||
        lower == "today" ||
        lower == "my schedule" ||
        lower == "what's today") {
      final schedule = await MemoryService.getTodaySchedule();
      return RouterResult(reply: schedule, action: "SHOW_SCHEDULE");
    }

    if (intent == "ADD_REMINDER" ||
        lower.startsWith("remind me") ||
        lower.startsWith("set reminder")) {
      return RouterResult(
        reply:        "Sure $name! What should I remind you about and when? ⏰",
        action:       "ADD_REMINDER_PROMPT",
        needsFollowUp: true,
      );
    }

    // ── IMAGE GENERATION ──────────────────────────────────────
    if (intent == "IMAGE_GEN" ||
        lower.startsWith("generate image") ||
        lower.startsWith("create image") ||
        lower.startsWith("make image")) {
      final prompt = userMessage
          .replaceAll(RegExp(
              r'^(generate|create|make)\s*(image|picture|photo)'
              r'(\s*of)?\s*',
              caseSensitive: false), '')
          .trim();
      final result = await ImageGenSkill.generate(prompt);
      return RouterResult(
        reply:    result.message,
        action:   "IMAGE_GEN",
        imageUrl: result.imageUrl,
      );
    }

    // ── WEB RESEARCH ──────────────────────────────────────────
    if (intent == "WEB_SEARCH" ||
        lower.startsWith("research:") ||
        lower.startsWith("search:") ||
        lower.startsWith("search web")) {
      final query = userMessage
          .replaceAll(RegExp(
              r'^(research:|search:|search web)\s*',
              caseSensitive: false), '')
          .trim();
      final result = await WebResearchSkill.research(query);
      return RouterResult(reply: result, action: "WEB_SEARCH");
    }

    // ── PDF / RESUME ──────────────────────────────────────────
    if (intent == "MAKE_PDF" ||
        lower.startsWith("make pdf") ||
        lower.startsWith("build resume") ||
        lower.startsWith("make resume")) {
      if (lower.contains("resume")) {
        final result = await PdfMakerSkill.buildResume();
        return RouterResult(
          reply:    result.message,
          action:   "MAKE_RESUME",
          filePath: result.filePath,
        );
      }
      return RouterResult(
        reply:        "Sure $name! What should the PDF be about? 📄",
        action:       "MAKE_PDF_PROMPT",
        needsFollowUp: true,
      );
    }

    // ── ESSAY / PROMPT ────────────────────────────────────────
    if (intent == "WRITE_ESSAY" ||
        lower.startsWith("write essay") ||
        lower.startsWith("write article")) {
      final topic = userMessage
          .replaceAll(RegExp(
              r'^(write essay|write article)\s*:?\s*',
              caseSensitive: false), '')
          .trim();
      final result = await PromptGenSkill.writeEssay(topic);
      return RouterResult(reply: result, action: "WRITE_ESSAY");
    }

    if (intent == "GENERATE_PROMPT" ||
        lower.startsWith("generate prompt") ||
        lower.startsWith("prompt for")) {
      final topic = userMessage
          .replaceAll(RegExp(
              r'^(generate prompt|prompt for)\s*:?\s*',
              caseSensitive: false), '')
          .trim();
      final result = await PromptGenSkill.generatePrompt(topic);
      return RouterResult(reply: result, action: "GENERATE_PROMPT");
    }

    // ── PLANNER ───────────────────────────────────────────────
    if (lower.startsWith("plan today") ||
        lower == "daily plan" ||
        lower == "my consistency" ||
        lower == "weekly report") {
      final result = await PlannerSkill.getDailyPlan();
      return RouterResult(reply: result, action: "PLANNER");
    }

    // ── GREETING ──────────────────────────────────────────────
    if (intent == "GREETING") {
      final schedule = await MemoryService.getTodaySchedule();
      final greeting = VyshuPersonality.faceDetectedGreeting(
          mode, schedule);
      return RouterResult(reply: greeting, action: "GREETING");
    }

    // ── YES ───────────────────────────────────────────────────
    if (intent == "YES") {
      return RouterResult(
        reply:  "Let's go $name! 💙 What first?",
        action: "YES",
      );
    }

    // ── DELAY ─────────────────────────────────────────────────
    if (intent == "DELAY") {
      return RouterResult(
        reply:  "No rush $name 😊 I'll be here when you're ready.",
        action: "DELAY",
      );
    }

    // ── MOBILE CONTROL ────────────────────────────────────────
    if (intent == "MOBILE_CONTROL" ||
        _isMobileCommand(lower)) {
      return RouterResult(
        reply:         "",
        action:        "MOBILE_CONTROL",
        mobileCommand: lower,
      );
    }

    // ── GENERAL CHAT → GEMINI ─────────────────────────────────
    final systemPrompt = VyshuPersonality.buildPrompt(mode);
    final history      = await MemoryService.getRecentChatHistory();

    final rawReply = await GeminiEngine.ask(
      systemPrompt: systemPrompt,
      userMessage:  userMessage,
      history:      history,
    );

    final naturalReply =
        VyshuPersonality.naturalizeReply(rawReply, mode);

    await MemoryService.addChatHistory(userMessage, naturalReply);

    return RouterResult(
      reply:  naturalReply,
      action: "GENERAL_CHAT",
    );
  }

  static bool _isMobileCommand(String text) {
    const keywords = [
      "wifi","torch","hotspot","bluetooth","volume",
      "brightness","flashlight","open spotify","open youtube",
      "turn on","turn off","switch on","switch off",
    ];
    return keywords.any((k) => text.contains(k));
  }
}

class RouterResult {
  final String  reply;
  final String  action;
  final bool    needsFollowUp;
  final String? imageUrl;
  final String? filePath;
  final String? mobileCommand;

  RouterResult({
    required this.reply,
    required this.action,
    this.needsFollowUp  = false,
    this.imageUrl,
    this.filePath,
    this.mobileCommand,
  });
}
