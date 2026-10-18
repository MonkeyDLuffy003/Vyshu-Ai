import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Cost tier classification for providers
enum ProviderCostTier {
  free,
  cheap,
  standard,
  onDevice,
}

/// Health status of an individual API key in the Vault
enum KeyHealthStatus {
  working,
  rateLimited,
  invalid,
  disabled,
  untested,
}

/// Response returned from any LLMProvider call
class LLMResponse {
  final bool success;
  final String text;
  final String providerId;
  final String? keyId;
  final String? error;
  final bool isRateLimited;
  final bool isInvalidKey;

  const LLMResponse({
    required this.success,
    required this.text,
    required this.providerId,
    this.keyId,
    this.error,
    this.isRateLimited = false,
    this.isInvalidKey = false,
  });
}

/// Core LLMProvider contract: No LLM call may exist outside implementations of this interface.
abstract class LLMProvider {
  String get id;
  String get displayName;
  String get baseUrl;
  String get defaultModel;
  bool get supportsVision;
  bool get supportsJson;
  ProviderCostTier get costTier;

  Future<LLMResponse> complete({
    required String prompt,
    required String systemPrompt,
    required String apiKey,
    String? keyId,
    Map<String, dynamic>? jsonSchema,
    String? modelOverride,
  });

  Stream<String> stream({
    required String prompt,
    required String systemPrompt,
    required String apiKey,
  });

  Future<LLMResponse> testKey(String apiKey);
}

/// 1. GeminiProvider — Google Gemini 2.5 Flash implementation
class GeminiProvider implements LLMProvider {
  @override
  String get id => 'gemini';

  @override
  String get displayName => 'Google Gemini 2.5 Flash';

  @override
  String get baseUrl => 'https://generativelanguage.googleapis.com/v1beta';

  @override
  String get defaultModel => 'gemini-2.5-flash';

  @override
  bool get supportsVision => true;

  @override
  bool get supportsJson => true;

  @override
  ProviderCostTier get costTier => ProviderCostTier.free;

  @override
  Future<LLMResponse> complete({
    required String prompt,
    required String systemPrompt,
    required String apiKey,
    String? keyId,
    Map<String, dynamic>? jsonSchema,
    String? modelOverride,
  }) async {
    final model = modelOverride ?? defaultModel;
    debugPrint('VYSHU_AGENT: [GeminiProvider] Calling $model (json=${jsonSchema != null})');

    try {
      final uri = Uri.parse('$baseUrl/models/$model:generateContent?key=${apiKey.trim()}');
      final Map<String, dynamic> generationConfig = {
        'temperature': jsonSchema != null ? 0.1 : 0.65,
      };
      if (jsonSchema != null) {
        generationConfig['responseMimeType'] = 'application/json';
      }

      final payload = {
        'system_instruction': {
          'parts': [
            {'text': systemPrompt}
          ]
        },
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': generationConfig,
      };

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 18));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final candidates = decoded['candidates'] as List?;
        final text = candidates != null && candidates.isNotEmpty
            ? (candidates[0]['content']?['parts']?[0]?['text']?.toString() ?? '')
            : '';
        debugPrint('VYSHU_AGENT: [GeminiProvider] Success (${text.length} chars)');
        return LLMResponse(
          success: true,
          text: text.trim(),
          providerId: id,
          keyId: keyId,
        );
      } else if (response.statusCode == 429) {
        debugPrint('VYSHU_AGENT: [GeminiProvider] Rate limited (429)');
        return LLMResponse(
          success: false,
          text: '',
          providerId: id,
          keyId: keyId,
          error: 'Rate limit reached (HTTP 429)',
          isRateLimited: true,
        );
      } else if (response.statusCode == 400 || response.statusCode == 403) {
        final isInvalid = response.body.contains('API_KEY_INVALID') ||
            response.body.contains('invalid') ||
            response.statusCode == 403;
        debugPrint('VYSHU_AGENT: [GeminiProvider] Auth/Key error (${response.statusCode})');
        return LLMResponse(
          success: false,
          text: '',
          providerId: id,
          keyId: keyId,
          error: 'Invalid or unauthorized Gemini key (${response.statusCode})',
          isInvalidKey: isInvalid,
        );
      }

      return LLMResponse(
        success: false,
        text: '',
        providerId: id,
        keyId: keyId,
        error: 'Gemini HTTP ${response.statusCode}',
      );
    } catch (e) {
      debugPrint('VYSHU_AGENT: [GeminiProvider] Exception: $e');
      return LLMResponse(
        success: false,
        text: '',
        providerId: id,
        keyId: keyId,
        error: 'Network error: $e',
      );
    }
  }

  @override
  Stream<String> stream({
    required String prompt,
    required String systemPrompt,
    required String apiKey,
  }) async* {
    final res = await complete(prompt: prompt, systemPrompt: systemPrompt, apiKey: apiKey);
    if (res.success) {
      yield res.text;
    } else {
      yield 'Error: ${res.error}';
    }
  }

  @override
  Future<LLMResponse> testKey(String apiKey) async {
    return complete(
      prompt: 'Reply with the single word OK.',
      systemPrompt: 'You are a connectivity check.',
      apiKey: apiKey,
    );
  }
}

