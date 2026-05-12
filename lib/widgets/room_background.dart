import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../brain/config.dart';

// ── Room time state ───────────────────────────────────────────
enum RoomTimeState { day, night }

class RoomSystem {

  // Detect day/night from device time + timezone
  static RoomTimeState getTimeState() {
    final hour = DateTime.now().hour;
    // Night: 6PM (18) to 6AM (6)
    if (hour >= 18 || hour < 6) return RoomTimeState.night;
    return RoomTimeState.day;
  }

  // Get correct background asset
  static String getBackground(String room) {
    final timeState = getTimeState();

    switch (room) {
      case "office":
        // Office doesn't change with time
        return "assets/rooms/room_office.jpg";

      case "home":
        // Home changes day/night
        return timeState == RoomTimeState.night
            ? "assets/rooms/room_home_night.jpg"
            : "assets/rooms/room_home_day.jpg";

      // Adaptive rooms
      case "park":       return "assets/rooms/room_park.jpg";
      case "tajmahal":   return "assets/rooms/room_tajmahal.jpg";
      case "restaurant": return "assets/rooms/room_restaurant.jpg";
      case "cinema":     return "assets/rooms/room_cinema.jpg";
      case "shopping":   return "assets/rooms/room_shopping.jpg";
      case "beach":      return "assets/rooms/room_beach.jpg";
      case "space":      return "assets/rooms/room_space.jpg";

      default: return "assets/rooms/room_home_day.jpg";
    }
  }

  // Get overlay opacity based on room + time
  static double getOverlayOpacity(String room) {
    final timeState = getTimeState();
    if (room == "cinema") return 0.65;
    if (room == "space")  return 0.50;
    if (timeState == RoomTimeState.night) return 0.55;
    return 0.40;
  }

  // Get accent color per room
  static Color getAccentColor(String room) {
    final timeState = getTimeState();
    switch (room) {
      case "office":     return const Color(0xFF00B4FF);
      case "home":
        return timeState == RoomTimeState.night
            ? const Color(0xFF7C4DFF)  // purple night
            : const Color(0xFF7EC8E3); // soft blue day
      case "park":       return const Color(0xFF4CAF50);
      case "restaurant": return const Color(0xFFFF7043);
      case "cinema":     return const Color(0xFF9C27B0);
      case "beach":      return const Color(0xFF29B6F6);
      case "space":      return const Color(0xFF7C4DFF);
      case "tajmahal":   return const Color(0xFFFFB300);
      case "shopping":   return const Color(0xFF00BCD4);
      default:           return const Color(0xFF00B4FF);
    }
  }

  // Get Vyshu outfit for adaptive rooms
  static String getAdaptiveOutfit(String room) {
    switch (room) {
      case "park":
      case "beach":      return "assets/vyshu/adaptive/outfit_outdoor.png";
      case "restaurant": return "assets/vyshu/adaptive/outfit_elegant.png";
      case "cinema":     return "assets/vyshu/adaptive/outfit_smart.png";
      case "shopping":   return "assets/vyshu/adaptive/outfit_trendy.png";
      case "tajmahal":   return "assets/vyshu/adaptive/outfit_ethnic.png";
      case "space":      return "assets/vyshu/adaptive/outfit_futuristic.png";
      default:           return "assets/vyshu/home/outfit_1.png";
    }
  }

  // Room label for UI
  static String getRoomLabel(String room) {
    final timeState = getTimeState();
    switch (room) {
      case "office": return "OFFICE";
      case "home":
        return timeState == RoomTimeState.night
            ? "HOME • NIGHT"
            : "HOME • DAY";
      default:
        final name = room[0].toUpperCase() + room.substring(1);
        return "ADAPTIVE • $name";
    }
  }
}

// ── Virtual Room Widget ───────────────────────────────────────
class VirtualRoom extends StatefulWidget {
  final String room;
  final Widget child;

  const VirtualRoom({
    super.key,
    required this.room,
    required this.child,
  });

  @override
  State<VirtualRoom> createState() => _VirtualRoomState();
}

