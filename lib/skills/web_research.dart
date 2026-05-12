import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../brain/config.dart';
import '../brain/memory_service.dart';

class WebResearchSkill {
  static Future<String> research(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final key   = prefs.getString(VyshuConfig.kTavilyKey) ?? "";

    if (key.isEmpty) {
      return "⚠️ Tavily key not set!\n"
          "Go to Settings → API Keys to add it.";
    }

    try {
      final response = await http.post(
        Uri.parse(VyshuConfig.tavilyUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "api_key":     key,
          "query":       query,
          "max_results": 5,
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data    = jsonDecode(response.body);
        final results = (data["results"] as List).take(3).map((r) {
          final content = r['content'].toString();
          final preview = content.length > 150
              ? content.substring(0, 150)
              : content;
          return "• ${r['title']}\n  $preview...";
        }).join("\n\n");

        final summary = "🔍 Research: $query\n\n$results";
        await MemoryService.addResearch(query, summary);
        return summary;
      }
      return "❌ Search failed. Try again!";
    } catch (e) {
      return "❌ Error: $e";
    }
  }
}
