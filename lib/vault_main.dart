import 'package:flutter/material.dart';
import 'ai/llm_provider.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await providerManager.init();
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
      home: const SettingsScreen(),
    );
  }
}
