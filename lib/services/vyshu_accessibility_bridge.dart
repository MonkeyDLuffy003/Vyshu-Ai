import 'package:flutter/services.dart';

/// Dart-side bridge to VyshuAccessibilityService.kt over the
/// `com.vyshu.ai/accessibility` MethodChannel.
///
/// NOTE: if you already have a vyshu_accessibility_bridge.dart in the repo,
/// this replaces it — it keeps the original toggleWifi/toggleBluetooth/
/// toggleHotspot/setTorch/setBrightness/setVolume methods and adds the new
/// ones needed for OPEN_APP, SEND_WHATSAPP, CALL_CONTACT, and SET_ALARM.
class VyshuAccessibilityBridge {
  static const MethodChannel _channel = MethodChannel('com.vyshu.ai/accessibility');

  static Future<bool> toggleWifi() async {
    try {
      return await _channel.invokeMethod('openQuickSettingsAndTapTile', {'tileLabel': 'Wi-Fi'}) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> toggleBluetooth() async {
    try {
      return await _channel.invokeMethod('openQuickSettingsAndTapTile', {'tileLabel': 'Bluetooth'}) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> toggleHotspot() async {
    try {
      return await _channel.invokeMethod('openHotspotPanel') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> setTorch(bool on) async {
    try {
      return await _channel.invokeMethod('setTorch', {'on': on}) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> setBrightness(int value) async {
    try {
      final ok = await _channel.invokeMethod('setBrightness', {'value': value}) ?? false;
      if (ok == false) {
        // Permission likely not granted yet — send the user to grant it.
        await requestWriteSettingsPermission();
      }
      return ok;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> setVolume(int streamType, int level) async {
    try {
      return await _channel.invokeMethod('setVolume', {'streamType': streamType, 'level': level}) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens Android's "Modify system settings" permission screen for this
  /// app. Required once before setBrightness() will actually work.
  static Future<void> requestWriteSettingsPermission() async {
    try {
      await _channel.invokeMethod('requestWriteSettingsPermission');
    } catch (_) {}
  }

  /// Opens ANY installed app by matching its visible name (e.g. "Instagram",
  /// "Camera", "Maps"). Requires the <queries> block in AndroidManifest.xml
  /// to actually see other apps — see manifest fix.
  static Future<bool> openApp(String appName) async {
    try {
      return await _channel.invokeMethod('launchAppByName', {'appName': appName}) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens a WhatsApp chat with the given contact, pre-filled with the
  /// message. Teja still has to tap Send himself — WhatsApp does not allow
  /// third-party apps to send messages silently, by design.
  static Future<bool> sendWhatsAppMessage(String contactName, String message) async {
    try {
      return await _channel.invokeMethod(
            'sendWhatsAppMessage',
            {'contactName': contactName, 'message': message},
          ) ??
          false;
    } catch (_) {
      return false;
    }
  }

  /// Places an outbound call to a saved contact by name (looked up via
  /// READ_CONTACTS, dialed via CALL_PHONE — both already in the manifest).
  static Future<bool> callContact(String contactName) async {
    try {
      return await _channel.invokeMethod('callContact', {'contactName': contactName}) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens the phone's clock app pre-filled to create an alarm at hour:minute.
  /// Some clock apps show a confirmation screen regardless (Android does not
  /// let apps silently create alarms without at least the option to review).
  static Future<bool> setAlarm(int hour, int minute, {String message = 'Vyshu reminder'}) async {
    try {
      return await _channel.invokeMethod(
            'setAlarm',
            {'hour': hour, 'minute': minute, 'message': message},
          ) ??
          false;
    } catch (_) {
      return false;
    }
  }
}
