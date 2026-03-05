import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String _tab = 'buttons'; // 'buttons' | 'scan' | 'system'

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
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
                          child: const Icon(Icons.settings, color: Color(0xFFA5B4FC), size: 24),
                        ),
                        const SizedBox(width: 14),
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Colors.white, Color(0xFFA1A1AA)],
                          ).createShader(bounds),
                          child: const Text(
                            'SETTINGS',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(Icons.close, size: 28,
                              color: Colors.white.withValues(alpha: 0.6)),
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
                        _tabButton('Activation', 'activation'),
                        _tabButton('Setup', 'setup'),
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
                    : _tab == 'activation'
                        ? _buildScanTab(state)
                        : _buildSetupTab(state),
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
                    'DONE',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.5),
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

  Widget _tabButton(String label, String tab) {
    final active = _tab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = tab),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? const Color(0xFF818CF8) : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: active ? Colors.white : Colors.white.withValues(alpha: 0.5),
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

        // ── Global button appearance ─────────────────────────────
        const SizedBox(height: 8),
        Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
        const SizedBox(height: 24),

        // Label Position
        _sectionLabel('Label Position', Icons.text_format, const Color(0xFFF472B6)),
        const SizedBox(height: 8),
        Text(
          'Where the label appears on each button.',
          style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.6), height: 1.5),
        ),
        const SizedBox(height: 12),
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

        // Layout
        _sectionLabel('Button Layout', Icons.grid_view, const Color(0xFF818CF8)),
        const SizedBox(height: 8),
        Text(
          'Enter positioning mode to drag and resize buttons.',
          style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.6), height: 1.5),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              final state = context.read<AppState>();
              Navigator.of(context).pop();
              state.closeSettings();
              state.togglePositioning(true);
            },
            icon: const Icon(Icons.open_with, size: 20),
            label: const Text('MOVE & PLACE BUTTONS',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
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
        const SizedBox(height: 32),
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
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: active
                              ? const Color(0xFFC7D2FE)
                              : Colors.white.withValues(alpha: 0.6),
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
                        size: 20,
                        color: const Color(0xFF818CF8).withValues(alpha: 0.7)),
                    const SizedBox(width: 6),
                    Text(
                      'Add',
                      style: TextStyle(
                        fontSize: 14,
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
      key: ValueKey(btn.id),
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
        const SizedBox(height: 8),
        Text(
          'Tap the entire screen, or just the button.',
          style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.6)),
        ),
        const SizedBox(height: 12),
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
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.record_voice_over_outlined, size: 16,
                    color: const Color(0xFF818CF8).withValues(alpha: 0.8)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Type text to have it read aloud by the robot voice when this switch is activated.',
                    style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.65), height: 1.45),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.mic_outlined, size: 16,
                    color: const Color(0xFF34D399).withValues(alpha: 0.8)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Or tap the mic to record your own audio. Text is optional — add it for closed captions.',
                    style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.65), height: 1.45),
                  ),
                ),
              ]),
              const SizedBox(height: 6),
              Text(
                'Up to 10 phrases per switch — each tap cycles to the next.',
                style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.35), height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(btn.phrases.length, (idx) => _phraseRow(state, btn, idx)),
        if (btn.phrases.length < 10)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: GestureDetector(
              onTap: () => state.addPhrase(btn.id),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 16, color: Colors.white.withValues(alpha: 0.5)),
                    const SizedBox(width: 6),
                    Text(
                      'Add phrase',
                      style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('RESET TO DEFAULT',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFF87171),
                side: BorderSide(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                    style: BorderStyle.solid),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),

        // Audio storage info
        const SizedBox(height: 24),
        FutureBuilder<int>(
          future: state.getStorageSize(),
          builder: (context, snap) {
            final sizeStr = snap.hasData ? state.formatBytes(snap.data!) : '…';
            return Text(
              'Recordings are using $sizeStr of storage. Go to the Setup tab to free up space.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.3),
                height: 1.5,
              ),
            );
          },
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
    final phraseText = btn.phrases[idx].trim();
    final hasTts = !hasAudio && phraseText.isNotEmpty;
    final isThisRecording = state.isRecording &&
        state.currentRecordingBtnId == btn.id &&
        state.currentRecordingIdx == idx;
    final isOtherRecording = state.isRecording && !isThisRecording;

    // Mode badge colours
    final Color badgeBg = hasAudio
        ? const Color(0xFF10B981).withValues(alpha: 0.15)
        : hasTts
            ? const Color(0xFF6366F1).withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.04);
    final Color badgeBorder = hasAudio
        ? const Color(0xFF34D399).withValues(alpha: 0.5)
        : hasTts
            ? const Color(0xFF818CF8).withValues(alpha: 0.5)
            : Colors.white.withValues(alpha: 0.1);
    final Color badgeText = hasAudio
        ? const Color(0xFF6EE7B7)
        : hasTts
            ? const Color(0xFFA5B4FC)
            : Colors.white.withValues(alpha: 0.25);
    final String badgeLabel = hasAudio ? 'AUDIO' : hasTts ? 'TTS' : 'EMPTY';
    final IconData badgeIcon = hasAudio
        ? Icons.mic
        : hasTts
            ? Icons.record_voice_over
            : Icons.remove_circle_outline;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              // Mode chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  border: Border.all(color: badgeBorder),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 11, color: badgeText),
                    const SizedBox(width: 4),
                    Text(
                      badgeLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: badgeText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const SizedBox(width: 32), // align with text above
              // Text input
              Expanded(
                child: _textField(
                  value: btn.phrases[idx],
                  placeholder: 'Phrase (optional with audio)',
                  onChanged: (v) =>
                      state.updateButton(btn.id, (b) => b.phrases[idx] = v),
                ),
              ),
              const SizedBox(width: 8),
              // Action buttons
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
              ] else ...[
                // TTS preview (only when text is present)
                if (hasTts) ...[
                  _iconButton(
                    icon: Icons.record_voice_over,
                    color: const Color(0xFFA5B4FC),
                    bgColor: const Color(0xFF6366F1).withValues(alpha: 0.12),
                    borderColor: const Color(0xFF818CF8).withValues(alpha: 0.4),
                    onTap: () => state.previewPhraseText(phraseText),
                  ),
                  const SizedBox(width: 4),
                ],
                if (state.canRecord)
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
              if (btn.phrases.length > 1) ...[
                const SizedBox(width: 4),
                _iconButton(
                  icon: Icons.close,
                  color: Colors.white.withValues(alpha: 0.45),
                  bgColor: Colors.white.withValues(alpha: 0.04),
                  borderColor: Colors.white.withValues(alpha: 0.1),
                  onTap: () => state.removePhrase(btn.id, idx),
                ),
              ],
            ],
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
  // ── Slot card ────────────────────────────────────────────────────────────
  Widget _buildSlotCard(BuildContext context, AppState state, int slot) {
    final isActive = state.currentSlot == slot;
    final name = state.slotNames[slot];
    return GestureDetector(
      onTap: isActive
          ? null
          : () => state.switchToSlot(slot),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF312E81).withValues(alpha: 0.55)
              : const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? const Color(0xFF818CF8)
                : Colors.white.withValues(alpha: 0.12),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Slot number badge
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF4F46E5)
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${slot + 1}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: isActive
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  color: isActive
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ),
            // Active badge or "Tap to load" hint
            if (isActive)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'ACTIVE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFA5B4FC),
                    letterSpacing: 0.8,
                  ),
                ),
              )
            else
              Text(
                'Tap to load',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
            const SizedBox(width: 10),
            // Rename button
            GestureDetector(
              onTap: () => _showRenameSlotDialog(context, state, slot),
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRenameSlotDialog(
      BuildContext context, AppState state, int slot) async {
    final ctrl = TextEditingController(text: state.slotNames[slot]);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Rename Slot ${slot + 1}',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 24,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.07),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            counterStyle:
                TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            hintText: 'Slot name…',
            hintStyle:
                TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          ),
          onSubmitted: (_) {
            state.setSlotName(slot, ctrl.text);
            Navigator.of(ctx).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            ),
          ),
          TextButton(
            onPressed: () {
              state.setSlotName(slot, ctrl.text);
              Navigator.of(ctx).pop();
            },
            child: const Text(
              'Save',
              style: TextStyle(
                  color: Color(0xFF818CF8), fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    ctrl.dispose();
  }

  Widget _buildSetupTab(AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Save Slots ──────────────────────────────────────────
        _sectionLabel('Save Slots', Icons.bookmark_outline, const Color(0xFFA78BFA)),
        const SizedBox(height: 8),
        Text(
          'Store up to 3 independent profiles. Each profile saves its buttons, switch access settings, background colour, and voice recordings.',
          style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.6), height: 1.5),
        ),
        const SizedBox(height: 12),
        for (int i = 0; i < 3; i++) _buildSlotCard(context, state, i),
        const SizedBox(height: 24),

        // ── Fullscreen ──────────────────────────────────────────
        _sectionLabel('Display', Icons.fullscreen, const Color(0xFF64B5F6)),
        const SizedBox(height: 8),
        Text(
          'Hide the system status and navigation bars for more screen space. Applies to all profiles.',
          style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.6), height: 1.5),
        ),
        const SizedBox(height: 12),
        _toggleRow(
          label: 'Fullscreen',
          subtitle: 'Hides system bars — swipe from edge to temporarily restore',
          value: state.isFullscreen,
          onTap: () => state.setFullscreen(!state.isFullscreen),
        ),
        const SizedBox(height: 24),

        // Background Colour
        _sectionLabel('Background Colour', Icons.palette_outlined, const Color(0xFF94A3B8)),
        const SizedBox(height: 8),
        Text(
          'Choose a background colour for this profile.',
          style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.6), height: 1.5),
        ),
        const SizedBox(height: 12),
        _buildBgColorPicker(state),
        const SizedBox(height: 24),

        // Recorded Voice Volume
        _sectionLabel(
            'Recorded Voice Volume', Icons.volume_up, const Color(0xFF60A5FA)),
        const SizedBox(height: 8),
        Text(
          'Boosts the volume of your microphone recordings. Applies to all profiles.',
          style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.6), height: 1.5),
        ),
        const SizedBox(height: 12),
        _sliderCard(
          label: 'Playback Boost',
          valueLabel: '${state.playbackGain.toStringAsFixed(1)}×',
          value: state.playbackGain,
          min: 1,
          max: 40,
          divisions: 78,
          onChanged: (v) {
            state.playbackGain = v;
            state.saveGlobalSettings();
            state.notify();
          },
        ),
        const SizedBox(height: 24),

        // Speech
        _sectionLabel('Speech', Icons.record_voice_over, const Color(0xFF34D399)),
        const SizedBox(height: 8),
        Text(
          'Adjust the volume, speaking speed, and choose a TTS voice. Applies to all profiles.',
          style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.6), height: 1.5),
        ),
        const SizedBox(height: 12),
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

        // Menu Access Guard
        _sectionLabel('Menu Access Guard', Icons.lock_outline, const Color(0xFFFBBF24)),
        const SizedBox(height: 8),
        Text(
          'Controls how the Settings and Move & Place buttons are opened, to prevent accidental access. Applies to all profiles.',
          style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.6), height: 1.5),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _toggleButton(
              label: 'Hold',
              icon: Icons.touch_app,
              active: state.guardMode == GuardMode.hold,
              onTap: () { state.guardMode = GuardMode.hold; state.saveGlobalSettings(); state.notify(); },
            ),
            const SizedBox(width: 8),
            _toggleButton(
              label: 'Taps',
              icon: Icons.ads_click,
              active: state.guardMode == GuardMode.taps,
              onTap: () { state.guardMode = GuardMode.taps; state.saveGlobalSettings(); state.notify(); },
            ),
            const SizedBox(width: 8),
            _toggleButton(
              label: 'Off',
              icon: Icons.lock_open_outlined,
              active: state.guardMode == GuardMode.off,
              onTap: () { state.guardMode = GuardMode.off; state.saveGlobalSettings(); state.notify(); },
            ),
          ],
        ),
        if (state.guardMode == GuardMode.hold) ...[
          const SizedBox(height: 12),
          _sliderCard(
            label: 'Hold Duration',
            valueLabel: '${state.guardHoldSeconds.toStringAsFixed(1)}s',
            value: state.guardHoldSeconds,
            min: 1.0,
            max: 10.0,
            divisions: 18,
            onChanged: (v) { state.guardHoldSeconds = v; state.saveGlobalSettings(); state.notify(); },
          ),
        ],
        if (state.guardMode == GuardMode.taps) ...[
          const SizedBox(height: 12),
          _sliderCard(
            label: 'Number of Taps',
            valueLabel: '${state.guardTapCount} taps',
            value: state.guardTapCount.toDouble().clamp(2.0, 5.0),
            min: 2.0,
            max: 5.0,
            divisions: 3,
            onChanged: (v) { state.guardTapCount = v.round(); state.saveGlobalSettings(); state.notify(); },
          ),
        ],
        const SizedBox(height: 24),

        // Setup Access Key
        _sectionLabel('Setup Access Key', Icons.vpn_key_outlined, const Color(0xFF4ADE80)),
        const SizedBox(height: 8),
        Text(
          'A keyboard shortcut that opens Settings directly, bypassing the touch guard. Useful for the person configuring the app. Applies to all profiles.',
          style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.6), height: 1.5),
        ),
        const SizedBox(height: 12),
        _keyBindRow(
          context,
          label: 'Open Settings',
          keyValue: state.settingsKey,
          allowClear: true,
          onSet: (k) {
            state.settingsKey = k;
            state.saveGlobalSettings();
            state.notify();
          },
        ),
        const SizedBox(height: 24),

        // Adapted Switch Access
        _sectionLabel('Adapted Switch Access', Icons.keyboard_alt_outlined, const Color(0xFF38BDF8)),
        const SizedBox(height: 8),
        Text(
          'Map keyboard keys or switch inputs to directly activate buttons or confirm a scan selection.',
          style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.6), height: 1.5),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.25)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.mouse, size: 16, color: Color(0xFF38BDF8)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'In Scan mode, a mouse click anywhere on the screen also confirms the highlighted button.',
                  style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.65), height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'DIRECT ACTIVATION KEYS',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.35), letterSpacing: 1.0),
        ),
        const SizedBox(height: 8),
        for (int i = 0; i < 4; i++) ..._switchKeyRow(context, state, i),
        const SizedBox(height: 16),
        Text(
          'SCAN CONFIRMATION KEY',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.35), letterSpacing: 1.0),
        ),
        const SizedBox(height: 8),
        _keyBindRow(
          context,
          label: 'Confirm Selection',
          keyValue: state.scanConfirmKey,
          onSet: (k) {
            state.scanConfirmKey = k;
            state.saveState();
            state.notify();
          },
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
  //  SCAN TAB
  // ══════════════════════════════════════════════════════════════════
  Widget _buildScanTab(AppState state) {
    final scanActive = state.activationMode == ActivationMode.scan;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tap Feedback
        _sectionLabel('Tap Feedback', Icons.notifications, const Color(0xFFFBBF24)),
        const SizedBox(height: 8),
        Text(
          'Get confirmation when a button is activated.',
          style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.6), height: 1.5),
        ),
        const SizedBox(height: 12),
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
        _sectionLabel('Activation Cooldown', Icons.hourglass_bottom, const Color(0xFF34D399)),
        const SizedBox(height: 8),
        Text(
          'Prevents accidental double-taps by ignoring extra touches for a short time.',
          style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.6), height: 1.5),
        ),
        const SizedBox(height: 12),
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

        // Activation Mode
        _sectionLabel('Activation Method', Icons.mouse, const Color(0xFF22D3EE)),
        const SizedBox(height: 8),
        Text(
          'Press activates on touch-down. Release activates when you lift your finger. Scan cycles through buttons automatically and activates on confirmation.',
          style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.6), height: 1.5),
        ),
        const SizedBox(height: 12),
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
            const SizedBox(width: 8),
            _toggleButton(
              label: 'Scan',
              active: state.activationMode == ActivationMode.scan,
              enabled: state.buttons.length > 1,
              onTap: () {
                state.activationMode = ActivationMode.scan;
                state.saveState();
                state.notify();
              },
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ── Scan options — always visible, greyed out when scan is not active ──
        Opacity(
          opacity: scanActive ? 1.0 : 0.38,
          child: IgnorePointer(
            ignoring: !scanActive,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel('Scan Speed', Icons.speed, const Color(0xFF22D3EE)),
                const SizedBox(height: 8),
                Text(
                  'How long the scanner stays on each button before moving on.',
                  style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.6), height: 1.5),
                ),
                const SizedBox(height: 12),
                _sliderCard(
                  label: 'Seconds per button',
                  valueLabel: '${state.scanInterval}s',
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
                const SizedBox(height: 24),
                _sectionLabel('Scan Highlight Colour', Icons.palette_outlined, const Color(0xFF22D3EE)),
                const SizedBox(height: 8),
                Text(
                  'The colour used to highlight the currently selected button.',
                  style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.6), height: 1.5),
                ),
                const SizedBox(height: 12),
                _buildScanColorPicker(state),
                const SizedBox(height: 24),
                _sectionLabel('Scanning Mode', Icons.view_agenda_outlined, const Color(0xFF22D3EE)),
                const SizedBox(height: 8),
                Text(
                  'Standard scans through each button. Sub-scan lets you pick which phrase to speak after choosing a button.',
                  style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.6), height: 1.5),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _toggleButton(
                      label: 'Standard',
                      icon: Icons.swap_horiz,
                      active: !state.scanSubScan,
                      onTap: () {
                        state.scanSubScan = false;
                        state.saveState();
                        state.notify();
                      },
                    ),
                    const SizedBox(width: 8),
                    _toggleButton(
                      label: 'Sub-scan',
                      icon: Icons.format_list_bulleted,
                      active: state.scanSubScan,
                      onTap: () {
                        final needsStopOnSelection = !state.scanStopOnSelection;
                        final needsConfirmTone = !state.scanConfirmTone;
                        state.scanSubScan = true;
                        // Sub-scan requires Stop on Selection to work correctly.
                        if (needsStopOnSelection) {
                          state.scanStopOnSelection = true;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                '"Stop Scan on Selection" has been turned on — sub-scan needs it to work.',
                                style: TextStyle(
                                  color: Color(0xFF1A1A1A),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              backgroundColor: const Color(0xFFFBBF24),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                        // Confirmation tone greatly improves sub-scan usability.
                        if (needsConfirmTone) {
                          state.scanConfirmTone = true;
                        }
                        state.saveState();
                        state.notify();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _sectionLabel('Scanning Behaviour', Icons.tune, const Color(0xFF22D3EE)),
                const SizedBox(height: 8),
                Text(
                  'Fine-tune how the scanner sounds, responds, and moves.',
                  style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.6), height: 1.5),
                ),
                const SizedBox(height: 12),
                _toggleRow(
                  icon: Icons.volume_up,
                  label: 'Audible Tick',
                  subtitle: 'Click sound on each selection change',
                  value: state.scanTick,
                  onTap: () {
                    state.scanTick = !state.scanTick;
                    state.saveState();
                    state.notify();
                  },
                ),
                const SizedBox(height: 8),
                _toggleRow(
                  icon: Icons.record_voice_over,
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
                  icon: Icons.replay,
                  label: 'Reset Countdown on Selection',
                  subtitle: 'Restart the scan timer each time a button is activated',
                  value: state.scanResetOnActivate,
                  onTap: () {
                    state.scanResetOnActivate = !state.scanResetOnActivate;
                    state.saveState();
                    state.notify();
                  },
                ),
                const SizedBox(height: 8),
                _toggleRow(
                  icon: Icons.stop_circle_outlined,
                  label: 'Stop Scan on Selection',
                  subtitle: 'Scanning halts after a button is activated',
                  value: state.scanStopOnSelection,
                  onTap: () {
                    state.scanStopOnSelection = !state.scanStopOnSelection;
                    state.saveState();
                    state.notify();
                  },
                ),
                const SizedBox(height: 8),
                _toggleRow(
                  icon: Icons.notifications_active_outlined,
                  label: 'Confirmation Tone',
                  subtitle: 'Plays a tone when a selection is confirmed, before the phrase is spoken',
                  value: state.scanConfirmTone,
                  onTap: () {
                    state.scanConfirmTone = !state.scanConfirmTone;
                    state.saveState();
                    state.notify();
                  },
                ),
                const SizedBox(height: 8),
                _toggleRow(
                  icon: Icons.touch_app,
                  label: 'Click to Begin',
                  subtitle: 'First switch press starts scanning; subsequent presses activate',
                  value: state.scanClickToBegin,
                  onTap: () {
                    state.scanClickToBegin = !state.scanClickToBegin;
                    state.saveState();
                    state.notify();
                  },
                ),
                const SizedBox(height: 8),
                _toggleRow(
                  icon: Icons.replay_circle_filled,
                  label: 'Click to Restart',
                  subtitle: 'After scanning stops, press your switch again to start a new scan',
                  value: state.scanClickToRestart,
                  onTap: () {
                    state.scanClickToRestart = !state.scanClickToRestart;
                    state.saveState();
                    state.notify();
                  },
                ),
                const SizedBox(height: 8),
                _toggleRow(
                  icon: Icons.back_hand_outlined,
                  label: 'Show Stop Button',
                  subtitle: 'Adds a Stop option to the scan progression — select it to halt scanning',
                  value: state.scanStopButton,
                  onTap: () {
                    state.scanStopButton = !state.scanStopButton;
                    state.saveState();
                    state.notify();
                  },
                ),
                const SizedBox(height: 8),
                _toggleRow(
                  icon: Icons.add_comment_outlined,
                  label: 'Something Else Button',
                  subtitle: 'Adds a button that speaks a custom phrase without stopping the scan',
                  value: state.scanAltButton,
                  onTap: () {
                    state.scanAltButton = !state.scanAltButton;
                    state.saveState();
                    state.notify();
                  },
                ),
                if (state.scanAltButton) ...[
                  const SizedBox(height: 8),
                  KeyedSubtree(
                    key: ValueKey(state.scanAltButtonPhrase),
                    child: _textField(
                      value: state.scanAltButtonPhrase,
                      placeholder: 'e.g. Something Else',
                      onChanged: (v) {
                        state.scanAltButtonPhrase = v.isEmpty ? 'Something Else' : v;
                        state.saveState();
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
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

  Widget _buildBgColorPicker(AppState state) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: kBgColors.map((b) {
        final active = state.bgColorName == b.name;
        return GestureDetector(
          onTap: () => state.setBgColor(b.name),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: b.color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: active
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.2),
                width: active ? 3 : 1.5,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.25),
                        blurRadius: 8,
                        spreadRadius: 0,
                      )
                    ]
                  : null,
            ),
            child: Text(
              b.name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: b.color.computeLuminance() > 0.4
                    ? Colors.black.withValues(alpha: active ? 0.85 : 0.55)
                    : Colors.white.withValues(alpha: active ? 1.0 : 0.7),
              ),
            ),
          ),
        );
      }).toList(),
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
        Icon(icon, size: 26, color: color),
        const SizedBox(width: 12),
        Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 20,
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
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        hintText: placeholder,
        hintStyle: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.35)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                Icon(icon, size: 22,
                    color: active
                        ? const Color(0xFFC7D2FE)
                        : Colors.white.withValues(alpha: 0.4)),
                const SizedBox(width: 8),
              ],
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: active
                      ? const Color(0xFFC7D2FE)
                      : enabled
                          ? Colors.white.withValues(alpha: 0.8)
                          : Colors.white.withValues(alpha: 0.4),
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
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.8),
                      letterSpacing: 1.2)),
              Text(valueLabel,
                  style: const TextStyle(
                      fontSize: 17,
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
    IconData? icon,
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
          if (icon != null) ...
            [
              Container(
                width: 38,
                height: 38,
                margin: const EdgeInsets.only(right: 14),
                decoration: BoxDecoration(
                  color: value
                      ? const Color(0xFF4F46E5).withValues(alpha: 0.18)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: value
                      ? const Color(0xFFC7D2FE)
                      : Colors.white.withValues(alpha: 0.35),
                ),
              ),
            ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(),
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withValues(alpha: 0.9),
                        letterSpacing: 1.2)),
                const SizedBox(height: 8),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withValues(alpha: 0.55),
                        height: 1.4)),
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
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: value
                      ? const Color(0xFFC7D2FE)
                      : Colors.white.withValues(alpha: 0.8),
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
    return _PressIconBtn(
      icon: icon,
      color: color,
      bgColor: bgColor,
      borderColor: borderColor,
      onTap: onTap,
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
            fontSize: small ? 13 : 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
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
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
            ),
          ],
        ),
        content: Text(description,
            style: TextStyle(
                fontSize: 15,
                color: Colors.white.withValues(alpha: 0.6),
                height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel',
                style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.6))),
          ),
          ElevatedButton(
            onPressed: () {
              onConfirm();
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child:
                const Text('Confirm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Returns [row, spacing] for a switch-key binding entry.
  List<Widget> _switchKeyRow(BuildContext ctx, AppState state, int i) {
    final label = state.buttons.length > i
        ? 'Button ${i + 1}${state.buttons[i].label.isNotEmpty ? '  —  ${state.buttons[i].label}' : ''}'
        : 'Button ${i + 1} (slot unused)';
    return [
      _keyBindRow(
        ctx,
        label: label,
        keyValue: state.switchKeys[i],
        enabled: state.buttons.length > i,
        onSet: (k) {
          state.switchKeys[i] = k;
          state.saveState();
          state.notify();
        },
      ),
      if (i < 3) const SizedBox(height: 6),
    ];
  }

  Widget _keyBindRow(
    BuildContext context, {
    required String label,
    required String keyValue,
    required ValueChanged<String> onSet,
    bool enabled = true,
    bool allowClear = false,
  }) {
    final display = keyValue == ' ' ? 'Space' : (keyValue.isEmpty ? '—' : keyValue);
    return Opacity(
      opacity: enabled ? 1.0 : 0.38,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: enabled ? 0.05 : 0.02),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: enabled ? 0.1 : 0.05)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.85)),
              ),
            ),
            if (allowClear && keyValue.isNotEmpty) ...[
              GestureDetector(
                onTap: enabled ? () => onSet('') : null,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  child: Icon(Icons.close, size: 14,
                      color: Colors.white.withValues(alpha: 0.45)),
                ),
              ),
            ],
            GestureDetector(
              onTap: enabled ? () => _showKeyCaptureDialog(context, label, onSet) : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF38BDF8).withValues(alpha: enabled ? 0.12 : 0.04),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF38BDF8).withValues(alpha: enabled ? 0.45 : 0.1),
                  ),
                ),
                child: Text(
                  display,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                    color: const Color(0xFF7DD3FC).withValues(alpha: enabled ? 1.0 : 0.3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showKeyCaptureDialog(BuildContext context, String label, ValueChanged<String> onSet) {
    showDialog<void>(
      context: context,
      builder: (_) => _KeyCaptureDialog(label: label, onSet: onSet),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Key-capture dialog for Adapted Switch Access bindings
// ─────────────────────────────────────────────────────────────────────────────
class _KeyCaptureDialog extends StatefulWidget {
  const _KeyCaptureDialog({required this.label, required this.onSet});
  final String label;
  final ValueChanged<String> onSet;

  @override
  State<_KeyCaptureDialog> createState() => _KeyCaptureDialogState();
}

class _KeyCaptureDialogState extends State<_KeyCaptureDialog> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent) {
          final k = event.logicalKey.keyLabel;
          if (k.isNotEmpty) {
            widget.onSet(k);
            Navigator.of(context).pop();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: AlertDialog(
        backgroundColor: const Color(0xFF1C1C2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          widget.label,
          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.keyboard_alt_outlined, color: Color(0xFF38BDF8), size: 44),
            const SizedBox(height: 14),
            Text(
              'Press any key or switch button',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.65), height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pressable icon button with scale + brightness depression feedback
// ─────────────────────────────────────────────────────────────────────────────
class _PressIconBtn extends StatefulWidget {
  const _PressIconBtn({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.borderColor,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final Color bgColor;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  State<_PressIconBtn> createState() => _PressIconBtnState();
}

class _PressIconBtnState extends State<_PressIconBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _bright;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 160),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.82).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _bright = Tween<double>(begin: 1.0, end: 1.6).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _down() => _ctrl.forward();

  void _up() {
    _ctrl.reverse();
    widget.onTap();
  }

  void _cancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _down(),
      onTapUp: (_) => _up(),
      onTapCancel: _cancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Transform.scale(
          scale: _scale.value,
          child: ColorFiltered(
            colorFilter: ColorFilter.matrix([
              _bright.value, 0, 0, 0, 0,
              0, _bright.value, 0, 0, 0,
              0, 0, _bright.value, 0, 0,
              0, 0, 0, 1, 0,
            ]),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: widget.bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: widget.borderColor),
              ),
              child: Center(
                child: Icon(widget.icon, size: 16, color: widget.color),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
