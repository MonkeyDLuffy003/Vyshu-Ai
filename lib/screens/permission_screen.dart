import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';

/// First-boot onboarding screen. This MUST run before any voice,
/// accessibility, calling, or notification-reading feature is used.
/// Without this, those features fail silently or crash — this is the
/// root cause behind several of Teja's reported bugs (voice not working,
/// accessibility not working, "open app" doing nothing).
class PermissionScreen extends StatefulWidget {
  final Widget nextScreen;
  const PermissionScreen({super.key, required this.nextScreen});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  static const String _onboardKey = 'vyshu_onboarding_complete';

  bool _checking = true;
  bool _requesting = false;

  // Tracks granted state for display purposes
  final Map<String, bool> _status = {
    'Microphone (voice chat)': false,
    'Contacts (calling)': false,
    'Phone calls': false,
    'Notifications': false,
    'Camera (torch/scan)': false,
    'Storage (offline music)': false,
    'Bluetooth': false,
  };

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyOnboarded();
  }

  Future<void> _checkIfAlreadyOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool(_onboardKey) ?? false;
    if (done) {
      _goNext();
      return;
    }
    setState(() => _checking = false);
  }

  void _goNext() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => widget.nextScreen),
    );
  }

  Future<void> _requestAllPermissions() async {
    setState(() => _requesting = true);

    // Standard runtime-requestable permissions
    final results = await [
      Permission.microphone,
      Permission.contacts,
      Permission.phone,
      Permission.notification,
      Permission.camera,
      Permission.storage,
      Permission.bluetooth,
      Permission.bluetoothConnect,
    ].request();

    setState(() {
      _status['Microphone (voice chat)'] =
          results[Permission.microphone]?.isGranted ?? false;
      _status['Contacts (calling)'] =
          results[Permission.contacts]?.isGranted ?? false;
      _status['Phone calls'] = results[Permission.phone]?.isGranted ?? false;
      _status['Notifications'] =
          results[Permission.notification]?.isGranted ?? false;
      _status['Camera (torch/scan)'] =
          results[Permission.camera]?.isGranted ?? false;
      _status['Storage (offline music)'] =
          results[Permission.storage]?.isGranted ?? false;
      _status['Bluetooth'] =
          (results[Permission.bluetooth]?.isGranted ?? false) ||
              (results[Permission.bluetoothConnect]?.isGranted ?? false);
      _requesting = false;
    });
  }

  /// WRITE_SETTINGS, Notification Listener access, and Accessibility
  /// can't be requested via permission_handler — Android requires the
  /// user to manually flip these in a system settings screen. We deep
  /// link there directly so Teja isn't hunting through menus.
  Future<void> _openSystemSetting(String action) async {
    try {
      final intent = AndroidIntent(
        action: action,
        flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await intent.launch();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open settings: $e')),
        );
      }
    }
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardKey, true);
    _goNext();
  }

  Widget _permissionTile(String label, bool granted) {
    return ListTile(
      leading: Icon(
        granted ? Icons.check_circle : Icons.radio_button_unchecked,
        color: granted ? const Color(0xFF00FF99) : Colors.white38,
      ),
      title: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: Color(0xFF05050F),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00CCFF)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF05050F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const Text(
                'Before Vyshu wakes up',
                style: TextStyle(
                  color: Color(0xFF00CCFF),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "She needs a few permissions to talk, call, and control your phone. "
                "Nothing works without these — Android blocks it otherwise.",
                style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    ..._status.entries
                        .map((e) => _permissionTile(e.key, e.value)),
                    const Divider(color: Color(0xFF222244)),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'These two need a manual toggle (Android requires it):',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.settings_accessibility,
                          color: Color(0xFF00CCFF)),
                      title: const Text('Accessibility Service',
                          style: TextStyle(color: Colors.white)),
                      subtitle: const Text(
                        'Needed for app-opening and screen automation',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                      trailing: TextButton(
                        onPressed: () => _openSystemSetting(
                            'android.settings.ACCESSIBILITY_SETTINGS'),
                        child: const Text('Open'),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.notifications_active,
                          color: Color(0xFF00CCFF)),
                      title: const Text('Notification Access',
                          style: TextStyle(color: Colors.white)),
                      subtitle: const Text(
                        'Needed for Vyshu to read notifications aloud',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                      trailing: TextButton(
                        onPressed: () => _openSystemSetting(
                            'android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS'),
                        child: const Text('Open'),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.tune, color: Color(0xFF00CCFF)),
                      title: const Text('Modify System Settings',
                          style: TextStyle(color: Colors.white)),
                      subtitle: const Text(
                        'Needed for WiFi/brightness/volume toggles',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                      trailing: TextButton(
                        onPressed: () => _openSystemSetting(
                            'android.settings.action.MANAGE_WRITE_SETTINGS'),
                        child: const Text('Open'),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _requesting ? null : _requestAllPermissions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF12122A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _requesting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Color(0xFF00CCFF)),
                        )
                      : const Text('Grant App Permissions',
                          style: TextStyle(color: Color(0xFF00CCFF))),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _finishOnboarding,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00CCFF),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Continue to Vyshu",
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
