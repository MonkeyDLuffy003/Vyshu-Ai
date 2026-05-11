// ================================================================
// VYSHU AI V4 — MAIN.DART
// App entry | Futuristic white-blue-black theme | Bottom nav
// ================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/chat_screen.dart';
import 'screens/control_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor:       Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const VyshuApp());
}

class VyshuApp extends StatelessWidget {
  const VyshuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:        "Vyshu AI",
      debugShowCheckedModeBanner: false,
      theme:        _buildTheme(),
      home:         const VyshuHome(),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      brightness:     Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF000000),
      primaryColor:   const Color(0xFF00B4FF),
      colorScheme:    const ColorScheme.dark(
        primary:      Color(0xFF00B4FF),
        secondary:    Color(0xFF00FFFF),
        surface:      Color(0xFF0A1628),
        background:   Color(0xFF000000),
        onPrimary:    Color(0xFFFFFFFF),
        onSurface:    Color(0xFFFFFFFF),
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor:      Colors.white,
        displayColor:   Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor:  const Color(0xFF000000),
        elevation:        0,
        centerTitle:      true,
        titleTextStyle:   GoogleFonts.orbitron(
          color:      const Color(0xFF00B4FF),
          fontSize:   18,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        ),
        iconTheme: const IconThemeData(color: Color(0xFF00B4FF)),
      ),
      cardTheme: CardTheme(
        color:        const Color(0xFF0F1F38),
        elevation:    0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x3300B4FF), width: 1),
        ),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF00B4FF)),
      inputDecorationTheme: InputDecorationTheme(
        filled:      true,
        fillColor:   const Color(0xFF0A1628),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide:   const BorderSide(color: Color(0xFF00B4FF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide:   const BorderSide(color: Color(0x5500B4FF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide:   const BorderSide(color: Color(0xFF00B4FF), width: 2),
        ),
        hintStyle: const TextStyle(color: Color(0xFF7EC8E3)),
      ),
    );
  }
}

// ── Main home with bottom navigation ─────────────────────────
class VyshuHome extends StatefulWidget {
  const VyshuHome({super.key});
  @override
  State<VyshuHome> createState() => _VyshuHomeState();
}

class _VyshuHomeState extends State<VyshuHome> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ChatScreen(),
    ControlScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index:    _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF000000),
        border: Border(
          top: BorderSide(color: Color(0x3300B4FF), width: 1),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex:     _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        backgroundColor:  const Color(0xFF000000),
        selectedItemColor:   const Color(0xFF00B4FF),
        unselectedItemColor: const Color(0xFF3A5A7A),
        selectedLabelStyle: GoogleFonts.orbitron(
            fontSize: 10, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 10),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon:       Icon(Icons.chat_bubble_outline_rounded),
            activeIcon: Icon(Icons.chat_bubble_rounded),
            label:      "Chat",
          ),
          BottomNavigationBarItem(
            icon:       Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard_rounded),
            label:      "Control",
          ),
          BottomNavigationBarItem(
            icon:       Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings_rounded),
            label:      "Settings",
          ),
        ],
      ),
    );
  }
}
