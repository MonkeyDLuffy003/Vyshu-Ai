import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum KeyCategory {
  ai,
  webSearch,
  maps,
  image,
  video,
  audio,
  translation,
  communication,
  developer,
}

enum RotationState {
  available,
  active,
  cooldown,
  disabled,
  invalid,
}

class ManagedCredential {
  final String id;
  final String providerId;
  final String keyAlias;
  final String rawKey; // Encrypted or secured in storage
  RotationState state;
  int cooldownUntil; // Epoch ms
  int lastUsedTimestamp;
  int errorCountToday;
  int dailyRequestCount;

  ManagedCredential({
    required this.id,
    required this.providerId,
    required this.keyAlias,
    required this.rawKey,
    this.state = RotationState.available,
    this.cooldownUntil = 0,
    this.lastUsedTimestamp = 0,
    this.errorCountToday = 0,
    this.dailyRequestCount = 0,
  });

  bool get isMasked => true;

  String get maskedValue {
    if (rawKey.isEmpty) return '(empty)';
    if (rawKey.length <= 8) return '****';
    return '${rawKey.substring(0, 4)}...${rawKey.substring(rawKey.length - 4)}';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'providerId': providerId,
        'keyAlias': keyAlias,
        'rawKey': rawKey,
        'state': state.name,
        'cooldownUntil': cooldownUntil,
        'lastUsedTimestamp': lastUsedTimestamp,
        'errorCountToday': errorCountToday,
        'dailyRequestCount': dailyRequestCount,
      };

  factory ManagedCredential.fromJson(Map<String, dynamic> j) => ManagedCredential(
        id: j['id'] ?? '',
        providerId: j['providerId'] ?? '',
        keyAlias: j['keyAlias'] ?? '',
        rawKey: j['rawKey'] ?? '',
        state: RotationState.values.firstWhere(
          (s) => s.name == j['state'],
          orElse: () => RotationState.available,
        ),
        cooldownUntil: j['cooldownUntil'] ?? 0,
        lastUsedTimestamp: j['lastUsedTimestamp'] ?? 0,
        errorCountToday: j['errorCountToday'] ?? 0,
        dailyRequestCount: j['dailyRequestCount'] ?? 0,
      );
}

class ProviderSpec {
  final String id;
  final String displayName;
  final KeyCategory category;
  final String documentationUrl;
  final String freeTierSummary;
  final int defaultCooldownSeconds;
  final bool isDefaultFree;

  const ProviderSpec({
    required this.id,
    required this.displayName,
    required this.category,
    required this.documentationUrl,
    required this.freeTierSummary,
    this.defaultCooldownSeconds = 60,
    this.isDefaultFree = true,
  });
}

