import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Floating output bar that shows the last spoken phrase, or an animated
/// waveform when audio is playing but there is no text caption.
class OutputBar extends StatefulWidget {
  final String? text;
  final bool isPlaying;
  final Offset position; // percentage 0-100
  final double scale;

  const OutputBar({
    super.key,
    this.text,
    this.isPlaying = false,
    this.position = const Offset(50, 92),
    this.scale = 1.0,
  });

  @override
  State<OutputBar> createState() => _OutputBarState();
}

class _OutputBarState extends State<OutputBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wave;

  bool get _hasText => widget.text != null && widget.text!.isNotEmpty;
  bool get _showWave => widget.isPlaying && !_hasText;
  bool get _visible => _hasText || _showWave;

  @override
  void initState() {
    super.initState();
    _wave = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _syncAnimation();
  }

  @override
  void didUpdateWidget(OutputBar old) {
    super.didUpdateWidget(old);
    _syncAnimation();
  }

  void _syncAnimation() {
    if (_showWave) {
      if (!_wave.isAnimating) _wave.repeat();
    } else {
      if (_wave.isAnimating) _wave.stop();
    }
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      top: 0,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final left = constraints.maxWidth * widget.position.dx / 100;
          final top = constraints.maxHeight * widget.position.dy / 100;
          return Stack(
            children: [
              Positioned(
                left: left,
                top: top,
                child: FractionalTranslation(
                  translation: const Offset(-0.5, -0.5),
                  child: Transform.scale(
                    scale: widget.scale,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth:
                                MediaQuery.of(context).size.width * 0.88,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 36,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.14),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.50),
                                blurRadius: 40,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            transitionBuilder: (child, anim) =>
                                FadeTransition(opacity: anim, child: child),
                            child: _hasText
                                ? Text(
                                    widget.text!,
                                    key: ValueKey(widget.text),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.2,
                                      color: Colors.white,
                                    ),
                                  )
                                : _WaveformBars(
                                    key: const ValueKey('__wave__'),
                                    controller: _wave,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated equaliser bars — shown in place of text for audio-only buttons
// ─────────────────────────────────────────────────────────────────────────────

class _WaveformBars extends AnimatedWidget {
  const _WaveformBars({
    super.key,
    required AnimationController controller,
  }) : super(listenable: controller);

  // Phase offsets (radians) and speed multipliers per bar — chosen so the bars
  // never all peak or dip together, giving a natural flowing look.
  static const _phases = [0.00, 1.05, 2.10, 0.52, 1.57];
  static const _speeds = [1.00, 1.30, 0.85, 1.15, 0.70];

  static const _barCount  = 5;
  static const _barWidth  = 5.0;
  static const _barGap    = 4.0;
  static const _minHeight = 5.0;
  static const _maxHeight = 28.0;

  @override
  Widget build(BuildContext context) {
    final t = (listenable as AnimationController).value; // 0..1 repeating

    return SizedBox(
      height: _maxHeight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(_barCount, (i) {
          final angle = t * 2 * math.pi * _speeds[i] + _phases[i];
          final frac  = math.sin(angle) * 0.5 + 0.5; // 0..1
          final h     = _minHeight + (_maxHeight - _minHeight) * frac;

          return Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : _barGap),
            child: Align(
              alignment: Alignment.center,
              child: Container(
                width: _barWidth,
                height: h,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}