import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../services/brain_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final BrainService _brain = BrainService();
  final List<Map<String, String>> _messages = [];
  bool _isTyping = false;

  String _currentMode = 'HOME';

  late AnimationController _collapseController;
  late Animation<double> _avatarSize;

  bool get _isCollapsed => _messages.length > 1;

  // ---------------------------------------------------------
  // VOICE: speech-to-text (listening) + flutter_tts (speaking)
  // ---------------------------------------------------------
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _speechAvailable = false;
  bool _isListening = false;
  bool _voiceOutputOn = true; // Vyshu speaks her replies by default

  @override
  void initState() {
    super.initState();
    _collapseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _avatarSize = CurvedAnimation(parent: _collapseController, curve: Curves.easeInOut);
    _initSpeech();
    _initTts();
    _addMessage('vyshu', _greeting());
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _isListening = false);
        }
      },
      onError: (error) {
        if (mounted) setState(() => _isListening = false);
        _showSnack('Voice input error: ${error.errorMsg}');
      },
    );
    if (mounted) setState(() {});
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-IN');
    await _tts.setSpeechRate(0.48);
    await _tts.setPitch(1.05);
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      _showSnack('Voice input not available — check microphone permission in Settings.');
      return;
    }
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    setState(() => _isListening = true);
    await _speech.listen(
      onResult: (result) {
        setState(() {
          _input.text = result.recognizedWords;
        });
        if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
          _sendMessage();
        }
      },
      listenFor: const Duration(seconds: 20),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
    );
  }

  Future<void> _speak(String text) async {
    if (!_voiceOutputOn) return;
    // Strip emojis/markdown-ish symbols so TTS doesn't try to pronounce them
    final clean = text.replaceAll(RegExp(r'[*_~`]'), '');
    await _tts.stop();
    await _tts.speak(clean);
  }

  void _toggleVoiceOutput() {
    setState(() => _voiceOutputOn = !_voiceOutputOn);
    if (!_voiceOutputOn) _tts.stop();
    _showSnack(_voiceOutputOn ? 'Voice replies on' : 'Voice replies off — text only');
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    final timeGreeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    return "$timeGreeting, Teja. I'm online and ready whenever you need me.";
  }

  void _addMessage(String role, String text) {
    setState(() {
      _messages.add({'role': role, 'text': text});
      if (_isCollapsed) {
        _collapseController.forward();
      }
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
    if (role == 'vyshu') {
      _speak(text);
    }
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
    setState(() => _currentMode = _currentMode == 'HOME' ? 'OFFICE' : 'HOME');
  }

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _avatarSize,
      builder: (context, child) {
        final t = _avatarSize.value;
        final avatarDiameter = _lerp(96, 36, t);
        final headerPadding = _lerp(20, 10, t);

        return Container(
          padding: EdgeInsets.fromLTRB(20, headerPadding, 20, headerPadding),
          decoration: const BoxDecoration(
            color: Color(0xFF0B0B16),
            border: Border(bottom: BorderSide(color: Color(0xFF1C1C30))),
          ),
          child: Row(
            children: [
              Container(
                width: avatarDiameter,
                height: avatarDiameter,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF7C3AED), Color(0xFF1E1240)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withOpacity(0.35),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/vyshu_avatar.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: avatarDiameter * 0.45,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Vyshu AI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(right: 5),
                          decoration: const BoxDecoration(
                            color: Color(0xFF22D3A8),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const Text(
                          'Online',
                          style: TextStyle(color: Color(0xFF22D3A8), fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Voice output toggle — lets Teja silence her per plan item #13
              IconButton(
                onPressed: _toggleVoiceOutput,
                icon: Icon(
                  _voiceOutputOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                  color: const Color(0xFF8FD3FF),
                  size: 20,
                ),
              ),
              GestureDetector(
                onTap: _toggleMode,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14142A),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF2A2A4A)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _currentMode == 'HOME' ? Icons.home_rounded : Icons.work_rounded,
                        color: const Color(0xFF8FD3FF),
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _currentMode,
                        style: const TextStyle(
                          color: Color(0xFF8FD3FF),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessage(Map<String, String> msg) {
    final isUser = msg['role'] == 'user';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 14),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 15),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.76,
          ),
          decoration: BoxDecoration(
            color: isUser ? const Color(0xFF1E63E0) : const Color(0xFF181826),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isUser ? 18 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 18),
            ),
          ),
          child: Text(
            msg['text'] ?? '',
            style: TextStyle(
              color: isUser ? Colors.white : const Color(0xFFE4E4F0),
              fontSize: 15,
              height: 1.45,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 14),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF181826),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TypingDot(delay: 0),
              SizedBox(width: 4),
              _TypingDot(delay: 150),
              SizedBox(width: 4),
              _TypingDot(delay: 300),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    _collapseController.dispose();
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050510),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.only(top: 10, bottom: 6),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_isTyping && index == _messages.length) {
                    return _buildTypingIndicator();
                  }
                  return _buildMessage(_messages[index]);
                },
              ),
            ),
            if (_isListening)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.graphic_eq, color: Color(0xFF1E63E0), size: 16),
                    SizedBox(width: 6),
                    Text('Listening...',
                        style: TextStyle(color: Color(0xFF1E63E0), fontSize: 12)),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              decoration: const BoxDecoration(
                color: Color(0xFF050510),
                border: Border(top: BorderSide(color: Color(0xFF1A1A2E))),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _startListening,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isListening
                            ? const Color(0xFF1E63E0)
                            : const Color(0xFF14142A),
                        border: Border.all(
                          color: _isListening
                              ? const Color(0xFF1E63E0)
                              : const Color(0xFF2A2A4A),
                        ),
                      ),
                      child: Icon(
                        _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                        color: _isListening ? Colors.white : const Color(0xFF8FD3FF),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _input,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: _isListening ? 'Listening...' : 'Message Vyshu',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: const Color(0xFF14142A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF1E63E0),
                      ),
                      child: const Icon(Icons.arrow_upward_rounded,
                          color: Colors.white, size: 20),
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

double _lerp(double a, double b, double t) {
  return a + (b - a) * t;
}

class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final opacity = (0.4 + 0.6 * (1 - (_controller.value - 0.5).abs() * 2)).clamp(0.4, 1.0);
        return Opacity(
          opacity: opacity,
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF8FD3FF),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