class VyshuVaultRegistry {
  static const List<ProviderSpec> SUPPORTED_PROVIDERS = [
    // --- AI / BRAIN ---
    ProviderSpec(
      id: 'gemini',
      displayName: 'Google Gemini (Free Tier)',
      category: KeyCategory.ai,
      documentationUrl: 'https://aistudio.google.com/apikey',
      freeTierSummary: 'Gemini 2.5 Flash: 15 RPM, 1M TPM, 1,500 RPD free allowance',
      defaultCooldownSeconds: 60,
    ),
    ProviderSpec(
      id: 'groq',
      displayName: 'Groq Cloud (Free Tier)',
      category: KeyCategory.ai,
      documentationUrl: 'https://console.groq.com/keys',
      freeTierSummary: 'Llama 3.3 70B: 30 RPM, 14,400 RPD free allowance',
      defaultCooldownSeconds: 60,
    ),
    ProviderSpec(
      id: 'huggingface',
      displayName: 'Hugging Face Inference (Free Tier)',
      category: KeyCategory.ai,
      documentationUrl: 'https://huggingface.co/settings/tokens',
      freeTierSummary: 'Serverless Inference API (Rate limited, free token)',
      defaultCooldownSeconds: 120,
    ),

    // --- WEB SEARCH ---
    ProviderSpec(
      id: 'duckduckgo',
      displayName: 'DuckDuckGo Instant Answer / HTML',
      category: KeyCategory.webSearch,
      documentationUrl: 'https://duckduckgo.com',
      freeTierSummary: 'Zero key required / Unlimited fair use',
      isDefaultFree: true,
    ),
    ProviderSpec(
      id: 'tavily',
      displayName: 'Tavily Search (Free Tier)',
      category: KeyCategory.webSearch,
      documentationUrl: 'https://tavily.com',
      freeTierSummary: '1,000 free research searches per month',
      defaultCooldownSeconds: 60,
    ),
    ProviderSpec(
      id: 'searxng',
      displayName: 'SearXNG Custom Instance',
      category: KeyCategory.webSearch,
      documentationUrl: 'https://searxng.org',
      freeTierSummary: 'Decentralized open web search (Free/Self-hosted)',
    ),

    // --- MAPS / NAVIGATION ---
    ProviderSpec(
      id: 'openstreetmap',
      displayName: 'OpenStreetMap / Nominatim',
      category: KeyCategory.maps,
      documentationUrl: 'https://nominatim.org',
      freeTierSummary: '1 req/sec free geocoding & reverse geocoding policy',
    ),
    ProviderSpec(
      id: 'osrm',
      displayName: 'OSRM Routing Service',
      category: KeyCategory.maps,
      documentationUrl: 'https://project-osrm.org',
      freeTierSummary: 'Open source routing machine free demo tier',
    ),

    // --- IMAGE AI ---
    ProviderSpec(
      id: 'pollinations',
      displayName: 'Pollinations.ai Image Gen',
      category: KeyCategory.image,
      documentationUrl: 'https://pollinations.ai',
      freeTierSummary: 'Free open tier image generation / zero key required',
    ),
    ProviderSpec(
      id: 'huggingface_image',
      displayName: 'Hugging Face FLUX / SDXL',
      category: KeyCategory.image,
      documentationUrl: 'https://huggingface.co/settings/tokens',
      freeTierSummary: 'Free serverless diffusion models via HF User Token',
    ),

    // --- VOICE / TTS / STT ---
    ProviderSpec(
      id: 'android_speech',
      displayName: 'Android On-Device Speech (Offline & Free)',
      category: KeyCategory.audio,
      documentationUrl: 'https://developer.android.com',
      freeTierSummary: 'Zero API keys required / native OS recognition',
    ),
    ProviderSpec(
      id: 'android_tts',
      displayName: 'Android Text-To-Speech (Native & Free)',
      category: KeyCategory.audio,
      documentationUrl: 'https://developer.android.com',
      freeTierSummary: 'Zero API keys required / 100% offline OS voice',
    ),

    // --- COMMUNICATION ---
    ProviderSpec(
      id: 'discord',
      displayName: 'Discord Bot Gateway (Free Tier)',
      category: KeyCategory.communication,
      documentationUrl: 'https://discord.com/developers/applications',
      freeTierSummary: 'Free standard Discord Bot API & Gateway token',
    ),
  ];

  static const String STORAGE_VAULT_KEY = 'vyshu_vault_multiprovider_credentials_v1';
}

class VyshuVaultManager {
  static final VyshuVaultManager _instance = VyshuVaultManager._internal();
  factory VyshuVaultManager() => _instance;
  VyshuVaultManager._internal();