/// 2. OpenAICompatibleProvider — Covers Groq, OpenRouter, Mistral, Together, DeepSeek via baseUrl + key
class OpenAICompatibleProvider implements LLMProvider {
  @override
  final String id;

  @override
  final String displayName;

  @override
  final String baseUrl;

  @override
  final String defaultModel;

  @override
  final bool supportsVision;

  @override
  final bool supportsJson;

  @override
  final ProviderCostTier costTier;

  const OpenAICompatibleProvider({
    required this.id,
    required this.displayName,
    required this.baseUrl,
    required this.defaultModel,
    this.supportsVision = false,
    this.supportsJson = true,
    this.costTier = ProviderCostTier.free,
  });

  @override
  Future<LLMResponse> complete({
    required String prompt,
    required String systemPrompt,
    required String apiKey,
    String? keyId,
    Map<String, dynamic>? jsonSchema,
    String? modelOverride,
  }) async {
    final model = modelOverride ?? defaultModel;
    debugPrint('VYSHU_AGENT: [OpenAICompat:$id] Calling $model at $baseUrl');

    try {
      final uri = Uri.parse('$baseUrl/chat/completions');
      final Map<String, dynamic> body = {
        'model': model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': prompt},
        ],
        'temperature': jsonSchema != null ? 0.1 : 0.65,
      };

      if (jsonSchema != null && supportsJson) {
        body['response_format'] = {'type': 'json_object'};
      }

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${apiKey.trim()}',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 18));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final text = decoded['choices']?[0]?['message']?['content']?.toString() ?? '';
        debugPrint('VYSHU_AGENT: [OpenAICompat:$id] Success (${text.length} chars)');
        return LLMResponse(
          success: true,
          text: text.trim(),
          providerId: id,
          keyId: keyId,
        );
      } else if (response.statusCode == 429) {
        debugPrint('VYSHU_AGENT: [OpenAICompat:$id] Rate limited (429)');
        return LLMResponse(
          success: false,
          text: '',
          providerId: id,
          keyId: keyId,
          error: 'Rate limit reached (HTTP 429)',
          isRateLimited: true,
        );
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        debugPrint('VYSHU_AGENT: [OpenAICompat:$id] Invalid key (${response.statusCode})');
        return LLMResponse(
          success: false,
          text: '',
          providerId: id,
          keyId: keyId,
          error: 'Invalid API key (${response.statusCode})',
          isInvalidKey: true,
        );
      }

      return LLMResponse(
        success: false,
        text: '',
        providerId: id,
        keyId: keyId,
        error: '$displayName HTTP ${response.statusCode}',
      );
    } catch (e) {
      debugPrint('VYSHU_AGENT: [OpenAICompat:$id] Exception: $e');
      return LLMResponse(
        success: false,
        text: '',
        providerId: id,
        keyId: keyId,
        error: 'Network error: $e',
      );
    }
  }

  @override
  Stream<String> stream({
    required String prompt,
    required String systemPrompt,
    required String apiKey,
  }) async* {
    final res = await complete(prompt: prompt, systemPrompt: systemPrompt, apiKey: apiKey);
    if (res.success) {
      yield res.text;
    } else {
      yield 'Error: ${res.error}';
    }
  }

  @override
  Future<LLMResponse> testKey(String apiKey) async {
    return complete(
      prompt: 'Reply with the single word OK.',
      systemPrompt: 'You are a connectivity check.',
      apiKey: apiKey,
    );
  }
}

/// 3. OnDeviceProvider — Local on-device stub (MediaPipe / AICore ready behind flag)
class OnDeviceProvider implements LLMProvider {
  static const bool isEnabledFlag = false; // Clearly marked behind flag until local weights loaded

  @override
  String get id => 'on_device';

  @override
  String get displayName => 'On-Device Local Model (Stub)';

  @override
  String get baseUrl => 'local://mediapipe';

  @override
  String get defaultModel => 'gemma-2b-it-int4';

  @override
  bool get supportsVision => false;

  @override
  bool get supportsJson => true;

