import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Dart-side bridge to VyshuAccessibilityService.kt and MainActivity.kt over the
/// `com.vyshu.ai/accessibility` MethodChannel.
class VyshuAccessibilityBridge {
  static const MethodChannel _channel = MethodChannel('com.vyshu.ai/accessibility');

  /// Checks whether the VyshuAccessibilityService is currently connected and enabled.
  static Future<bool> isServiceEnabled() async {
    try {
      final res = await _channel.invokeMethod<bool>('isServiceEnabled');
      return res ?? false;
    } catch (e) {
      debugPrint('VYSHU_AGENT: [Bridge] isServiceEnabled error: $e');
      return false;
    }
  }

  /// Opens Android Accessibility Settings so the user can toggle Vyshu AI on.
  static Future<bool> openAccessibilitySettings() async {
    try {
      return await _channel.invokeMethod<bool>('openAccessibilitySettings') ?? false;
    } catch (e) {
      debugPrint('VYSHU_AGENT: [Bridge] openAccessibilitySettings error: $e');
      return false;
    }
  }

  /// Dumps a compact representation of the current screen from AccessibilityService:
  /// { "package": "...", "nodes": [ {"id","text","desc","bounds","clickable","editable","password"} ] }
  static Future<Map<String, dynamic>> dumpScreenCompact() async {
    try {
      final raw = await _channel.invokeMethod<dynamic>('dumpScreenCompact');
      if (raw is Map) {
        return Map<String, dynamic>.from(raw);
      }
      return {'package': 'unknown', 'nodes': []};
    } catch (e) {
      debugPrint('VYSHU_AGENT: [Bridge] dumpScreenCompact error: $e');
      return {'package': 'unknown', 'nodes': []};
    }
  }

  static Future<bool> tapNodeByText(String text) async {
    try {
      return await _channel.invokeMethod<bool>('tapNodeByText', {'text': text}) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> tapNodeById(String viewId) async {
    try {
      return await _channel.invokeMethod<bool>('tapNodeById', {'viewId': viewId}) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> tapCoordinates(int x, int y) async {
    try {
      return await _channel.invokeMethod<bool>('tapCoordinates', {'x': x, 'y': y}) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> typeText(
    String text, {
    String targetHint = '',
    bool submit = false,
  }) async {
    try {
      return await _channel.invokeMethod<bool>('typeText', {
            'text': text,
            'targetHint': targetHint,
            'submit': submit,
          }) ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> scrollScreen(String direction) async {
    try {
      return await _channel.invokeMethod<bool>('scrollScreen', {'direction': direction}) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> swipeCoordinates({
    required int startX,
    required int startY,
    required int endX,
    required int endY,
    int durationMs = 350,
  }) async {
    try {
      return await _channel.invokeMethod<bool>('swipeCoordinates', {
            'startX': startX,
            'startY': startY,
            'endX': endX,
            'endY': endY,
            'durationMs': durationMs,
          }) ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> pressBack() async {
    try {
      return await _channel.invokeMethod<bool>('performGlobal', {'action': 'back'}) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> pressHome() async {
    try {
      return await _channel.invokeMethod<bool>('performGlobal', {'action': 'home'}) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> pressRecents() async {
    try {
      return await _channel.invokeMethod<bool>('performGlobal', {'action': 'recents'}) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> toggleWifi() async {
    try {
      return await _channel.invokeMethod<bool>('openQuickSettingsAndTapTile', {'tileLabel': 'Wi-Fi'}) ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> toggleBluetooth() async {
    try {
      return await _channel.invokeMethod<bool>('openQuickSettingsAndTapTile', {'tileLabel': 'Bluetooth'}) ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> toggleHotspot() async {
    try {
      return await _channel.invokeMethod<bool>('openHotspotPanel') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> setTorch(bool on) async {
    try {
      return await _channel.invokeMethod<bool>('setTorch', {'on': on}) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> setBrightness(int value) async {
    try {
      final ok = await _channel.invokeMethod<bool>('setBrightness', {'value': value}) ?? false;
      if (ok == false) {
        await requestWriteSettingsPermission();
      }
      return ok;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> setVolume(int streamType, int level) async {
    try {
      return await _channel.invokeMethod<bool>('setVolume', {
            'streamType': streamType,
            'level': level,
          }) ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> requestWriteSettingsPermission() async {
    try {
      await _channel.invokeMethod('requestWriteSettingsPermission');
    } catch (_) {}
  }

  static Future<bool> openApp(String appName) async {
    try {
      return await _channel.invokeMethod<bool>('launchAppByName', {'appName': appName}) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> sendWhatsAppMessage(String contactName, String message) async {
    try {
      return await _channel.invokeMethod<bool>(
            'sendWhatsAppMessage',
            {'contactName': contactName, 'message': message},
          ) ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> callContact(String contactName) async {
    try {
      return await _channel.invokeMethod<bool>('callContact', {'contactName': contactName}) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> setAlarm(int hour, int minute, {String message = 'Vyshu reminder'}) async {
    try {
      return await _channel.invokeMethod<bool>(
            'setAlarm',
            {'hour': hour, 'minute': minute, 'message': message},
          ) ??
          false;
    } catch (_) {
      return false;
    }
  }

  // --- ALWAYS-ON SERVICE & WAKE WORD CONTROLS ---

  static Future<bool> setAlwaysOnService(bool enabled) async {
    try {
      return await _channel.invokeMethod<bool>('setAlwaysOnService', {'enabled': enabled}) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isAlwaysOnServiceRunning() async {
    try {
      return await _channel.invokeMethod<bool>('isAlwaysOnServiceRunning') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> requestBatteryOptimizationExemption() async {
    try {
      return await _channel.invokeMethod<bool>('requestBatteryExemption') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> requestOverlayPermission() async {
    try {
      return await _channel.invokeMethod<bool>('requestOverlayPermission') ?? false;
    } catch (_) {
      return false;
    }
  }

  // --- SYSTEM OVERLAY HUD (Live Task Progress + Emergency STOP) ---

  static Future<void> showOverlayHud({
    required String goal,
    required String stepText,
  }) async {
    try {
      await _channel.invokeMethod('showOverlayHud', {
        'goal': goal,
        'stepText': stepText,
      });
    } catch (_) {}
  }

  static Future<void> updateOverlayHud({
    required String goal,
    required String stepText,
  }) async {
    try {
      await _channel.invokeMethod('updateOverlayHud', {
        'goal': goal,
        'stepText': stepText,
      });
    } catch (_) {}
  }

  static Future<void> hideOverlayHud() async {
    try {
      await _channel.invokeMethod('hideOverlayHud');
    } catch (_) {}
  }

  /// Registers listener for native callbacks (e.g. hardware overlay STOP button or wake-word task)
  static void registerNativeCallbackHandler({
    required VoidCallback onEmergencyStopFromOverlay,
    required ValueChanged<String> onWakeWordCommand,
  }) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onOverlayEmergencyStop') {
        debugPrint('VYSHU_AGENT: [Bridge] Received emergency STOP from native system overlay');
        onEmergencyStopFromOverlay();
      } else if (call.method == 'onWakeWordGoal') {
        final goal = call.arguments?.toString() ?? '';
        debugPrint('VYSHU_AGENT: [Bridge] Received wake-word goal: "$goal"');
        if (goal.isNotEmpty) {
          onWakeWordCommand(goal);
        }
      }
      return true;
    });
  }
}
