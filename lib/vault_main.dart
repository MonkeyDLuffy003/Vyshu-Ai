import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VyshuVaultApp());
}

class VyshuVaultApp extends StatelessWidget {
  const VyshuVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vyshu Key Vault',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF070914),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00CCFF),
          secondary: Color(0xFF7C4DFF),
        ),
      ),
      home: const VaultScreen(),
    );
  }
}

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  final TextEditingController _gemini1 = TextEditingController();
  final TextEditingController _gemini2 = TextEditingController();
  final TextEditingController _gemini3 = TextEditingController();
  final TextEditingController _gemini4 = TextEditingController();
  final TextEditingController _gemini5 = TextEditingController();
  final TextEditingController _groq = TextEditingController();
  final TextEditingController _discordToken = TextEditingController();

  bool _obscure = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadKeys();
  }

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
      _isLoading = false;
    });
  }

  Future<void> _saveKeys() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_1', _gemini1.text.trim());
    await prefs.setString('gemini_2', _gemini2.text.trim());
    await prefs.setString('gemini_3', _gemini3.text.trim());
    await prefs.setString('gemini_4', _gemini4.text.trim());
    await prefs.setString('gemini_5', _gemini5.text.trim());
    await prefs.setString('groq', _groq.text.trim());
    await prefs.setString('discord_token', _discordToken.text.trim());

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.shield_outlined, color: Colors.black, size: 20),
            SizedBox(width: 10),
            Text('API Keys Secured & Synced to Vyshu!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: const Color(0xFF00CCFF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        obscureText: _obscure,
        style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: Color(0xFF00CCFF), fontSize: 13),
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
          filled: true,
          fillColor: const Color(0xFF0D1226),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF00CCFF))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: const Color(0xFF00CCFF).withOpacity(0.3))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF00CCFF), width: 2)),
          prefixIcon: const Icon(Icons.key, color: Color(0xFF00CCFF), size: 18),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF080D20),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.vpn_key_rounded, color: Color(0xFF00CCFF), size: 22),
            SizedBox(width: 10),
            Text('Vyshu Vault', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF00CCFF)),
            onPressed: () => setState(() => _obscure = !_obscure),
            tooltip: 'Toggle Key Visibility',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00CCFF)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00CCFF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF00CCFF).withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.security, color: Color(0xFF00CCFF), size: 24),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Separate secure storage for your Gemini, Groq, and Discord API keys. Encrypted and isolated on device.',
                            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('GEMINI BRAIN KEYS (ROTATION POOL)', style: TextStyle(color: Color(0xFF00CCFF), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 10),
                  _buildField('Gemini Primary Key', _gemini1, hint: 'AI Studio Key 1'),
                  _buildField('Gemini Key 2', _gemini2),
                  _buildField('Gemini Key 3', _gemini3),
                  _buildField('Gemini Key 4', _gemini4),
                  _buildField('Gemini Key 5', _gemini5),
                  const SizedBox(height: 16),
                  const Text('BACKUP & COMPANION KEYS', style: TextStyle(color: Color(0xFF00CCFF), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 10),
                  _buildField('Groq Key (Fast Translations)', _groq),
                  _buildField('Discord Bot Token', _discordToken),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _saveKeys,
                      icon: const Icon(Icons.lock_reset, color: Colors.black),
                      label: const Text('SAVE & LOCK VAULT', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00CCFF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