  final List<ManagedCredential> _credentials = [];
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(VyshuVaultRegistry.STORAGE_VAULT_KEY);

    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List;
        _credentials.clear();
        for (final item in list) {
          _credentials.add(ManagedCredential.fromJson(item));
        }
      } catch (e) {
        debugPrint('Error loading vault credentials: $e');
      }
    } else {
      // Migrate legacy keys if available in SharedPreferences
      await _migrateLegacyKeys(prefs);
    }
    _cleanExpiredCooldowns();
    _initialized = true;
  }

  Future<void> _migrateLegacyKeys(SharedPreferences prefs) async {
    final legacyGemini = [
      prefs.getString('gemini_1'),
      prefs.getString('gemini_2'),
      prefs.getString('gemini_3'),
      prefs.getString('gemini_4'),
      prefs.getString('gemini_5'),
    ];

    int idx = 1;
    for (final k in legacyGemini) {
      if (k != null && k.trim().length > 10) {
        _credentials.add(ManagedCredential(
          id: 'gemini-$idx-${DateTime.now().millisecondsSinceEpoch}',
          providerId: 'gemini',
          keyAlias: 'Gemini Key #$idx',
          rawKey: k.trim(),
          state: RotationState.available,
        ));
      }
      idx++;
    }

    final groq = prefs.getString('groq');
    if (groq != null && groq.trim().length > 10) {
      _credentials.add(ManagedCredential(
        id: 'groq-1-${DateTime.now().millisecondsSinceEpoch}',
        providerId: 'groq',
        keyAlias: 'Groq Primary Key',
        rawKey: groq.trim(),
        state: RotationState.available,
      ));
    }

    final discord = prefs.getString('discord_token');
    if (discord != null && discord.trim().length > 10) {
      _credentials.add(ManagedCredential(
        id: 'discord-1-${DateTime.now().millisecondsSinceEpoch}',
        providerId: 'discord',
        keyAlias: 'Discord Bot Token',
        rawKey: discord.trim(),
        state: RotationState.available,
      ));
    }

    await _save();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _credentials.map((c) => c.toJson()).toList();
    await prefs.setString(VyshuVaultRegistry.STORAGE_VAULT_KEY, jsonEncode(jsonList));
  }

  void _cleanExpiredCooldowns() {
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final c in _credentials) {
      if (c.state == RotationState.cooldown && c.cooldownUntil <= now) {
        c.state = RotationState.available;
      }
    }
  }

  // --- VAULT RETRIEVAL & KEY ROTATION (STATE MACHINE) ---

  /// Requests the next active eligible key for a provider.
  /// If the current key hits a rate limit or cooldown, the state machine
  /// selects the next available key in the provider pool without bypassing quotas.
  ManagedCredential? acquireActiveCredential(String providerId) {
    _cleanExpiredCooldowns();
    final pool = _credentials.where((c) => c.providerId == providerId).toList();

    // 1. Check if there's already an active key
    for (final c in pool) {
      if (c.state == RotationState.active) {
        c.lastUsedTimestamp = DateTime.now().millisecondsSinceEpoch;
        c.dailyRequestCount++;
        _save();
        return c;
      }
    }

    // 2. Otherwise pick the next available key
    for (final c in pool) {
      if (c.state == RotationState.available) {
        c.state = RotationState.active;
        c.lastUsedTimestamp = DateTime.now().millisecondsSinceEpoch;
        c.dailyRequestCount++;
        _save();
        return c;
      }
    }

    // None available (all are in cooldown, disabled, or invalid)
    return null;
  }

  /// Reports a rate-limit (e.g. HTTP 429) legitimately encountered on this key.
  /// Puts this key into COOLDOWN and prompts the pool to rotate to the next key.
  void reportRateLimit(String credentialId, {int? cooldownSeconds}) {
    final cred = _credentials.firstWhere((c) => c.id == credentialId, orElse: () => ManagedCredential(id: '', providerId: '', keyAlias: '', rawKey: ''));
    if (cred.id.isEmpty) return;

    final spec = VyshuVaultRegistry.SUPPORTED_PROVIDERS.firstWhere(
      (p) => p.id == cred.providerId,
      orElse: () => const ProviderSpec(id: '', displayName: '', category: KeyCategory.ai, documentationUrl: '', freeTierSummary: ''),
    );

    final duration = cooldownSeconds ?? spec.defaultCooldownSeconds;
    cred.state = RotationState.cooldown;
    cred.cooldownUntil = DateTime.now().millisecondsSinceEpoch + (duration * 1000);
    cred.errorCountToday++;
    _save();
  }

  /// Reports an invalid or revoked key (e.g. HTTP 401 or 403 Invalid API Key).
  void reportInvalidKey(String credentialId) {
    final cred = _credentials.firstWhere((c) => c.id == credentialId, orElse: () => ManagedCredential(id: '', providerId: '', keyAlias: '', rawKey: ''));
    if (cred.id.isNotEmpty) {
      cred.state = RotationState.invalid;
      _save();
    }
  }

  // --- CRUD OPERATIONS ---
  List<ManagedCredential> getCredentialsForProvider(String providerId) {
    _cleanExpiredCooldowns();
    return _credentials.where((c) => c.providerId == providerId).toList();
  }

  List<ManagedCredential> getAllCredentials() {
    _cleanExpiredCooldowns();
    return List.unmodifiable(_credentials);
  }

  Future<ManagedCredential> addCredential({
    required String providerId,
    required String keyAlias,
    required String rawKey,
  }) async {
    final cred = ManagedCredential(
      id: 'cred-${DateTime.now().millisecondsSinceEpoch}',
      providerId: providerId,
      keyAlias: keyAlias.trim(),
      rawKey: rawKey.trim(),
      state: RotationState.available,
    );
    _credentials.add(cred);
    await _save();
    return cred;
  }

  Future<void> deleteCredential(String id) async {
    _credentials.removeWhere((c) => c.id == id);
    await _save();
  }

  Future<void> toggleCredentialState(String id) async {
    final cred = _credentials.firstWhere((c) => c.id == id, orElse: () => ManagedCredential(id: '', providerId: '', keyAlias: '', rawKey: ''));
    if (cred.id.isNotEmpty) {
      if (cred.state == RotationState.disabled) {
        cred.state = RotationState.available;
      } else {
        cred.state = RotationState.disabled;
      }
      await _save();
    }
  }
}

final vyshuVaultManager = VyshuVaultManager();
