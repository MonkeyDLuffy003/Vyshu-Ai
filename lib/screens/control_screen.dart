import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../ai/sub_agent_dispatcher.dart';
import '../ai/vyshu_brain.dart';
import '../services/output_policy_service.dart';
import '../services/vyshu_accessibility_bridge.dart';

/// Control Panel — Accessibility Status, Always-On Wake Word Toggle,
/// Sleep Mode & Output Policy, Autonomous Agent Goal Runner, Mobile Accessories & Sub-Agents.
class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> with WidgetsBindingObserver {
  bool _torchOn = false;
  bool _brightnessFull = false;
  bool _accessibilityEnabled = false;
  bool _alwaysOnRunning = false;
  final TextEditingController _goalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    outputPolicyService.init();
    outputPolicyService.addListener(_onPolicyChanged);
    _refreshSystemState();
  }

  void _onPolicyChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    outputPolicyService.removeListener(_onPolicyChanged);
    WidgetsBinding.instance.removeObserver(this);
    _goalController.dispose();
    super.dispose();
  }

  /// Automatically re-checks Accessibility connection when user returns from Settings!
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshSystemState();
    }
  }

  Future<void> _refreshSystemState() async {
    final acc = await VyshuAccessibilityBridge.isServiceEnabled();
    final alwaysOn = await VyshuAccessibilityBridge.isAlwaysOnServiceRunning();
    if (!mounted) return;
    setState(() {
      _accessibilityEnabled = acc;
      _alwaysOnRunning = alwaysOn;
    });
  }

  Future<void> _openAccessibilitySettings() async {
    final ok = await VyshuAccessibilityBridge.openAccessibilitySettings();
    if (!ok) {
      _showError('Could not open Accessibility Settings.');
    }
  }

  Future<void> _toggleAlwaysOn(bool value) async {
    if (value) {
      await VyshuAccessibilityBridge.requestBatteryOptimizationExemption();
      await VyshuAccessibilityBridge.requestOverlayPermission();
    }
    final ok = await VyshuAccessibilityBridge.setAlwaysOnService(value);
    if (!mounted) return;
    setState(() => _alwaysOnRunning = ok ? value : _alwaysOnRunning);
  }

  Future<void> _toggleTorch() async {
    if (!_accessibilityEnabled) {
      _promptEnableAccessibility('Torch control');
      return;
    }
    final newState = !_torchOn;
    final ok = await VyshuAccessibilityBridge.setTorch(newState);
    if (ok) {
      setState(() => _torchOn = newState);
    } else {
      _showError('Torch toggle failed.');
    }
  }

  Future<void> _toggleBrightness() async {
    if (!_accessibilityEnabled) {
      _promptEnableAccessibility('Brightness control');
      return;
    }
    final newValue = _brightnessFull ? 60 : 255;
    final ok = await VyshuAccessibilityBridge.setBrightness(newValue);
    if (ok) {
      setState(() => _brightnessFull = !_brightnessFull);
    } else {
      _showError('Grant "Modify system settings" permission first.');
    }
  }

  Future<void> _runManualAgentGoal() async {
    final goal = _goalController.text.trim();
    if (goal.isEmpty) return;
    _goalController.clear();
    await vyshuBrain.runAgentGoal(goal);
  }

  void _promptEnableAccessibility(String feature) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Accessibility Service Required',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '$feature needs the Vyshu Accessibility Service enabled.\n\n'
          'Tap "Open Settings" below, find "Vyshu AI" in the list, and turn it on.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00CCFF),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _openAccessibilitySettings();
            },
            child: const Text(
              'Open Settings',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Vyshu Control Center',
          style: TextStyle(
            color: Color(0xFF00CCFF),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF00CCFF)),
            tooltip: 'Re-check service status',
            onPressed: _refreshSystemState,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Accessibility Service Banner (Tap to enable flow)
            _buildAccessibilityBanner(),
            const SizedBox(height: 14),

            // 2. Always-On Wake Word Foreground Service Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF101528),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _alwaysOnRunning
                      ? const Color(0xFF00CCFF)
                      : Colors.white12,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.hearing, color: Color(0xFF00CCFF)),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Always-On Wake Word Service',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Wake word "Hey Vyshu" · Asks "What do you need?" & runs task',
                              style: TextStyle(color: Colors.white60, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _alwaysOnRunning,
                        activeColor: const Color(0xFF00CCFF),
                        onChanged: _toggleAlwaysOn,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () =>
                            VyshuAccessibilityBridge.requestBatteryOptimizationExemption(),
                        icon: const Icon(Icons.battery_charging_full,
                            size: 16, color: Color(0xFF00CCFF)),
                        label: const Text('Exempt Battery', style: TextStyle(fontSize: 12)),
                      ),
                      TextButton.icon(
                        onPressed: () =>
                            VyshuAccessibilityBridge.requestOverlayPermission(),
                        icon: const Icon(Icons.layers_outlined,
                            size: 16, color: Color(0xFF00CCFF)),
                        label: const Text('Grant Overlay HUD', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 3. Vyshu Sleep & Quiet Hours Control (Feature 7)
            _buildSleepModeCard(),

            const SizedBox(height: 16),

            // 4. Direct Autonomous Goal Launcher
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF101528),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Run Autonomous UI Goal (Observe → Plan → Act → Verify)',
                    style: TextStyle(
                      color: Color(0xFF00CCFF),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _goalController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: 'e.g. open YouTube and play lo-fi for 1 hour',
                            hintStyle: TextStyle(color: Colors.white38),
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00CCFF),
                          foregroundColor: Colors.black,
                          minimumSize: const Size(72, 44),
                        ),
                        onPressed: _runManualAgentGoal,
                        child: const Text(
                          'Run',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 4. Mobile Accessories
            const Text(
              'Mobile Accessories',
              style: TextStyle(
                color: Color(0xFF00CCFF),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildTile(
                  icon: Icons.wifi,
                  label: 'Wi-Fi',
                  active: false,
                  onTap: () => VyshuAccessibilityBridge.toggleWifi(),
                ),
                _buildTile(
                  icon: Icons.bluetooth,
                  label: 'Bluetooth',
                  active: false,
                  onTap: () => VyshuAccessibilityBridge.toggleBluetooth(),
                ),
                _buildTile(
                  icon: Icons.wifi_tethering,
                  label: 'Hotspot',
                  active: false,
                  onTap: () => VyshuAccessibilityBridge.toggleHotspot(),
                ),
                _buildTile(
                  icon: _torchOn ? Icons.flashlight_on : Icons.flashlight_off,
                  label: 'Torch',
                  active: _torchOn,
                  onTap: _toggleTorch,
                ),
                _buildTile(
                  icon: Icons.brightness_6,
                  label: _brightnessFull ? 'Bright: Full' : 'Bright: Dim',
                  active: _brightnessFull,
                  onTap: _toggleBrightness,
                ),
                _buildTile(
                  icon: Icons.music_note,
                  label: 'Vaani 1h',
                  active: false,
                  onTap: () {
                    subAgentDispatcher.dispatch(
                      agent: 'Vaani',
                      task: 'Play focus playlist for 1 hour',
                      durationMinutes: 60,
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 5. Quick Open Apps
            const Text(
              'Open Apps',
              style: TextStyle(
                color: Color(0xFF00CCFF),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.6,
              children: [
                _buildAppButton(
                  icon: Icons.play_circle_fill,
                  label: 'YouTube',
                  color: Colors.red,
                  uri: 'https://www.youtube.com',
                ),
                _buildAppButton(
                  icon: Icons.music_note,
                  label: 'Spotify',
                  color: Colors.green,
                  uri: 'spotify:',
                ),
                _buildAppButton(
                  icon: Icons.chat,
                  label: 'WhatsApp',
                  color: Colors.teal,
                  uri: 'whatsapp:',
                ),
                _buildAppButton(
                  icon: Icons.discord,
                  label: 'Discord',
                  color: Colors.indigoAccent,
                  uri: 'discord:',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessibilityBanner() {
    final color = _accessibilityEnabled ? Colors.green : Colors.orange;
    final text = _accessibilityEnabled
        ? 'Accessibility Service: Connected & Ready'
        : 'Accessibility Service: Disabled (Tap to enable)';

    return InkWell(
      onTap: _openAccessibilitySettings,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
        ),
        child: Row(
          children: [
            Icon(
              _accessibilityEnabled ? Icons.check_circle : Icons.warning,
              color: color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.open_in_new, color: Colors.white54, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildSleepModeCard() {
    final settings = outputPolicyService.settings;
    final isSleepActive = outputPolicyService.isSleepModeActive;
    final isManual = outputPolicyService.isManualSleepActive;

    final bedTimeStr =
        '${settings.bedHour.toString().padLeft(2, '0')}:${settings.bedMinute.toString().padLeft(2, '0')}';
    final wakeTimeStr =
        '${settings.wakeHour.toString().padLeft(2, '0')}:${settings.wakeMinute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isSleepActive ? const Color(0xFF13112E) : const Color(0xFF101528),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSleepActive ? const Color(0xFF8B5CF6) : Colors.white12,
          width: isSleepActive ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSleepActive ? Icons.bedtime : Icons.nights_stay_outlined,
                color: isSleepActive ? const Color(0xFFA78BFA) : const Color(0xFF00CCFF),
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vyshu Sleep & Quiet Hours',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      isSleepActive
                          ? (isManual
                              ? 'Active (Manual Override) · Audio Muted'
                              : 'Active (Scheduled) · Audio Muted')
                          : (settings.scheduleEnabled
                              ? 'Scheduled: $bedTimeStr → $wakeTimeStr'
                              : 'Schedule Off · Normal Mode'),
                      style: TextStyle(
                        color: isSleepActive ? const Color(0xFFA78BFA) : Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSleepActive
                      ? const Color(0xFF8B5CF6).withOpacity(0.2)
                      : Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSleepActive ? const Color(0xFF8B5CF6) : Colors.white24,
                  ),
                ),
                child: Text(
                  isSleepActive ? 'SLEEP ACTIVE' : 'DAY MODE',
                  style: TextStyle(
                    color: isSleepActive ? const Color(0xFFA78BFA) : Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 10),

          // Manual Override Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manual Sleep Mode',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Instant silent mode override anytime',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
              Switch(
                value: settings.manualSleepActive,
                activeColor: const Color(0xFFA78BFA),
                onChanged: (val) async {
                  await outputPolicyService.setManualSleepMode(val);
                },
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Schedule Toggle & Time Pickers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bedtime Schedule',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Auto-quiet between bedtime and wake-up',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
              Switch(
                value: settings.scheduleEnabled,
                activeColor: const Color(0xFF00CCFF),
                onChanged: (val) async {
                  await outputPolicyService.setScheduleEnabled(val);
                },
              ),
            ],
          ),

          if (settings.scheduleEnabled) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(hour: settings.bedHour, minute: settings.bedMinute),
                      );
                      if (picked != null) {
                        await outputPolicyService.setBedTime(picked.hour, picked.minute);
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.nightlight_round, size: 16, color: Color(0xFFA78BFA)),
                          const SizedBox(width: 6),
                          Text(
                            'Bed: $bedTimeStr',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(hour: settings.wakeHour, minute: settings.wakeMinute),
                      );
                      if (picked != null) {
                        await outputPolicyService.setWakeTime(picked.hour, picked.minute);
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.wb_sunny_outlined, size: 16, color: Color(0xFFFBBF24)),
                          const SizedBox(width: 6),
                          Text(
                            'Wake: $wakeTimeStr',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),
          const Text(
            'Sleep Audio Policy',
            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              ChoiceChip(
                label: const Text('Text Only', style: TextStyle(fontSize: 11)),
                selected: settings.sleepAudioMode == AudioOutputMode.textOnly,
                selectedColor: const Color(0xFF8B5CF6),
                backgroundColor: const Color(0xFF1E2238),
                labelStyle: TextStyle(
                  color: settings.sleepAudioMode == AudioOutputMode.textOnly ? Colors.white : Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
                onSelected: (selected) {
                  if (selected) outputPolicyService.setSleepAudioMode(AudioOutputMode.textOnly);
                },
              ),
              ChoiceChip(
                label: const Text('Whisper (Low Vol)', style: TextStyle(fontSize: 11)),
                selected: settings.sleepAudioMode == AudioOutputMode.lowVolume,
                selectedColor: const Color(0xFF8B5CF6),
                backgroundColor: const Color(0xFF1E2238),
                labelStyle: TextStyle(
                  color: settings.sleepAudioMode == AudioOutputMode.lowVolume ? Colors.white : Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
                onSelected: (selected) {
                  if (selected) outputPolicyService.setSleepAudioMode(AudioOutputMode.lowVolume);
                },
              ),
              ChoiceChip(
                label: const Text('Voice on Demand', style: TextStyle(fontSize: 11)),
                selected: settings.sleepAudioMode == AudioOutputMode.voiceOnDemand,
                selectedColor: const Color(0xFF8B5CF6),
                backgroundColor: const Color(0xFF1E2238),
                labelStyle: TextStyle(
                  color: settings.sleepAudioMode == AudioOutputMode.voiceOnDemand ? Colors.white : Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
                onSelected: (selected) {
                  if (selected) outputPolicyService.setSleepAudioMode(AudioOutputMode.voiceOnDemand);
                },
              ),
            ],
          ),

          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Quiet Notifications', style: TextStyle(color: Colors.white70, fontSize: 12)),
              Switch(
                value: settings.quietNotifications,
                activeColor: const Color(0xFF00CCFF),
                onChanged: (val) => outputPolicyService.setQuietNotifications(val),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Allow Priority Alarms', style: TextStyle(color: Colors.white70, fontSize: 12)),
              Switch(
                value: settings.allowPriorityAlarms,
                activeColor: const Color(0xFF00CCFF),
                onChanged: (val) => outputPolicyService.setAllowPriorityAlarms(val),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    final borderColor = active ? const Color(0xFF00CCFF) : Colors.white24;
    final bgColor = active
        ? const Color(0xFF00CCFF).withOpacity(0.2)
        : const Color(0xFF1A1A1A);
    final iconColor = active ? const Color(0xFF00CCFF) : Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 30),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppButton({
    required IconData icon,
    required String label,
    required Color color,
    required String uri,
  }) {
    return InkWell(
      onTap: () async {
        final parsed = Uri.parse(uri);
        try {
          await launchUrl(parsed, mode: LaunchMode.externalApplication);
        } catch (_) {
          _showError('Could not open $label — is it installed?');
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.6), width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
