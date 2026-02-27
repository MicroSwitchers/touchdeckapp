import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// Conditional imports for non-web platforms
import 'app_state_io.dart' if (dart.library.html) 'app_state_web.dart' as platform;

import '../constants.dart';
import '../models/app_button.dart';

class AppState extends ChangeNotifier {
  /// Public notify helper so UI code can trigger rebuilds.
  void notify() => notifyListeners();

  // ── Button data ──────────────────────────────────────────────────
  List<AppButton> buttons = [];
  String? editingBtnId;

  // ── Global settings ──────────────────────────────────────────────
  ActivationMode activationMode = ActivationMode.press;
  LabelPosition labelPos = LabelPosition.on;
  bool hapticsEnabled = true;
  bool audioCueEnabled = true;
  bool touchTargetScreen = false; // false = button, true = whole screen
  double debounceTime = 0;
  double playbackGain = 3.0;
  double scanInterval = 2.0;
  String scanColor = 'Yellow';
  bool scanTick = false;
  bool scanAnnounce = false;
  bool scanClearDebounce = false;

  // ── Positioning ──────────────────────────────────────────────────
  bool isPositioningMode = false;
  Offset outputBarPos = const Offset(50, 92);
  double outputBarScale = 1.0;
  bool showOutputBarInPositioning = true;

  // ── Runtime state (not persisted) ────────────────────────────────
  bool showSettings = false;
  String settingsTab = 'buttons';
  String? activeButtonId; // currently pressed
  String? playingButtonId; // currently speaking / playing audio
  bool isSpeaking = false;
  bool inDebounce = false;
  bool isRecording = false;
  bool get canRecord => platform.hasRecording && _recorder != null;
  String? outputBarText;
  Timer? _outputBarTimer;

  // ── Scan state ───────────────────────────────────────────────────
  Timer? _scanTimer;
  int scanIdx = 0;

  // ── Debounce ─────────────────────────────────────────────────────
  Timer? _debounceTimer;

  // ── TTS ──────────────────────────────────────────────────────────
  final FlutterTts _tts = FlutterTts();
  List<dynamic> voices = []; // raw flutter_tts voice list (native only)
  List<Map<String, dynamic>> ttsVoices = []; // normalised for settings UI
  String selectedVoiceURI = '';
  double ttsRate = 1.0; // 1.0 = normal speed (range 0.25–2.0)
  // _ttsUnlocked intentionally removed — unlock is called on every tap;
  // the JS side guards against duplicate or overlapping unlock calls.

  // ── Audio playback ───────────────────────────────────────────────
  final AudioPlayer _player = AudioPlayer();

  // ── Recording ────────────────────────────────────────────────────
  dynamic _recorder;
  String? _currentRecordingBtnId;
  int? _currentRecordingIdx;

  String? get currentRecordingBtnId => _currentRecordingBtnId;
  int? get currentRecordingIdx => _currentRecordingIdx;

  // ── Prefs ────────────────────────────────────────────────────────
  SharedPreferences? _prefs;

  // ────────────────────────────────────────────────────────────────
  // INIT
  // ────────────────────────────────────────────────────────────────
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    // Create recorder only on non-web platforms
    if (platform.hasRecording) {
      _recorder = platform.createRecorder();
    }

    await _initTts();
    await _loadState();

    _player.onPlayerComplete.listen((_) {
      isSpeaking = false;
      playingButtonId = null;
      notifyListeners();
    });

