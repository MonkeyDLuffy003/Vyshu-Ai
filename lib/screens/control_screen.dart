import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Control Panel screen for Vyshu AI.
///
/// Wires UI controls to the native Android side via
/// MethodChannel('com.vyshu.ai/accessibility'), which (per
/// VyshuAccessibilityService.kt) should forward to:
///   setTorch(on: Boolean)
///   setBrightness(value: Int)
///   setVolume(streamType: Int, level: Int)
///   openQuickSettingsAndTapTile(tileLabel: String)
///
/// ASSUMED method/argument names below (NOT verified against
/// MainActivity.kt, which wasn't available when this was written):
///   'setTorch'                      args: {'on': bool}
///   'setBrightness'                 args: {'value': int 0-255}
///   'setVolume'                     args: {'streamType': int, 'level': int}
///   'openQuickSettingsAndTapTile'   args: {'label': String}
/// If MainActivity.kt forwards these under different names/keys, only the
/// _invoke() calls in this file need to change to match.
///
/// Quick Settings tile label text varies by OEM (stock Android vs Samsung
/// One UI vs MIUI etc). If a tile tap silently fails, check the exact label
/// text shown on your device and adjust the strings passed to _tapTile().
class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  static const _channel = MethodChannel('com.vyshu.ai/accessibility');

  // Android AudioManager.STREAM_MUSIC
  static const int _streamMusic = 3;
  static const double _maxVolume = 15;

  bool _torchOn = false;
  double _brightness = 128;
  double _volume = 7;

  bool _busy = false;
  String? _lastError;

  Future<bool> _invoke(String method, [Map<String, dynamic>? args]) async {
    try {
      final result = await _channel.invokeMethod<bool>(method, args);
      if (mounted) setState(() => _lastError = null);
      return result ?? false;
    } on MissingPluginException {
      if (mounted) {
        setState(() => _lastError =
            'Native method "$method" not found. Check MainActivity.kt registers this channel/method.');
      }
      return false;
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() => _lastError = '$method failed: ${e.message}');
      }
      return false;
    }
  }

  Future<void> _toggleTorch(bool on) async {
    setState(() => _busy = true);
    final ok = await _invoke('setTorch', {'on': on});
    setState(() {
      _busy = false;
      if (ok) _torchOn = on;
    });
    if (!ok) _showSnack('Could not toggle torch.');
  }

  void _onBrightnessChanged(double value) => setState(() => _brightness = value);

  Future<void> _commitBrightness(double value) async {
    final ok = await _invoke('setBrightness', {'value': value.round()});
    if (!ok) {
      _showSnack(
        'Brightness control needs "Modify system settings" permission. '
        'Enable it in Settings > Apps > Vyshu AI > Special app access.',
      );
    }
  }

  void _onVolumeChanged(double value) => setState(() => _volume = value);

  Future<void> _commitVolume(double value) async {
    final ok = await _invoke('setVolume', {
      'streamType': _streamMusic,
      'level': value.round(),
    });
    if (!ok) _showSnack('Could not set volume.');
  }

  Future<void> _tapTile(String label) async {
    setState(() => _busy = true);
    final ok = await _invoke('openQuickSettingsAndTapTile', {'label': label});
    setState(() => _busy = false);
    if (!ok) {
      _showSnack(
        'Could not tap "$label" tile. Make sure the Accessibility Service '
        'is enabled, and that the label matches your device\'s wording.',
      );
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Control Panel')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_lastError != null) ...[
            Card(
              color: Colors.red.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_lastError!, style: const TextStyle(color: Colors.red)),
              ),
            ),
            const SizedBox(height: 16),
          ],
          _toggleRow(
            icon: Icons.flashlight_on,
            label: 'Torch',
            value: _torchOn,
            onChanged: _busy ? null : _toggleTorch,
          ),
          const Divider(),
          _sliderRow(
            icon: Icons.brightness_6,
            label: 'Brightness',
            value: _brightness,
            min: 0,
            max: 255,
            onChanged: _onBrightnessChanged,
            onChangeEnd: _commitBrightness,
          ),
          const Divider(),
          _sliderRow(
            icon: Icons.volume_up,
            label: 'Volume',
            value: _volume,
            min: 0,
            max: _maxVolume,
            onChanged: _onVolumeChanged,
            onChangeEnd: _commitVolume,
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text('Quick Settings', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          _tileButton(icon: Icons.wifi, label: 'Wi-Fi'),
          _tileButton(icon: Icons.bluetooth, label: 'Bluetooth'),
          _tileButton(icon: Icons.wifi_tethering, label: 'Hotspot'),
          _tileButton(icon: Icons.airplanemode_active, label: 'Airplane mode'),
        ],
      ),
    );
  }

  Widget _toggleRow({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }

  Widget _sliderRow({
    required IconData icon,
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required ValueChanged<double> onChangeEnd,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Slider(
        value: value,
        min: min,
        max: max,
        onChanged: onChanged,
        onChangeEnd: onChangeEnd,
      ),
    );
  }

  Widget _tileButton({required IconData icon, required String label}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.touch_app),
      onTap: _busy ? null : () => _tapTile(label),
    );
  }
}
