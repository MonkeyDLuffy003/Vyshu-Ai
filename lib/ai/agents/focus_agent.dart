import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../services/output_policy_service.dart';
import '../../services/vyshu_accessibility_bridge.dart';

/// Status of a Focus Session
enum FocusSessionState { idle, active, paused, completed }

/// FocusAgent — Feature Agent 4
/// Enforces deep-work focus sessions, monitors distracting apps via Accessibility Bridge,
/// and gently steers user away from time sinks back to productivity.
class FocusAgent extends ChangeNotifier {
  static final FocusAgent instance = FocusAgent._internal();
  factory FocusAgent() => instance;
  FocusAgent._internal();

  FocusSessionState _state = FocusSessionState.idle;
  int _targetMinutes = 25;
  int _remainingSeconds = 0;
  String _currentGoal = 'Deep Work Session';
  Timer? _countdownTimer;
  Timer? _appMonitorTimer;

  static const Set<String> defaultBlockedPackages = {
    'com.instagram.android',
    'com.facebook.katana',
    'com.zhiliaoapp.musically', // TikTok
    'com.twitter.android',
    'com.reddit.frontpage',
    'com.snapchat.android',
  };

  Set<String> _blockedPackages = Set.from(defaultBlockedPackages);

  FocusSessionState get state => _state;
  bool get isActive => _state == FocusSessionState.active;
  int get remainingSeconds => _remainingSeconds;
  int get targetMinutes => _targetMinutes;
  String get currentGoal => _currentGoal;

  String get formattedRemaining {
    final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// Starts a focus session for [minutes] with [goal].
  void startSession({int minutes = 25, String goal = 'Deep Work'}) {
    stopSession(reason: 'Restarted');
    _targetMinutes = minutes;
    _remainingSeconds = minutes * 60;
    _currentGoal = goal;
    _state = FocusSessionState.active;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _completeSession();
      }
    });

    // Check foreground app every 3 seconds via accessibility bridge
    _appMonitorTimer = Timer.periodic(const Duration(seconds: 3), (_) => _checkForegroundApp());

    debugPrint('VYSHU_AGENT: [FocusAgent] Started session "$goal" for $minutes min');
    notifyListeners();
  }

  Future<void> _checkForegroundApp() async {
    if (!isActive) return;
    try {
      final screen = await VyshuAccessibilityBridge.dumpScreenCompact();
      final pkg = screen['packageName'] as String? ?? '';
      if (_blockedPackages.contains(pkg)) {
        debugPrint('VYSHU_AGENT: [FocusAgent] Blocked app detected: $pkg during focus session! Redirecting...');
        await VyshuAccessibilityBridge.pressHome();
        // Check output policy before making any audible alert
        if (outputPolicyService.canSpeakSpontaneously) {
          // Normal mode — brief gentle reminder
        }
      }
    } catch (_) {}
  }

  void pauseSession() {
    if (_state != FocusSessionState.active) return;
    _countdownTimer?.cancel();
    _appMonitorTimer?.cancel();
    _state = FocusSessionState.paused;
    notifyListeners();
  }

  void resumeSession() {
    if (_state != FocusSessionState.paused) return;
    _state = FocusSessionState.active;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _completeSession();
      }
    });
    _appMonitorTimer = Timer.periodic(const Duration(seconds: 3), (_) => _checkForegroundApp());
    notifyListeners();
  }

  void stopSession({String reason = 'Stopped'}) {
    _countdownTimer?.cancel();
    _appMonitorTimer?.cancel();
    _state = FocusSessionState.idle;
    _remainingSeconds = 0;
    debugPrint('VYSHU_AGENT: [FocusAgent] Session stopped: $reason');
    notifyListeners();
  }

  void _completeSession() {
    _countdownTimer?.cancel();
    _appMonitorTimer?.cancel();
    _state = FocusSessionState.completed;
    debugPrint('VYSHU_AGENT: [FocusAgent] Focus session completed successfully!');
    notifyListeners();
  }

  void addBlockedPackage(String pkg) {
    _blockedPackages.add(pkg.trim());
  }

  void removeBlockedPackage(String pkg) {
    _blockedPackages.remove(pkg.trim());
  }
}

final focusAgent = FocusAgent.instance;
