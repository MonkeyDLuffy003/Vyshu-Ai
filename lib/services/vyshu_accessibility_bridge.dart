import 'package:flutter/services.dart';

/// Bridge to VyshuAccessibilityService.kt for system toggle features
/// (plan section 1.10 / 5: WiFi, Bluetooth, Torch, Hotspot, Brightness, Volume).
///
/// IMPORTANT: BIND_ACCESSIBILITY_SERVICE can't be auto-granted via a normal
/// permission dialog. Your onboarding Step 6 should call
/// openAccessibilitySettings() and ask the user to manually flip the
/// "Vyshu AI" toggle on in Settings > Accessibility.
class VyshuAccessibilityBridge {
  static const MethodChannel _channel =
      MethodChannel('com.vyshu.ai/accessibility');

  /// Whether the user has enabled the Vyshu accessibility service.
  static Future<bool> isServiceEnabled() async {
    return await _channel.invokeMethod('isServiceEnabled') ?? false;
  }

  /// Sends the user to Settings > Accessibility to enable the service.
  static Future<void> openAccessibilitySettings() async {
    await _channel.invokeMethod('openAccessibilitySettings');
  }

  /// Sends the user to the system WRITE_SETTINGS grant screen
  /// (needed once, before setBrightness() will work).
  static Future<void> openWriteSettingsPermission() async {
    await _channel.invokeMethod('openWriteSettingsPermission');
  }

  // ---- Direct toggles (no accessibility tile-tapping needed) ----

  static Future<bool> setTorch(bool on) async {
    return await _channel.invokeMethod('setTorch', {'on': on}) ?? false;
  }

  /// value 0-255
  static Future<bool> setBrightness(int value) async {
    return await _channel.invokeMethod('setBrightness', {'value': value}) ??
        false;
  }

  /// streamType: use AudioManager constants, e.g. 3 = STREAM_MUSIC
  static Future<bool> setVolume(int streamType, int level) async {
    return await _channel.invokeMethod(
          'setVolume',
          {'streamType': streamType, 'level': level},
        ) ??
        false;
  }

  // ---- Gesture-automated toggles (require the accessibility service) ----

  static Future<bool> toggleWifi() async {
    return await _channel.invokeMethod(
          'toggleQuickSettingsTile',
          {'tile': 'Wi-Fi'},
        ) ??
        false;
  }

  static Future<bool> toggleBluetooth() async {
    return await _channel.invokeMethod(
          'toggleQuickSettingsTile',
          {'tile': 'Bluetooth'},
        ) ??
        false;
  }

  static Future<bool> toggleHotspot() async {
    return await _channel.invokeMethod(
          'toggleQuickSettingsTile',
          {'tile': 'Hotspot'},
        ) ??
        false;
  }

  static Future<bool> toggleAirplaneMode() async {
    return await _channel.invokeMethod(
          'toggleQuickSettingsTile',
          {'tile': 'Airplane mode'},
        ) ??
        false;
  }
}
