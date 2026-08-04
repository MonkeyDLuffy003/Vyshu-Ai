import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Controllers defined ONCE in State — never rebuilt
  final TextEditingController _gemini1 = TextEditingController();
  final TextEditingController _gemini2 = TextEditingController();
  final TextEditingController _gemini3 = TextEditingController();
  final TextEditingController _gemini4 = TextEditingController();
  final TextEditingController _gemini5 = TextEditingController();
  final TextEditingController _groq = TextEditingController();
  final TextEditingController _discordToken = TextEditingController();
  final TextEditingController _discordId = TextEditingController();
  final TextEditingController _gcsJson = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadKeys();
  }

  // Load saved keys on screen open
  Future<void> _loadKeys() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _gemini1.text = prefs.getString('gemini_1') ?? '';
      _gemini2.text = prefs.getString('gemini_2') ?? '';
      _gemini3.text = prefs.getString('gemini_3') ?? '';
      _gemini4.text = prefs.getString('gemini_4') ?? '';
      _gemini5.text = prefs.getString('gemini_5') ?? '';
      _groq.text = prefs.getString('groq') ?? '';
      _discordToken.text = prefs.getString('discord_token') ?? '';
      _discordId.text = prefs.getString('discord_id') ?? '';
      _gcsJson.text = prefs.getString('gcs_json') ?? '';
      _isLoading = false;
    });
  }

  // Save all keys
  Future<void> _saveKeys() async {
    setState(() => _isSaving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_1', _gemini1.text.trim());
    await prefs.setString('gemini_2', _gemini2.text.trim());
    await prefs.setString('gemini_3', _gemini3.text.trim());
    await prefs.setString('gemini_4', _gemini4.text.trim());
    await prefs.setString('gemini_5', _gemini5.text.trim());
    await prefs.setString('groq', _groq.text.trim());
    await prefs.setString('discord_token', _discordToken.text.trim());
    await prefs.setString('discord_id', _discordId.text.trim());
    await prefs.setString('gcs_json', _gcsJson.text.trim());
    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Vault Locked & Saved!'),
          backgroundColor: Color(0xFF00CCFF),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _gemini1.dispose();
    _gemini2.dispose();
    _gemini3.dispose();
    _gemini4.dispose();
    _gemini5.dispose();
    _groq.dispose();
    _discordToken.dispose();
    _discordId.dispose();
    _gcsJson.dispose();
    super.dispose();
  }

  Widget _buildKeyField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        obscureText: true,
        enableSuggestions: false,
        autocorrect: false,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          filled: true,
          fillColor: const Color(0xFF111111),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF00CCFF)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF333333)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF00CCFF), width: 2),
          ),
          suffixIcon: IconButton(
            icon: const Icon(Icons.visibility, color: Colors.white38),
            onPressed: () {
              // Toggle visibility handled by obscureText
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          '🔐 Vyshu Vault',
          style: TextStyle(color: Color(0xFF00CCFF), fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00CCFF)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gemini Keys (Brain)',
                    style: TextStyle(
                      color: Color(0xFF00CCFF),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildKeyField('Gemini Key 1 (Primary)', _gemini1),
                  _buildKeyField('Gemini Key 2', _gemini2),
                  _buildKeyField('Gemini Key 3', _gemini3),
                  _buildKeyField('Gemini Key 4', _gemini4),
                  _buildKeyField('Gemini Key 5', _gemini5),
                  const SizedBox(height: 8),
                  const Text(
                    'Groq Key (Translation)',
                    style: TextStyle(
                      color: Color(0xFF00CCFF),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildKeyField('Groq API Key', _groq),
                  const SizedBox(height: 8),
                  const Text(
                    'Discord',
                    style: TextStyle(
                      color: Color(0xFF00CCFF),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildKeyField('Discord Token', _discordToken),
                  _buildKeyField('Discord Admin ID', _discordId),
                  const SizedBox(height: 8),
                  const Text(
                    'Google Cloud Storage',
                    style: TextStyle(
                      color: Color(0xFF00CCFF),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildKeyField('GCS Service Account JSON', _gcsJson),
                  const Text(
                    'Note: Paste the JSON content here or use the file picker (V2).',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveKeys,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.lock, color: Colors.white),
                      label: Text(
                        _isSaving ? 'Saving...' : 'Lock & Save Vault',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00CCFF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
