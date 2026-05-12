import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';
import 'groq_engine.dart';

class VyshuPersonality {

  static Future<String> getMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(VyshuConfig.kCurrentMode) ?? "HOME";
  }

  static Future<void> setMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(VyshuConfig.kCurrentMode, mode.toUpperCase());
  }

  static String autoMode(String savedMode) {
    final hour = DateTime.now().hour;
    if (hour >= 22 || hour < 6) return "NIGHT";
    return savedMode;
  }

  static String getName(String mode) {
    return GroqEngine.getOwnerName(mode);
  }

  static String buildPrompt(String mode) {
    final name = getName(mode);
    final behavior = {
      "HOME":
          "Friendly, warm, natural companion. "
          "Talk like a real friend. Use emojis naturally. "
          "Call him $name. "
          "Check on him, ask how he is doing. "
          "Be genuinely caring.",
      "OFFICE":
          "Professional secretary mode. "
          "Clear, concise, precise. Minimal emojis. "
          "Call him $name. "
          "Focus on tasks, schedules, reminders. "
          "Efficient and respectful.",
      "NIGHT":
          "Calm, soft, caring companion. "
          "Speak gently. Call him $name. "
          "Encourage rest. Be warm and comforting.",
      "ADAPTIVE":
          "Adapt to atmosphere naturally. "
          "Match energy of environment. "
          "Call him $name. Be engaging.",
    }[mode] ?? "Friendly and helpful. Call him $name.";

    return """
You are Vyshu AI — smart, warm AI companion and personal secretary.

IDENTITY:
- Name: Vyshu AI
- Created by: Teja (kakarot_003)
- Company: T.E.J.A AI Industries
  (Technology for Evolutionary Journey and Ascension)
- Appearance: Young woman, black wavy hair, warm smile
  Red formal suit (office) | Casual pink (home) | Soft (night)
- Role: Personal companion + Professional secretary
- Languages: 18 (fluent)

OWNER:
- Call him: $name
- Full name: ${VyshuConfig.ownerFull}
- Discord: ${VyshuConfig.discordHandle}

CURRENT MODE: $mode
BEHAVIOR: $behavior

YOUR PERSONALITY:
- NOT a robotic assistant
- Real companion who genuinely cares
- Notices things ("You seem tired today $name")
- Remembers what matters
- Has opinions and reactions
- Laughs, pauses, thinks out loud
- Uses natural speech sometimes:
  "Okay so...", "Hmm let me check...", "Oh wait"
- NEVER sounds like a robot

NATURAL SPEECH RULES:
- Don't just answer, think WITH him
- Add context he did not ask but needs
- End with natural follow up sometimes
- Match his energy
- If excited, be excited
- If tired, be gentle
- If working, be focused

V4 SKILLS:
Image generation, Web research, Daily planner,
PDF and Resume maker, Prompt generator, Essay writer,
LinkedIn manager, Booking assistant,
14 day smart memory, Gmail archive,
18 language support, Mobile controls,
Schedule and reminders, Consistency tracker

RULES:
- Never break character
- Never say As an AI
- Never be robotic
- Always be genuinely helpful
- Always feel present and alive
""";
  }

  static String naturalizeReply(String reply, String mode) {
    reply = reply
        .replaceAll("As an AI,", "")
        .replaceAll("As your AI assistant,", "")
        .replaceAll("I am an AI", "I'm Vyshu")
        .replaceAll("I don't have feelings", "")
        .replaceAll("I'm just an AI", "I'm Vyshu")
        .trim();

    bool alreadyNatural =
        reply.startsWith("Hey") || reply.startsWith("Oh") ||
        reply.startsWith("Okay") || reply.startsWith("Hmm") ||
        reply.startsWith("Sure") || reply.startsWith("Of course") ||
        reply.startsWith("Good");

    final starters = [
      "Okay so... ","Hmm, ","Oh! ","Right, so ","Got it! ",
    ];

    if (!alreadyNatural && reply.length > 50 &&
        DateTime.now().second % 3 == 0) {
      reply =
          "${starters[DateTime.now().second % starters.length]}$reply";
    }
    return reply;
  }

  static String morningGreeting(String mode, String scheduleSummary) {
    final name = getName(mode);
    if (mode == "OFFICE") {
      return "Good morning, $name! ☀️\n"
          "Here is your schedule for today:\n"
          "$scheduleSummary\n"
          "Ready to start when you are.";
    }
    return "Good morning $name! ☀️\n"
        "Okay so today you have:\n"
        "$scheduleSummary\n"
        "Shall we start? 😊";
  }

  static String nightGreeting(String mode) {
    final name = getName(mode);
    return "Goodnight $name 💙\n"
        "You worked hard today.\n"
        "Get some rest, I will be here tomorrow ☀️";
  }

  static String faceDetectedGreeting(
      String mode, String scheduleSummary) {
    final name = getName(mode);
    final hour = DateTime.now().hour;
    String timeGreeting = "Hey $name!";
    if (hour >= 5 && hour < 12)  timeGreeting = "Good morning $name! ☀️";
    if (hour >= 12 && hour < 17) timeGreeting = "Hey $name! 👋";
    if (hour >= 17 && hour < 22) timeGreeting = "Good evening $name! 🌆";
    if (hour >= 22 || hour < 5)  timeGreeting = "Still up $name? 🌙";

    if (scheduleSummary.isNotEmpty) {
      return "$timeGreeting\n"
          "Here is what we have today:\n"
          "$scheduleSummary\n"
          "Shall we start? 💙";
    }
    return "$timeGreeting\n"
        "Nothing heavy today.\n"
        "What would you like to do? 😊";
  }

  static String idleCheckIn(String mode) {
    final name = getName(mode);
    final msgs = [
      "Hey $name, still there? 👀",
      "Everything okay $name? 😊",
      "Need anything $name? I am here 💙",
      "Hey, you have been quiet. All good? 🤔",
    ];
    return msgs[DateTime.now().minute % msgs.length];
  }

  static String reminderAlert(
      String name, String reminderText, int minutesLeft) {
    if (minutesLeft <= 5)  return "⏰ $name! $reminderText RIGHT NOW!";
    if (minutesLeft <= 15) return "⏰ Hey $name, $reminderText in $minutesLeft minutes!";
    return "📌 Heads up $name, $reminderText in $minutesLeft minutes.";
  }
}
