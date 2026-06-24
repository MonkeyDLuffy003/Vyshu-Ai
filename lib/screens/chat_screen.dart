import 'package:flutter/material.dart';
import '../services/brain_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final BrainService _brain = BrainService();
  final List<Map<String, String>> _messages = [];
  bool _isTyping = false;

  // Current mode shown in the top-right pill ("HOME" / "OFFICE")
  String _currentMode = 'HOME';

  // Index of the selected icon in the mode row beneath the avatar
  int _selectedModeIcon = 0;

  final List<IconData> _modeIcons = [
    Icons.home_rounded,
    Icons.auto_awesome,
    Icons.waves_rounded,
    Icons.pets_rounded,
    Icons.wb_sunny_rounded,
    Icons.favorite_rounded,
    Icons.blur_circular_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _addMessage('vyshu', _greeting());
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    String timeGreeting;
    if (hour < 12) {
      timeGreeting = 'Good morning';
    } else if (hour < 17) {
      timeGreeting = 'Good afternoon';
    } else {
      timeGreeting = 'Good evening';
    }
    return "$timeGreeting Teja! \u{1F499}\nI'm Vyshu \u2014 your companion and secretary.\nTalk to me anytime \u{1F60A}";
  }

  void _addMessage(String role, String text) {
    setState(() {
      _messages.add({'role': role, 'text': text});
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;

    _input.clear();
    _addMessage('user', text);
    setState(() => _isTyping = true);

    final reply = await _brain.respond(text);

    setState(() => _isTyping = false);
    _addMessage('vyshu', reply);
  }

  void _toggleMode() {
    setState(() {
      _currentMode = _currentMode == 'HOME' ? 'OFFICE' : 'HOME';
    });
  }

  // ---------------------------------------------------------
  // AVATAR CAPSULE (top section, matches reference design)
  // ---------------------------------------------------------
  Widget _buildAvatarHeader() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'VYSHU AI',
              style: TextStyle(
                color: Color(0xFF00CCFF),
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            GestureDetector(
              onTap: _toggleMode,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF00CCFF).withOpacity(0.6)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _currentMode == 'HOME' ? Icons.home_rounded : Icons.work_rounded,
                      color: const Color(0xFF00CCFF),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _currentMode,
                      style: const TextStyle(
                        color: Color(0xFF00CCFF),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // The avatar capsule — uses your real Vyshu avatar image if present,
        // falls back to a person icon if the asset is missing so it never crashes.
        Container(
          width: 170,
          height: 230,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(85),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF8B5CF6), Color(0xFF3B1F6E)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withOpacity(0.4),
                blurRadius: 30,
                spreadRadius: 4,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(85),
            child: Image.asset(
              'assets/images/vyshu_avatar.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Falls back cleanly if the asset path/name doesn't match
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person, color: Color(0xFF8B5CF6), size: 32),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Vyshu AI',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ],
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 18),

        // Mode icon row
        SizedBox(
          height: 50,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            itemCount: _modeIcons.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final isSelected = index == _selectedModeIcon;
              return GestureDetector(
                onTap: () => setState(() => _selectedModeIcon = index),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? const Color(0xFF00CCFF)
                        : const Color(0xFF111122),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF00CCFF)
                          : const Color(0xFF222244),
                    ),
                  ),
                  child: Icon(
                    _modeIcons[index],
                    color: isSelected ? Colors.black : const Color(0xFF00CCFF),
                    size: 20,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${_currentMode[0]}${_currentMode.substring(1).toLowerCase()} \u00B7 ${_selectedModeIcon == 0 ? "Night" : "Active"}',
          style: const TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 1),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMessage(Map<String, String> msg) {
    final isUser = msg['role'] == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFF00CCFF).withOpacity(0.15)
              : const Color(0xFF12122A),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: Border.all(
            color: isUser
                ? const Color(0xFF00CCFF).withOpacity(0.4)
                : const Color(0xFF222244),
          ),
        ),
        child: Text(
          msg['text'] ?? '',
          style: TextStyle(
            color: isUser ? Colors.white : const Color(0xFFAEE9FF),
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05050F),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _buildAvatarHeader(),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.only(top: 4),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_isTyping && index == _messages.length) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF12122A),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 8,
                              height: 8,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF00CCFF),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Vyshu is thinking...',
                              style: TextStyle(color: Colors.white54, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return _buildMessage(_messages[index]);
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: const BoxDecoration(
                color: Color(0xFF05050F),
                border: Border(top: BorderSide(color: Color(0xFF1A1A2E))),
              ),
              child: Row(
                children: [
                  // Mic button on the left, matching reference layout
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF00CCFF).withOpacity(0.6)),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.mic_none_rounded, color: Color(0xFF00CCFF)),
                      onPressed: () {
                        // Voice input wiring comes in a later phase
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('\u{1F399}\u{FE0F} Voice mode coming soon!')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _input,
                      style: const TextStyle(color: Colors.white),
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Talk to Vyshu... \u{1F499}',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: const Color(0xFF12122A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF00CCFF), Color(0xFF7B2FFF)],
                        ),
                      ),
                      child: const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