    notifyListeners();
  }

  Future<void> _initTts() async {
    if (kIsWeb) {
      // On web, all TTS is handled by the tdTTS JS helper (see web/index.html).
      // Register the JS→Dart completion bridge once here.
      platform.initWebTtsCallback();
      // Voices load asynchronously in many browsers — retry a few times.
      _loadWebVoices();
      Future.delayed(const Duration(milliseconds: 800), _loadWebVoices);
      Future.delayed(const Duration(milliseconds: 3000), _loadWebVoices);
      return;
    }

    // ── Native platforms: use flutter_tts ──────────────────────────
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(ttsRate);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    voices = await _tts.getVoices ?? [];
    ttsVoices = voices.map((v) {
      final m = Map<String, dynamic>.from(v as Map);
      return <String, dynamic>{
        'name': m['name'] ?? '',
        'uri': m['name'] ?? '', // name is used as the unique key on native
        'lang': m['locale'] ?? '',
        'local': 'true',
      };
    }).toList();

    _tts.setCompletionHandler(() {
      isSpeaking = false;
      playingButtonId = null;
      notifyListeners();
    });

    _tts.setErrorHandler((msg) {
      isSpeaking = false;
      playingButtonId = null;
      notifyListeners();
    });
  }

  /// Fetch the browser voice list from JS and refresh [ttsVoices].
  Future<void> _loadWebVoices() async {
    final fetched = await platform.getWebVoices();
    if (fetched.isNotEmpty) {
      ttsVoices = fetched;
      notifyListeners();
    }
  }

  /// Public: update the voice list (callable from Settings).
  Future<void> refreshWebVoices() => _loadWebVoices();

  /// Unlock the iOS Safari SpeechSynthesis audio context.
  /// Called SYNCHRONOUSLY inside the user-gesture handler on every tap so
  /// the audio context is re-activated even after the app is backgrounded.
  /// The JS unlock() function self-guards against duplicate/concurrent calls.
  void _ensureTtsUnlocked() {
    if (!kIsWeb) return;
    platform.unlockTtsForMobileBrowser(null);
  }

  // ────────────────────────────────────────────────────────────────
  // PERSISTENCE
  // ────────────────────────────────────────────────────────────────
  Future<void> _loadState() async {
    final p = _prefs!;

    // Buttons
    final btnJson = p.getString('buttons');
    if (btnJson != null) {
      try {
        buttons = AppButton.decodeList(btnJson);
      } catch (_) {
        buttons = [_defaultButton()];
      }
    } else {
      buttons = [_defaultButton()];
    }

    // Settings
    activationMode = ActivationMode.values.firstWhere(
      (m) => m.name == (p.getString('activationMode') ?? 'press'),
      orElse: () => ActivationMode.press,
    );
    labelPos = LabelPosition.values.firstWhere(
      (l) => l.name == (p.getString('labelPos') ?? 'on'),
      orElse: () => LabelPosition.on,
    );
    hapticsEnabled = p.getBool('hapticsEnabled') ?? true;
    audioCueEnabled = p.getBool('audioCueEnabled') ?? true;
    touchTargetScreen = p.getBool('touchTargetScreen') ?? false;
    debounceTime = p.getDouble('debounceTime') ?? 0;
    playbackGain = p.getDouble('playbackGain') ?? 3.0;
    scanInterval = p.getDouble('scanInterval') ?? 2.0;
    scanColor = p.getString('scanColor') ?? 'Yellow';
    scanTick = p.getBool('scanTick') ?? false;
    scanAnnounce = p.getBool('scanAnnounce') ?? false;
    scanClearDebounce = p.getBool('scanClearDebounce') ?? false;
    selectedVoiceURI = p.getString('selectedVoiceURI') ?? '';
    ttsRate = p.getDouble('ttsRate') ?? 1.0;

    final obpJson = p.getString('outputBarPos');
    if (obpJson != null) {
      try {
        final m = jsonDecode(obpJson);
        outputBarPos = Offset(
          (m['x'] as num).toDouble(),
          (m['y'] as num).toDouble(),
        );
      } catch (_) {}
    }
    outputBarScale = p.getDouble('outputBarScale') ?? 1.0;
    showOutputBarInPositioning = p.getBool('showOutputBarInPositioning') ?? true;

    editingBtnId = p.getString('editingBtnId');
    if (editingBtnId != null && !buttons.any((b) => b.id == editingBtnId)) {
      editingBtnId = buttons.isNotEmpty ? buttons.first.id : null;
    }

    if (buttons.length == 1 && activationMode == ActivationMode.scan) {
      activationMode = ActivationMode.press;
    }
    if (buttons.length > 1) touchTargetScreen = false;
  }

  Future<void> saveState() async {
    final p = _prefs!;
    await p.setString('buttons', AppButton.encodeList(buttons));
    await p.setString('activationMode', activationMode.name);
    await p.setString('labelPos', labelPos.name);
    await p.setBool('hapticsEnabled', hapticsEnabled);
    await p.setBool('audioCueEnabled', audioCueEnabled);
    await p.setBool('touchTargetScreen', touchTargetScreen);
    await p.setDouble('debounceTime', debounceTime);
    await p.setDouble('playbackGain', playbackGain);
    await p.setDouble('scanInterval', scanInterval);
    await p.setString('scanColor', scanColor);
    await p.setBool('scanTick', scanTick);
    await p.setBool('scanAnnounce', scanAnnounce);
    await p.setBool('scanClearDebounce', scanClearDebounce);
    await p.setString('selectedVoiceURI', selectedVoiceURI);
    await p.setDouble('ttsRate', ttsRate);
    await p.setString(
      'outputBarPos',
      jsonEncode({'x': outputBarPos.dx, 'y': outputBarPos.dy}),
    );
    await p.setDouble('outputBarScale', outputBarScale);
    await p.setBool('showOutputBarInPositioning', showOutputBarInPositioning);
    if (editingBtnId != null) {
      await p.setString('editingBtnId', editingBtnId!);
    }
  }

  AppButton _defaultButton([String? id]) => AppButton(
        id: id ?? const Uuid().v4(),
        color: kColors[0],
      );

  // ────────────────────────────────────────────────────────────────
  // BUTTON MANAGEMENT
  // ────────────────────────────────────────────────────────────────
  void addButton() {
    if (buttons.length >= 4) return;
    final offset = buttons.length * 10.0;
    final btn = AppButton(
      id: const Uuid().v4(),
      color: kColors[buttons.length % kColors.length],
      position: Offset(50 + offset, 50 - offset),
    );
    buttons.add(btn);
    if (buttons.length > 1) touchTargetScreen = false;
    editingBtnId = btn.id;
    saveState();
    notifyListeners();
  }

  void deleteButton(String id) {
    buttons.removeWhere((b) => b.id == id);
    if (buttons.isEmpty) buttons.add(_defaultButton());
    editingBtnId = buttons.first.id;
    if (buttons.length == 1 && activationMode == ActivationMode.scan) {
      activationMode = ActivationMode.press;
      stopScan();
    }
    saveState();
    notifyListeners();
  }

  void resetToDefault() {
    buttons = [_defaultButton()];
    editingBtnId = buttons.first.id;
    touchTargetScreen = false;
    if (activationMode == ActivationMode.scan) {
      activationMode = ActivationMode.press;
      stopScan();
    }
    saveState();
    notifyListeners();
  }

  void updateButton(String id, void Function(AppButton) updater) {
    final idx = buttons.indexWhere((b) => b.id == id);
    if (idx == -1) return;
    updater(buttons[idx]);
    saveState();
    notifyListeners();
  }

  // ────────────────────────────────────────────────────────────────
  // ACTIVATION
  // ────────────────────────────────────────────────────────────────
  void activateButton(String btnId, {bool autoClearVisual = true}) {
    if (isPositioningMode || showSettings || inDebounce) return;

    // Debounce
    if (debounceTime > 0) {
      inDebounce = true;
      _debounceTimer?.cancel();
      _debounceTimer = Timer(
        Duration(milliseconds: (debounceTime * 1000).round()),
        () {
          inDebounce = false;
          notifyListeners();
        },
      );
    }

    // Haptic
    if (hapticsEnabled) {
      platform.vibrateDevice();
    }

    // Unlock iOS Safari SpeechSynthesis audio context on first tap
    _ensureTtsUnlocked();

    // Visual press
    if (autoClearVisual) {
      activeButtonId = btnId;
      notifyListeners();
      Future.delayed(const Duration(milliseconds: 200), () {
        if (activeButtonId == btnId) {
          activeButtonId = null;
          notifyListeners();
        }
      });
    }

    final btn = buttons.firstWhere((b) => b.id == btnId, orElse: () => _defaultButton());
    if (!buttons.any((b) => b.id == btnId)) return;

    final idx = btn.phraseIndex;
    final phraseText = (btn.phrases[idx]).trim();
    final displayText = phraseText.isNotEmpty ? phraseText : btn.label;
    final hasAudio = idx < btn.hasAudio.length && btn.hasAudio[idx];

    // Show output bar
    final caption = displayText.isNotEmpty ? displayText : (hasAudio ? '🔊' : '');
    if (caption.isNotEmpty) showOutputBar(caption);

    // Play audio or TTS
    if (hasAudio) {
      _playRecordedAudio(btn.id, idx);
    } else if (phraseText.isNotEmpty) {
      _speakTts(phraseText, btnId);
    }

    // Phrase cycling
    final validSlots = <int>[];
    for (int i = 0; i < 3; i++) {
      if (btn.phrases[i].trim().isNotEmpty ||
          (i < btn.hasAudio.length && btn.hasAudio[i])) {
        validSlots.add(i);
      }
    }
    if (validSlots.length > 1) {
      int next = (idx + 1) % 3;
      int safety = 0;
      while (!validSlots.contains(next) && safety++ < 5) {
        next = (next + 1) % 3;
      }
      btn.phraseIndex = next;
      saveState();
    }

    notifyListeners();
  }

  // ── TTS ──────────────────────────────────────────────────────────
  void _speakTts(String text, String btnId) {
    if (text.isEmpty) return;

    isSpeaking = true;
    playingButtonId = btnId;
    notifyListeners();

    if (kIsWeb) {
      // Web: delegate to the tdTTS JS helper defined in web/index.html.
      platform.ttsSpeak(text, ttsRate, selectedVoiceURI, () {
        if (isSpeaking && playingButtonId == btnId) {
          isSpeaking = false;
          playingButtonId = null;
          notifyListeners();
        }
      });
    } else {
      // Native: apply rate + voice then speak via flutter_tts.
      () async {
        await _tts.setSpeechRate(ttsRate);
        if (selectedVoiceURI.isNotEmpty && voices.isNotEmpty) {
          final match = voices.cast<Map>().firstWhere(
            (v) => (v['name'] ?? '') == selectedVoiceURI,
            orElse: () => <String, dynamic>{},
          );
          if (match.isNotEmpty) {
            await _tts.setVoice({
              'name': match['name'] as String? ?? '',
              'locale': match['locale'] as String? ?? '',
            });
          }
        }
        await _tts.stop();
        await _tts.speak(text);
      }();
    }
  }

  /// Set TTS speaking rate and persist.
  void setTtsRate(double rate) {
    ttsRate = rate.clamp(0.25, 2.0);
    saveState();
    notifyListeners();
  }

  /// Set the selected TTS voice by its URI/name and persist.
  void setTtsVoice(String uri) {
    selectedVoiceURI = uri;
    saveState();
    notifyListeners();
  }

  /// Stop any active speech on all platforms.
  void _stopTts() {
    if (kIsWeb) {
      platform.ttsStop();
    } else {
      _tts.stop();
    }
    isSpeaking = false;
    playingButtonId = null;
  }

  // ── Audio playback ───────────────────────────────────────────────
  Future<void> _playRecordedAudio(String btnId, int phraseIdx) async {
    if (!platform.hasFileAudio) return;

    if (kIsWeb) {
      // Web: use synchronous path lookup + direct JS audio to avoid
      // async gaps that break iOS Safari's user-gesture context.
      final file = platform.audioFilePathSync(btnId, phraseIdx);
      if (!platform.audioFileExistsSync(file)) return;

      isSpeaking = true;
      playingButtonId = btnId;
      notifyListeners();

      final vol = playbackGain.clamp(0.0, 1.0);
      platform.webPlayAudio(file, vol, () {
        if (isSpeaking && playingButtonId == btnId) {
          isSpeaking = false;
          playingButtonId = null;
          notifyListeners();
        }
      });
    } else {
      // Native: use audioplayers as before
      final file = await platform.audioFilePath(btnId, phraseIdx);
      if (!await platform.audioFileExists(file)) return;

      isSpeaking = true;
      playingButtonId = btnId;
      notifyListeners();

      final vol = playbackGain.clamp(0.0, 5.0);
      await _player.setVolume(vol);
      await _player.play(DeviceFileSource(file));
    }
  }

  Future<void> playPreview(String btnId, int phraseIdx) async {
    if (!platform.hasFileAudio) return;

    if (kIsWeb) {
      final file = platform.audioFilePathSync(btnId, phraseIdx);
      if (!platform.audioFileExistsSync(file)) return;
      final vol = playbackGain.clamp(0.0, 1.0);
      platform.webPlayAudio(file, vol, () {});
    } else {
      final file = await platform.audioFilePath(btnId, phraseIdx);
      if (!await platform.audioFileExists(file)) return;
      final vol = playbackGain.clamp(0.0, 5.0);
      await _player.setVolume(vol);
      await _player.play(DeviceFileSource(file));
    }
  }

  // ── Recording ────────────────────────────────────────────────────
  Future<void> toggleRecording(String btnId, int phraseIdx) async {
    if (!platform.hasRecording || _recorder == null) return;
    if (isRecording) {
      await stopRecording();
      return;
    }
    if (!await _recorder.hasPermission()) {
      showOutputBar('Microphone permission denied');
      return;
    }

    _currentRecordingBtnId = btnId;
    _currentRecordingIdx = phraseIdx;

    final path = await platform.audioFilePath(btnId, phraseIdx);

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
      path: path,
    );
    isRecording = true;
    notifyListeners();
  }

  Future<void> stopRecording() async {
    if (_recorder == null) return;
    final path = await _recorder.stop();
    isRecording = false;

    if (path != null && _currentRecordingBtnId != null && _currentRecordingIdx != null) {
      final btn = buttons.firstWhere((b) => b.id == _currentRecordingBtnId, orElse: () => _defaultButton());
      if (buttons.any((b) => b.id == _currentRecordingBtnId)) {
        btn.hasAudio[_currentRecordingIdx!] = true;
        // On web, record_web returns a blob URL — store it so playback works.
        platform.storeWebAudioPath(_currentRecordingBtnId!, _currentRecordingIdx!, path);
        saveState();
      }
    }
    _currentRecordingBtnId = null;
    _currentRecordingIdx = null;
    notifyListeners();
  }

  Future<void> deleteRecording(String btnId, int phraseIdx) async {
    final path = await platform.audioFilePath(btnId, phraseIdx);
    await platform.deleteAudioFile(path);
    platform.clearWebAudioPath(btnId, phraseIdx);
    final btn = buttons.firstWhere((b) => b.id == btnId, orElse: () => _defaultButton());
    if (buttons.any((b) => b.id == btnId)) {
      btn.hasAudio[phraseIdx] = false;
      saveState();
    }
    notifyListeners();
  }

  Future<int> getStorageSize() async {
    return platform.getAudioStorageSize();
  }

  Future<void> clearAllAudio() async {
    await platform.clearAllAudioFiles();
    for (final b in buttons) {
      b.hasAudio = [false, false, false];
    }
    saveState();
    notifyListeners();
  }

  String formatBytes(int bytes) {
    if (bytes <= 0) return '0 Bytes';
    const suffixes = ['Bytes', 'KB', 'MB', 'GB'];
    final i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
  }

  // ────────────────────────────────────────────────────────────────
  // OUTPUT BAR
  // ────────────────────────────────────────────────────────────────
  void showOutputBar(String text) {
    outputBarText = text;
    _outputBarTimer?.cancel();
    _outputBarTimer = Timer(const Duration(seconds: 6), () {
      outputBarText = null;
      notifyListeners();
    });
    notifyListeners();
  }

  // ────────────────────────────────────────────────────────────────
  // SCANNING
  // ────────────────────────────────────────────────────────────────
  void startScan() {
    stopScan();
    if (activationMode != ActivationMode.scan ||
        buttons.isEmpty ||
        showSettings ||
        isPositioningMode) {
      return;
    }
    scanIdx = 0;
    notifyListeners();
    _scanTimer = Timer.periodic(
      Duration(milliseconds: (scanInterval * 1000).round()),
      (_) {
        scanIdx = (scanIdx + 1) % buttons.length;
        if (scanClearDebounce && inDebounce) {
          _debounceTimer?.cancel();
          inDebounce = false;
        }
        if (scanAnnounce) {
          final label = buttons[scanIdx].label;
          if (label.isNotEmpty && !isSpeaking) {
            // Use the unified TTS path so scan announce works on web too
            _speakTts(label, buttons[scanIdx].id);
          }
        }
        final scanLabel = buttons[scanIdx].label;
        if (scanLabel.isNotEmpty && !isSpeaking) {
          showOutputBar(scanLabel);
        }
        notifyListeners();
      },
    );
  }

  void stopScan() {
    _scanTimer?.cancel();
    _scanTimer = null;
  }

  void activateScanTarget() {
    if (buttons.isEmpty) return;
    final btn = buttons[scanIdx % buttons.length];
    activateButton(btn.id);
  }

  // ────────────────────────────────────────────────────────────────
  // AUTO GRID
  // ────────────────────────────────────────────────────────────────
  void arrangeGrid(Size canvasSize) {
    final n = buttons.length;
    final isLandscape = canvasSize.width > canvasSize.height;
    List<Offset> positions;
    double scale;

    if (n == 1) {
      positions = [const Offset(50, 50)];
      scale = 1.0;
    } else if (n == 2) {
      positions = isLandscape
          ? [const Offset(26, 50), const Offset(74, 50)]
          : [const Offset(50, 28), const Offset(50, 72)];
      scale = 0.9;
    } else if (n == 3) {
      positions = isLandscape
          ? [const Offset(17, 50), const Offset(50, 50), const Offset(83, 50)]
          : [const Offset(30, 26), const Offset(70, 26), const Offset(50, 74)];
      scale = isLandscape ? 0.70 : 0.82;
    } else {
      positions = [
        const Offset(27, 26),
        const Offset(73, 26),
        const Offset(27, 74),
        const Offset(73, 74),
      ];
      scale = 0.78;
    }

    for (int i = 0; i < positions.length && i < buttons.length; i++) {
      buttons[i].position = positions[i];
      buttons[i].scale = scale;
    }
    saveState();
    notifyListeners();
  }

  // ────────────────────────────────────────────────────────────────
  // SETTINGS HELPERS
  // ────────────────────────────────────────────────────────────────
  void openSettings() {
    stopScan();
    _stopTts();
    _player.stop();
    showSettings = true;
    editingBtnId ??= buttons.isNotEmpty ? buttons.first.id : null;
    notifyListeners();
  }

  void closeSettings() {
    if (isRecording) {
      stopRecording();
    }
    showSettings = false;
    saveState();
    notifyListeners();
  }

  void togglePositioning(bool active) {
    isPositioningMode = active;
    if (active) {
      stopScan();
    } else {
      saveState();
    }
    notifyListeners();
  }

  ScanColorDef get currentScanColor =>
      kScanColors.firstWhere((c) => c.name == scanColor, orElse: () => kScanColors[0]);

  @override
  void dispose() {
    _scanTimer?.cancel();
    _debounceTimer?.cancel();
    _outputBarTimer?.cancel();
    _player.dispose();
    if (_recorder != null) {
      try { _recorder.dispose(); } catch (_) {}
    }
    _stopTts();
    if (!kIsWeb) _tts.stop();
    super.dispose();
  }
}
