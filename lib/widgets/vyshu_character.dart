import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../brain/config.dart';
import 'room_background.dart';

class VyshuOutfit {
  final String   label;
  final String   assetPath;
  final IconData icon;
  const VyshuOutfit({
    required this.label,
    required this.assetPath,
    required this.icon,
  });
}

class VyshuWardrobe {

  // 7 OFFICE outfits
  static const List<VyshuOutfit> officeOutfits = [
    VyshuOutfit(label:"Red Formal",
        assetPath:"assets/vyshu/office/outfit_1.png",
        icon:Icons.work_rounded),
    VyshuOutfit(label:"Burgundy",
        assetPath:"assets/vyshu/office/outfit_2.png",
        icon:Icons.work_outline),
    VyshuOutfit(label:"Grey Blazer",
        assetPath:"assets/vyshu/office/outfit_3.png",
        icon:Icons.business_center_outlined),
    VyshuOutfit(label:"Sky Blue",
        assetPath:"assets/vyshu/office/outfit_4.png",
        icon:Icons.water_drop_outlined),
    VyshuOutfit(label:"Black Casual",
        assetPath:"assets/vyshu/office/outfit_5.png",
        icon:Icons.style_outlined),
    VyshuOutfit(label:"Dark Red",
        assetPath:"assets/vyshu/office/outfit_6.png",
        icon:Icons.checkroom_outlined),
    VyshuOutfit(label:"Black Formal",
        assetPath:"assets/vyshu/office/outfit_7.png",
        icon:Icons.cases_outlined),
  ];

  // 7 HOME outfits
  static const List<VyshuOutfit> homeOutfits = [
    VyshuOutfit(label:"Pink Cat",
        assetPath:"assets/vyshu/home/outfit_1.png",
        icon:Icons.home_rounded),
    VyshuOutfit(label:"Anime Dress",
        assetPath:"assets/vyshu/home/outfit_2.png",
        icon:Icons.auto_awesome),
    VyshuOutfit(label:"Blue Tie-Dye",
        assetPath:"assets/vyshu/home/outfit_3.png",
        icon:Icons.water),
    VyshuOutfit(label:"Monkey Print",
        assetPath:"assets/vyshu/home/outfit_4.png",
        icon:Icons.pets),
    VyshuOutfit(label:"Pink Shorts",
        assetPath:"assets/vyshu/home/outfit_5.png",
        icon:Icons.wb_sunny_outlined),
    VyshuOutfit(label:"Heart Print",
        assetPath:"assets/vyshu/home/outfit_6.png",
        icon:Icons.favorite_outline),
    VyshuOutfit(label:"Anime Cat",
        assetPath:"assets/vyshu/home/outfit_7.png",
        icon:Icons.catching_pokemon),
  ];

  static List<VyshuOutfit> getOutfits(String mode) =>
      mode == "OFFICE" ? officeOutfits : homeOutfits;

  static VyshuOutfit getDefault(String mode) =>
      mode == "OFFICE" ? officeOutfits[0] : homeOutfits[0];

  // Auto outfit for adaptive rooms
  static String getAdaptiveAsset(String room) {
    switch (room) {
      case "park":
      case "beach":
        return "assets/vyshu/adaptive/outfit_outdoor.png";
      case "restaurant":
        return "assets/vyshu/adaptive/outfit_elegant.png";
      case "cinema":
        return "assets/vyshu/adaptive/outfit_smart.png";
      case "shopping":
        return "assets/vyshu/adaptive/outfit_trendy.png";
      case "tajmahal":
        return "assets/vyshu/adaptive/outfit_ethnic.png";
      case "space":
        return "assets/vyshu/adaptive/outfit_futuristic.png";
      default:
        return "assets/vyshu/home/outfit_1.png";
    }
  }
}

class VyshuCharacter extends StatefulWidget {
  final bool   isTalking;
  final bool   isThinking;
  final String mode;
  final String room;
  final double height;

  const VyshuCharacter({
    super.key,
    this.isTalking  = false,
    this.isThinking = false,
    this.mode       = "HOME",
    this.room       = "home",
    this.height     = 200,
  });

  @override
  State<VyshuCharacter> createState() => _VyshuCharacterState();
}

