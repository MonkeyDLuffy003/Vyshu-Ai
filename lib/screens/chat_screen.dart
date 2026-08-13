import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../services/brain_service.dart';
import '../services/vyshu_accessibility_bridge.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final BrainService _brain = BrainService();

  // FIX: each message now carries an optional 'turnId' so edit/delete can
  // find and remove the matching entry in BrainService's saved history —
  // previously local bubbles and saved AI memory could drift apart.
  // Also carries 'type' ('text' | 'image' | 'video' | 'sticker') + 'path'
  // for the new media-attachment support.
  final List<Map<String, String>> _messages = [];
  bool _isTyping = false;
  int _warningCount = 0;

  // Selection mode (FIX: was completely missing before)
  bool _selectionMode = false;
  final Set<int> _selectedIndices = {};

  final List<String> _badWords = [
    "sex","porn","fuck","nude","xxx","penis","vagina","dick",
    "cock","bitch","shit","asshole","bastard","whore","slut",
    "cunt","motherfucker","nigga","puku","sulla","lanjakodaka",
    "munda","gudda","dengudu","pichodi","lanjodi","modda","pooku",
    "nayana","randi","bokka","bhenchod","madarchod","chutiya",
    "lund","gandu","bhosdike","harami","kutte","suar","haramzade",
    "maa ki aankh","teri maa"
  ];

  String _currentMode = 'HOME';

  late AnimationController _collapseController;
  late Animation<double> _avatarSize;

  bool get _isCollapsed => _messages.length > 1;

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _speechAvailable = false;
  bool _isListening = false;
  bool _voiceOutputOn = true;

  // FIX: matches ANY [TOOL: ...] tag, not just STICKER — this is the tag
  // that was leaking into the visible chat bubble and being read aloud.
  static final RegExp _anyToolTag = RegExp(r'\[TOOL:[^\]]*\]');

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

  @override
  void dispose() {
    _collapseController.dispose();
    _input.dispose();
    _scroll.dispose();
    _speech.stop();
    _tts.stop();
    super.dispose();
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

  /// Strips ALL tool tags (not just STICKER) before speaking, so Vyshu
  /// never reads "tool open whatsapp" out loud.
  Future<void> _speak(String text) async {
    if (!_voiceOutputOn) return;
    final clean = text.replaceAll(_anyToolTag, '').replaceAll(RegExp(r'[*_~`]'), '').trim();
    if (clean.isEmpty) return;
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

  void _addMessage(String role, String text, {String turnId = '', String type = 'text', String path = ''}) {
    setState(() {
      _messages.add({'role': role, 'text': text, 'turnId': turnId, 'type': type, 'path': path});
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
    if (role == 'vyshu' && type == 'text') {
      _speak(text);
      _handleToolCall(text);
    }
  }

  Future<void> _handleToolCall(String text) async {
    if (text.contains('[TOOL: OPEN_YOUTUBE]')) {
      await launchUrl(Uri.parse('https://www.youtube.com'), mode: LaunchMode.externalApplication);
    } else if (text.contains('[TOOL: OPEN_SPOTIFY]')) {
      await launchUrl(Uri.parse('spotify:'), mode: LaunchMode.externalApplication);
    } else if (text.contains('[TOOL: OPEN_WHATSAPP]')) {
      await launchUrl(Uri.parse('whatsapp:'), mode: LaunchMode.externalApplication);
    } else if (text.contains('[TOOL: OPEN_DISCORD]')) {
      await launchUrl(Uri.parse('discord:'), mode: LaunchMode.externalApplication);

      // ---- NEW tool tags below (none of these existed before) ----
    } else if (text.contains('[TOOL: OPEN_APP:')) {
      final match = RegExp(r'\[TOOL: OPEN_APP:(.+?)\]').firstMatch(text);
      if (match != null) {
        final appName = match.group(1)?.trim() ?? '';
        final ok = await VyshuAccessibilityBridge.openApp(appName);
        if (!ok) _showSnack('Could not find or open "$appName"');
      }
    } else if (text.contains('[TOOL: SEND_WHATSAPP:')) {
      final match = RegExp(r'\[TOOL: SEND_WHATSAPP:(.+?)\|(.+?)\]').firstMatch(text);
      if (match != null) {
        final contact = match.group(1)?.trim() ?? '';
        final message = match.group(2)?.trim() ?? '';
        final ok = await VyshuAccessibilityBridge.sendWhatsAppMessage(contact, message);
        if (!ok) _showSnack('Could not find contact "$contact"');
      }
    } else if (text.contains('[TOOL: CALL_CONTACT:')) {
      final match = RegExp(r'\[TOOL: CALL_CONTACT:(.+?)\]').firstMatch(text);
      if (match != null) {
        final contact = match.group(1)?.trim() ?? '';
        final ok = await VyshuAccessibilityBridge.callContact(contact);
        if (!ok) _showSnack('Could not find contact "$contact"');
      }
    } else if (text.contains('[TOOL: SET_ALARM:')) {
      final match = RegExp(r'\[TOOL: SET_ALARM:(\d{1,2}):(\d{2})\]').firstMatch(text);
      if (match != null) {
        final hour = int.tryParse(match.group(1) ?? '0') ?? 0;
        final minute = int.tryParse(match.group(2) ?? '0') ?? 0;
        final ok = await VyshuAccessibilityBridge.setAlarm(hour, minute);
        if (!ok) _showSnack('Could not set the alarm');
      }

      // ---- Existing tags ----
    } else if (text.contains('[TOOL: TOGGLE_WIFI]')) {
      await VyshuAccessibilityBridge.toggleWifi();
    } else if (text.contains('[TOOL: TOGGLE_BLUETOOTH]')) {
      await VyshuAccessibilityBridge.toggleBluetooth();
    } else if (text.contains('[TOOL: TOGGLE_HOTSPOT]')) {
      await VyshuAccessibilityBridge.toggleHotspot();
    } else if (text.contains('[TOOL: TORCH_ON]')) {
      await VyshuAccessibilityBridge.setTorch(true);
    } else if (text.contains('[TOOL: TORCH_OFF]')) {
      await VyshuAccessibilityBridge.setTorch(false);
    } else if (text.contains('[TOOL: SET_BRIGHTNESS:')) {
      final match = RegExp(r'\[TOOL: SET_BRIGHTNESS:(\d+)\]').firstMatch(text);
      if (match != null) {
        final val = int.tryParse(match.group(1) ?? '128') ?? 128;
        await VyshuAccessibilityBridge.setBrightness(val);
      }
    } else if (text.contains('[TOOL: SET_VOLUME:')) {
      final match = RegExp(r'\[TOOL: SET_VOLUME:(\d+)\]').firstMatch(text);
      if (match != null) {
        final val = int.tryParse(match.group(1) ?? '7') ?? 7;
        await VyshuAccessibilityBridge.setVolume(3, val); // 3 = STREAM_MUSIC
      }
    } else if (text.contains('[TOOL: SEARCH:')) {
      final match = RegExp(r'\[TOOL: SEARCH:(.+)\]').firstMatch(text);
      if (match != null) {
        final query = match.group(1) ?? '';
        final url = 'https://www.google.com/search?q=${Uri.encodeComponent(query)}';
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } else if (text.contains('[TOOL: SAVE_TASK:')) {
      final match = RegExp(r'\[TOOL: SAVE_TASK:(.+)\]').firstMatch(text);
      if (match != null) {
        final task = match.group(1) ?? '';
        await _brain.saveTask(task);
        _showSnack('Task saved: $task');
      }
    } else if (text.contains('[TOOL: CLEAR_TASKS]')) {
      await _brain.clearTasks();
      _showSnack('All tasks cleared');
    }
    // STICKER tag needs no action here — handled at render time in _buildMessage.
  }

  bool _containsBadWords(String text) {
    final t = text.toLowerCase();
    for (final word in _badWords) {
      if (t.contains(word)) return true;
    }
    return false;
  }

  String _getWarningMessage(int count) {
    final stages = {
      1: "Ayyo Teja! Easy bro!\nThat word is NOT allowed! Vyshu watching\nWarning 1/7 — Be nice!",
      2: "Teja bro SERIOUSLY?!\nVyshu picked up the slipper *WHACK*\nWarning 2/7 — Last easy one!",
      3: "Okay Teja...\nVyshu LOADING the gun *click click*\nWarning 3/7 — Getting serious!",
      4: "Teja BRO. STOP.\nTWO guns out now\nWarning 4/7 — Very serious!",
      5: "Teja! 5 warnings?! DANGER ZONE!\nWarning 5/7 — Admin watching!",
      6: "Teja — ONE. MORE. TIME.\nSlipper + Gun + Admin = YOUR FATE\nWarning 6/7 — FINAL WARNING!",
      7: "Teja — THAT'S IT!\n7/7 — You played yourself!\nADMIN ACTION INCOMING",
    };
    return stages[count] ?? "Past the limit! $count/7";
  }

  String _getWarningSticker(int count) {
    final stickers = {
      1: "happy", 2: "slipper1", 3: "slipper1",
      4: "slipper2", 5: "gun1", 6: "gun1", 7: "gun2"
    };
    return stickers[count] ?? "gun2";
  }

  Future<void> _sendMessage() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;

    _input.clear();
    _addMessage('user', text);

    if (_containsBadWords(text)) {
      setState(() => _warningCount++);
      final warning = _getWarningMessage(_warningCount);
      final sticker = _getWarningSticker(_warningCount);
      _addMessage('vyshu', warning, type: 'sticker', path: sticker);
      return;
    }

    setState(() => _isTyping = true);
    final result = await _brain.respond(text);
    setState(() => _isTyping = false);

    // FIX: tag the just-sent user bubble with the same turnId as the reply,
    // so edit/delete can find and remove both sides of the exchange.
    final turnId = result['id'] ?? '';
    if (turnId.isNotEmpty && _messages.isNotEmpty) {
      _messages[_messages.length - 1]['turnId'] = turnId;
    }
    _addMessage('vyshu', result['text'] ?? '', turnId: turnId);
  }

  void _toggleMode() {
    setState(() => _currentMode = _currentMode == 'HOME' ? 'OFFICE' : 'HOME');
  }

  // ---------------------------------------------------------
  // MEDIA ATTACHMENTS (FIX: was completely missing before)
  // ---------------------------------------------------------

  Future<void> _pickAndSendImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;
    _addMessage('user', '', type: 'image', path: file.path);
  }

  Future<void> _pickAndSendVideo() async {
    final picker = ImagePicker();
    final file = await picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;
    _addMessage('user', '', type: 'video', path: file.path);
  }

  void _showAttachmentSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF181826),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image_rounded, color: Colors.white70),
              title: const Text('Photo', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam_rounded, color: Colors.white70),
              title: const Text('Video', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendVideo();
              },
            ),
            ListTile(
              leading: const Icon(Icons.emoji_emotions_outlined, color: Colors.white70),
              title: const Text('Sticker', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showStickerPicker();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showStickerPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF181826),
      builder: (context) => SafeArea(
        child: GridView.count(
          crossAxisCount: 4,
          padding: const EdgeInsets.all(16),
          shrinkWrap: true,
          children: _brain.stickers.keys.map((name) {
            return GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _addMessage('user', '', type: 'sticker', path: name);
              },
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Image.asset(
                  _brain.stickers[name]!,
                  errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: Colors.white38),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // MESSAGE ACTIONS: copy / edit / delete / share / select
  // ---------------------------------------------------------

  void _copyMessage(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnack('Message copied to clipboard');
  }

  void _shareMessage(String text) {
    Share.share(text);
  }

  /// FIX: delete now also removes the matching entry from BrainService's
  /// saved history (if the message was part of an AI exchange), and removes
  /// BOTH bubbles of the pair, not just the one you long-pressed.
  Future<void> _deleteMessage(int index) async {
    final msg = _messages[index];
    final turnId = msg['turnId'] ?? '';

    setState(() {
      if (turnId.isNotEmpty) {
        _messages.removeWhere((m) => m['turnId'] == turnId);
      } else {
        _messages.removeAt(index);
      }
    });

    if (turnId.isNotEmpty) {
      await _brain.deleteTurn(turnId);
    }
    _showSnack('Message deleted');
  }

  /// FIX: editing now actually regenerates Vyshu's reply (previously just
  /// changed the bubble text with a "// Optional: re-trigger response"
  /// comment and did nothing else), and keeps AI memory in sync.
  void _editMessage(int index) {
    final msg = _messages[index];
    if (msg['role'] != 'user') return;
    final controller = TextEditingController(text: msg['text']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF181826),
        title: const Text('Edit Message', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          maxLines: null,
          decoration: const InputDecoration(
            hintText: 'Enter new message...',
            hintStyle: TextStyle(color: Colors.white54),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              final newText = controller.text.trim();
              if (newText.isEmpty) return;
              Navigator.pop(context);
              await _resendEditedMessage(index, newText);
            },
            child: const Text('Save & resend', style: TextStyle(color: Color(0xFF1E63E0))),
          ),
        ],
      ),
    );
  }

  Future<void> _resendEditedMessage(int index, String newText) async {
    final oldTurnId = _messages[index]['turnId'] ?? '';

    setState(() {
      _messages[index]['text'] = newText;
      // Remove the old Vyshu reply that belonged to this turn — a fresh
      // one is coming.
      if (oldTurnId.isNotEmpty) {
        _messages.removeWhere((m) => m['turnId'] == oldTurnId && m['role'] == 'vyshu');
      } else if (index + 1 < _messages.length && _messages[index + 1]['role'] == 'vyshu') {
        _messages.removeAt(index + 1);
      }
    });

    if (oldTurnId.isNotEmpty) {
      await _brain.discardTurnForEdit(oldTurnId);
    }

    setState(() => _isTyping = true);
    final result = await _brain.respond(newText);
    setState(() => _isTyping = false);

    final newTurnId = result['id'] ?? '';
    setState(() {
      _messages[index]['turnId'] = newTurnId;
    });
    _addMessage('vyshu', result['text'] ?? '', turnId: newTurnId);
  }

  void _enterSelectionMode(int index) {
    setState(() {
      _selectionMode = true;
      _selectedIndices.add(index);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedIndices.clear();
    });
  }

  Future<void> _deleteSelected() async {
    final indices = _selectedIndices.toList()..sort((a, b) => b.compareTo(a));
    for (final i in indices) {
      await _deleteMessage(i);
    }
    _exitSelectionMode();
  }

  void _shareSelected() {
    final indices = _selectedIndices.toList()..sort();
    final text = indices.map((i) => _messages[i]['text'] ?? '').where((t) => t.isNotEmpty).join('\n\n');
    if (text.isNotEmpty) Share.share(text);
    _exitSelectionMode();
  }

  void _showMessageOptions(int index) {
    if (_selectionMode) {
      setState(() {
        if (_selectedIndices.contains(index)) {
          _selectedIndices.remove(index);
        } else {
          _selectedIndices.add(index);
        }
      });
      return;
    }

    final msg = _messages[index];
    final isUser = msg['role'] == 'user';
    final isMedia = (msg['type'] ?? 'text') != 'text';

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF181826),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isMedia)
              ListTile(
                leading: const Icon(Icons.copy_rounded, color: Colors.white70),
                title: const Text('Copy', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _copyMessage(msg['text'] ?? '');
                },
              ),
            if (!isMedia)
              ListTile(
                leading: const Icon(Icons.share_rounded, color: Colors.white70),
                title: const Text('Share', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _shareMessage(msg['text'] ?? '');
                },
              ),
            if (isUser && !isMedia)
              ListTile(
                leading: const Icon(Icons.edit_rounded, color: Colors.white70),
                title: const Text('Edit', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _editMessage(index);
                },
              ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline_rounded, color: Colors.white70),
              title: const Text('Select', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _enterSelectionMode(index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              title: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(context);
                _deleteMessage(index);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  Widget _buildHeader() {
    if (_selectionMode) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: const BoxDecoration(
          color: Color(0xFF0B0B16),
          border: Border(bottom: BorderSide(color: Color(0xFF1C1C30))),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: _exitSelectionMode,
              icon: const Icon(Icons.close_rounded, color: Colors.white),
            ),
            Expanded(
              child: Text(
                '${_selectedIndices.length} selected',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            IconButton(
              onPressed: _selectedIndices.isEmpty ? null : _shareSelected,
              icon: const Icon(Icons.share_rounded, color: Colors.white70),
            ),
            IconButton(
              onPressed: _selectedIndices.isEmpty ? null : _deleteSelected,
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            ),
          ],
        ),
      );
    }

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

  Widget _buildMediaContent(Map<String, String> msg) {
    final type = msg['type'] ?? 'text';
    final path = msg['path'] ?? '';

    if (type == 'sticker') {
      final assetPath = _brain.stickers[path] ?? '';
      return Image.asset(
        assetPath,
        width: 120,
        height: 120,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    }
    if (type == 'image') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(path),
          width: 200,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox(
            width: 200,
            height: 120,
            child: Center(child: Icon(Icons.broken_image, color: Colors.white38)),
          ),
        ),
      );
    }
    if (type == 'video') {
      // MVP: shows a tappable video placeholder that opens the file in the
      // device's default player. A proper inline video player (video_player
      // package) is a reasonable next upgrade but out of scope for MVP.
      return GestureDetector(
        onTap: () => launchUrl(Uri.file(path)),
        child: Container(
          width: 200,
          height: 120,
          decoration: BoxDecoration(
            color: const Color(0xFF14142A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(Icons.play_circle_fill_rounded, color: Colors.white70, size: 40),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildMessage(int index) {
    final msg = _messages[index];
    final isUser = msg['role'] == 'user';
    final rawText = msg['text'] ?? '';
    final type = msg['type'] ?? 'text';
    final isSelected = _selectedIndices.contains(index);

    // FIX: strips ANY tool tag, not just STICKER — this is what was
    // showing "[TOOL: OPEN_WHATSAPP]" directly in the chat bubble before.
    final cleanText = rawText.replaceAll(_anyToolTag, '').trim();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 14),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(index),
              onTap: _selectionMode ? () => _showMessageOptions(index) : null,
              child: Container(
                padding: type == 'text'
                    ? const EdgeInsets.symmetric(vertical: 11, horizontal: 15)
                    : const EdgeInsets.all(6),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.76,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF2A2A55)
                      : (isUser ? const Color(0xFF1E63E0) : const Color(0xFF181826)),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isUser ? 18 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 18),
                  ),
                  border: isSelected ? Border.all(color: const Color(0xFF7C3AED), width: 2) : null,
                ),
                child: type == 'text'
                    ? Text(
                        cleanText,
                        style: TextStyle(
                          color: isUser ? Colors.white : const Color(0xFFE4E4F0),
                          fontSize: 15,
                          height: 1.45,
                        ),
                      )
                    : _buildMediaContent(msg),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 14),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 18),
          decoration: BoxDecoration(
            color: const Color(0xFF181826),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const SizedBox(
            width: 30,
            child: Text('...', style: TextStyle(color: Colors.white54, fontSize: 20)),
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: const BoxDecoration(
        color: Color(0xFF0B0B16),
        border: Border(top: BorderSide(color: Color(0xFF1C1C30))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              onPressed: _showAttachmentSheet,
              icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF8FD3FF)),
            ),
            IconButton(
              onPressed: _startListening,
              icon: Icon(
                _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                color: _isListening ? const Color(0xFFE05D5D) : const Color(0xFF8FD3FF),
              ),
            ),
            Expanded(
              child: TextField(
                controller: _input,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Message Vyshu',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF14142A),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
                textInputAction: TextInputAction.send,
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send_rounded, color: Color(0xFF1E63E0)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B16),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.only(top: 8),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) return _buildTypingIndicator();
                return _buildMessage(index);
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }
}

