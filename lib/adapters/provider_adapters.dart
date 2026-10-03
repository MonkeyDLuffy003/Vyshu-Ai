import 'dart:convert';
import 'package:http/http.dart' as http;
import '../vault/vault_registry.dart';

abstract class ProviderAdapter<Req, Resp> {
  String get providerId;
  KeyCategory get category;
  Future<AdapterResult<Resp>> execute(Req request);
}

class AdapterResult<T> {
  final bool isSuccess;
  final T? data;
  final String? errorMessage;
  final bool isRateLimited;
  final bool isInvalidCredential;
  final int? cooldownSeconds;

  AdapterResult.success(this.data)
      : isSuccess = true,
        errorMessage = null,
        isRateLimited = false,
        isInvalidCredential = false,
        cooldownSeconds = null;

  AdapterResult.rateLimited({this.cooldownSeconds})
      : isSuccess = false,
        data = null,
        errorMessage = 'Rate limit reached on current key',
        isRateLimited = true,
        isInvalidCredential = false;

  AdapterResult.invalidCredential(this.errorMessage)
      : isSuccess = false,
        data = null,
        isRateLimited = false,
        isInvalidCredential = true,
        cooldownSeconds = null;

  AdapterResult.failure(this.errorMessage)
      : isSuccess = false,
        data = null,
        isRateLimited = false,
        isInvalidCredential = false,
        cooldownSeconds = null;
}

/// --- GEMINI 2.5 FLASH FREE-TIER ADAPTER ---
class GeminiAdapter implements ProviderAdapter<String, String> {
  @override
  String get providerId => 'gemini';

  @override
  KeyCategory get category => KeyCategory.ai;

  @override
  Future<AdapterResult<String>> execute(String userPrompt) async {
    final cred = vyshuVaultManager.acquireActiveCredential(providerId);
    if (cred == null || cred.rawKey.isEmpty) {
      return AdapterResult.failure('No active Gemini key available in Vault.');
    }

    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${cred.rawKey}',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [{'text': userPrompt}]
            }
          ]
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
        return AdapterResult.success(text);
      } else if (response.statusCode == 429) {
        // Quota / Rate limit reached
        vyshuVaultManager.reportRateLimit(cred.id, cooldownSeconds: 60);
        return AdapterResult.rateLimited(cooldownSeconds: 60);
      } else if (response.statusCode == 400 || response.statusCode == 403) {
        if (response.body.contains('API_KEY_INVALID')) {
          vyshuVaultManager.reportInvalidKey(cred.id);
          return AdapterResult.invalidCredential('Gemini API Key invalid or expired.');
        }
      }

      return AdapterResult.failure('Gemini HTTP ${response.statusCode}: ${response.body}');
    } catch (e) {
      return AdapterResult.failure('Gemini Network error: $e');
    }
  }
}

/// --- GROQ CLOUD FREE-TIER ADAPTER ---
class GroqAdapter implements ProviderAdapter<String, String> {
  @override
  String get providerId => 'groq';

  @override
  KeyCategory get category => KeyCategory.ai;

  @override
  Future<AdapterResult<String>> execute(String userPrompt) async {
    final cred = vyshuVaultManager.acquireActiveCredential(providerId);
    if (cred == null || cred.rawKey.isEmpty) {
      return AdapterResult.failure('No active Groq key available in Vault.');
    }

    try {
      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${cred.rawKey}',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {'role': 'user', 'content': userPrompt}
          ],
          'temperature': 0.7,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['choices']?[0]?['message']?['content'] ?? '';
        return AdapterResult.success(text);
      } else if (response.statusCode == 429) {
        vyshuVaultManager.reportRateLimit(cred.id, cooldownSeconds: 60);
        return AdapterResult.rateLimited(cooldownSeconds: 60);
      } else if (response.statusCode == 401) {
        vyshuVaultManager.reportInvalidKey(cred.id);
        return AdapterResult.invalidCredential('Groq API Key invalid or unauthorized.');
      }

      return AdapterResult.failure('Groq HTTP ${response.statusCode}');
    } catch (e) {
      return AdapterResult.failure('Groq Network error: $e');
    }
  }
}

/// --- OPENSTREETMAP / NOMINATIM FREE GEOCODING ADAPTER ---
class NominatimMapsAdapter implements ProviderAdapter<String, Map<String, dynamic>> {
  @override
  String get providerId => 'openstreetmap';

  @override
  KeyCategory get category => KeyCategory.maps;

  @override
  Future<AdapterResult<Map<String, dynamic>>> execute(String locationQuery) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(locationQuery)}&format=json&limit=1',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'VyshuAI-Android/1.0 (Personal AI Secretary)'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        if (list.isNotEmpty) {
          final item = list[0] as Map<String, dynamic>;
          return AdapterResult.success({
            'lat': item['lat'],
            'lon': item['lon'],
            'display_name': item['display_name'],
          });
        }
        return AdapterResult.failure('Location not found.');
      }
      return AdapterResult.failure('Nominatim error: ${response.statusCode}');
    } catch (e) {
      return AdapterResult.failure('Maps network error: $e');
    }
  }
}

/// --- DUCKDUCKGO FREE WEB SEARCH ADAPTER ---
class DuckDuckGoSearchAdapter implements ProviderAdapter<String, List<String>> {
  @override
  String get providerId => 'duckduckgo';

  @override
  KeyCategory get category => KeyCategory.webSearch;

  @override
  Future<AdapterResult<List<String>>> execute(String query) async {
    try {
      final url = Uri.parse(
        'https://api.duckduckgo.com/?q=${Uri.encodeComponent(query)}&format=json&no_html=1&skip_disambig=1',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = <String>[];
        final abstractText = data['AbstractText'] as String?;
        if (abstractText != null && abstractText.isNotEmpty) {
          results.add(abstractText);
        }

        final related = data['RelatedTopics'] as List?;
        if (related != null) {
          for (final item in related) {
            if (item is Map && item['Text'] is String) {
              results.add(item['Text'] as String);
            }
          }
        }

        return AdapterResult.success(results.take(4).toList());
      }
      return AdapterResult.failure('DuckDuckGo response: ${response.statusCode}');
    } catch (e) {
      return AdapterResult.failure('Search network error: $e');
    }
  }
}

/// --- AI BRAIN ORCHESTRATION WITH AUTOMATIC FALLBACK ---
class AIBrainOrchestrator {
  final GeminiAdapter gemini = GeminiAdapter();
  final GroqAdapter groq = GroqAdapter();

  /// Executes LLM request through Gemini free-tier pool.
  /// If all Gemini keys are in COOLDOWN (or fail with 429),
  /// it seamlessly falls back to Groq free-tier pool without interrupting the user.
  Future<String> queryBrain(String prompt) async {
    await vyshuVaultManager.init();

    // 1. Try Gemini
    final geminiResult = await gemini.execute(prompt);
    if (geminiResult.isSuccess && geminiResult.data != null) {
      return geminiResult.data!;
    }

    // 2. If rate limited, try another Gemini key in pool
    if (geminiResult.isRateLimited) {
      final retryGemini = await gemini.execute(prompt);
      if (retryGemini.isSuccess && retryGemini.data != null) {
        return retryGemini.data!;
      }
    }

    // 3. Fallback to Groq free tier
    final groqResult = await groq.execute(prompt);
    if (groqResult.isSuccess && groqResult.data != null) {
      return groqResult.data!;
    }

    return "Vyshu AI: I was unable to connect to active LLM providers. Please check key status in Vyshu Vault.";
  }
}

final aiBrainOrchestrator = AIBrainOrchestrator();