class _VyshuCharacterState extends State<VyshuCharacter>
    with TickerProviderStateMixin {

  late AnimationController _floatController;
  late AnimationController _glowController;
  late AnimationController _talkController;
  late Animation<double>   _floatAnim;
  late Animation<double>   _glowAnim;

  int    _outfitIndex = 0;
  String _lastMode    = "";

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(
          parent: _floatController,
          curve:  Curves.easeInOut),
    );

    _glowController = AnimationController(
      vsync:    this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowAnim = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(
          parent: _glowController,
          curve:  Curves.easeInOut),
    );

    _talkController = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 300),
    );

    _loadOutfit();
  }

  @override
  void didUpdateWidget(VyshuCharacter old) {
    super.didUpdateWidget(old);
    if (widget.isTalking && !old.isTalking) {
      _talkController.repeat(reverse: true);
    } else if (!widget.isTalking && old.isTalking) {
      _talkController.stop();
      _talkController.reset();
    }
    if (widget.mode != _lastMode) {
      _loadOutfit();
      _lastMode = widget.mode;
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    _glowController.dispose();
    _talkController.dispose();
    super.dispose();
  }

  Future<void> _loadOutfit() async {
    final prefs = await SharedPreferences.getInstance();
    final key   = "vyshu_outfit_${widget.mode.toLowerCase()}";
    setState(() {
      _outfitIndex = prefs.getInt(key) ?? 0;
      _lastMode    = widget.mode;
    });
  }

  Future<void> _setOutfit(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final key   = "vyshu_outfit_${widget.mode.toLowerCase()}";
    await prefs.setInt(key, index);
    setState(() => _outfitIndex = index);
  }

  String _getCurrentAsset() {
    // Adaptive room → auto outfit
    if (widget.mode == "ADAPTIVE") {
      return VyshuWardrobe.getAdaptiveAsset(widget.room);
    }
    // Home night → softer outfit
    if (widget.mode == "HOME" &&
        RoomSystem.getTimeState() == RoomTimeState.night) {
      return "assets/vyshu/home/outfit_night.png";
    }
    final outfits = VyshuWardrobe.getOutfits(widget.mode);
    if (_outfitIndex < outfits.length) {
      return outfits[_outfitIndex].assetPath;
    }
    return VyshuWardrobe.getDefault(widget.mode).assetPath;
  }

  Color _getGlowColor() {
    final accent = RoomSystem.getAccentColor(widget.room);
    if (widget.mode == "OFFICE") return const Color(0xFF00B4FF);
    if (RoomSystem.getTimeState() == RoomTimeState.night) {
      return const Color(0xFF7C4DFF);
    }
    return accent;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([
            _floatController,
            _glowController,
            _talkController,
          ]),
          builder: (_, __) {
            final glow  = _glowAnim.value;
            final float = _floatAnim.value;
            final color = _getGlowColor();

            return Transform.translate(
              offset: Offset(0, float),
              child: Stack(
                alignment:   Alignment.center,
                clipBehavior: Clip.none,
                children: [

                  // Glow circle
                  Container(
                    width:  widget.height * 0.55,
                    height: widget.height * 0.55,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:       color.withOpacity(
                              glow * 0.25),
                          blurRadius:  60 + 30 * glow,
                          spreadRadius: 8,
                        ),
                        BoxShadow(
                          color:       color.withOpacity(
                              glow * 0.08),
                          blurRadius:  100,
                          spreadRadius: 25,
                        ),
                      ],
                    ),
                  ),

                  // Vyshu image
                  SizedBox(
                    height: widget.height,
                    child: Image.asset(
                      _getCurrentAsset(),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          _buildFallback(color),
                    ),
                  ),

                  // Thinking dots
                  if (widget.isThinking)
                    Positioned(
                      top: -22,
                      child: _buildThinkingDots(color),
                    ),

                  // Talking wave
                  if (widget.isTalking)
                    Positioned(
                      bottom: -10,
                      child: _buildTalkingWave(color),
                    ),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 10),

        // Wardrobe bar (office + home only)
        if (widget.mode != "ADAPTIVE")
          _buildWardrobeBar(),

        // Room + time label
        const SizedBox(height: 4),
        Text(
          RoomSystem.getRoomLabel(widget.room),
          style: GoogleFonts.orbitron(
            color:      const Color(0xFF00B4FF).withOpacity(0.7),
            fontSize:   9,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildFallback(Color color) {
    return Container(
      width:  widget.height * 0.5,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.height * 0.3),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end:   Alignment.bottomCenter,
          colors: [
            color.withOpacity(0.8),
            color.withOpacity(0.2),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person,
              color: Colors.white,
              size:  widget.height * 0.3),
          const SizedBox(height: 8),
          Text("Vyshu AI",
              style: GoogleFonts.orbitron(
                  color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildThinkingDots(Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) =>
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 6, height: 6,
          decoration: BoxDecoration(
              shape: BoxShape.circle, color: color),
        )
        .animate(onPlay: (c) => c.repeat())
        .scaleY(
          delay:    Duration(milliseconds: i * 150),
          duration: const Duration(milliseconds: 400),
          begin: 0.3, end: 1.0,
          curve: Curves.easeInOut,
        )
        .then().scaleY(end: 0.3),
      ),
    );
  }

  Widget _buildTalkingWave(Color color) {
    return AnimatedBuilder(
      animation: _talkController,
      builder: (_, __) => SizedBox(
        height: 18, width: 70,
        child: CustomPaint(
          painter: _WavePainter(
            progress: _talkController.value,
            color:    color,
          ),
        ),
      ),
    );
  }

  Widget _buildWardrobeBar() {
    final outfits = VyshuWardrobe.getOutfits(widget.mode);
    return SizedBox(
      height: 34,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        shrinkWrap:      true,
        itemCount:       outfits.length,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemBuilder: (_, i) {
          final selected = i == _outfitIndex;
          return GestureDetector(
            onTap: () => _setOutfit(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 32, height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? const Color(0xFF00B4FF)
                    : const Color(0xFF0A1628),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF00B4FF)
                      : const Color(0x5500B4FF),
                  width: selected ? 2 : 1,
                ),
              ),
              child: Icon(
                outfits[i].icon,
                size:  15,
                color: selected
                    ? Colors.white
                    : const Color(0xFF7EC8E3),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double progress;
  final Color  color;
  _WavePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color      = color.withOpacity(0.8)
      ..strokeWidth = 2
      ..style      = PaintingStyle.stroke;
    final path = Path();
    path.moveTo(0, size.height / 2);
    for (double x = 0; x < size.width; x++) {
      final ratio = x / size.width;
      final amp   = (ratio < 0.2 || ratio > 0.8) ? 2.0 : 6.0;
      final y = size.height / 2 +
          amp * sin((ratio * 4 * 3.14159) +
              (progress * 3.14159 * 2));
      path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.progress != progress;
}
