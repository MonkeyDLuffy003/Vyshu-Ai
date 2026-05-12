import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../brain/config.dart';

class ImageGenResult {
  final String  message;
  final String? imageUrl;
  ImageGenResult({required this.message, this.imageUrl});
}

class ImageGenSkill {
  static Future<ImageGenResult> generate(String prompt) async {
    final prefs = await SharedPreferences.getInstance();
    final key   = prefs.getString(VyshuConfig.kTogetherKey) ?? "";

    if (key.isEmpty) {
      return ImageGenResult(
        message: "⚠️ Together AI key not set!\n"
            "Go to Settings → API Keys to add it.");
    }

    try {
      final response = await http.post(
        Uri.parse(VyshuConfig.togetherUrl),
        headers: {
          "Authorization": "Bearer $key",
          "Content-Type":  "application/json",
        },
        body: jsonEncode({
          "model":  "stabilityai/stable-diffusion-xl-base-1.0",
          "prompt": prompt,
          "n":      1,
          "width":  512,
          "height": 512,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final url  = data["data"][0]["url"] as String?;
        return ImageGenResult(
          message:  "🎨 Image generated! Here it is 💙",
          imageUrl: url,
        );
      }
      return ImageGenResult(
          message: "❌ Image generation failed. Try again!");
    } catch (e) {
      return ImageGenResult(message: "❌ Error: $e");
    }
  }
}
