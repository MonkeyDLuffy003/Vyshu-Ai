import '../brain/gemini_engine.dart';

class PromptGenSkill {
  static Future<String> generatePrompt(String topic) async {
    return await GeminiEngine.ask(
      systemPrompt:
          "You are an expert AI prompt engineer. "
          "Generate an optimized detailed prompt for the topic. "
          "Format: clear, specific, with style, mood, "
          "and technical details. "
          "Make it work for Midjourney, SDXL, and Kling AI.",
      userMessage: "Generate prompt for: $topic",
    );
  }

  static Future<String> writeEssay(String topic) async {
    return await GeminiEngine.ask(
      systemPrompt:
          "You are an expert writer. "
          "Write a clear, engaging, well-structured essay. "
          "Use proper paragraphs. "
          "Make it informative and readable.",
      userMessage: "Write an essay about: $topic",
    );
  }
}
