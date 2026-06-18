import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    ChatScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF0A0A0A),
        indicatorColor: const Color(0xFF00CCFF).withOpacity(0.2),
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline, color: Colors.white54),
            selectedIcon: Icon(Icons.chat_bubble, color: Color(0xFF00CCFF)),
            label: 'Vyshu',
          ),
          NavigationDestination(
            icon: Icon(Icons.lock_outline, color: Colors.white54),
            selectedIcon: Icon(Icons.lock, color: Color(0xFF00CCFF)),
            label: 'Vault',
          ),
        ],
      ),
    );
  }
}
