import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../brain/config.dart';
import '../brain/memory_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _mode         = "HOME";
  String _adaptiveRoom = "park";
  bool   _voiceEnabled = true;

  // ── FIX: controllers live in state, not rebuilt on every frame ──
  final Map<String, TextEditingController> _controllers = {};

  final List<_KeyField> _keyFields = [
    _KeyField("Gemini Key 1",  VyshuConfig.kGeminiKey1),
    _KeyField("Gemini Key 2",  VyshuConfig.kGeminiKey2),
    _KeyField("Gemini Key 3",  VyshuConfig.kGeminiKey3),
    _KeyField("Groq API Key",  VyshuConfig.kGroqKey),
    _KeyField("Together AI",   VyshuConfig.kTogetherKey),
    _KeyField("Tavily Search", VyshuConfig.kTavilyKey),
    _KeyField("Gmail Address", VyshuConfig.kGmailAddress,
        hint: "yourname@gmail.com"),
    _KeyField("App Password",  VyshuConfig.kGmailAppPwd,
        hint: "xxxx xxxx xxxx xxxx", obscure: true),
  ];

  @override
  void initState() {
    super.initState();
    // Create controllers first, then populate from prefs
    for (final f in _keyFields) {
      _controllers[f.prefKey] = TextEditingController();
    }
    _loadSettings();
  }

  @override
  void dispose() {
    // Dispose all controllers to avoid memory leaks
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _mode         = prefs.getString(VyshuConfig.kCurrentMode)  ?? "HOME";
      _adaptiveRoom = prefs.getString(VyshuConfig.kAdaptiveRoom) ?? "park";
      _voiceEnabled = prefs.getBool(VyshuConfig.kVoiceEnabled)   ?? true;

      // Populate text controllers with stored values
      for (final f in _keyFields) {
        _controllers[f.prefKey]!.text =
            prefs.getString(f.prefKey) ?? "";
      }
    });
  }

  Future<void> _savePref(String key, dynamic val) async {
    final prefs = await SharedPreferences.getInstance();
    if (val is String) await prefs.setString(key, val);
    if (val is bool)   await prefs.setBool(key, val);
  }

  Future<void> _saveKey(String prefKey, String label) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefKey, _controllers[prefKey]!.text.trim());
    _showSnack("$label saved!");
  }

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
              _buildSection("Virtual Room and Mode",
                  Icons.meeting_room_outlined, [
                _buildModeSelector(),
                if (_mode == "ADAPTIVE") ...[
                  const SizedBox(height: 12),
                  _buildRoomSelector(),
                ],
              ]),
              const SizedBox(height: 16),
              _buildSection("Vyshu Wardrobe",
                  Icons.checkroom_outlined, [
                _buildWardrobeGrid(),
              ]),
              const SizedBox(height: 16),
              _buildSection("API Keys",
                  Icons.key_rounded, [
                ..._keyFields
                    .where((f) => f.prefKey != VyshuConfig.kGmailAddress &&
                                  f.prefKey != VyshuConfig.kGmailAppPwd)
                    .map((f) => _buildKeyField(f)),
              ]),
              const SizedBox(height: 16),
              _buildSection("Gmail Archive",
                  Icons.email_outlined, [
                ..._keyFields
                    .where((f) => f.prefKey == VyshuConfig.kGmailAddress ||
                                  f.prefKey == VyshuConfig.kGmailAppPwd)
                    .map((f) => _buildKeyField(f)),
                const SizedBox(height: 8),
                _buildArchiveButton(),
              ]),
              const SizedBox(height: 16),
              _buildSection("Voice",
                  Icons.volume_up_outlined, [
                _buildToggleRow(
                    "Voice Output", _voiceEnabled, (v) {
                  setState(() => _voiceEnabled = v);
                  _savePref(VyshuConfig.kVoiceEnabled, v);
                }),
              ]),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(children: [
      const Icon(Icons.settings_rounded,
          color: Color(0xFF00B4FF), size: 22),
      const SizedBox(width: 10),
      Text("SETTINGS",
          style: GoogleFonts.orbitron(
            color:         const Color(0xFF00B4FF),
            fontSize:      16,
            fontWeight:    FontWeight.w700,
            letterSpacing: 2,
          )),
    ]);
  }

  Widget _buildSection(String title, IconData icon,
      List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        const Color(0xFF0F1F38),
        borderRadius: BorderRadius.circular(16),
        border: const Border.fromBorderSide(
          BorderSide(color: Color(0x3300B4FF)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: const Color(0xFF00FFFF), size: 16),
            const SizedBox(width: 8),
            Text(title,
                style: GoogleFonts.inter(
                  color:      const Color(0xFF00FFFF),
                  fontSize:   13,
                  fontWeight: FontWeight.w600,
                )),
          ]),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    final modes = ["HOME", "OFFICE", "ADAPTIVE"];
    final icons = [
      Icons.home_rounded,
      Icons.work_rounded,
      Icons.explore_rounded,
    ];
    return Row(
      children: List.generate(3, (i) {
        final selected = _mode == modes[i];
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() => _mode = modes[i]);
              _savePref(VyshuConfig.kCurrentMode, modes[i]);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin:  const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF00B4FF)
                    : const Color(0xFF0A1628),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(children: [
                Icon(icons[i], color: Colors.white, size: 20),
                const SizedBox(height: 4),
                Text(modes[i],
                    style: GoogleFonts.orbitron(
                      color:      Colors.white,
                      fontSize:   9,
                      fontWeight: FontWeight.w600,
                    )),
              ]),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildRoomSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Choose Adaptive Room:",
            style: GoogleFonts.inter(
                color: const Color(0xFF7EC8E3), fontSize: 12)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: VyshuConfig.adaptiveRooms.map((room) {
            final selected = _adaptiveRoom == room;
            final emoji    = VyshuConfig.roomEmojis[room] ?? "🌍";
            return GestureDetector(
              onTap: () {
                setState(() => _adaptiveRoom = room);
                _savePref(VyshuConfig.kAdaptiveRoom, room);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF00B4FF)
                      : const Color(0xFF0A1628),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF00B4FF)
                        : const Color(0x5500B4FF),
                  ),
                ),
                child: Text(
                  "$emoji ${room[0].toUpperCase()}${room.substring(1)}",
                  style: GoogleFonts.inter(
                      color: Colors.white, fontSize: 12),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildWardrobeGrid() {
    final outfits = [
      {"label": "Office 1", "icon": Icons.work_rounded},
      {"label": "Office 2", "icon": Icons.work_outline},
      {"label": "Office 3", "icon": Icons.business_center_outlined},
      {"label": "Home 1",   "icon": Icons.home_rounded},
      {"label": "Home 2",   "icon": Icons.favorite_outline},
      {"label": "Night",    "icon": Icons.nights_stay_rounded},
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing:  8,
      crossAxisSpacing: 8,
      childAspectRatio: 0.85,
      children: outfits.map((o) => Container(
        decoration: BoxDecoration(
          color:        const Color(0xFF0A1628),
          borderRadius: BorderRadius.circular(12),
          border: const Border.fromBorderSide(
            BorderSide(color: Color(0x3300B4FF)),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(o["icon"] as IconData,
                color: const Color(0xFF00B4FF), size: 28),
            const SizedBox(height: 6),
            Text(o["label"] as String,
                style: GoogleFonts.inter(
                  color:    const Color(0xFF7EC8E3),
                  fontSize: 10,
                )),
          ],
        ),
      )).toList(),
    );
  }

  // ── FIX: uses persistent controller from state map ──
  Widget _buildKeyField(_KeyField field) {
    final controller = _controllers[field.prefKey]!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(field.label,
              style: GoogleFonts.inter(
                color:    const Color(0xFF7EC8E3),
                fontSize: 11,
              )),
          const SizedBox(height: 4),
          Row(children: [
            Expanded(
              child: TextField(
                controller:  controller,
                obscureText: field.obscure,
                style: GoogleFonts.inter(
                    color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText:  field.hint,
                  hintStyle: GoogleFonts.inter(
                    color:    const Color(0xFF3A5A7A),
                    fontSize: 12,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _saveKey(field.prefKey, field.label),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color:        const Color(0xFF00B4FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 16),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildArchiveButton() {
    return GestureDetector(
      onTap: () async {
        _showSnack("Archiving to Gmail...");
        final result = await MemoryService.archiveToGmail();
        _showSnack(result);
      },
      child: Container(
        width:   double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color:        const Color(0xFF002A4A),
          borderRadius: BorderRadius.circular(10),
          border: const Border.fromBorderSide(
            BorderSide(color: Color(0xFF00B4FF)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.archive_outlined,
                color: Color(0xFF00B4FF), size: 18),
            const SizedBox(width: 8),
            Text("Archive Expired Memory to Gmail",
                style: GoogleFonts.inter(
                  color:      const Color(0xFF00B4FF),
                  fontSize:   13,
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow(String label, bool value,
      ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                color: Colors.white, fontSize: 13)),
        Switch(
          value:              value,
          onChanged:          onChanged,
          activeColor:        const Color(0xFF00B4FF),
          inactiveTrackColor: const Color(0xFF1A2A3A),
        ),
      ],
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:         Text(msg,
          style: GoogleFonts.inter(fontSize: 13)),
      backgroundColor: const Color(0xFF0A1628),
      duration:  const Duration(seconds: 2),
    ));
  }
}

// ── Helper data class ──
class _KeyField {
  final String label;
  final String prefKey;
  final String hint;
  final bool   obscure;

  const _KeyField(this.label, this.prefKey,
      {this.hint = "Enter key...", this.obscure = false});
}
