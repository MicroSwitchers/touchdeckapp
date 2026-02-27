import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/app_button.dart';

/// A single large circular 3D-style button with polished visuals.
class BigButton extends StatefulWidget {
  final AppButton data;
  final bool isPressed;
  final bool isSpeaking;
  final bool isScanHighlighted;
  final ScanColorDef? scanColorDef;
  final bool showLabel;
  final bool isPositioningMode;
  final VoidCallback? onTap;
  final VoidCallback? onTapDown;
  final VoidCallback? onTapUp;

  const BigButton({
    super.key,
    required this.data,
    this.isPressed = false,
    this.isSpeaking = false,
    this.isScanHighlighted = false,
    this.scanColorDef,
    this.showLabel = true,
    this.isPositioningMode = false,
    this.onTap,
    this.onTapDown,
    this.onTapUp,
  });

  @override
  State<BigButton> createState() => _BigButtonState();
}

class _BigButtonState extends State<BigButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _scaleAnim = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.elasticOut,
    );
    _fadeAnim = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeIn,
    );
    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.data.color;
    final pressed = widget.isPressed;
    final size = 240.0 * widget.data.scale;
    final depth = (10.0 * widget.data.scale).clamp(8.0, 14.0);

    // Face sits at top:0, slab peeks out below
    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: GestureDetector(
          onTapDown: (_) => widget.onTapDown?.call(),
          onTapUp: (_) => widget.onTapUp?.call(),
          onTapCancel: () => widget.onTapUp?.call(),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            curve: Curves.easeOut,
            width: size,
            height: size + (pressed ? 2.0 : depth),
            transform: Matrix4.translationValues(
                0, pressed ? depth - 2.0 : 0, 0),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // ── 3D Cylinder Body (Base) ────────────
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  bottom: 0, // Fills the entire AnimatedContainer height (size + depth)
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(size / 2),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color.lerp(c.dark, Colors.black, 0.15)!,
                          Color.lerp(c.dark, Colors.black, 0.65)!,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.50),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                          spreadRadius: -2,
                        ),
                        // Coloured ambient shadow
                        if (!pressed)
                          BoxShadow(
                            color: c.primary.withValues(alpha: 0.22),
                            blurRadius: 28,
                            offset: const Offset(0, 12),
                            spreadRadius: -4,
                          ),
                        // Speaking glow
                        if (widget.isSpeaking) ...[
                          BoxShadow(
                            color: c.glowColor,
                            blurRadius: 40,
                            spreadRadius: 6,
                          ),
                          BoxShadow(
                            color: c.primary.withValues(alpha: 0.18),
                            blurRadius: 80,
                            spreadRadius: 8,
                          ),
                        ],
                        // Scan ring
                        if (widget.isScanHighlighted &&
                            widget.scanColorDef != null) ...[
                          BoxShadow(
                            color: widget.scanColorDef!.ring,
                            blurRadius: 0,
                            spreadRadius: 6,
                          ),
                          BoxShadow(
                            color: widget.scanColorDef!.glow,
                            blurRadius: 32,
                            spreadRadius: 4,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // ── Face tile — sits at the top ─────────────────────
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: const Alignment(-0.3, -0.5),
                        radius: 1.2,
                        colors: [
                          Color.lerp(c.light, Colors.white, 0.25)!,
                          c.primary,
                          Color.lerp(c.dark, Colors.black, 0.3)!,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 1.0,
                      ),
                    ),
                  ),
                ),

                // ── Top-edge bevel — simulates light hitting the rim ─
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                        colors: [
                          Colors.white.withValues(alpha: pressed ? 0.08 : 0.35),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Bottom-edge inner shadow ────────────
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.center,
                        colors: [
                          Colors.black.withValues(alpha: pressed ? 0.45 : 0.25),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Speaking border ──────────────────────────────────
                if (widget.isSpeaking)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: c.glowColor,
                          width: 3.0,
                        ),
                      ),
                    ),
                  ),

                // ── Positioning mode overlay ─────────────────────────
                if (widget.isPositioningMode)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.32),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.open_with_rounded,
                          size: 52 * widget.data.scale.clamp(0.6, 1.4),
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ),

                // ── Label ────────────────────────────────────────────
                if (widget.showLabel && widget.data.label.isNotEmpty)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    child: SizedBox(
                      width: size,
                      height: size,
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal:
                                20.0 * widget.data.scale.clamp(0.5, 1.2),
                          ),
                          child: Text(
                            widget.data.label,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize:
                                  24.0 * widget.data.scale.clamp(0.6, 1.5),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                              height: 1.2,
                              color: c.textColor,
                              shadows: [
                                Shadow(
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                  color: (c.textColor == Colors.black
                                          ? Colors.white
                                          : Colors.black)
                                      .withValues(alpha: 0.45),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
