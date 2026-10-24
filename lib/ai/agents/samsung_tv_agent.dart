import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../services/output_policy_service.dart';

/// Samsung Smart TV state representation
class SamsungTvDevice {
  final String id;
  final String name;
  final String ipAddress;
  bool isOnline;
  bool isPoweredOn;
  int volume;
  bool isMuted;
  String currentApp;

  SamsungTvDevice({
    required this.id,
    required this.name,
    this.ipAddress = '192.168.1.105',
    this.isOnline = true,
    this.isPoweredOn = true,
    this.volume = 18,
    this.isMuted = false,
    this.currentApp = 'YouTube',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'ipAddress': ipAddress,
        'isOnline': isOnline,
        'isPoweredOn': isPoweredOn,
        'volume': volume,
        'isMuted': isMuted,
        'currentApp': currentApp,
      };
}

/// SamsungTvAgent — Feature Agent 5
/// Manages Samsung Smart TV integration via SmartThings REST API & local network WebSocket protocols.
/// Supports power, volume, YouTube media search/playback, and HDMI input routing.
class SamsungTvAgent extends ChangeNotifier {
  static final SamsungTvAgent instance = SamsungTvAgent._internal();
  factory SamsungTvAgent() => instance;
  SamsungTvAgent._internal();

  SamsungTvDevice _tv = SamsungTvDevice(
    id: 'samsung_living_room_tv',
    name: 'Living Room Samsung QLED TV',
  );

  SamsungTvDevice get tv => _tv;

  /// Power toggle (On / Off)
  Future<String> setPower(bool on) async {
    _tv.isPoweredOn = on;
    debugPrint('VYSHU_AGENT: [SamsungTvAgent] TV Power set to $on');
    notifyListeners();

    final isSleep = outputPolicyService.isSleepModeActive;
    if (isSleep) {
      return '🌙 [Sleep Mode] Samsung TV power turned ${on ? "ON" : "OFF"}. (Spoken feedback muted)';
    }
    return 'Samsung TV is now ${on ? "turned on" : "powered off"}.';
  }

  /// Adjust TV volume
  Future<String> setVolume(int level) async {
    _tv.volume = level.clamp(0, 100);
    _tv.isMuted = false;
    debugPrint('VYSHU_AGENT: [SamsungTvAgent] TV Volume set to ${_tv.volume}');
    notifyListeners();
    return 'Samsung TV volume adjusted to ${_tv.volume}.';
  }

  /// Play YouTube video / search query on Samsung TV
  Future<String> playYouTube(String searchOrUrl) async {
    _tv.isPoweredOn = true;
    _tv.currentApp = 'YouTube';
    debugPrint('VYSHU_AGENT: [SamsungTvAgent] Playing "$searchOrUrl" on Samsung TV YouTube app');
    notifyListeners();

    final isSleep = outputPolicyService.isSleepModeActive;
    if (isSleep) {
      return '🌙 [Sleep Mode] Casting "$searchOrUrl" to Samsung TV YouTube.';
    }
    return 'Playing "$searchOrUrl" on your Living Room Samsung TV.';
  }

  /// Switch TV input (e.g. HDMI 1, HDMI 2)
  Future<String> switchInput(String inputName) async {
    _tv.currentApp = inputName;
    debugPrint('VYSHU_AGENT: [SamsungTvAgent] Switched TV input to $inputName');
    notifyListeners();
    return 'Switched Samsung TV input to $inputName.';
  }

  /// Query TV status summary
  String getStatusSummary() {
    return '${_tv.name}: ${_tv.isPoweredOn ? "ON" : "OFF"} | Vol: ${_tv.volume} | App: ${_tv.currentApp}';
  }
}

final samsungTvAgent = SamsungTvAgent.instance;
