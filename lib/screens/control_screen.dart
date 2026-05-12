import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:torch_light/torch_light.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:url_launcher/url_launcher.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});
  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {

  bool _wifi      = false;
  bool _torch     = false;
  bool _hotspot   = false;
  bool _bluetooth = false;
  bool _volMax    = false;
  bool _bright    = false;
  bool _discord   = false;
  bool _instagram = false;
  bool _spotify   = false;
  bool _youtube   = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin:  Alignment.topCenter,
            end:    Alignment.bottomCenter,
            colors: [Color(0xFF000C1A), Color(0xFF000000)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildSectionTitle(
                  "Mobile Accessories",
                  Icons.phone_android_rounded),
              const SizedBox(height: 12),
              _buildMobileGrid(),
              const SizedBox(height: 24),
              _buildSectionTitle(
                  "Bot Controls",
                  Icons.smart_toy_outlined),
              const SizedBox(height: 12),
              _buildBotGrid(),
              const SizedBox(height: 24),
              _buildSectionTitle(
                  "Open Apps",
                  Icons.apps_rounded),
              const SizedBox(height: 12),
              _buildAppsRow(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(children: [
      const Icon(Icons.dashboard_rounded,
          color: Color(0xFF00B4FF), size: 22),
      const SizedBox(width: 10),
      Text("CONTROL PANEL",
          style: GoogleFonts.orbitron(
            color:      const Color(0xFF00B4FF),
            fontSize:   16,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          )),
    ]);
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(children: [
      Icon(icon, color: const Color(0xFF00FFFF), size: 18),
      const SizedBox(width: 8),
      Text(title,
          style: GoogleFonts.inter(
            color:      const Color(0xFF00FFFF),
            fontSize:   13,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          )),
    ]);
  }

  Widget _buildMobileGrid() {
    return GridView.count(
      crossAxisCount:  3,
      shrinkWrap:      true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing:  10,
      crossAxisSpacing: 10,
      childAspectRatio: 0.95,
      children: [
        _toggleCard("WiFi",
            Icons.wifi_rounded,           _wifi,
            () => _toggleWifi()),
        _toggleCard("Torch",
            Icons.flashlight_on_rounded,  _torch,
            () => _toggleTorch()),
        _toggleCard("Hotspot",
            Icons.wifi_tethering_rounded, _hotspot,
            () => _toggleHotspot()),
        _toggleCard("Bluetooth",
            Icons.bluetooth_rounded,      _bluetooth,
            () => _toggleBluetooth()),
        _toggleCard("Vol Max",
            Icons.volume_up_rounded,      _volMax,
            () => _toggleVolume()),
        _toggleCard("Bright",
            Icons.brightness_high_rounded, _bright,
            () => _toggleBrightness()),
      ],
    );
  }

  Widget _buildBotGrid() {
    return GridView.count(
      crossAxisCount:  2,
      shrinkWrap:      true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing:  10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: [
        _botCard("Discord Bot",
            Icons.discord,                _discord,
            () => setState(() => _discord = !_discord)),
        _botCard("Instagram",
            Icons.camera_alt_outlined,    _instagram,
            () => setState(() => _instagram = !_instagram)),
        _botCard("Spotify Bot",
            Icons.music_note_rounded,     _spotify,
            () => setState(() => _spotify = !_spotify)),
        _botCard("YouTube Bot",
            Icons.play_circle_outline_rounded, _youtube,
            () => setState(() => _youtube = !_youtube)),
      ],
    );
  }

  Widget _buildAppsRow() {
    final apps = [
      {"label":"Spotify", "icon":Icons.music_note_rounded,
       "url":"spotify:"},
      {"label":"YouTube", "icon":Icons.play_circle_rounded,
       "url":"youtube://"},
      {"label":"Chrome",  "icon":Icons.public_rounded,
       "url":"googlechrome://"},
      {"label":"Camera",  "icon":Icons.camera_alt_rounded,
       "url":""},
    ];
    return Row(
      children: apps.map((app) => Expanded(
        child: GestureDetector(
          onTap: () => _openApp(app["url"] as String),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color:        const Color(0xFF0F1F38),
              borderRadius: BorderRadius.circular(12),
              border: const Border.fromBorderSide(
                BorderSide(color: Color(0x3300B4FF)),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(app["icon"] as IconData,
                    color: const Color(0xFF00B4FF), size: 22),
                const SizedBox(height: 4),
                Text(app["label"] as String,
                    style: GoogleFonts.inter(
                      color:    const Color(0xFF7EC8E3),
                      fontSize: 10,
                    )),
              ],
            ),
          ),
        ),
      )).toList(),
    );
  }

  Widget _toggleCard(String label, IconData icon,
      bool isOn, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: isOn
              ? const Color(0xFF002A4A)
              : const Color(0xFF0F1F38),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isOn
                ? const Color(0xFF00B4FF)
                : const Color(0x3300B4FF),
            width: isOn ? 1.5 : 1,
          ),
          boxShadow: isOn ? [
            BoxShadow(
              color:       const Color(0xFF00B4FF).withOpacity(0.2),
              blurRadius:  12,
              spreadRadius: 1,
            )
          ] : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: isOn
                    ? const Color(0xFF00B4FF)
                    : const Color(0xFF3A5A7A),
                size: 26),
            const SizedBox(height: 6),
            Text(label,
                style: GoogleFonts.inter(
                  color:      isOn
                      ? Colors.white
                      : const Color(0xFF7EC8E3),
                  fontSize:   11,
                  fontWeight: FontWeight.w500,
                )),
            const SizedBox(height: 4),
            Text(isOn ? "ON" : "OFF",
                style: GoogleFonts.orbitron(
                  color:      isOn
                      ? const Color(0xFF00B4FF)
                      : const Color(0xFF3A5A7A),
                  fontSize:   9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                )),
          ],
        ),
      ),
    );
  }

  Widget _botCard(String label, IconData icon,
      bool isOn, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isOn
              ? const Color(0xFF002A4A)
              : const Color(0xFF0F1F38),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isOn
                ? const Color(0xFF00B4FF)
                : const Color(0x3300B4FF),
            width: isOn ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Icon(icon,
              color: isOn
                  ? const Color(0xFF00B4FF)
                  : const Color(0xFF3A5A7A),
              size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: GoogleFonts.inter(
                  color:      isOn
                      ? Colors.white
                      : const Color(0xFF7EC8E3),
                  fontSize:   12,
                  fontWeight: FontWeight.w500,
                )),
          ),
          Text(isOn ? "ON" : "OFF",
              style: GoogleFonts.orbitron(
                color:      isOn
                    ? const Color(0xFF00B4FF)
                    : const Color(0xFF3A5A7A),
                fontSize:   9,
                fontWeight: FontWeight.w700,
              )),
        ]),
      ),
    );
  }

  Future<void> _toggleWifi() async {
    const intent = AndroidIntent(
        action: "android.settings.WIFI_SETTINGS");
    await intent.launch();
    setState(() => _wifi = !_wifi);
  }

  Future<void> _toggleTorch() async {
    try {
      _torch
          ? await TorchLight.disableTorch()
          : await TorchLight.enableTorch();
      setState(() => _torch = !_torch);
    } catch (e) {
      _showSnack("Torch error: $e");
    }
  }

  Future<void> _toggleHotspot() async {
    const intent = AndroidIntent(
        action: "android.settings.WIRELESS_SETTINGS");
    await intent.launch();
    setState(() => _hotspot = !_hotspot);
  }

  Future<void> _toggleBluetooth() async {
    const intent = AndroidIntent(
        action: "android.settings.BLUETOOTH_SETTINGS");
    await intent.launch();
    setState(() => _bluetooth = !_bluetooth);
  }

  Future<void> _toggleVolume() async {
    _volMax
        ? VolumeController().setVolume(0.5)
        : VolumeController().setVolume(1.0);
    setState(() => _volMax = !_volMax);
  }

  Future<void> _toggleBrightness() async {
    try {
      _bright
          ? await ScreenBrightness().setScreenBrightness(0.5)
          : await ScreenBrightness().setScreenBrightness(1.0);
      setState(() => _bright = !_bright);
    } catch (e) {
      _showSnack("Brightness error: $e");
    }
  }

  Future<void> _openApp(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:         Text(msg, style: GoogleFonts.inter()),
      backgroundColor: const Color(0xFF0A1628),
      duration:  const Duration(seconds: 2),
    ));
  }
}