  @override
  ProviderCostTier get costTier => ProviderCostTier.onDevice;

  @override
  Future<LLMResponse> complete({
    required String prompt,
    required String systemPrompt,
    required String apiKey,
    String? keyId,
    Map<String, dynamic>? jsonSchema,
    String? modelOverride,
  }) async {
    debugPrint('VYSHU_AGENT: [OnDeviceProvider] Invoked (flag=$isEnabledFlag)');
    if (!isEnabledFlag) {
      return const LLMResponse(
        success: false,
        text: '',
        providerId: 'on_device',
        error: 'On-device model weights not loaded. Add a cloud key in Vault.',
      );
    }
    return const LLMResponse(
      success: true,
      text: '{"thought":"On-device stub active","action":"finish","args":{"summary":"Completed locally"},"done":true}',
      providerId: 'on_device',
    );
  }

  @override
  Stream<String> stream({
    required String prompt,
    required String systemPrompt,
    required String apiKey,
  }) async* {
    yield 'On-device provider stub.';
  }

  @override
  Future<LLMResponse> testKey(String apiKey) async {
    return const LLMResponse(
      success: false,
      text: '',
      providerId: 'on_device',
      error: 'On-device model weights not installed yet.',
    );
  }
}

/// Stored key entry with priority, health status, and cooldown tracking
class VaultKeyEntry {
  final String id;
  final String providerId;
  String label;
  final String apiKey;
  int priority; // 1 = highest priority
  bool enabled;
  KeyHealthStatus status;
  int cooldownUntilMs;
  int lastUsedMs;
  String? lastError;

  VaultKeyEntry({
    required this.id,
    required this.providerId,
    required this.label,
    required this.apiKey,
    this.priority = 1,
    this.enabled = true,
    this.status = KeyHealthStatus.untested,
    this.cooldownUntilMs = 0,
    this.lastUsedMs = 0,
    this.lastError,
  });

  bool get isEligible {
    if (!enabled) return false;
    if (status == KeyHealthStatus.invalid || status == KeyHealthStatus.disabled) return false;
    if (status == KeyHealthStatus.rateLimited &&
        DateTime.now().millisecondsSinceEpoch < cooldownUntilMs) {
      return false;
    }
    return apiKey.trim().isNotEmpty;
  }

  String get maskedKey {
    final clean = apiKey.trim();
    if (clean.isEmpty) return '(empty)';
    if (clean.length <= 8) return '****';
    return '${clean.substring(0, 4)}...${clean.substring(clean.length - 4)}';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'providerId': providerId,
        'label': label,
        'apiKey': apiKey,
        'priority': priority,
        'enabled': enabled,
        'status': status.name,
        'cooldownUntilMs': cooldownUntilMs,
        'lastUsedMs': lastUsedMs,
        'lastError': lastError,
      };

  factory VaultKeyEntry.fromJson(Map<String, dynamic> json) {
    return VaultKeyEntry(
      id: json['id']?.toString() ?? '',
      providerId: json['providerId']?.toString() ?? 'gemini',
      label: json['label']?.toString() ?? 'API Key',
      apiKey: json['apiKey']?.toString() ?? '',
      priority: (json['priority'] as num?)?.toInt() ?? 1,
      enabled: json['enabled'] as bool? ?? true,
      status: KeyHealthStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => KeyHealthStatus.untested,
      ),
      cooldownUntilMs: (json['cooldownUntilMs'] as num?)?.toInt() ?? 0,
      lastUsedMs: (json['lastUsedMs'] as num?)?.toInt() ?? 0,
      lastError: json['lastError']?.toString(),
    );
  }
}

/// ProviderManager — Central registry, priority queue, key health & automatic fallback
class ProviderManager extends ChangeNotifier {
  static final ProviderManager instance = ProviderManager._internal();
  factory ProviderManager() => instance;
  ProviderManager._internal();

  static const String _storageKey = 'vyshu_provider_manager_keys_v2';
  static const String _defaultEnvGeminiKey = String.fromEnvironment('DEFAULT_GEMINI_KEY');

