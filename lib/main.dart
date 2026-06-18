import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const VyshuApp());
}

class VyshuApp extends StatelessWidget {
  const VyshuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vyshu AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00CCFF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
