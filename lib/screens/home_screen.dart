import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  // ── Settings button guard ─────────────────────────────────────────────
  Timer? _settingsHoldTimer;
  double _settingsHoldProgress = 0;
  int _settingsTapCount = 0;
  Timer? _settingsTapTimer;

  // ── Move button guard ───────────────────────────────────────────────
  Timer? _moveHoldTimer;
  double _moveHoldProgress = 0;
  int _moveTapCount = 0;
  Timer? _moveTapTimer;

  // ── Gesture tracking for positioning mode ────────────────────────
  String? _draggingBtnId;
  Offset? _dragStartGlobal;
  Offset? _dragStartPos;
  double? _scaleStartValue; // initial scale when pinch begins

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _settingsHoldTimer?.cancel();
    _settingsTapTimer?.cancel();
    _moveHoldTimer?.cancel();
    _moveTapTimer?.cancel();
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (!mounted) return false;
    final state = context.read<AppState>();
    final key = event.logicalKey.keyLabel;

    // Setup access key — opens settings directly, bypasses guard
    if (state.settingsKey.isNotEmpty &&
        key == state.settingsKey &&
        !state.showSettings &&
        !state.isPositioningMode) {
      _openSettings();
      return true;
    }

    if (state.showSettings || state.isPositioningMode) return false;

    // Scan confirmation
    if (state.activationMode == ActivationMode.scan) {
      if (key == state.scanConfirmKey) {
        state.activateScanTarget();
        return true;
      }
    }
    // Direct button activation (always available)
    for (int i = 0; i < state.switchKeys.length && i < state.buttons.length; i++) {
      final binding = state.switchKeys[i];
      if (binding.isNotEmpty && key == binding) {
        state.activateButton(state.buttons[i].id);
        return true;
      }
    }
    return false;
  }

  // ── Guard hint (shown on every button press when a guard is active) ────────
  void _showGuardHint(AppState state) {
    final String? msg;
    switch (state.guardMode) {
      case GuardMode.hold:
        final secs = state.guardHoldSeconds.round();
        msg = 'Hold for ${secs}s to open settings';
      case GuardMode.taps:
        msg = 'Tap ${state.guardTapCount}× quickly to open settings';
      case GuardMode.off:
        msg = null;
    }
    if (msg == null) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            msg,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.65),
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.black.withValues(alpha: 0.55),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          margin: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      );
  }

  // ── Generic guard helpers ────────────────────────────────────────────
  void _startHold({
    required Timer? Function() getTimer,
    required void Function(Timer?) setTimer,
    required void Function(double) setProgress,
    required double holdSeconds,
    required VoidCallback onComplete,
  }) {
    final start = DateTime.now();
    final t = Timer.periodic(const Duration(milliseconds: 16), (_) {
      final pct = (DateTime.now().difference(start).inMilliseconds /
              (holdSeconds * 1000))
          .clamp(0.0, 1.0);
      setState(() => setProgress(pct));
      if (pct >= 1.0) {
        _endHold(currentTimer: getTimer(), setTimer: setTimer, setProgress: setProgress);
        onComplete();
      }
    });
    setTimer(t);
  }

  void _endHold({
    required Timer? currentTimer,
    required void Function(Timer?) setTimer,
    required void Function(double) setProgress,
  }) {
    currentTimer?.cancel();
    setTimer(null);
    setState(() => setProgress(0));
  }

  void _handleTapGuard({
    required int currentCount,
    required void Function(int) setCount,
    required Timer? tapTimer,
    required void Function(Timer?) setTapTimer,
    required int required,
    required VoidCallback onComplete,
  }) {
    setTapTimer(null);
    tapTimer?.cancel();
    final newCount = currentCount + 1;
    setState(() => setCount(newCount));
    if (newCount >= required) {
      setState(() => setCount(0));
      onComplete();
    } else {
      final t = Timer(const Duration(milliseconds: 1500), () {
        setState(() => setCount(0));
      });
      setTapTimer(t);
    }
  }

  // Returns true when the background is light enough to need dark-coloured UI.
  bool _isLight(Color c) => c.computeLuminance() > 0.4;

  // ── Settings button actions ────────────────────────────────────────────
  void _settingsHoldStart(AppState state) {
    _showGuardHint(state);
    _startHold(
      getTimer: () => _settingsHoldTimer,
      setTimer: (t) => _settingsHoldTimer = t,
      setProgress: (v) => _settingsHoldProgress = v,
      holdSeconds: state.guardHoldSeconds,
      onComplete: _openSettings,
    );
  }

  void _settingsHoldEnd() => _endHold(
        currentTimer: _settingsHoldTimer,
        setTimer: (t) => _settingsHoldTimer = t,
        setProgress: (v) => _settingsHoldProgress = v,
      );

  void _settingsTap(AppState state) {
    _showGuardHint(state);
    _handleTapGuard(
      currentCount: _settingsTapCount,
      setCount: (v) => _settingsTapCount = v,
      tapTimer: _settingsTapTimer,
      setTapTimer: (t) => _settingsTapTimer = t,
      required: state.guardTapCount,
      onComplete: _openSettings,
    );
  }

  // ── Move button actions ──────────────────────────────────────────────
  void _moveHoldStart(AppState state) {
    _showGuardHint(state);
    _startHold(
      getTimer: () => _moveHoldTimer,
      setTimer: (t) => _moveHoldTimer = t,
      setProgress: (v) => _moveHoldProgress = v,
      holdSeconds: state.guardHoldSeconds,
      onComplete: _openMoveMode,
    );
  }

  void _moveHoldEnd() => _endHold(
        currentTimer: _moveHoldTimer,
        setTimer: (t) => _moveHoldTimer = t,
        setProgress: (v) => _moveHoldProgress = v,
      );

  void _moveTap(AppState state) {
    _showGuardHint(state);
    _handleTapGuard(
      currentCount: _moveTapCount,
      setCount: (v) => _moveTapCount = v,
      tapTimer: _moveTapTimer,
      setTapTimer: (t) => _moveTapTimer = t,
      required: state.guardTapCount,
      onComplete: _openMoveMode,
    );
  }

  void _openMoveMode() {
    final state = context.read<AppState>();
    state.togglePositioning(true);
  }

  void _openSettings() {
    final state = context.read<AppState>();
    state.openSettings();
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const SettingsScreen()))
        .then((_) {
      state.closeSettings();
      state.reapplyFullscreen();
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
          Positioned.fill(
            child: IgnorePointer(child: _AppBackground(baseColor: state.backgroundColor)),
          ),

          // ── Main canvas with buttons ──────────────────────────────
          _buildCanvas(state),

          // ── Scan overlay ──────────────────────────────────────────
          if (state.activationMode == ActivationMode.scan &&
              !state.showSettings &&
              !state.isPositioningMode) ...[
            Positioned.fill(
              child: GestureDetector(
                onTap: () => state.activateScanTarget(),
                behavior: HitTestBehavior.translucent,
              ),
            ),
            // "Tap to begin" hint when waiting for first switch press
            if (state.scanPaused)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 28,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        'Tap your switch to begin scanning',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.75),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            // Stop button (bottom-right, part of scan progression)
            if (state.scanStopButton)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 20,
                right: 20,
                child: IgnorePointer(
                  child: _ScanStopButton(
                    highlighted: state.scanStopHighlighted,
                    scanColor: state.currentScanColor,
                    paused: state.scanPaused,
                  ),
                ),
              ),
            // Alt button (bottom-left, speaks phrase without stopping scan)
            if (state.scanAltButton)
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 20,
                left: 20,
                child: IgnorePointer(
                  child: _ScanAltButton(
                    highlighted: state.scanAltHighlighted,
                    activateCount: state.scanAltActivateCount,
                    scanColor: state.currentScanColor,
                    paused: state.scanPaused,
                    phrase: state.scanAltButtonPhrase,
                  ),
                ),
              ),
          ],

          // ── Output bar ────────────────────────────────────────────
          OutputBar(
            text: state.outputBarText,
            isPlaying: state.isSpeaking,
            position: state.outputBarPos,
            scale: state.outputBarScale,
          ),

          // ── Positioning overlay ───────────────────────────────────
          if (state.isPositioningMode) _buildPositioningOverlay(state, _isLight(state.backgroundColor)),

          // ── Settings gear + Move button (top-right) ───────────────────────
          if (!state.isPositioningMode)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 16,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMoveButton(state, _isLight(state.backgroundColor)),
                  const SizedBox(width: 10),
                  _buildGearButton(state, _isLight(state.backgroundColor)),
                ],
              ),
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
          children: [
            ...state.buttons.map((btn) {
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
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            color: _isLight(state.backgroundColor) ? Colors.black87 : Colors.white,
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
          }),
            // Colour-picker swatches overlaid on each button in positioning mode
          if (state.isPositioningMode)
            ...state.buttons.map((btn) {
              final left = w * btn.position.dx / 100;
              final top = h * btn.position.dy / 100;
              final btnSize = 200.0 * btn.scale;
              final swatchSize = (btnSize * 0.22).clamp(24.0, 36.0);
              return Positioned(
                left: left + btnSize * 0.28,
                top: top + btnSize * 0.28,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _showPositioningColorPicker(state, btn),
                  child: Container(
                    width: swatchSize,
                    height: swatchSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: btn.color.gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: Colors.white, width: 2.0),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.palette_outlined,
                      size: swatchSize * 0.5,
                      color: btn.color.textColor,
                    ),
                  ),
                ),
              );
            }),
          ],
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
  // GEAR BUTTON — settings access
  // ────────────────────────────────────────────────────────────────
  Widget _buildGearButton(AppState state, bool isLight) {
    return _buildGuardButton(
      state: state,
      isLight: isLight,
      icon: Icons.settings_outlined,
      holdProgress: _settingsHoldProgress,
      tapCount: _settingsTapCount,
      onHoldStart: () => _settingsHoldStart(state),
      onHoldEnd: _settingsHoldEnd,
      onTap: () => _settingsTap(state),
      onTapOff: _openSettings,
      onHint: () => _showGuardHint(state),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // MOVE BUTTON — quick access to positioning mode
  // ────────────────────────────────────────────────────────────────
  Widget _buildMoveButton(AppState state, bool isLight) {
    return _buildGuardButton(
      state: state,
      isLight: isLight,
      icon: Icons.open_with,
      holdProgress: _moveHoldProgress,
      tapCount: _moveTapCount,
      onHoldStart: () => _moveHoldStart(state),
      onHoldEnd: _moveHoldEnd,
      onTap: () => _moveTap(state),
      onTapOff: _openMoveMode,
      onHint: () => _showGuardHint(state),
    );
  }

  // Shared guard button shell used by both gear and move buttons
  Widget _buildGuardButton({
    required AppState state,
    required bool isLight,
    required IconData icon,
    required double holdProgress,
    required int tapCount,
    required VoidCallback onHoldStart,
    required VoidCallback onHoldEnd,
    required VoidCallback onTap,
    required VoidCallback onTapOff,
    required VoidCallback onHint,
  }) {
    final baseInk = isLight ? Colors.black : Colors.white;
    final bgAlpha = holdProgress > 0 ? 0.18 : 0.10;
    final borderAlpha = holdProgress > 0 ? 0.32 : 0.16;
    final isHolding = holdProgress > 0;
    final iconColor = isHolding
        ? const Color(0xFF818CF8)
        : baseInk.withValues(alpha: isLight ? 0.60 : 0.55);

    final isTapsMode = state.guardMode == GuardMode.taps;
    final isOffMode = state.guardMode == GuardMode.off;
    final remaining = isTapsMode ? state.guardTapCount - tapCount : 0;

    Widget btn = GestureDetector(
      onLongPressStart: state.guardMode == GuardMode.hold ? (_) => onHoldStart() : null,
      onLongPressEnd: state.guardMode == GuardMode.hold ? (_) => onHoldEnd() : null,
      onLongPressCancel: state.guardMode == GuardMode.hold ? onHoldEnd : null,
      onTapDown: isOffMode ? (_) => onTapOff() : null,
      onTap: isOffMode ? null : (isTapsMode ? onTap : onHint),
      child: SizedBox(
        width: 64,
        height: 64,
        child: ClipOval(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: baseInk.withValues(alpha: bgAlpha),
                border: Border.all(color: baseInk.withValues(alpha: borderAlpha)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (state.guardMode == GuardMode.hold)
                    SizedBox(
                      width: 54,
                      height: 54,
                      child: CircularProgressIndicator(
                        value: holdProgress,
                        strokeWidth: 3.0,
                        backgroundColor: baseInk.withValues(alpha: 0.08),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF818CF8)),
                      ),
                    ),
                  Icon(icon, size: 28, color: iconColor),
                  // tap counter badge
                  if (isTapsMode && tapCount > 0)
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        width: 16, height: 16,
                        decoration: const BoxDecoration(
                          color: Color(0xFF818CF8),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$remaining',
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
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
    return btn;
  }

  // ────────────────────────────────────────────────────────────────
  // POSITIONING OVERLAY
  // ────────────────────────────────────────────────────────────────
  Widget _buildPositioningOverlay(AppState state, bool isLight) {
    return Stack(
      children: [
        // Grid background
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _GridPainter(isLight: isLight)),
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
                  Icon(Icons.open_with, color: Colors.white, size: 24),
                  SizedBox(width: 14),
                  Text(
                    'Drag to Move • Pinch / Scroll to Resize',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
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
          left: 16,
          right: 16,
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              if (state.buttons.length < 4)
                _posButton(
                  icon: Icons.add_circle_outline,
                  label: 'Add Switch',
                  color: const Color(0xFF818CF8),
                  isLight: isLight,
                  onTap: () => state.addButton(),
                ),
              _posButton(
                icon: Icons.grid_3x3,
                label: 'Auto Arrange',
                color: const Color(0xFF10B981),
                isLight: isLight,
                onTap: () {
                  final size = MediaQuery.of(context).size;
                  state.arrangeGrid(size);
                },
              ),
              _posButton(
                icon: Icons.rotate_left,
                label: 'Reset',
                color: isLight ? Colors.black87 : Colors.white,
                isLight: isLight,
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
              ElevatedButton.icon(
                onPressed: () => state.togglePositioning(false),
                icon: const Icon(Icons.lock, size: 24),
                label: const Text('Lock',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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

  // ────────────────────────────────────────────────────────────────
  // POSITIONING COLOUR PICKER
  // ────────────────────────────────────────────────────────────────
  void _showPositioningColorPicker(AppState state, AppButton btn) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Switch Colour',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 8,
              shrinkWrap: true,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              physics: const NeverScrollableScrollPhysics(),
              children: kColors.map((c) {
                final active = btn.color.name == c.name;
                return GestureDetector(
                  onTap: () {
                    state.updateButton(btn.id, (b) => b.color = c);
                    Navigator.of(ctx).pop();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: c.gradient,
                      ),
                      boxShadow: active
                          ? [
                              const BoxShadow(
                                  color: Colors.white,
                                  spreadRadius: 3,
                                  blurRadius: 0),
                              BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  spreadRadius: 5,
                                  blurRadius: 0),
                            ]
                          : null,
                    ),
                    child: active
                        ? const Center(
                            child: Icon(Icons.check,
                                color: Colors.white, size: 16))
                        : null,
                  ),
                );
              }).toList(),
            ),
            if (state.buttons.length > 1) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    state.deleteButton(btn.id);
                  },
                  icon: const Icon(Icons.delete_outline, size: 20),
                  label: const Text(
                    'Delete Switch',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFF87171),
                    side: BorderSide(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _posButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isLight,
    required VoidCallback onTap,
  }) {
    final fg = isLight ? Colors.black87 : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isLight
              ? Colors.black.withValues(alpha: 0.08)
              : color.withValues(alpha: 0.12),
          border: Border.all(
              color: isLight
                  ? Colors.black.withValues(alpha: 0.25)
                  : color.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: fg),
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(
                    fontSize: 16,
                    color: fg, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

/// Atmospheric background: deep base with two refined radial glows.
class _AppBackground extends StatelessWidget {
  const _AppBackground({required this.baseColor});
  final Color baseColor;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(color: baseColor);
  }
}

/// Subtle dot grid for positioning mode.
class _GridPainter extends CustomPainter {
  const _GridPainter({this.isLight = false});
  final bool isLight;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isLight ? Colors.black : Colors.white).withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    const spacing = 40.0;
    const radius = 1.3;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => old.isLight != isLight;
}

/// Stop button shown in the bottom-right corner during scan mode.
/// Highlighted when the scan progression lands on it.
class _ScanAltButton extends StatefulWidget {
  const _ScanAltButton({
    required this.highlighted,
    required this.activateCount,
    required this.scanColor,
    required this.paused,
    required this.phrase,
  });
  final bool highlighted;
  final int activateCount;
  final ScanColorDef scanColor;
  final bool paused;
  final String phrase;

  @override
  State<_ScanAltButton> createState() => _ScanAltButtonState();
}

class _ScanAltButtonState extends State<_ScanAltButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flash;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _flash = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..addStatusListener((s) {
        if (s == AnimationStatus.completed) _flash.reverse();
      });
    _glowAnim = CurvedAnimation(parent: _flash, curve: Curves.easeOut);
  }

  @override
  void didUpdateWidget(_ScanAltButton old) {
    super.didUpdateWidget(old);
    if (widget.activateCount != old.activateCount) {
      _flash.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _flash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ringColor = widget.highlighted
        ? widget.scanColor.ring
        : Colors.white.withValues(alpha: 0.15);
    const bgColor = Colors.black;
    final fgColor = widget.highlighted
        ? widget.scanColor.ring
        : Colors.white.withValues(alpha: widget.paused ? 0.25 : 0.7);

    return AnimatedBuilder(
      animation: _glowAnim,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.record_voice_over_outlined, size: 22, color: fgColor),
          const SizedBox(width: 8),
          Text(
            widget.phrase.toUpperCase(),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: fgColor,
            ),
          ),
        ],
      ),
      builder: (context, child) {
        final t = _glowAnim.value; // driven by activation, not highlight
        return Transform.scale(
          scale: 1.0 + t * 0.09,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: t > 0
                    ? Color.lerp(ringColor, widget.scanColor.ring, t)!
                    : ringColor,
                width: widget.highlighted ? 2.5 : 1.0 + t * 2.0,
              ),
              boxShadow: t > 0
                  ? [
                      BoxShadow(
                        color: widget.scanColor.glow
                            .withValues(alpha: t * 0.9),
                        blurRadius: t * 50,
                        spreadRadius: t * 12,
                      ),
                    ]
                  : widget.highlighted
                      ? [
                          BoxShadow(
                            color: widget.scanColor.glow
                                .withValues(alpha: 0.3),
                            blurRadius: 14,
                            spreadRadius: 1,
                          ),
                        ]
                      : [],
            ),
            child: child,
          ),
        );
      },
    );
  }
}

class _ScanStopButton extends StatelessWidget {
  const _ScanStopButton({
    required this.highlighted,
    required this.scanColor,
    required this.paused,
  });
  final bool highlighted;
  final ScanColorDef scanColor;
  final bool paused;

  @override
  Widget build(BuildContext context) {
    final ringColor = highlighted ? scanColor.ring : Colors.white.withValues(alpha: 0.15);
    final glowColor = highlighted ? scanColor.glow : Colors.transparent;
    const bgColor = Colors.black;
    final fgColor = highlighted
        ? scanColor.ring
        : Colors.white.withValues(alpha: paused ? 0.25 : 0.7);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ringColor, width: highlighted ? 2.5 : 1.0),
        boxShadow: highlighted
            ? [BoxShadow(color: glowColor, blurRadius: 18, spreadRadius: 2)]
            : [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.stop_circle_outlined, size: 22, color: fgColor),
          const SizedBox(width: 8),
          Text(
            'STOP',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: fgColor,
            ),
          ),
        ],
      ),
    );
  }
}
