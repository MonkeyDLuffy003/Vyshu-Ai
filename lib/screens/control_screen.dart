import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Control Panel — Mobile Accessories + Open Apps.
///
/// This wires directly into the existing native method channel
/// "com.vyshu.ai/accessibility" (see MainActivity.kt +
/// VyshuAccessibilityService.kt). That native code was already built
/// and working — this screen just needed to exist to actually call it.
class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  static const _channel = MethodChannel('com.vyshu.ai/accessibility');

  bool _torchOn = false;
  bool _brightnessFull = false;
  bool _accessibilityEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkAccessibilityStatus();
  }

  Future<void> _checkAccessibilityStatus() async {
    try {
      final enabled = await _channel.invokeMethod<bool>('isServiceEnabled');
      setState(() => _accessibilityEnabled = enabled ?? false);
    } catch (_) {
      setState(() => _accessibilityEnabled = false);
    }
  }

  Future<void> _openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } catch (e) {
      _showError('Could not open accessibility settings: $e');
    }
  }

  Future<void> _toggleTorch() async {
    if (!_accessibilityEnabled) {
      _promptEnableAccessibility('Torch control');
      return;
    }
    final newState = !_torchOn;
    try {
      final ok = await _channel
          .invokeMethod<bool>('setTorch', {'on': newState});
      if (ok == true) {
        setState(() => _torchOn = newState);
      } else {
        _showError('Torch toggle failed — camera may be in use.');
      }
    } catch (e) {
      _showError('Torch error: $e');
    }
  }

  Future<void> _toggleBrightness() async {
    if (!_accessibilityEnabled) {
      _promptEnableAccessibility('Brightness control');
      return;
    }
    final newValue = _brightnessFull ? 50 : 255;
    try {
      final ok = await _channel
          .invokeMethod<bool>('setBrightness', {'value': newValue});
      if (ok == true) {
        setState(() => _brightnessFull = !_brightnessFull);
      } else {
        _showError(
            'Brightness change failed — needs "Modify system settings" permission.');
        await _channel.invokeMethod('openWriteSettingsPermission');
      }
    } catch (e) {
      _showError('Brightness error: $e');
    }
  }

  Future<void> _toggleQuickSettingsTile(String tileName) async {
    if (!_accessibilityEnabled) {
      _promptEnableAccessibility('$tileName control');
      return;
    }
    try {
      final ok = await _channel.invokeMethod<bool>(
          'toggleQuickSettingsTile', {'tile': tileName});
      if (ok != true) {
        _showError(
            '$tileName tile not found — try opening Quick Settings once manually first.');
      }
    } catch (e) {
      _showError('$tileName error: $e');
    }
  }

  void _promptEnableAccessibility(String featureName) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF12122A),
        title: Text('$featureName needs Accessibility',
            style: const TextStyle(color: Colors.white)),
        content: const Text(
          'Vyshu needs Accessibility Service enabled to control hardware. '
          'Tap below to turn it on in Settings.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _openAccessibilitySettings();
            },
            child: const Text('Open Settings',
                style: TextStyle(color: Color(0xFF00CCFF))),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openExternalApp(String packageOrUrl, {bool isUrl = false}) async {
    try {
      final uri = isUrl
          ? Uri.parse(packageOrUrl)
          : Uri.parse('package:$packageOrUrl');
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        _showError('Could not open app — it may not be installed.');
      }
    } catch (e) {
      _showError('Open app error: $e');
    }
  }

  Widget _accessoryTile({
    required IconData icon,
    required String label,
    required bool isOn,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0E1422),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isOn ? const Color(0xFF00CCFF) : const Color(0xFF1A2436),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(
          children: [
            Icon(icon, color: isOn ? const Color(0xFF00CCFF) : Colors.white38, size: 28),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 4),
            Text(
              isOn ? 'ON' : 'OFF',
              style: TextStyle(
                color: isOn ? const Color(0xFF00CCFF) : Colors.white24,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _appTile(IconData icon, String label, String packageName) {
    return GestureDetector(
      onTap: () => _openExternalApp(packageName),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0E1422),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1A2436)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF00CCFF), size: 26),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05050F),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: const [
                Icon(Icons.dashboard_customize, color: Color(0xFF00CCFF)),
                SizedBox(width: 10),
                Text(
                  'CONTROL PANEL',
                  style: TextStyle(
                    color: Color(0xFF00CCFF),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            if (!_accessibilityEnabled)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: GestureDetector(
                  onTap: _openAccessibilitySettings,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A1A1A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orangeAccent.withOpacity(0.5)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orangeAccent, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Accessibility disabled — hardware controls won\'t work. Tap to enable.',
                            style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            const Text('Mobile Accessories',
                style: TextStyle(color: Color(0xFF00CCFF), fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _accessoryTile(
                  icon: Icons.wifi,
                  label: 'WiFi',
                  isOn: false,
                  onTap: () => _toggleQuickSettingsTile('Wi-Fi'),
                ),
                _accessoryTile(
                  icon: Icons.flashlight_on,
                  label: 'Torch',
                  isOn: _torchOn,
                  onTap: _toggleTorch,
                ),
                _accessoryTile(
                  icon: Icons.wifi_tethering,
                  label: 'Hotspot',
                  isOn: false,
                  onTap: () => _toggleQuickSettingsTile('Hotspot'),
                ),
                _accessoryTile(
                  icon: Icons.bluetooth,
                  label: 'Bluetooth',
                  isOn: false,
                  onTap: () => _toggleQuickSettingsTile('Bluetooth'),
                ),
                _accessoryTile(
                  icon: Icons.volume_up,
                  label: 'Vol Max',
                  isOn: false,
                  onTap: () => _toggleQuickSettingsTile('Volume'),
                ),
                _accessoryTile(
                  icon: Icons.brightness_7,
                  label: 'Bright',
                  isOn: _brightnessFull,
                  onTap: _toggleBrightness,
                ),
              ],
            ),
            const SizedBox(height: 28),
            const Text('Open Apps',
                style: TextStyle(color: Color(0xFF00CCFF), fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _appTile(Icons.music_note, 'Spotify', 'com.spotify.music'),
                _appTile(Icons.play_circle_fill, 'YouTube', 'com.google.android.youtube'),
                _appTile(Icons.public, 'Chrome', 'com.android.chrome'),
                _appTile(Icons.camera_alt, 'Camera', 'com.android.camera2'),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Note: Discord/Instagram/Spotify "Bot Controls" need a separate '
              'always-on backend (V2) — they can\'t run inside this app directly.',
              style: TextStyle(color: Colors.white24, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