  final Map<String, LLMProvider> _providers = {
    'gemini': GeminiProvider(),
    'groq': const OpenAICompatibleProvider(
      id: 'groq',
      displayName: 'Groq (Llama 3.3 70B Fast)',
      baseUrl: 'https://api.groq.com/openai/v1',
      defaultModel: 'llama-3.3-70b-versatile',
      supportsJson: true,
      costTier: ProviderCostTier.free,
    ),
    'openrouter': const OpenAICompatibleProvider(
      id: 'openrouter',
      displayName: 'OpenRouter (Free/Multi-Model)',
      baseUrl: 'https://openrouter.ai/api/v1',
      defaultModel: 'meta-llama/llama-3.3-70b-instruct:free',
      supportsJson: true,
      costTier: ProviderCostTier.free,
    ),
    'mistral': const OpenAICompatibleProvider(
      id: 'mistral',
      displayName: 'Mistral AI (La Plateforme)',
      baseUrl: 'https://api.mistral.ai/v1',
      defaultModel: 'mistral-small-latest',
      supportsJson: true,
      costTier: ProviderCostTier.free,
    ),
    'on_device': OnDeviceProvider(),
  };

  final List<VaultKeyEntry> _keys = [];
  bool _initialized = false;

  List<LLMProvider> get registeredProviders => _providers.values.toList();
  List<VaultKeyEntry> get keys => List.unmodifiable(_keys);

