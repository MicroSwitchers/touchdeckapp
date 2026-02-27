import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Floating output bar that shows the last spoken phrase.
class OutputBar extends StatelessWidget {
  final String? text;
  final Offset position; // percentage 0-100
  final double scale;

  const OutputBar({
    super.key,
    this.text,
    this.position = const Offset(50, 92),
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    if (text == null || text!.isEmpty) return const SizedBox.shrink();

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      top: 0,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final left = constraints.maxWidth * position.dx / 100;
          final top = constraints.maxHeight * position.dy / 100;
          return Stack(
            children: [
              Positioned(
                left: left,
                top: top,
                child: FractionalTranslation(
                  translation: const Offset(-0.5, -0.5),
                  child: Transform.scale(
                    scale: scale,
                    child: AnimatedOpacity(
                      opacity: text != null ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 400),
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
                            child: Text(
                              text ?? '',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                                color: Colors.white,
                              ),
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
