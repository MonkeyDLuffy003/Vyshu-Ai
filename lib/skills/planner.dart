import '../brain/memory_service.dart';

class PlannerSkill {
  static Future<String> getDailyPlan() async {
    final schedule = await MemoryService.getTodaySchedule();
    final now      = DateTime.now();
    return "📅 Daily Plan — "
        "${now.day}/${now.month}/${now.year}\n\n"
        "$schedule\n\n"
        "Say 'add schedule: [title] at [time]' to add more!";
  }

  static Future<String> getConsistency() async {
    return "📊 Consistency tracking coming in V4.1!\n"
        "Say 'mark done: [task]' and I will track it 💙";
  }
}