  bool get hasAnyUsableKey {
    _refreshCooldowns();
    return _keys.any((k) => k.isEligible) || _defaultEnvGeminiKey.isNotEmpty;
  }

  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List;
        _keys
          ..clear()
          ..addAll(list.map((e) => VaultKeyEntry.fromJson(Map<String, dynamic>.from(e))));
      } catch (e) {
        debugPrint('VYSHU_AGENT: [ProviderManager] Error loading keys: $e');
      }
    }

    // Also sync any legacy keys from SharedPreferences so existing setups never break
    await _syncLegacyPrefs(prefs);
    _refreshCooldowns();
    _initialized = true;
    notifyListeners();
  }

  Future<void> _syncLegacyPrefs(SharedPreferences prefs) async {
    bool changed = false;
    for (int i = 1; i <= 5; i++) {
      final legacy = prefs.getString('gemini_$i')?.trim() ?? '';
      if (legacy.length > 8 && !_keys.any((k) => k.apiKey == legacy)) {
        _keys.add(VaultKeyEntry(
          id: 'legacy_gemini_$i',
          providerId: 'gemini',
          label: 'Gemini Key #$i',
          apiKey: legacy,
          priority: i,
          status: KeyHealthStatus.working,
        ));
        changed = true;
      }
    }
    final legacyGroq = prefs.getString('groq')?.trim() ?? '';
    if (legacyGroq.length > 8 && !_keys.any((k) => k.apiKey == legacyGroq)) {
      _keys.add(VaultKeyEntry(
        id: 'legacy_groq_1',
        providerId: 'groq',
        label: 'Groq Primary Key',
        apiKey: legacyGroq,
        priority: 2,
        status: KeyHealthStatus.working,
      ));
      changed = true;
    }
    if (changed) {
      await _persist();
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_keys.map((k) => k.toJson()).toList()));

    // Keep legacy gemini_1..5 and groq synced for backward compatibility
    final geminiKeys = _keys.where((k) => k.providerId == 'gemini' && k.enabled).toList();
    for (int i = 0; i < 5; i++) {
      await prefs.setString('gemini_${i + 1}', i < geminiKeys.length ? geminiKeys[i].apiKey : '');
    }
    final groqKey = _keys.where((k) => k.providerId == 'groq' && k.enabled).firstOrNull;
    if (groqKey != null) {
      await prefs.setString('groq', groqKey.apiKey);
    }
    notifyListeners();
  }

  void _refreshCooldowns() {
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final k in _keys) {
      if (k.status == KeyHealthStatus.rateLimited && k.cooldownUntilMs <= now) {
        k.status = KeyHealthStatus.working;
        k.cooldownUntilMs = 0;
      }
    }
  }

  Future<VaultKeyEntry> addKey({
    required String providerId,
    required String label,
    required String apiKey,
    int priority = 1,
  }) async {
    await init();
    final entry = VaultKeyEntry(
      id: 'key_${DateTime.now().millisecondsSinceEpoch}',
      providerId: providerId,
      label: label.trim().isEmpty ? '$providerId Key' : label.trim(),
      apiKey: apiKey.trim(),
      priority: priority,
      status: KeyHealthStatus.untested,
    );
    _keys.add(entry);
    await _persist();
    debugPrint('VYSHU_AGENT: [ProviderManager] Added key ${entry.id} for $providerId (priority $priority)');
    return entry;
  }

  Future<void> removeKey(String id) async {
    _keys.removeWhere((k) => k.id == id);
    await _persist();
  }

  Future<void> toggleKeyEnabled(String id) async {
    final idx = _keys.indexWhere((k) => k.id == id);
    if (idx != -1) {
      _keys[idx].enabled = !_keys[idx].enabled;
      _keys[idx].status = _keys[idx].enabled ? KeyHealthStatus.untested : KeyHealthStatus.disabled;
      await _persist();
    }
  }

  Future<void> updateKeyPriority(String id, int newPriority) async {
    final idx = _keys.indexWhere((k) => k.id == id);
    if (idx != -1) {
      _keys[idx].priority = newPriority.clamp(1, 10);
      await _persist();
    }
  }

  Future<LLMResponse> testSpecificKey(String id) async {
    final idx = _keys.indexWhere((k) => k.id == id);
    if (idx == -1) {
      return const LLMResponse(success: false, text: '', providerId: 'unknown', error: 'Key not found');
    }
    final entry = _keys[idx];
    final provider = _providers[entry.providerId];
    if (provider == null) {
      return LLMResponse(success: false, text: '', providerId: entry.providerId, error: 'Provider not found');
    }

    final res = await provider.testKey(entry.apiKey);
    if (res.success) {
      entry.status = KeyHealthStatus.working;
      entry.lastError = null;
    } else if (res.isRateLimited) {
      entry.status = KeyHealthStatus.rateLimited;
      entry.cooldownUntilMs = DateTime.now().millisecondsSinceEpoch + 60000;
      entry.lastError = res.error;
    } else if (res.isInvalidKey) {
      entry.status = KeyHealthStatus.invalid;
      entry.lastError = res.error;
    } else {
      entry.lastError = res.error;
    }
    await _persist();
    return res;
  }

  /// Complete a prompt using the priority-ordered pool of keys across all providers.
  /// Automatically rotates on 429/error and falls back to the next provider.
  Future<LLMResponse> completeWithFallback({
    required String prompt,
    required String systemPrompt,
    Map<String, dynamic>? jsonSchema,
    bool preferFastModel = false,
  }) async {
    await init();
    _refreshCooldowns();

    final candidates = _keys.where((k) => k.isEligible).toList()
      ..sort((a, b) {
        final pCmp = a.priority.compareTo(b.priority);
        if (pCmp != 0) return pCmp;
        return a.lastUsedMs.compareTo(b.lastUsedMs); // Round-robin within same priority
      });

    // If no Vault keys exist but build-time DEFAULT_GEMINI_KEY exists, use it
    if (candidates.isEmpty && _defaultEnvGeminiKey.isNotEmpty) {
      final gemini = _providers['gemini']!;
      return gemini.complete(
        prompt: prompt,
        systemPrompt: systemPrompt,
        apiKey: _defaultEnvGeminiKey,
        jsonSchema: jsonSchema,
      );
    }

    if (candidates.isEmpty) {
      debugPrint('VYSHU_AGENT: [ProviderManager] Zero eligible API keys in Vault.');
      return const LLMResponse(
        success: false,
        text: '',
        providerId: 'none',
        error: 'NO_KEYS_AVAILABLE',
      );
    }

    String lastError = 'All providers failed';
    for (final entry in candidates) {
      final provider = _providers[entry.providerId];
      if (provider == null) continue;

      debugPrint(
          'VYSHU_AGENT: [ProviderManager] Trying provider=${provider.id} key=${entry.label} (priority=${entry.priority})');
      entry.lastUsedMs = DateTime.now().millisecondsSinceEpoch;

      final res = await provider.complete(
        prompt: prompt,
        systemPrompt: systemPrompt,
        apiKey: entry.apiKey,
        keyId: entry.id,
        jsonSchema: jsonSchema,
      );

      if (res.success && res.text.isNotEmpty) {
        entry.status = KeyHealthStatus.working;
        entry.lastError = null;
        await _persist();
        return res;
      }

      if (res.isRateLimited) {
        entry.status = KeyHealthStatus.rateLimited;
        entry.cooldownUntilMs = DateTime.now().millisecondsSinceEpoch + 60000;
        entry.lastError = 'Rate limited (60s cooldown)';
        debugPrint('VYSHU_AGENT: [ProviderManager] Key ${entry.label} hit 429 -> COOLDOWN 60s. Rotating...');
      } else if (res.isInvalidKey) {
        entry.status = KeyHealthStatus.invalid;
        entry.lastError = res.error;
        debugPrint('VYSHU_AGENT: [ProviderManager] Key ${entry.label} marked INVALID. Rotating...');
      } else {
        entry.lastError = res.error;
        debugPrint('VYSHU_AGENT: [ProviderManager] Key ${entry.label} failed (${res.error}). Fallback...');
      }
      lastError = res.error ?? lastError;
      await _persist();
    }

    return LLMResponse(
      success: false,
      text: '',
      providerId: 'exhausted',
      error: lastError,
    );
  }
}

final providerManager = ProviderManager.instance;
