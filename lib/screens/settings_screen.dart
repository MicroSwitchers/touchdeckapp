import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../models/app_button.dart';
import '../services/app_state.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _tab = 'buttons'; // 'buttons' | 'system'

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      body: SafeArea(
        child: Column(
          children: [
            // ── Accent strip ────────────────────────────────────────
            Container(
              height: 3,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFFA855F7), Color(0xFFEC4899)],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
            ),

            // ── Header ──────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D12),
                border: Border(
                  bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF6366F1).withValues(alpha: 0.25),
                                const Color(0xFFA855F7).withValues(alpha: 0.15),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Icon(Icons.settings, color: Color(0xFFA5B4FC), size: 20),
                        ),
                        const SizedBox(width: 12),
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Colors.white, Color(0xFFA1A1AA)],
                          ).createShader(bounds),
                          child: const Text(
                            'Settings',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(Icons.close,
                              color: Colors.white.withValues(alpha: 0.4)),
                        ),
                      ],
                    ),
                  ),
                  // Tabs
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _tabButton('Buttons', 'buttons'),
                        _tabButton('System', 'system'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Content ─────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _tab == 'buttons'
                    ? _buildButtonsTab(state)
                    : _buildSystemTab(state),
              ),
            ),

            // ── Done button ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D12),
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 8,
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(String label, String tab) {
    final active = _tab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = tab),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? const Color(0xFF818CF8) : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              color: active ? Colors.white : Colors.white.withValues(alpha: 0.35),
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  BUTTONS TAB
  // ══════════════════════════════════════════════════════════════════
  Widget _buildButtonsTab(AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Button selector row
        _buildButtonSelector(state),
        const SizedBox(height: 24),
        // Edit form for selected button
        if (state.editingBtnId != null) _buildButtonEditor(state),
      ],
    );
  }

  Widget _buildButtonSelector(AppState state) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...state.buttons.asMap().entries.map((e) {
            final i = e.key;
            final b = e.value;
            final active = state.editingBtnId == b.id;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  state.editingBtnId = b.id;
                  state.notify();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFF6366F1).withValues(alpha: 0.18)
                        : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: active
                          ? const Color(0xFF818CF8)
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: b.color.gradient),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        b.label.isNotEmpty ? b.label : 'Button ${i + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: active
                              ? const Color(0xFFC7D2FE)
                              : Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (state.buttons.length < 4)
            GestureDetector(
              onTap: () => state.addButton(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF818CF8).withValues(alpha: 0.4),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add,
                        size: 16,
                        color: const Color(0xFF818CF8).withValues(alpha: 0.7)),
                    const SizedBox(width: 4),
                    Text(
                      'Add',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF818CF8).withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildButtonEditor(AppState state) {
    final btn = state.buttons.firstWhere(
      (b) => b.id == state.editingBtnId,
      orElse: () => state.buttons.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label & Touch Target
        _sectionLabel('Button Label', Icons.text_fields, const Color(0xFFA855F7)),
        const SizedBox(height: 8),
        _textField(
          value: btn.label,
          placeholder: 'e.g. Yes, No, Help',
          onChanged: (v) => state.updateButton(btn.id, (b) => b.label = v),
        ),
        const SizedBox(height: 16),

        // Touch target
        _sectionLabel('Touch Target', Icons.touch_app, const Color(0xFF6366F1)),
        const SizedBox(height: 4),
        Text(
          'Tap the entire screen, or just the button.',
          style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.35)),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _toggleButton(
              label: 'Screen',
              active: state.touchTargetScreen,
              enabled: state.buttons.length == 1,
              onTap: () {
                if (state.buttons.length > 1) return;
                state.touchTargetScreen = true;
                state.saveState();
                state.notify();
              },
            ),
            const SizedBox(width: 8),
            _toggleButton(
              label: 'Button',
              active: !state.touchTargetScreen,
              onTap: () {
                state.touchTargetScreen = false;
                state.saveState();
                state.notify();
              },
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Color picker
        _sectionLabel('Colour', Icons.palette, const Color(0xFFEC4899)),
        const SizedBox(height: 8),
        _buildColorPicker(state, btn),
        const SizedBox(height: 20),

        // Phrases & Audio
        _sectionLabel('Phrases & Audio', Icons.chat_bubble_outline, const Color(0xFF818CF8)),
        const SizedBox(height: 4),
        Text(
          'Add up to 3 phrases to cycle through on each tap. Recording audio overrides the robot voice.',
          style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.35)),
        ),
        const SizedBox(height: 12),
        ...List.generate(3, (idx) => _phraseRow(state, btn, idx)),
        const SizedBox(height: 20),

        // Size slider
        _buildSizeSlider(state, btn),
        const SizedBox(height: 16),

        // Delete button
        if (state.buttons.length > 1)
          _dangerButton(
            label: 'Delete',
            onTap: () => _showConfirm(
              context,
              'Delete button?',
              'This will remove this button and its recordings.',
              () => state.deleteButton(btn.id),
            ),
          ),
        const SizedBox(height: 24),

        // Reset to default
        Container(
          padding: const EdgeInsets.only(top: 24),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showConfirm(
                context,
                'Reset to default?',
                'This will remove all buttons and create a single default button.',
                () => state.resetToDefault(),
              ),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('RESET TO DEFAULT',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFF87171),
                side: BorderSide(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                    style: BorderStyle.solid),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorPicker(AppState state, AppButton btn) {
    return GridView.count(
      crossAxisCount: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: kColors.map((c) {
        final active = btn.color.name == c.name;
        return GestureDetector(
          onTap: () => state.updateButton(btn.id, (b) => b.color = c),
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
                      BoxShadow(color: Colors.white, spreadRadius: 3, blurRadius: 0),
                      BoxShadow(
                          color: Colors.white.withValues(alpha: 0.3),
                          spreadRadius: 5,
                          blurRadius: 0),
                      BoxShadow(
                          color: c.glowColor.withValues(alpha: 0.4),
                          spreadRadius: 4,
                          blurRadius: 16),
                    ]
                  : null,
            ),
            child: active
                ? const Center(
                    child: Icon(Icons.check, color: Colors.white, size: 16))
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _phraseRow(AppState state, AppButton btn, int idx) {
    final hasAudio = idx < btn.hasAudio.length && btn.hasAudio[idx];
    final isThisRecording = state.isRecording &&
        state.currentRecordingBtnId == btn.id &&
        state.currentRecordingIdx == idx;
    final isOtherRecording = state.isRecording && !isThisRecording;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Index badge
          Container(
            width: 24,
            alignment: Alignment.center,
            child: Text(
              '${idx + 1}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF818CF8).withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Text input
          Expanded(
            child: _textField(
              value: btn.phrases[idx],
              placeholder: 'Phrase',
              onChanged: (v) =>
                  state.updateButton(btn.id, (b) => b.phrases[idx] = v),
            ),
          ),
          const SizedBox(width: 8),
          // Record / Play / Delete
          if (hasAudio) ...[
            _iconButton(
              icon: Icons.play_arrow,
              color: const Color(0xFF6EE7B7),
              bgColor: const Color(0xFF10B981).withValues(alpha: 0.15),
              borderColor: const Color(0xFF34D399).withValues(alpha: 0.4),
              onTap: () => state.playPreview(btn.id, idx),
            ),
            const SizedBox(width: 4),
            _iconButton(
              icon: Icons.delete_outline,
              color: const Color(0xFFF87171),
              bgColor: const Color(0xFFEF4444).withValues(alpha: 0.1),
              borderColor: const Color(0xFFEF4444).withValues(alpha: 0.25),
              onTap: () => state.deleteRecording(btn.id, idx),
            ),
          ] else if (state.canRecord)
            _iconButton(
              icon: isThisRecording ? Icons.stop : Icons.mic,
              color: isThisRecording 
                  ? Colors.white 
                  : isOtherRecording 
                      ? Colors.white.withValues(alpha: 0.1) 
                      : Colors.white.withValues(alpha: 0.4),
              bgColor: isThisRecording
                  ? const Color(0xFFDC2626)
                  : Colors.white.withValues(alpha: 0.05),
              borderColor: Colors.white.withValues(alpha: 0.1),
              onTap: () {
                if (!isOtherRecording) {
                  state.toggleRecording(btn.id, idx);
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSizeSlider(AppState state, AppButton btn) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionLabel('Size', Icons.aspect_ratio, const Color(0xFF22D3EE)),
              Text(
                '${btn.scale.toStringAsFixed(1)}×',
                style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: Color(0xFF67E8F9)),
              ),
            ],
          ),
          Slider(
            value: btn.scale,
            min: 0.5,
            max: 2.0,
            divisions: 15,
            activeColor: const Color(0xFF6366F1),
            onChanged: (v) =>
                state.updateButton(btn.id, (b) => b.scale = v),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  SYSTEM TAB
  // ══════════════════════════════════════════════════════════════════
  Widget _buildSystemTab(AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Activation Mode
        _sectionLabel('Activation Mode', Icons.mouse, const Color(0xFF22D3EE)),
        const SizedBox(height: 4),
        Text(
          '"Release" helps users who drag their finger.${state.buttons.length > 1 ? ' "Scan" highlights buttons one by one for switch users.' : ''}',
          style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.35)),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _toggleButton(
              label: 'Press',
              active: state.activationMode == ActivationMode.press,
              onTap: () {
                state.activationMode = ActivationMode.press;
                state.stopScan();
                state.saveState();
                state.notify();
              },
            ),
            const SizedBox(width: 8),
            _toggleButton(
              label: 'Release',
              active: state.activationMode == ActivationMode.release,
              onTap: () {
                state.activationMode = ActivationMode.release;
                state.stopScan();
                state.saveState();
                state.notify();
              },
            ),
            if (state.buttons.length > 1) ...[
              const SizedBox(width: 8),
              _toggleButton(
                label: 'Scan',
                active: state.activationMode == ActivationMode.scan,
                onTap: () {
                  state.activationMode = ActivationMode.scan;
                  state.saveState();
                  state.notify();
                },
              ),
            ],
          ],
        ),

        // Scan options
        if (state.activationMode == ActivationMode.scan) ...[
          const SizedBox(height: 16),
          _sliderCard(
            label: 'Scan Speed',
            valueLabel: '${state.scanInterval}s per button',
            value: state.scanInterval,
            min: 0.5,
            max: 5.0,
            divisions: 9,
            onChanged: (v) {
              state.scanInterval = v;
              state.saveState();
              state.notify();
            },
          ),
          const SizedBox(height: 12),
          _buildScanColorPicker(state),
          const SizedBox(height: 12),
          _toggleRow(
            label: 'Audible Tick',
            subtitle: 'Click on each selection change',
            value: state.scanTick,
            onTap: () {
              state.scanTick = !state.scanTick;
              state.saveState();
              state.notify();
            },
          ),
          const SizedBox(height: 8),
          _toggleRow(
            label: 'Speak Button Name',
            subtitle: 'Read button label aloud as scanner highlights it',
            value: state.scanAnnounce,
            onTap: () {
              state.scanAnnounce = !state.scanAnnounce;
              state.saveState();
              state.notify();
            },
          ),
          const SizedBox(height: 8),
          _toggleRow(
            label: 'Clear Cooldown on Advance',
            subtitle: 'Resets activation cooldown when scanner moves',
            value: state.scanClearDebounce,
            onTap: () {
              state.scanClearDebounce = !state.scanClearDebounce;
              state.saveState();
              state.notify();
            },
          ),
        ],
        const SizedBox(height: 24),

        // Tap Feedback
        _sectionLabel('Tap Feedback', Icons.notifications, const Color(0xFFFBBF24)),
        const SizedBox(height: 4),
        Text(
          'Get confirmation when you tap a button.',
          style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.35)),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _toggleButton(
              label: 'Vibration',
              icon: Icons.bolt,
              active: state.hapticsEnabled,
              onTap: () {
                state.hapticsEnabled = !state.hapticsEnabled;
                state.saveState();
                state.notify();
              },
            ),
            const SizedBox(width: 12),
            _toggleButton(
              label: 'Sound',
              icon: Icons.music_note,
              active: state.audioCueEnabled,
              onTap: () {
                state.audioCueEnabled = !state.audioCueEnabled;
                state.saveState();
                state.notify();
              },
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Activation Cooldown
        _sectionLabel(
            'Activation Cooldown', Icons.hourglass_bottom, const Color(0xFF34D399)),
        const SizedBox(height: 4),
        Text(
          'Prevents accidental double-taps by ignoring extra touches for a short time.',
          style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.35)),
        ),
        const SizedBox(height: 8),
        _sliderCard(
          label: 'Debounce Time',
          valueLabel: '${state.debounceTime}s',
          value: state.debounceTime,
          min: 0,
          max: 5,
          divisions: 10,
          onChanged: (v) {
            state.debounceTime = v;
            state.saveState();
            state.notify();
          },
        ),
        const SizedBox(height: 24),

        // Recorded Voice Volume
        _sectionLabel(
            'Recorded Voice Volume', Icons.volume_up, const Color(0xFF60A5FA)),
        const SizedBox(height: 4),
        Text(
          'Boosts the volume of your microphone recordings.',
          style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.35)),
        ),
        const SizedBox(height: 8),
        _sliderCard(
          label: 'Playback Boost',
          valueLabel: '${state.playbackGain.toStringAsFixed(1)}×',
          value: state.playbackGain,
          min: 1,
          max: 5,
          divisions: 8,
          onChanged: (v) {
            state.playbackGain = v;
            state.saveState();
            state.notify();
          },
        ),
        const SizedBox(height: 24),

        // Speech
        _sectionLabel('Speech', Icons.record_voice_over, const Color(0xFF34D399)),
        const SizedBox(height: 4),
        Text(
          'Adjust the volume, speaking speed, and choose a TTS voice.',
          style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.35)),
        ),
        const SizedBox(height: 8),
        _sliderCard(
          label: 'Speaking Rate',
          valueLabel: '${state.ttsRate.toStringAsFixed(2)}×',
          value: state.ttsRate,
          min: 0.25,
          max: 2.0,
          divisions: 7,
          onChanged: (v) {
            state.setTtsRate(v);
          },
        ),
        const SizedBox(height: 12),
        _sliderCard(
          label: 'Text to Speech Volume',
          valueLabel: '${(state.ttsVolume * 100).toInt()}%',
          value: state.ttsVolume,
          min: 0.0,
          max: 1.0,
          divisions: 10,
          onChanged: (v) {
            state.setTtsVolume(v);
          },
        ),
        const SizedBox(height: 12),
        _buildVoicePicker(context, state),
        const SizedBox(height: 24),

        // Button Label Position
        _sectionLabel('Button Label Position', Icons.text_format, const Color(0xFFF472B6)),
        const SizedBox(height: 4),
        Text(
          'Where the button label appears.',
          style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.35)),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _toggleButton(
              label: 'On Button',
              active: state.labelPos == LabelPosition.on,
              onTap: () {
                state.labelPos = LabelPosition.on;
                state.saveState();
                state.notify();
              },
            ),
            const SizedBox(width: 8),
            _toggleButton(
              label: 'Under',
              active: state.labelPos == LabelPosition.under,
              onTap: () {
                state.labelPos = LabelPosition.under;
                state.saveState();
                state.notify();
              },
            ),
            const SizedBox(width: 8),
            _toggleButton(
              label: 'Hidden',
              active: state.labelPos == LabelPosition.off,
              onTap: () {
                state.labelPos = LabelPosition.off;
                state.saveState();
                state.notify();
              },
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Button Layout
        _sectionLabel('Button Layout', Icons.grid_view, const Color(0xFF818CF8)),
        const SizedBox(height: 4),
        Text(
          'Enter positioning mode to arrange your buttons.',
          style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.35)),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              final state = context.read<AppState>();
              Navigator.of(context).pop();
              state.closeSettings();
              state.togglePositioning(true);
            },
            icon: const Icon(Icons.open_with, size: 16),
            label: const Text('MOVE & PLACE BUTTONS',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFA5B4FC),
              side: BorderSide(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.45),
                  style: BorderStyle.solid),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Storage
        Container(
          padding: const EdgeInsets.only(top: 24),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('Storage', Icons.storage, const Color(0xFFF87171)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FutureBuilder<int>(
                      future: state.getStorageSize(),
                      builder: (context, snap) {
                        return Text(
                          snap.hasData
                              ? state.formatBytes(snap.data!)
                              : 'Calculating...',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD4D4D8)),
                        );
                      },
                    ),
                    _dangerButton(
                      label: 'Clear All',
                      small: true,
                      onTap: () => _showConfirm(
                        context,
                        'Delete all audio?',
                        'This will permanently remove all recorded sounds. Button text labels will be kept.',
                        () => state.clearAllAudio(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  VOICE PICKER
  // ══════════════════════════════════════════════════════════════════
  Widget _buildVoicePicker(BuildContext context, AppState state) {
    final voices = state.ttsVoices;
    final selectedUri = state.selectedVoiceURI;

    String selectedLabel = 'Default';
    if (selectedUri.isNotEmpty && voices.isNotEmpty) {
      final match = voices.firstWhere(
        (v) => (v['uri'] as String? ?? '') == selectedUri,
        orElse: () => <String, dynamic>{},
      );
      if (match.isNotEmpty) {
        selectedLabel = match['name'] as String? ?? selectedUri;
      }
    }

    return GestureDetector(
      onTap: () => _showVoicePicker(context, state),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.record_voice_over, size: 16, color: Color(0xFF34D399)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VOICE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.4),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selectedLabel,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: Colors.white.withValues(alpha: 0.35)),
          ],
        ),
      ),
    );
  }

  void _showVoicePicker(BuildContext context, AppState state) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0D0D12),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSt) {
          final voices = state.ttsVoices;
          final selectedUri = state.selectedVoiceURI;

          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder: (_, scrollCtrl) => Column(
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Title row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(
                    children: [
                      const Text(
                        'Select Voice',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          state.refreshWebVoices().then((_) => setSt(() {}));
                        },
                        child: const Text(
                          'Refresh',
                          style: TextStyle(color: Color(0xFF818CF8), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                // Voice list
                Expanded(
                  child: ListView(
                    controller: scrollCtrl,
                    children: [
                      // Default option
                      _voiceTile(
                        name: 'Default',
                        lang: 'System default voice',
                        isSelected: selectedUri.isEmpty,
                        onTap: () {
                          state.setTtsVoice('');
                          Navigator.pop(ctx);
                        },
                      ),
                      if (voices.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No voices found.\nTap Refresh — voices may still be loading.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      ...voices.map((v) {
                        final name = v['name'] as String? ?? '';
                        final lang = v['lang'] as String? ?? v['locale'] as String? ?? '';
                        final uri = v['uri'] as String? ?? name;
                        return _voiceTile(
                          name: name,
                          lang: lang,
                          isSelected: selectedUri == uri,
                          onTap: () {
                            state.setTtsVoice(uri);
                            Navigator.pop(ctx);
                          },
                        );
                      }),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _voiceTile({
    required String name,
    required String lang,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        Icons.record_voice_over,
        size: 20,
        color: isSelected ? const Color(0xFF34D399) : Colors.white.withValues(alpha: 0.35),
      ),
      title: Text(
        name,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.85),
        ),
      ),
      subtitle: Text(
        lang,
        style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4)),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Color(0xFF34D399), size: 18)
          : null,
    );
  }

  Widget _buildScanColorPicker(AppState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'OUTLINE COLOUR',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: 0.4),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kScanColors.map((c) {
              final active = state.scanColor == c.name;
              return GestureDetector(
                onTap: () {
                  state.scanColor = c.name;
                  state.saveState();
                  state.notify();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.swatch,
                    boxShadow: active
                        ? [
                            const BoxShadow(
                                color: Colors.white,
                                spreadRadius: 2,
                                blurRadius: 0),
                          ]
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  SHARED WIDGETS
  // ══════════════════════════════════════════════════════════════════
  Widget _sectionLabel(String text, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 6),
        Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _textField({
    required String value,
    required String placeholder,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      initialValue: value,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.25)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF818CF8)),
        ),
      ),
    );
  }

  Widget _toggleButton({
    required String label,
    required bool active,
    IconData? icon,
    bool enabled = true,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFF4F46E5).withValues(alpha: 0.28)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active
                  ? const Color(0xFF818CF8).withValues(alpha: 0.7)
                  : Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16,
                    color: active
                        ? const Color(0xFFC7D2FE)
                        : Colors.white.withValues(alpha: 0.4)),
                const SizedBox(width: 6),
              ],
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: active
                      ? const Color(0xFFC7D2FE)
                      : enabled
                          ? Colors.white.withValues(alpha: 0.4)
                          : Colors.white.withValues(alpha: 0.2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sliderCard({
    required String label,
    required String valueLabel,
    required double value,
    required double min,
    required double max,
    int? divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label.toUpperCase(),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.4),
                      letterSpacing: 1)),
              Text(valueLabel,
                  style: const TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF22D3EE))),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: const Color(0xFF6366F1),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _toggleRow({
    required String label,
    required String subtitle,
    required bool value,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(),
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withValues(alpha: 0.4),
                        letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 9,
                        color: Colors.white.withValues(alpha: 0.3))),
              ],
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: value
                    ? const Color(0xFF4F46E5).withValues(alpha: 0.28)
                    : Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: value
                      ? const Color(0xFF818CF8).withValues(alpha: 0.7)
                      : Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: Text(
                value ? 'ON' : 'OFF',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: value
                      ? const Color(0xFFC7D2FE)
                      : Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required Color color,
    required Color bgColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Center(child: Icon(icon, size: 16, color: color)),
      ),
    );
  }

  Widget _dangerButton({
    required String label,
    required VoidCallback onTap,
    bool small = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: small ? 12 : 16,
          vertical: small ? 8 : 10,
        ),
        decoration: BoxDecoration(
          border: Border.all(
              color: const Color(0xFFEF4444).withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(small ? 8 : 12),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: small ? 11 : 12,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFF87171),
          ),
        ),
      ),
    );
  }

  void _showConfirm(
    BuildContext context,
    String title,
    String description,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D0D12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.25)),
              ),
              child: const Icon(Icons.warning_amber,
                  color: Color(0xFFF87171), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
            ),
          ],
        ),
        content: Text(description,
            style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.4),
                height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4))),
          ),
          ElevatedButton(
            onPressed: () {
              onConfirm();
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child:
                const Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
