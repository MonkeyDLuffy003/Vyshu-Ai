import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Defines how Vyshu is allowed to output speech and audio
enum AudioOutputMode {
  normal, // Normal conversational volume
  lowVolume, // Soft/whisper low-volume output (e.g. 15-20% media volume)
  voiceOnDemand, // Only speaks if user explicitly says "speak this", "read aloud", etc.
  textOnly, // Strictly no spoken audio output
}

/// Settings and rules for Vyshu Sleep Mode
class SleepModeSettings {
  bool manualSleepActive;
  bool scheduleEnabled;
  int bedHour; // e.g. 23 (11:00 PM)
  int bedMinute; // e.g. 0
  int wakeHour; // e.g. 7 (07:00 AM)
  int wakeMinute; // e.g. 30
  AudioOutputMode sleepAudioMode;
  bool allowPriorityAlarms;
  bool quietNotifications;
  int lowVolumeLevel; // e.g. 2 out of 15

  SleepModeSettings({
    this.manualSleepActive = false,
    this.scheduleEnabled = true,
    this.bedHour = 23,
    this.bedMinute = 0,
    this.wakeHour = 7,
    this.wakeMinute = 30,
    this.sleepAudioMode = AudioOutputMode.textOnly,
    this.allowPriorityAlarms = true,
    this.quietNotifications = true,
    this.lowVolumeLevel = 2,
  });

  Map<String, dynamic> toJson() => {
        'manualSleepActive': manualSleepActive,
        'scheduleEnabled': scheduleEnabled,
        'bedHour': bedHour,
        'bedMinute': bedMinute,
        'wakeHour': wakeHour,
        'wakeMinute': wakeMinute,
        'sleepAudioMode': sleepAudioMode.name,
        'allowPriorityAlarms': allowPriorityAlarms,
        'quietNotifications': quietNotifications,
        'lowVolumeLevel': lowVolumeLevel,
      };

  factory SleepModeSettings.fromJson(Map<String, dynamic> j) => SleepModeSettings(
        manualSleepActive: j['manualSleepActive'] as bool? ?? false,
        scheduleEnabled: j['scheduleEnabled'] as bool? ?? true,
        bedHour: (j['bedHour'] as num?)?.toInt() ?? 23,
        bedMinute: (j['bedMinute'] as num?)?.toInt() ?? 0,
        wakeHour: (j['wakeHour'] as num?)?.toInt() ?? 7,
        wakeMinute: (j['wakeMinute'] as num?)?.toInt() ?? 30,
        sleepAudioMode: AudioOutputMode.values.firstWhere(
          (m) => m.name == j['sleepAudioMode'],
          orElse: () => AudioOutputMode.textOnly,
        ),
        allowPriorityAlarms: j['allowPriorityAlarms'] as bool? ?? true,
        quietNotifications: j['quietNotifications'] as bool? ?? true,
        lowVolumeLevel: (j['lowVolumeLevel'] as num?)?.toInt() ?? 2,
      );
}

/// OutputPolicyService — Central governing audio and interaction policy for Vyshu.
/// All 6 agents (Android Task Agent, Call Intelligence, Focus, Samsung TV, News Express, Language Coach)
/// must consult this service before emitting audio, playing sounds, or presenting announcements.
class OutputPolicyService extends ChangeNotifier {
  static final OutputPolicyService instance = OutputPolicyService._internal();
  factory OutputPolicyService() => instance;
  OutputPolicyService._internal();

  static const String _storageKey = 'vyshu_sleep_mode_settings_v1';
  SleepModeSettings _settings = SleepModeSettings();
  bool _initialized = false;

  SleepModeSettings get settings => _settings;
  bool get isManualSleepActive => _settings.manualSleepActive;

