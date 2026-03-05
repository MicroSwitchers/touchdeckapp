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
  final bool isScanConfirmed;
  final bool showLabel;
  final bool isPositioningMode;
  /// Responsive base pixel size (before scale). Defaults to 290.
  final double baseSize;
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
    this.isScanConfirmed = false,
    this.showLabel = true,
    this.isPositioningMode = false,
    this.baseSize = 290.0,
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
    final base = widget.baseSize;
    final f = base / 290.0; // scale factor for UI elements relative to design base
    final size = base * widget.data.scale;
    final depth = (22.0 * widget.data.scale * f).clamp(6.0, 30.0); // taller 3D slab

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
                          color: Colors.black.withValues(alpha: 0.60),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                          spreadRadius: -4,
                        ),
                        // Soft colored drop shadow — visible depth, no glare
                        if (!pressed)
                          BoxShadow(
                            color: c.primary.withValues(alpha: 0.28),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                            spreadRadius: -4,
                          ),
                        // Press / activation glow
                        if (pressed && !widget.isSpeaking) ...[
                          BoxShadow(
                            color: c.glowColor,
                            blurRadius: 28,
                            spreadRadius: 4,
                          ),
                        ],
                        // Speaking glow
                        if (widget.isSpeaking) ...[
                          BoxShadow(
                            color: c.glowColor,
                            blurRadius: 32,
                            spreadRadius: 6,
                          ),
                        ],
                        // Scan ring
                        if (widget.isScanHighlighted &&
                            widget.scanColorDef != null) ...[
                          BoxShadow(
                            color: widget.scanColorDef!.ring,
                            blurRadius: 0,
                            spreadRadius: 8,
                          ),
                          BoxShadow(
                            color: widget.scanColorDef!.glow,
                            blurRadius: 48,
                            spreadRadius: 6,
                          ),
                        ],
                        // Scan confirmed — brighter ring + glow in the highlight colour
                        if (widget.isScanConfirmed && widget.scanColorDef != null) ...[
                          BoxShadow(
                            color: widget.scanColorDef!.ring,
                            blurRadius: 0,
                            spreadRadius: 14,
                          ),
                          BoxShadow(
                            color: widget.scanColorDef!.glow.withValues(alpha: 0.75),
                            blurRadius: 48,
                            spreadRadius: 12,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // ── Face tile — matte, high-contrast, no glare ──────
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // Gentle matte gradient: slightly lighter at top, slightly
                      // darker at bottom — gives clear 3D depth without glare.
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color.lerp(c.primary, Colors.white, pressed ? 0.0 : 0.12)!,
                          c.primary,
                          Color.lerp(c.primary, Colors.black, 0.22)!,
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                      // Colored border using the button's own dark shade — no white glare
                      border: Border.all(
                        color: Color.lerp(c.dark, Colors.black, 0.25)!,
                        width: 3.0,
                      ),
                    ),
                  ),
                ),

                // ── Pressed inner shadow (depth cue when tapped) ─────
                if (pressed)
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
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.30),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.5],
                        ),
                      ),
                    ),
                  ),

                // ── Pressed / activated glow border ─────────────────
                if (pressed && !widget.isSpeaking)
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
                          width: 5.0,
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
                          width: 6.0, // thicker ring — clearly visible for low vision
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
                          size: 52 * widget.data.scale.clamp(0.6, 1.4) * f,
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
                                20.0 * widget.data.scale.clamp(0.5, 1.2) * f,
                          ),
                          child: Text(
                            widget.data.label,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize:
                                  24.0 * widget.data.scale.clamp(0.6, 1.5) * f,
                                fontWeight: FontWeight.w900, // Extra bold for punchiness
                                letterSpacing: 0.5,
                                height: 1.1,
                                color: c.textColor,
                                shadows: [
                                  // Single clear shadow for maximum readability
                                  Shadow(
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                    color: (c.textColor == Colors.black
                                            ? Colors.white
                                            : Colors.black)
                                        .withValues(alpha: 0.55),
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
