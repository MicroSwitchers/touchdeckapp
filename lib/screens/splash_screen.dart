import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final AnimationController _slideCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _slideCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slide = Tween(begin: const Offset(0, 0.05), end: Offset.zero).animate(
        CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        _fadeCtrl.forward();
        _slideCtrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  void _goHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 450),
      ),
    );
  }

  Future<void> _selectSlot(AppState state, int slot) async {
    if (slot != state.currentSlot) {
      await state.switchToSlot(slot);
    }
    if (mounted) _goHome();
  }

  Widget _buildStartCard(AppState state, int slot) {
    final isLast = state.currentSlot == slot;
    final name = state.slotNames[slot];
    final enabled = state.isInitialized;

    return GestureDetector(
      onTap: enabled ? () => _selectSlot(state, slot) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: BoxDecoration(
          color: isLast
              ? const Color(0xFF312E81).withValues(alpha: 0.55)
              : Colors.white.withValues(alpha: enabled ? 0.06 : 0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isLast
                ? const Color(0xFF818CF8)
                : Colors.white.withValues(alpha: 0.15),
            width: isLast ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Slot number badge
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isLast
                    ? const Color(0xFF4F46E5)
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '${slot + 1}',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: isLast
                        ? Colors.white
                        : Colors.white.withValues(
                            alpha: enabled ? 0.45 : 0.2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight:
                      isLast ? FontWeight.w700 : FontWeight.w400,
                  color: enabled
                      ? (isLast
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.7))
                      : Colors.white.withValues(alpha: 0.25),
                ),
              ),
            ),
            if (isLast && enabled)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFF4F46E5).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'LAST USED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFA5B4FC),
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            const SizedBox(width: 10),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.white.withValues(
                  alpha: enabled ? (isLast ? 0.5 : 0.25) : 0.1),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: SafeArea(
            child: Consumer<AppState>(
              builder: (context, state, _) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                      // ── Logo + title ──────────────────────────────
                      const SizedBox(height: 40),
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                              blurRadius: 40,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: CustomPaint(painter: _IconPainter()),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'TapDeck',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.4,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Quick and flexible talking switch configurations',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          color: Colors.white.withValues(alpha: 0.75),
                          letterSpacing: 0.3,
                          height: 1.45,
                        ),
                      ),

                      // ── Slot picker ───────────────────────────────
                      const SizedBox(height: 32),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'CHOOSE A PROFILE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.4),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      for (int i = 0; i < 3; i++) _buildStartCard(state, i),

                      // ── Disclaimer ────────────────────────────────
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline,
                                size: 15,
                                color: Colors.amber.shade400
                                    .withValues(alpha: 0.8)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'For informal and recreational use only. '
                                'Not a primary communication device. '
                                'All data is saved locally on your device.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.55),
                                  height: 1.55,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'by Niall Brown · Early Childhood Vision Consultant',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.35),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 28),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ── Icon painter — matches the SVG (512×512 coordinate space) ────────────────

class _IconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 512.0;

    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF09090B),
    );

    final bubblePaint = Paint()..color = const Color(0xFF6366F1);

    // Rim highlight (rect2-9): x=157 y=108 w=232 h=210 rx=116 — lighter tint
    final rimPaint = Paint()..color = const Color(0xFF9292F4);
    canvas.drawRRect(
      RRect.fromLTRBR(
        157 * s, 108 * s, 389 * s, 318 * s,
        Radius.circular(116 * s),
      ),
      rimPaint,
    );

    // Main bubble (rect2): x=140 y=110 w=232 h=210 rx=116
    canvas.drawRRect(
      RRect.fromLTRBR(
        140 * s, 110 * s, 372 * s, 320 * s,
        Radius.circular(116 * s),
      ),
      bubblePaint,
    );

    // Bubble tail: translated points (180,288) (156,362) (250,288)
    final tailPath = Path()
      ..moveTo(180 * s, 288 * s)
      ..lineTo(156 * s, 362 * s)
      ..lineTo(250 * s, 288 * s)
      ..close();
    canvas.drawPath(tailPath, bubblePaint);

    // Sound-wave bars
    final barR = Radius.circular(15 * s);

    // Left bar — x=184 y=174 w=30 h=89, 85% opacity
    canvas.drawRRect(
      RRect.fromLTRBR(
          184 * s, 174 * s, 214 * s, 263 * s, barR),
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
    // Centre bar — x=241 y=152 w=30 h=131, 100% opacity
    canvas.drawRRect(
      RRect.fromLTRBR(
          241 * s, 152 * s, 271 * s, 283 * s, barR),
      Paint()..color = Colors.white,
    );
    // Right bar — x=298 y=174 w=30 h=89, 85% opacity
    canvas.drawRRect(
      RRect.fromLTRBR(
          298 * s, 174 * s, 328 * s, 263 * s, barR),
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
