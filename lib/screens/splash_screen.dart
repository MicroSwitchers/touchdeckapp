import 'package:flutter/material.dart';
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

  void _proceed() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 450),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: GestureDetector(
        onTap: _proceed,
        behavior: HitTestBehavior.opaque,
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: SafeArea(
              child: Column(
                children: [
                  // ── Centre content ─────────────────────────────────────
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon
                        Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(36),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                                blurRadius: 48,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: CustomPaint(painter: _IconPainter()),
                        ),
                        const SizedBox(height: 28),
                        // App name
                        const Text(
                          'TapDeck',
                          style: TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.4,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Tagline
                        Text(
                          'Quick and flexible talking switch configurations',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 19,
                            color: Colors.white.withValues(alpha: 0.75),
                            letterSpacing: 0.3,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Disclaimer ─────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 18),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.info_outline,
                                  size: 15,
                                  color: Colors.amber.shade400
                                      .withValues(alpha: 0.85)),
                              const SizedBox(width: 7),
                              Text(
                                'Please note',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.amber.shade400
                                      .withValues(alpha: 0.95),
                                  fontSize: 15,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'This app is for flexible, informal, fun and recreational use. '
                            'Not to be used as a primary communication device. '
                            'You can only save one setup at a time, saved on your device\'s local memory.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white.withValues(alpha: 0.72),
                              height: 1.65,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Tap hint ───────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.only(bottom: 28),
                    child: Text(
                      'Tap anywhere to continue',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.45),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
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
