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
    super.dispose();
  }

  Widget _buildKeyField(String