  /// Returns whether Sleep Mode is currently in effect (either manually toggled or matching the active bedtime schedule).
  bool get isSleepModeActive {
    if (_settings.manualSleepActive) return true;
    if (!_settings.scheduleEnabled) return false;

    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final bedMinutes = _settings.bedHour * 60 + _settings.bedMinute;
    final wakeMinutes = _settings.wakeHour * 60 + _settings.wakeMinute;

    if (bedMinutes > wakeMinutes) {
      // Overnight schedule (e.g. 23:00 to 07:30)
      return currentMinutes >= bedMinutes || currentMinutes < wakeMinutes;
    } else {
      // Same-day schedule (e.g. 13:00 to 15:00 quiet hours)
      return currentMinutes >= bedMinutes && currentMinutes < wakeMinutes;
    }
  }

  /// Determines the active speech output permission for a given agent interaction.
  /// If [explicitUserVoiceRequest] is true (e.g. user specifically said "speak this" or "read aloud"),
  /// speech is permitted even during Sleep Mode using the configured low-volume voice.
  AudioOutputMode resolveOutputMode({bool explicitUserVoiceRequest = false}) {
    if (!isSleepModeActive) {
      return AudioOutputMode.normal;
    }

    if (explicitUserVoiceRequest) {
      // User explicitly asked for spoken audio in Sleep Mode
      return _settings.sleepAudioMode == AudioOutputMode.lowVolume
          ? AudioOutputMode.lowVolume
          : AudioOutputMode.lowVolume;
    }

    return _settings.sleepAudioMode;
  }

  /// Checks if spoken voice output is allowed for standard unprompted output.
  bool get canSpeakSpontaneously {
    if (!isSleepModeActive) return true;
    return false; // Never announce spontaneously during Sleep Mode!
  }

  /// Checks if quiet notifications should be enforced.
  bool get shouldMuteNotifications {
    if (!isSleepModeActive) return false;
    return _settings.quietNotifications;
  }

  Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        _settings = SleepModeSettings.fromJson(jsonDecode(raw));
      } catch (e) {
        debugPrint('VYSHU_AGENT: [OutputPolicyService] Error loading sleep settings: $e');
      }
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_settings.toJson()));
    notifyListeners();
  }

  /// Manually activate or deactivate Sleep Mode
  Future<void> setManualSleepMode(bool active) async {
    await init();
    _settings.manualSleepActive = active;
    debugPrint('VYSHU_AGENT: [OutputPolicyService] Manual Sleep Mode -> $active (Active=$isSleepModeActive)');
    await _persist();
  }

  /// Toggle manual Sleep Mode
  Future<bool> toggleManualSleepMode() async {
    await init();
    _settings.manualSleepActive = !_settings.manualSleepActive;
    await _persist();
    return _settings.manualSleepActive;
  }

  /// Update schedule enabled state
  Future<void> setScheduleEnabled(bool enabled) async {
    await init();
    _settings.scheduleEnabled = enabled;
    await _persist();
  }

  /// Update bedtime hour and minute
  Future<void> setBedTime(int hour, int minute) async {
    await init();
    _settings.bedHour = hour;
    _settings.bedMinute = minute;
    await _persist();
  }

  /// Update wake-up hour and minute
  Future<void> setWakeTime(int hour, int minute) async {
    await init();
    _settings.wakeHour = hour;
    _settings.wakeMinute = minute;
    await _persist();
  }

  /// Update audio mode when Sleep Mode is active
  Future<void> setSleepAudioMode(AudioOutputMode mode) async {
    await init();
    _settings.sleepAudioMode = mode;
    await _persist();
  }

  /// Update quiet notifications
  Future<void> setQuietNotifications(bool enabled) async {
    await init();
    _settings.quietNotifications = enabled;
    await _persist();
  }

  /// Update priority alarms
  Future<void> setAllowPriorityAlarms(bool enabled) async {
    await init();
    _settings.allowPriorityAlarms = enabled;
    await _persist();
  }

  /// Update low volume level (1-15)
  Future<void> setLowVolumeLevel(int level) async {
    await init();
    _settings.lowVolumeLevel = level;
    await _persist();
  }

  /// Update full sleep settings
  Future<void> updateSettings(SleepModeSettings newSettings) async {
    _settings = newSettings;
    await _persist();
  }
}

final outputPolicyService = OutputPolicyService.instance;
