import 'package:flutter/material.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:url_launcher/url_launcher.dart';

class VirtualRoomScreen extends StatefulWidget {
  const VirtualRoomScreen({super.key});

  @override
  State<VirtualRoomScreen> createState() => _VirtualRoomScreenState();
}

class _VirtualRoomScreenState extends State<VirtualRoomScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  String _vyshuDialogue = "Hi Teja! Welcome to your 3D Virtual Room. Your apps are organized and ready on the shelf. What would you like to open?";
  String _activeInterference = "RESONANCE ONLINE";
  bool _isInterfering = false;

  final List<Map<String, dynamic>> _quickBooks = [
    {
      'title': 'WhatsApp',
      'category': 'Social',
      'icon': Icons.chat,
      'color': Color(0xFF25D366),
      'package': 'com.whatsapp',
      'uri': 'whatsapp://',
    },
    {
      'title': 'YouTube',
      'category': 'Video',
      'icon': Icons.play_arrow,
      'color': Color(0xFFFF0000),
      'package': 'com.google.android.youtube',
      'uri': 'vnd.youtube://',
    },
    {
      'title': 'Spotify',
      'category': 'Music',
      'icon': Icons.music_note,
      'color': Color(0xFF1DB954),
      'package': 'com.spotify.music',
      'uri': 'spotify://',
    },
    {
      'title': 'Photos',
      'category': 'Memories',
      'icon': Icons.photo_library,
      'color': Color(0xFFFFB300),
      'package': 'com.google.android.apps.photos',
      'uri': null,
    },
    {
      'title': 'Instagram',
      'category': 'Social',
      'icon': Icons.camera_alt,
      'color': Color(0xFFE1306C),
      'package': 'com.instagram.android',
      'uri': 'instagram://',
    },
    {
      'title': 'Maps',
      'category': 'Explore',
      'icon': Icons.navigation,
      'color': Color(0xFF4285F4),
      'package': 'com.google.android.apps.maps',
      'uri': 'geo:0,0',
    },
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _triggerInterference(String tag) {
    setState(() {
      _isInterfering = true;
      _activeInterference = tag;
    });
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        setState(() => _isInterfering = false);
      }
    });
  }

  Future<void> _launchBook(Map<String, dynamic> book) async {
    final title = book['title'] as String;
    _triggerInterference('LAUNCHING: ${title.toUpperCase()}');
    setState(() {
      _vyshuDialogue = "Opening $title for you right now, Teja!";
    });

    try {
      final uriStr = book['uri'] as String?;
      if (uriStr != null) {
        final uri = Uri.parse(uriStr);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      }

      final packageName = book['package'] as String?;
      if (packageName != null) {
        final intent = AndroidIntent(
          action: 'android.intent.action.MAIN',
          package: packageName,
          category: 'android.intent.category.LAUNCHER',
        );
        await intent.launch();
      }
    } catch (e) {
      debugPrint("Error launching $title: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070914),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080D22),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF00CCFF).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF00CCFF).withOpacity(0.4)),
              ),
              child: const Icon(Icons.blur_on, color: Color(0xFF00CCFF), size: 20),
            ),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VYSHU AI 3D ROOM',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
                ),
                Text(
                  'Android Launcher & Library Shelf',
                  style: TextStyle(fontSize: 10, color: Color(0xFF00CCFF)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.5)),
            ),
            child: const Row(
              children: [
                Icon(Icons.fiber_manual_record, color: Colors.greenAccent, size: 10),
                SizedBox(width: 4),
                Text('3D LIVE', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Vyshu Speech HUD Bubble
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF080D22).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF00CCFF).withOpacity(0.35)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00CCFF).withOpacity(0.15),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Color(0xFF00CCFF), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _vyshuDialogue,
                        style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 3D Holographic Character Centerpiece
              GestureDetector(
                onTap: () {
                  _triggerInterference("RESONANCE SYNC");
                  setState(() {
                    _vyshuDialogue = "I'm right here with you in the room, Teja! Your phone is completely at your command.";
                  });
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Holographic Gyroscope Ring
                    RotationTransition(
                      turns: _animController,
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF00CCFF).withOpacity(0.25),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),

                    // Avatar Card
                    Container(
                      width: 150,
                      height: 190,
                      decoration: BoxDecoration(
                        color: const Color(0xFF090E24),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _isInterfering ? Colors.pinkAccent : const Color(0xFF00CCFF),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_isInterfering ? Colors.pinkAccent : const Color(0xFF00CCFF)).withOpacity(0.4),
                            blurRadius: 25,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Stack(
                          children: [
                            Image.asset(
                              'assets/images/vyshu_avatar.png',
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.person, color: Color(0xFF00CCFF), size: 60),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                color: Colors.black.withOpacity(0.7),
                                child: const Text(
                                  'VYSHU AI',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF00CCFF),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Interference Badge
                    if (_isInterfering)
                      Positioned(
                        top: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00CCFF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '⚡ $_activeInterference',
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Android Shelf Header (Organized App Launcher)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.apps, color: Color(0xFF00CCFF), size: 18),
                        SizedBox(width: 8),
                        Text(
                          "APPS SHELF",
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                      ],
                    ),
                    Text(
                      "Organized by Category",
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // 3D Quick-Launch Books Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _quickBooks.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.9,
                ),
                itemBuilder: (context, index) {
                  final b = _quickBooks[index];
                  final color = b['color'] as Color;
                  return InkWell(
                    onTap: () => _launchBook(b),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF090E24),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: color.withOpacity(0.4)),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: color.withOpacity(0.6)),
                            ),
                            child: Icon(b['icon'] as IconData, color: Colors.white, size: 22),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            b['title'] as String,
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            b['category'] as String,
                            style: TextStyle(color: color, fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
