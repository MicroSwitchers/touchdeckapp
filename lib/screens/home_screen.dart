import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../models/app_button.dart';
import '../services/app_state.dart';
import '../widgets/big_button.dart';
import '../widgets/output_bar.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ── Settings hold-to-open ────────────────────────────────────────
  Timer? _holdTimer;
  double _holdProgress = 0;
  static const _holdDuration = Duration(seconds: 3);

  // ── Gesture tracking for positioning mode ────────────────────────
  String? _draggingBtnId;
  Offset? _dragStartGlobal;
  Offset? _dragStartPos;
  double? _scaleStartValue; // initial scale when pinch begins

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  void _startHold() {
    final start = DateTime.now();
    _holdTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      final elapsed = DateTime.now().difference(start).inMilliseconds;
      final pct = (elapsed / _holdDuration.inMilliseconds).clamp(0.0, 1.0);
      setState(() => _holdProgress = pct);
      if (pct >= 1.0) {
        _endHold();
        _openSettings();
      }
    });
  }

  void _endHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
    setState(() => _holdProgress = 0);
  }

  void _openSettings() {
    final state = context.read<AppState>();
    state.openSettings();
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const SettingsScreen()))
        .then((_) {
      state.closeSettings();
      // Restart scan if needed
      if (state.activationMode == ActivationMode.scan) {
        state.startScan();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      body: Stack(
        children: [
          // ── Atmospheric background ───────────────────────────────
          const Positioned.fill(
            child: IgnorePointer(child: _AppBackground()),
          ),

          // ── Main canvas with buttons ──────────────────────────────
          _buildCanvas(state),

          // ── Scan overlay ──────────────────────────────────────────
          if (state.activationMode == ActivationMode.scan &&
              !state.showSettings &&
              !state.isPositioningMode)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => state.activateScanTarget(),
                behavior: HitTestBehavior.translucent,
              ),
            ),

          // ── Output bar ────────────────────────────────────────────
          OutputBar(
            text: state.outputBarText,
            position: state.outputBarPos,
            scale: state.outputBarScale,
          ),

          // ── Positioning overlay ───────────────────────────────────
          if (state.isPositioningMode) _buildPositioningOverlay(state),

          // ── Settings gear (top-right) ─────────────────────────────
          if (!state.isPositioningMode)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 16,
              child: _buildGearButton(),
            ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // CANVAS — renders all buttons at their percentage positions
  // ────────────────────────────────────────────────────────────────
  Widget _buildCanvas(AppState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return Stack(
          children: state.buttons.map((btn) {
            final left = w * btn.position.dx / 100;
            final top = h * btn.position.dy / 100;
            final btnSize = 200.0 * btn.scale;

            final isPressed = state.activeButtonId == btn.id;
            final isSpeakingThis =
                state.isSpeaking && state.playingButtonId == btn.id;
            final isScanHL = state.activationMode == ActivationMode.scan &&
                state.buttons.indexOf(btn) == state.scanIdx;

            Widget button = BigButton(
              data: btn,
              isPressed: isPressed,
              isSpeaking: isSpeakingThis,
              isScanHighlighted: isScanHL,
              scanColorDef: isScanHL ? state.currentScanColor : null,
              showLabel: state.labelPos == LabelPosition.on,
              isPositioningMode: state.isPositioningMode,
              onTapDown: () => _handleTapDown(state, btn),
              onTapUp: () => _handleTapUp(state, btn),
              onTap: () => _handleTap(state, btn),
            );

            // "Under" label
            Widget child;
            if (state.labelPos == LabelPosition.under &&
                btn.label.isNotEmpty) {
              child = Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  button,
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.10),
                              Colors.white.withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18)),
                        ),
                        child: Text(
                          btn.label.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            } else {
              child = button;
            }

            // Positioning mode: wrap with drag + pinch + scroll support
            if (state.isPositioningMode) {
              child = Listener(
                // Mouse scroll to resize
                onPointerSignal: (event) {
                  if (event is PointerScrollEvent) {
                    final delta = event.scrollDelta.dy;
                    final scaleChange = delta > 0 ? -0.05 : 0.05;
                    state.updateButton(btn.id, (b) {
                      b.scale = (b.scale + scaleChange).clamp(0.3, 2.5);
                    });
                  }
                },
                child: GestureDetector(
                  // Scale gesture handles both single-finger drag AND pinch-to-zoom
                  onScaleStart: (d) {
                    _draggingBtnId = btn.id;
                    _dragStartGlobal = d.focalPoint;
                    _dragStartPos = btn.position;
                    _scaleStartValue = btn.scale;
                  },
                  onScaleUpdate: (d) {
                    if (_draggingBtnId != btn.id) return;
                    // Handle drag (translation)
                    final dx = d.focalPoint.dx - _dragStartGlobal!.dx;
                    final dy = d.focalPoint.dy - _dragStartGlobal!.dy;
                    state.updateButton(btn.id, (b) {
                      b.position = Offset(
                        (_dragStartPos!.dx + dx / w * 100).clamp(0, 100),
                        (_dragStartPos!.dy + dy / h * 100).clamp(0, 100),
                      );
                      // Handle pinch-to-zoom (scale changes beyond 1.0)
                      if ((d.scale - 1.0).abs() > 0.01) {
                        b.scale = (_scaleStartValue! * d.scale).clamp(0.3, 2.5);
                      }
                    });
                  },
                  onScaleEnd: (_) {
                    _draggingBtnId = null;
                    state.saveState();
                  },
                  child: child,
                ),
              );
            }

            return Positioned(
              left: left - btnSize / 2,
              top: top - btnSize / 2 - (state.labelPos == LabelPosition.under && btn.label.isNotEmpty ? 20 : 0),
              child: child,
            );
          }).toList(),
        );
      },
    );
  }

  // ────────────────────────────────────────────────────────────────
  // TOUCH HANDLERS — Press / Release mode logic
  // ────────────────────────────────────────────────────────────────
  void _handleTapDown(AppState state, AppButton btn) {
    if (state.isPositioningMode || state.showSettings) return;
    if (state.activationMode == ActivationMode.scan) return;
    if (state.buttons.length == 1 && state.touchTargetScreen) return;

    state.activeButtonId = btn.id;
    state.notify();

    if (state.activationMode == ActivationMode.press) {
      state.activateButton(btn.id, autoClearVisual: false);
    }
  }

  void _handleTapUp(AppState state, AppButton btn) {
    if (state.activeButtonId == btn.id) {
      state.activeButtonId = null;
      state.notify();
    }
  }

  void _handleTap(AppState state, AppButton btn) {
    if (state.isPositioningMode || state.showSettings) return;
    if (state.activationMode == ActivationMode.scan) return;

    // In press mode, activation already happened on tapDown
    if (state.activationMode == ActivationMode.press) return;

    // Release mode: activate on tap (finger lift)
    state.activateButton(btn.id);
  }

  // ────────────────────────────────────────────────────────────────
  // GEAR BUTTON — hold 3 seconds to open settings
  // ────────────────────────────────────────────────────────────────
  Widget _buildGearButton() {
    return GestureDetector(
      onLongPressStart: (_) => _startHold(),
      onLongPressEnd: (_) => _endHold(),
      onLongPressCancel: () => _endHold(),
      onTap: () {}, // block accidental tap
      child: SizedBox(
        width: 56,
        height: 56,
        child: ClipOval(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(
                        alpha: _holdProgress > 0 ? 0.16 : 0.09),
                    Colors.white.withValues(
                        alpha: _holdProgress > 0 ? 0.07 : 0.03),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(
                      alpha: _holdProgress > 0 ? 0.30 : 0.14),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Progress ring
                  SizedBox(
                    width: 46,
                    height: 46,
                    child: CircularProgressIndicator(
                      value: _holdProgress,
                      strokeWidth: 2.5,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF818CF8)),
                    ),
                  ),
                  Icon(
                    Icons.settings_outlined,
                    size: 22,
                    color: _holdProgress > 0
                        ? const Color(0xFFA5B4FC)
                        : Colors.white.withValues(alpha: 0.50),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // POSITIONING OVERLAY
  // ────────────────────────────────────────────────────────────────
  Widget _buildPositioningOverlay(AppState state) {
    return Stack(
      children: [
        // Grid background
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _GridPainter()),
          ),
        ),

        // Top banner
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.45),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.open_with, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Text(
                    'Drag to Move • Pinch / Scroll to Resize',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Bottom controls
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 24,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _posButton(
                icon: Icons.grid_3x3,
                label: 'Auto Arrange',
                color: const Color(0xFF10B981),
                onTap: () {
                  final size = MediaQuery.of(context).size;
                  state.arrangeGrid(size);
                },
              ),
              const SizedBox(width: 16),
              _posButton(
                icon: Icons.rotate_left,
                label: 'Reset',
                color: Colors.white,
                onTap: () {
                  for (int i = 0; i < state.buttons.length; i++) {
                    state.buttons[i].position =
                        Offset(50, 50 + i * 10.0);
                    state.buttons[i].scale = 1.0;
                  }
                  state.saveState();
                  state.notify();
                },
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => state.togglePositioning(false),
                icon: const Icon(Icons.lock, size: 20),
                label: const Text('Lock Positions',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _posButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: Colors.white),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

/// Atmospheric background: deep base with two refined radial glows.
class _AppBackground extends StatelessWidget {
  const _AppBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Deep base
        const ColoredBox(color: Color(0xFF07070E)),
        // Central indigo lift — keeps the canvas from feeling flat
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.3),
              radius: 1.15,
              colors: [Color(0x256366F1), Color(0x006366F1)],
              stops: [0.0, 1.0],
            ),
          ),
        ),
        // Violet warmth — bottom-left corner
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-1.1, 1.05),
              radius: 0.85,
              colors: [Color(0x177C3AED), Color(0x007C3AED)],
            ),
          ),
        ),
        // Edge vignette
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.2,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.42),
              ],
              stops: const [0.5, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

/// Subtle dot grid for positioning mode.
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    const spacing = 36.0;
    const radius = 1.2;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