class _VirtualRoomState extends State<VirtualRoom>
    with TickerProviderStateMixin {

  late AnimationController _ambientController;
  late AnimationController _particleController;
  final List<_Particle>    _particles = [];
  RoomTimeState _timeState = RoomTimeState.day;

  @override
  void initState() {
    super.initState();
    _timeState = RoomSystem.getTimeState();

    _ambientController = AnimationController(
      vsync:    this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _particleController = AnimationController(
      vsync:    this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _generateParticles();
  }

  @override
  void dispose() {
    _ambientController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _generateParticles() {
    final rand = Random();
    for (int i = 0; i < 10; i++) {
      _particles.add(_Particle(
        x:     rand.nextDouble(),
        y:     rand.nextDouble(),
        size:  rand.nextDouble() * 3 + 1,
        delay: rand.nextDouble(),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg      = RoomSystem.getBackground(widget.room);
    final overlay = RoomSystem.getOverlayOpacity(widget.room);
    final accent  = RoomSystem.getAccentColor(widget.room);

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── 1. Room background ──────────────────────────────
        Image.asset(
          bg,
          fit:   BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => _buildFallback(accent),
        ).animate().fadeIn(duration: 800.ms),

        // ── 2. Dark overlay ─────────────────────────────────
        AnimatedBuilder(
          animation: _ambientController,
          builder: (_, __) => Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end:   Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(
                    overlay - 0.03 * _ambientController.value),
                  Colors.black.withOpacity(
                    overlay + 0.06 * _ambientController.value),
                ],
              ),
            ),
          ),
        ),

        // ── 3. Night stars (home night + space) ─────────────
        if (_timeState == RoomTimeState.night ||
            widget.room == "space")
          AnimatedBuilder(
            animation: _particleController,
            builder:   (_, __) => CustomPaint(
              painter: _StarPainter(
                progress: _particleController.value,
                opacity:  widget.room == "space" ? 0.8 : 0.3,
              ),
            ),
          ),

        // ── 4. Office scan lines ─────────────────────────────
        if (widget.room == "office")
          AnimatedBuilder(
            animation: _ambientController,
            builder:   (_, __) => CustomPaint(
              painter: _ScanLinePainter(
                progress: _ambientController.value,
                color:    accent,
              ),
            ),
          ),

        // ── 5. Floating particles ────────────────────────────
        ..._buildParticles(accent),

        // ── 6. Bottom glow (ground reflection) ──────────────
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: AnimatedBuilder(
            animation: _ambientController,
            builder: (ctx, __) => Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end:   Alignment.topCenter,
                  colors: [
                    accent.withOpacity(
                      0.06 + 0.04 * _ambientController.value),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── 7. Content ───────────────────────────────────────
        widget.child,
      ],
    );
  }

  Widget _buildFallback(Color accent) {
    final isNight = _timeState == RoomTimeState.night;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin:  Alignment.topCenter,
          end:    Alignment.bottomCenter,
          colors: isNight
              ? [const Color(0xFF000814), const Color(0xFF001428)]
              : [const Color(0xFF000C1A), const Color(0xFF001E3C)],
        ),
      ),
    );
  }

  List<Widget> _buildParticles(Color accent) {
    return _particles.map((p) {
      return AnimatedBuilder(
        animation: _particleController,
        builder: (ctx, __) {
          final progress = (_particleController.value + p.delay) % 1.0;
          final yOffset  = -progress * 0.4;
          final opacity  = sin(progress * pi).clamp(0.0, 0.5);
          return Positioned(
            left: p.x * MediaQuery.of(ctx).size.width,
            top:  (p.y + yOffset) * MediaQuery.of(ctx).size.height,
            child: Container(
              width:  p.size,
              height: p.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withOpacity(opacity * 0.4),
                boxShadow: [BoxShadow(
                  color:      accent.withOpacity(opacity * 0.3),
                  blurRadius: p.size * 3,
                )],
              ),
            ),
          );
        },
      );
    }).toList();
  }
}

// ── Particle model ─────────────────────────────────────────────
class _Particle {
  final double x, y, size, delay;
  const _Particle({
    required this.x, required this.y,
    required this.size, required this.delay,
  });
}

// ── Star painter (night home + space) ─────────────────────────
class _StarPainter extends CustomPainter {
  final double progress;
  final double opacity;
  _StarPainter({required this.progress, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final rand  = Random(42);
    final paint = Paint();
    for (int i = 0; i < 80; i++) {
      final x       = rand.nextDouble() * size.width;
      final y       = rand.nextDouble() * size.height * 0.6;
      final r       = rand.nextDouble() * 1.5 + 0.5;
      final twinkle = sin((progress * 2 * pi) + i).abs();
      paint.color = Colors.white.withOpacity(
          opacity * (0.3 + 0.5 * twinkle));
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(_StarPainter old) =>
      old.progress != progress;
}

// ── Office scan line painter ───────────────────────────────────
class _ScanLinePainter extends CustomPainter {
  final double progress;
  final Color  color;
  _ScanLinePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color      = color.withOpacity(0.03)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(
          Offset(0, y), Offset(size.width, y), paint);
    }
    final hPaint = Paint()
      ..color      = color.withOpacity(0.07)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(0, progress * size.height),
      Offset(size.width, progress * size.height),
      hPaint,
    );
  }

  @override
  bool shouldRepaint(_ScanLinePainter old) =>
      old.progress != progress;
}
