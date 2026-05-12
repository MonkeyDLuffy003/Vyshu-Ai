import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../brain/command_router.dart';
import '../brain/config.dart';
import '../brain/memory_service.dart';
import '../widgets/room_background.dart';
import '../widgets/vyshu_character.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with TickerProviderStateMixin {

  final List<ChatMessage>     _messages = [];
  final TextEditingController _input    = TextEditingController();
  final ScrollController      _scroll   = ScrollController();
  bool   _isThinking  = false;
  bool   _isTalking   = false;
  bool   _isListening = false;
  String _currentMode = "HOME";
  String _currentRoom = "home";

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _showWelcome();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentMode = prefs.getString(VyshuConfig.kCurrentMode) ?? "HOME";
      _currentRoom = _getRoom(_currentMode, prefs);
    });
    final expiredMsg = await _checkExpiry();
    if (expiredMsg.isNotEmpty) _addVyshu(expiredMsg);
  }

  String _getRoom(String mode, SharedPreferences prefs) {
    if (mode == "OFFICE")   return "office";
    if (mode == "ADAPTIVE") {
      return prefs.getString(VyshuConfig.kAdaptiveRoom) ?? "park";
    }
    return "home";
  }

  Future<String> _checkExpiry() async {
    final expired = await MemoryService.getExpiredEntries();
    if (expired.isEmpty) return "";
    final name = _currentMode == "OFFICE" ? "Teja sir" : "Teja";
    return "Hey $name! I have ${expired.length} old temp entries "
        "(${VyshuConfig.memoryExpiryDays} days+).\n"
        "Your reminders and schedules are safe 💙\n"
        "Say 'archive to gmail' to save and clear them!";
  }

  void _showWelcome() {
    final hour = DateTime.now().hour;
    String greeting = "Hey";
    if (hour >= 5  && hour < 12) greeting = "Good morning";
    if (hour >= 12 && hour < 17) greeting = "Good afternoon";
    if (hour >= 17 && hour < 22) greeting = "Good evening";
    if (hour >= 22 || hour < 5)  greeting = "Still up";

    final name = _currentMode == "OFFICE" ? "Teja sir" : "Teja";
    Future.delayed(const Duration(milliseconds: 600), () {
      _addVyshu(
        "$greeting $name! 💙\n"
        "I'm Vyshu — your companion and secretary.\n"
        "Talk to me anytime 😊",
      );
    });
  }

  void _addVyshu(String text) {
    setState(() {
      _messages.add(ChatMessage(text: text, isVyshu: true));
      _isTalking = true;
    });
    _scrollBottom();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isTalking = false);
    });
  }

  void _addUser(String text) {
    setState(() => _messages.add(
        ChatMessage(text: text, isVyshu: false)));
    _scrollBottom();
  }

  void _scrollBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve:    Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    _addUser(text);
    setState(() => _isThinking = true);

    final result = await CommandRouter.route(text);
    setState(() => _isThinking = false);

    if (result.reply.isNotEmpty) _addVyshu(result.reply);

    if (result.imageUrl != null) {
      setState(() => _messages.add(ChatMessage(
        text: "", isVyshu: true,
        imageUrl: result.imageUrl,
      )));
      _scrollBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: VirtualRoom(
        room:    _currentRoom,
        child:   SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              VyshuCharacter(
                isTalking:  _isTalking,
                isThinking: _isThinking,
                mode:       _currentMode,
                height:     180,
              ),
              Expanded(child: _buildChatList()),
              if (_isThinking) _buildThinkingBar(),
              _buildInputBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final emoji = VyshuConfig.roomEmojis[_currentRoom] ?? "💙";
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text("VYSHU AI",
              style: GoogleFonts.orbitron(
                color:      const Color(0xFF00B4FF),
                fontSize:   15,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
              )),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color:        const Color(0xFF0A1628).withOpacity(0.85),
              borderRadius: BorderRadius.circular(20),
              border: const Border.fromBorderSide(
                BorderSide(color: Color(0x5500B4FF)),
              ),
            ),
            child: Text(
              "$emoji $_currentMode",
              style: GoogleFonts.inter(
                color:      const Color(0xFF00B4FF),
                fontSize:   11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 8),
      itemCount:   _messages.length,
      itemBuilder: (_, i) => _buildBubble(_messages[i]),
    );
  }

  Widget _buildBubble(ChatMessage msg) {
    if (!msg.isVyshu) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8, left: 60),
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color:        const Color(0xFF00B4FF),
            borderRadius: const BorderRadius.only(
              topLeft:     Radius.circular(18),
              topRight:    Radius.circular(18),
              bottomLeft:  Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(msg.text,
              style: GoogleFonts.inter(
                  color: Colors.white, fontSize: 14)),
        ),
      ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.3);
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8, right: 60),
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0A1628).withOpacity(0.9),
          borderRadius: const BorderRadius.only(
            topLeft:     Radius.circular(4),
            topRight:    Radius.circular(18),
            bottomLeft:  Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
          border: const Border.fromBorderSide(
            BorderSide(color: Color(0x3300B4FF)),
          ),
        ),
        child: msg.imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  msg.imageUrl!,
                  width: 220,
                  fit:   BoxFit.cover,
                ),
              )
            : Text(msg.text,
                style: GoogleFonts.inter(
                  color:    const Color(0xFFE8F4FF),
                  fontSize: 14,
                )),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.3);
  }

  Widget _buildThinkingBar() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          "Vyshu is thinking...",
          style: GoogleFonts.inter(
            color:      const Color(0xFF7EC8E3),
            fontSize:   12,
            fontStyle:  FontStyle.italic,
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true))
          .fadeIn(duration: 600.ms),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF000000).withOpacity(0.8),
        border: const Border(
          top: BorderSide(color: Color(0x2200B4FF)),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () =>
                setState(() => _isListening = !_isListening),
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isListening
                    ? const Color(0xFF00B4FF)
                    : const Color(0xFF0A1628),
                border: Border.all(
                    color: const Color(0xFF00B4FF), width: 1),
              ),
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: Colors.white, size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller:     _input,
              style: GoogleFonts.inter(
                  color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: "Talk to Vyshu... 💙",
                hintStyle: GoogleFonts.inter(
                  color:    const Color(0xFF7EC8E3),
                  fontSize: 14,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
              ),
              onSubmitted: (_) => _send(),
              textInputAction: TextInputAction.send,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 44, height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF00B4FF),
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String  text;
  final bool    isVyshu;
  final String? imageUrl;
  const ChatMessage({
    required this.text,
    required this.isVyshu,
    this.imageUrl,
  });
}
