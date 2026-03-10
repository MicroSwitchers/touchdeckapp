import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// Conditional imports for non-web platforms
import 'app_state_io.dart' if (dart.library.html) 'app_state_web.dart' as platform;

import '../constants.dart';
import '../models/app_button.dart';

// ── Guard mode enum ──────────────────────────────────────────────────────
enum GuardMode { hold, taps, off }

class AppState extends ChangeNotifier {
  /// Public notify helper so UI code can trigger rebuilds.
  void notify() => notifyListeners();

  // ── Button data ──────────────────────────────────────────────────
  List<AppButton> buttons = [];
  String? editingBtnId;

  // ── Save slots (global — not per-slot) ───────────────────────────
  int currentSlot = 0;
  List<String> slotNames = ['Slot 1', 'Slot 2', 'Slot 3'];
  // ── Global settings ──────────────────────────────────────────────
  ActivationMode activationMode = ActivationMode.press;
  LabelPosition labelPos = LabelPosition.on;
  bool hapticsEnabled = true;
  bool audioCueEnabled = true;
  bool touchTargetScreen = false; // false = button, true = whole screen
  double debounceTime = 0;
  double playbackGain = 40.0;
  double ttsVolume = 0.5;
  double scanInterval = 2.0;
  String scanColor = 'Yellow';
  bool scanTick = true;
  bool scanAnnounce = true;
  bool scanResetOnActivate = true;
  bool scanClickToBegin = true;
  bool scanClickToRestart = true;
  bool scanStopButton = false;
  bool scanAltButton = false;
  String scanAltButtonPhrase = 'Something Else';
  bool scanStopOnSelection = false;
  bool scanConfirmTone = false;
  bool scanSubScan = false;
  // ── Adapted switch access ─────────────────────────────────────────
  List<String> switchKeys = ['1', '2', '3', '4'];
  String scanConfirmKey = ' ';
  // ── Setup access key (opens settings via keyboard, bypasses guard) ───
  String settingsKey = 'M'; // default M key — app-wide, not per-profile
  String bgColorName = 'Very Dark'; // background colour choice

  // ── Menu access guard ─────────────────────────────────────────────
  GuardMode guardMode = GuardMode.hold;
  double guardHoldSeconds = 3.0;
  int guardTapCount = 3;

  // ── Display ──────────────────────────────────────────────────────
  bool isFullscreen = false;

  // ── Positioning ──────────────────────────────────────────────────
  bool isPositioningMode = false;
  Offset outputBarPos = const Offset(50, 92);
  double outputBarScale = 1.0;
  bool showOutputBarInPositioning = true;

  /// Resolved background colour from the user's chosen preset.
  Color get backgroundColor => kBgColors
      .firstWhere((b) => b.name == bgColorName, orElse: () => kBgColors[4])
      .color;

  // ── Runtime state (not persisted) ────────────────────────────────
  /// Becomes true once init() has finished loading state from prefs.
  bool isInitialized = false;
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
  bool _scanPaused = false;
  bool get scanPaused => _scanPaused;
  // ── Sub-scan state ────────────────────────────────────────────────
  bool _inSubScan = false;
  String? _subScanBtnId;
  int _subScanPhraseIdx = 0;
  List<int> _subScanValidSlots = [];
  // ── Scan confirmed flash (not persisted) ─────────────────────────
  String? _scanConfirmedBtnId;
  String? get scanConfirmedBtnId => _scanConfirmedBtnId;
  // ── Scan audio-wait flag ───────────────────────────────────────
  // True when the scan timer has fired and started an announcement;
  // the next tick is deferred until the announcement finishes.
  bool _scanWaitingForAudio = false;
  bool get inSubScan => _inSubScan;
  String? get subScanBtnId => _subScanBtnId;
  int get subScanPhraseIdx => _subScanPhraseIdx;
  List<int> get subScanValidSlots => List.unmodifiable(_subScanValidSlots);
  int get _altSlot  => buttons.length;
  int get _stopSlot => buttons.length + (scanAltButton ? 1 : 0);
  bool get scanStopHighlighted => scanStopButton && scanIdx == _stopSlot;
  bool get scanAltHighlighted  => scanAltButton  && scanIdx == _altSlot;
  int _scanAltActivateCount = 0;
  int get scanAltActivateCount => _scanAltActivateCount;
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

  AppState([SharedPreferences? prefs]) : _prefs = prefs;

  // ────────────────────────────────────────────────────────────────
  // INIT
  // ────────────────────────────────────────────────────────────────
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();

    // Load global slot metadata (not slot-prefixed).
    currentSlot = _prefs!.getInt('activeSlot') ?? 0;
    slotNames = [
      _prefs!.getString('slotName_0') ?? 'Slot 1',
      _prefs!.getString('slotName_1') ?? 'Slot 2',
      _prefs!.getString('slotName_2') ?? 'Slot 3',
    ];

    // Create recorder only on non-web platforms
    if (platform.hasRecording) {
      _recorder = platform.createRecorder();
    }

    // Load app-wide settings first (guard, TTS, fullscreen, setup key, volume).
    await _loadGlobalSettings();
    await _initTts();
    await _loadState();
    // Restore persisted audio recordings for the active slot (web only —
    // native recordings live as files and are referenced by path).
    if (kIsWeb) await _loadWebAudioForSlot(currentSlot);

    _player.onPlayerComplete.listen((_) {
      isSpeaking = false;
      playingButtonId = null;
      _onScanSpeechOrAudioComplete();
      notifyListeners();
    });

    isInitialized = true;
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
    await _tts.setVolume(ttsVolume);
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
      _onScanSpeechOrAudioComplete();
      notifyListeners();
    });

    _tts.setErrorHandler((msg) {
      isSpeaking = false;
      playingButtonId = null;
      _onScanSpeechOrAudioComplete();
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

  /// Encode all current settings + buttons into a plain map ready for
  /// jsonEncode. This is the canonical per-slot serialisation format.
  /// Per-profile serialisation. App-wide settings (guard, TTS, fullscreen,
  /// setup key, volume boost) are NOT stored here — see [saveGlobalSettings].
  Map<String, dynamic> _toStateMap() {
    return {
      'buttons': AppButton.encodeList(buttons),
      'activationMode': activationMode.name,
      'labelPos': labelPos.name,
      'hapticsEnabled': hapticsEnabled,
      'audioCueEnabled': audioCueEnabled,
      'touchTargetScreen': touchTargetScreen,
      'debounceTime': debounceTime,
      'scanInterval': scanInterval,
      'scanColor': scanColor,
      'scanTick': scanTick,
      'scanAnnounce': scanAnnounce,
      'scanResetOnActivate': scanResetOnActivate,
      'scanClickToBegin': scanClickToBegin,
      'scanClickToRestart': scanClickToRestart,
      'scanStopButton': scanStopButton,
      'scanAltButton': scanAltButton,
      'scanAltButtonPhrase': scanAltButtonPhrase,
      'scanStopOnSelection': scanStopOnSelection,
      'scanConfirmTone': scanConfirmTone,
      'scanSubScan': scanSubScan,
      'switchKeys': jsonEncode(switchKeys),
      'scanConfirmKey': scanConfirmKey,
      'outputBarPos': jsonEncode({'x': outputBarPos.dx, 'y': outputBarPos.dy}),
      'outputBarScale': outputBarScale,
      'showOutputBarInPositioning': showOutputBarInPositioning,
      'bgColorName': bgColorName,
      if (editingBtnId != null) 'editingBtnId': editingBtnId,
    };
  }

  /// Restore all settings + buttons from a slot map (produced by [_toStateMap]).
  void _fromStateMap(Map<String, dynamic> m) {
    final btnJson = m['buttons'] as String?;
    if (btnJson != null) {
      try {
        buttons = AppButton.decodeList(btnJson);
      } catch (_) {
        buttons = [_defaultButton()];
      }
    } else {
      buttons = [_defaultButton()];
    }

    activationMode = ActivationMode.values.firstWhere(
      (v) => v.name == (m['activationMode'] as String? ?? 'press'),
      orElse: () => ActivationMode.press,
    );
    labelPos = LabelPosition.values.firstWhere(
      (l) => l.name == (m['labelPos'] as String? ?? 'on'),
      orElse: () => LabelPosition.on,
    );
    hapticsEnabled = m['hapticsEnabled'] as bool? ?? true;
    audioCueEnabled = m['audioCueEnabled'] as bool? ?? true;
    touchTargetScreen = m['touchTargetScreen'] as bool? ?? false;
    debounceTime = (m['debounceTime'] as num?)?.toDouble() ?? 0.0;
    scanInterval = (m['scanInterval'] as num?)?.toDouble() ?? 2.0;
    scanColor = m['scanColor'] as String? ?? 'Yellow';
    scanTick = m['scanTick'] as bool? ?? true;
    scanAnnounce = m['scanAnnounce'] as bool? ?? true;
    scanResetOnActivate = m['scanResetOnActivate'] as bool? ?? true;
    scanClickToBegin = m['scanClickToBegin'] as bool? ?? true;
    scanClickToRestart = m['scanClickToRestart'] as bool? ?? true;
    scanStopButton = m['scanStopButton'] as bool? ?? false;
    scanAltButton = m['scanAltButton'] as bool? ?? false;
    scanAltButtonPhrase = m['scanAltButtonPhrase'] as String? ?? 'Something Else';
    scanStopOnSelection = m['scanStopOnSelection'] as bool? ?? false;
    scanConfirmTone = m['scanConfirmTone'] as bool? ?? false;
    scanSubScan = m['scanSubScan'] as bool? ?? false;

    final switchKeysJson = m['switchKeys'] as String?;
    if (switchKeysJson != null) {
      try {
        final list = (jsonDecode(switchKeysJson) as List).cast<String>();
        switchKeys = List.generate(4, (i) => i < list.length ? list[i] : '');
      } catch (_) {
        switchKeys = ['1', '2', '3', '4'];
      }
    } else {
      switchKeys = ['1', '2', '3', '4'];
    }

    scanConfirmKey = m['scanConfirmKey'] as String? ?? ' ';

    final obpJson = m['outputBarPos'] as String?;
    if (obpJson != null) {
      try {
        final mp = jsonDecode(obpJson) as Map;
        outputBarPos = Offset(
            (mp['x'] as num).toDouble(), (mp['y'] as num).toDouble());
      } catch (_) {}
    }
    outputBarScale = (m['outputBarScale'] as num?)?.toDouble() ?? 1.0;
    showOutputBarInPositioning = m['showOutputBarInPositioning'] as bool? ?? true;
    bgColorName = m['bgColorName'] as String? ?? 'Very Dark';

    editingBtnId = m['editingBtnId'] as String?;
    if (editingBtnId != null && !buttons.any((b) => b.id == editingBtnId)) {
      editingBtnId = buttons.isNotEmpty ? buttons.first.id : null;
    }

    if (buttons.length > 1) touchTargetScreen = false;
  }

  /// Read the legacy flat-key format (pre-slots) — used only for one-time
  /// migration of existing slot-0 data on first launch after upgrade.
  void _loadLegacyState(SharedPreferences p) {
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
    playbackGain = p.getDouble('playbackGain') ?? 40.0;
    scanInterval = p.getDouble('scanInterval') ?? 2.0;
    scanColor = p.getString('scanColor') ?? 'Yellow';
    scanTick = p.getBool('scanTick') ?? true;
    scanAnnounce = p.getBool('scanAnnounce') ?? true;
    scanResetOnActivate = p.getBool('scanResetOnActivate') ?? true;
    scanClickToBegin = p.getBool('scanClickToBegin') ?? true;
    scanClickToRestart = p.getBool('scanClickToRestart') ?? true;
    scanStopButton = p.getBool('scanStopButton') ?? false;
    scanAltButton = p.getBool('scanAltButton') ?? false;
    scanAltButtonPhrase = p.getString('scanAltButtonPhrase') ?? 'Something Else';
    scanStopOnSelection = p.getBool('scanStopOnSelection') ?? false;
    scanConfirmTone = p.getBool('scanConfirmTone') ?? false;
    scanSubScan = p.getBool('scanSubScan') ?? false;
    final switchKeysJson = p.getString('switchKeys');
    if (switchKeysJson != null) {
      try {
        final list = (jsonDecode(switchKeysJson) as List).cast<String>();
        switchKeys = List.generate(4, (i) => i < list.length ? list[i] : '');
      } catch (_) {
        switchKeys = ['1', '2', '3', '4'];
      }
    } else {
      switchKeys = ['1', '2', '3', '4'];
    }
    scanConfirmKey = p.getString('scanConfirmKey') ?? ' ';
    settingsKey = p.getString('settingsKey') ?? '';
    selectedVoiceURI = p.getString('selectedVoiceURI') ?? '';
    ttsRate = p.getDouble('ttsRate') ?? 1.0;
    ttsVolume = p.getDouble('ttsVolume') ?? 0.5;
    final obpJson = p.getString('outputBarPos');
    if (obpJson != null) {
      try {
        final mp = jsonDecode(obpJson) as Map;
        outputBarPos = Offset(
          (mp['x'] as num).toDouble(),
          (mp['y'] as num).toDouble(),
        );
      } catch (_) {}
    }
    outputBarScale = p.getDouble('outputBarScale') ?? 1.0;
    showOutputBarInPositioning = p.getBool('showOutputBarInPositioning') ?? true;
    bgColorName = p.getString('bgColorName') ?? 'Very Dark';
    guardMode = GuardMode.values.firstWhere(
      (m) => m.name == (p.getString('guardMode') ?? 'hold'),
      orElse: () => GuardMode.hold,
    );
    guardHoldSeconds = p.getDouble('guardHoldSeconds') ?? 3.0;
    guardTapCount = p.getInt('guardTapCount') ?? 3;
    isFullscreen = p.getBool('isFullscreen') ?? false;
    _applyFullscreen();

    editingBtnId = p.getString('editingBtnId');
    if (editingBtnId != null && !buttons.any((b) => b.id == editingBtnId)) {
      editingBtnId = buttons.isNotEmpty ? buttons.first.id : null;
    }

    if (buttons.length > 1) touchTargetScreen = false;
  }

  Future<void> _loadState() async {
    final p = _prefs!;
    // Try to load this slot's JSON blob.
    final slotJson = p.getString('slot_${currentSlot}_state');
    if (slotJson != null) {
      try {
        _fromStateMap(jsonDecode(slotJson) as Map<String, dynamic>);
        return;
      } catch (_) {}
    }
    // Slot 0 migration: read the legacy flat-key format and immediately
    // re-save in the new format so future launches use the JSON path.
    if (currentSlot == 0) {
      _loadLegacyState(p);
      await saveState();
    } else {
      // Empty new slot: reset every setting to its default.
      _fromStateMap({});
    }
  }

  Future<void> saveState() async {
    final p = _prefs;
    if (p == null) return; // guard: init not yet complete
    await p.setString('slot_${currentSlot}_state', jsonEncode(_toStateMap()));
  }

  /// Persist app-wide settings (shared across all profiles).
  /// Call instead of [saveState] when modifying global settings.
  Future<void> saveGlobalSettings() async {
    final p = _prefs;
    if (p == null) return;
    await p.setString('global_settingsKey', settingsKey);
    await p.setString('global_guardMode', guardMode.name);
    await p.setDouble('global_guardHoldSeconds', guardHoldSeconds);
    await p.setInt('global_guardTapCount', guardTapCount);
    await p.setBool('global_isFullscreen', isFullscreen);
    await p.setDouble('global_ttsRate', ttsRate);
    await p.setDouble('global_ttsVolume', ttsVolume);
    await p.setString('global_selectedVoiceURI', selectedVoiceURI);
    await p.setDouble('global_playbackGain', playbackGain);
  }

  /// Load app-wide settings from global SharedPreferences keys.
  /// On the first launch after this refactor, migrates values from the
  /// existing slot-0 JSON (or legacy flat keys) so nothing is lost.
  Future<void> _loadGlobalSettings() async {
    final p = _prefs!;
    // Migration sentinel: if global_settingsKey has never been saved,
    // this is the first launch after the refactor — migrate existing data.
    if (!p.containsKey('global_settingsKey')) {
      // Preferred source: slot_0_state JSON (most users will have this).
      final slot0Json = p.getString('slot_0_state');
      if (slot0Json != null) {
        try {
          final m = jsonDecode(slot0Json) as Map<String, dynamic>;
          settingsKey      = m['settingsKey']    as String? ?? 'M';
          guardMode        = GuardMode.values.firstWhere(
            (v) => v.name == (m['guardMode'] as String? ?? 'hold'),
            orElse: () => GuardMode.hold,
          );
          guardHoldSeconds = (m['guardHoldSeconds'] as num?)?.toDouble() ?? 3.0;
          guardTapCount    = m['guardTapCount']    as int?    ?? 3;
          isFullscreen     = m['isFullscreen']     as bool?   ?? false;
          ttsRate          = (m['ttsRate']          as num?)?.toDouble() ?? 1.0;
          ttsVolume        = (m['ttsVolume']        as num?)?.toDouble() ?? 0.5;
          selectedVoiceURI = m['selectedVoiceURI'] as String? ?? '';
          playbackGain     = (m['playbackGain']     as num?)?.toDouble() ?? 40.0;
          await saveGlobalSettings();
          _applyFullscreen();
          return;
        } catch (_) {}
      }
      // Fall back: legacy flat keys (pre-slot era) or plain defaults.
      settingsKey      = p.getString('settingsKey')      ?? 'M';
      guardMode        = GuardMode.values.firstWhere(
        (v) => v.name == (p.getString('guardMode') ?? 'hold'),
        orElse: () => GuardMode.hold,
      );
      guardHoldSeconds = p.getDouble('guardHoldSeconds') ?? 3.0;
      guardTapCount    = p.getInt('guardTapCount')       ?? 3;
      isFullscreen     = p.getBool('isFullscreen')       ?? false;
      ttsRate          = p.getDouble('ttsRate')          ?? 1.0;
      ttsVolume        = p.getDouble('ttsVolume')        ?? 0.5;
      selectedVoiceURI = p.getString('selectedVoiceURI') ?? '';
      playbackGain     = p.getDouble('playbackGain')     ?? 40.0;
      await saveGlobalSettings();
      _applyFullscreen();
      return;
    }
    // Normal path: read from global_* keys.
    settingsKey      = p.getString('global_settingsKey')      ?? 'M';
    guardMode        = GuardMode.values.firstWhere(
      (v) => v.name == (p.getString('global_guardMode') ?? 'hold'),
      orElse: () => GuardMode.hold,
    );
    guardHoldSeconds = p.getDouble('global_guardHoldSeconds') ?? 3.0;
    guardTapCount    = p.getInt('global_guardTapCount')       ?? 3;
    isFullscreen     = p.getBool('global_isFullscreen')       ?? false;
    ttsRate          = p.getDouble('global_ttsRate')          ?? 1.0;
    ttsVolume        = p.getDouble('global_ttsVolume')        ?? 0.5;
    selectedVoiceURI = p.getString('global_selectedVoiceURI') ?? '';
    playbackGain     = p.getDouble('global_playbackGain')     ?? 40.0;
    _applyFullscreen();
  }

  // ── Web audio persistence (per-slot) ─────────────────────────────

  /// Save a single recorded blob URL as base64 in SharedPreferences so
  /// it survives page reloads and slot switches.
  Future<void> _persistWebAudio(
      String btnId, int phraseIdx, String blobUrl) async {
    if (!kIsWeb) return;
    final b64 = await platform.audioBlobToBase64(blobUrl);
    if (b64 != null && b64.isNotEmpty) {
      await _prefs!.setString(
          'slot_${currentSlot}_audio_${btnId}_$phraseIdx', b64);
    }
  }

  /// Restore all persisted audio recordings for [slot] into the in-memory
  /// blob-URL map so they are ready for playback.
  Future<void> _loadWebAudioForSlot(int slot) async {
    if (!kIsWeb) return;
    final prefix = 'slot_${slot}_audio_';
    final keys = _prefs!.getKeys().where((k) => k.startsWith(prefix)).toList();
    for (final key in keys) {
      final rest = key.substring(prefix.length); // '<btnId>_<phraseIdx>'
      final lastUnderscore = rest.lastIndexOf('_');
      if (lastUnderscore < 0) continue;
      final btnId = rest.substring(0, lastUnderscore);
      final phraseIdx = int.tryParse(rest.substring(lastUnderscore + 1));
      if (phraseIdx == null) continue;
      final b64 = _prefs!.getString(key);
      if (b64 == null || b64.isEmpty) continue;
      final blobUrl = platform.audioBase64ToBlobUrl(b64);
      if (blobUrl == null || blobUrl.isEmpty) continue;
      platform.storeWebAudioPath(btnId, phraseIdx, blobUrl);
      // Ensure the hasAudio flag is consistent with the persisted recording.
      final btnIdx = buttons.indexWhere((b) => b.id == btnId);
      if (btnIdx >= 0 && phraseIdx < buttons[btnIdx].hasAudio.length) {
        buttons[btnIdx].hasAudio[phraseIdx] = true;
      }
    }
  }


  AppButton _defaultButton([String? id]) => AppButton(
        id: id ?? const Uuid().v4(),
        color: kColors[0],
        scale: 1.2,
        position: const Offset(50, 50),
      );

  // ────────────────────────────────────────────────────────────────
  // SLOT MANAGEMENT
  // ────────────────────────────────────────────────────────────────

  /// Switch to [newSlot] (0–2): saves the current slot, clears runtime audio
  /// state, then loads the new slot's settings and audio recordings.
  Future<void> switchToSlot(int newSlot) async {
    if (newSlot == currentSlot || newSlot < 0 || newSlot > 2) return;

    // Stop scanning and any active audio.
    stopScan();
    _stopTts();
    if (kIsWeb) {
      platform.webStopAudio();
    } else {
      try { await _player.stop(); } catch (_) {}
    }
    isSpeaking = false;
    playingButtonId = null;

    // Save current slot before leaving it.
    await saveState();

    // Switch.
    currentSlot = newSlot;
    await _prefs!.setInt('activeSlot', currentSlot);

    // Clear in-memory web audio paths — they belong to the old slot.
    if (kIsWeb) platform.clearAllWebAudioPaths();

    // Load new slot.
    await _loadState();
    if (kIsWeb) await _loadWebAudioForSlot(currentSlot);

    // Restart scan if the new slot uses scan activation.
    if (activationMode == ActivationMode.scan) startScan();

    notifyListeners();
  }

  /// Update the display name of [slot] and persist it globally.
  Future<void> setSlotName(int slot, String name) async {
    if (slot < 0 || slot > 2) return;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    slotNames[slot] = trimmed;
    await _prefs!.setString('slotName_$slot', trimmed);
    notifyListeners();
  }

  // ────────────────────────────────────────────────────────────────
  // BUTTON MANAGEMENT
  // ────────────────────────────────────────────────────────────────
  void addButton() {
    if (buttons.length >= 4) return;

    // Find the point in percentage space that maximises the minimum distance
    // to any existing button — i.e. the most open area on screen.
    Offset bestPos = const Offset(50, 50);
    double bestDist = -1;
    for (double x = 10; x <= 90; x += 5) {
      for (double y = 10; y <= 90; y += 5) {
        final candidate = Offset(x, y);
        double minDist = double.infinity;
        for (final b in buttons) {
          final d = (b.position - candidate).distance;
          if (d < minDist) minDist = d;
        }
        if (minDist > bestDist) {
          bestDist = minDist;
          bestPos = candidate;
        }
      }
    }

    final btn = AppButton(
      id: const Uuid().v4(),
      color: kColors[buttons.length % kColors.length],
      position: bestPos,
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

  void setBgColor(String name) {
    bgColorName = name;
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

  void addPhrase(String id) {
    final idx = buttons.indexWhere((b) => b.id == id);
    if (idx == -1) return;
    final btn = buttons[idx];
    if (btn.phrases.length >= 10) return;
    btn.phrases.add('');
    btn.hasAudio.add(false);
    saveState();
    notifyListeners();
  }

  void removePhrase(String id, int phraseIdx) {
    final idx = buttons.indexWhere((b) => b.id == id);
    if (idx == -1) return;
    final btn = buttons[idx];
    if (btn.phrases.length <= 1) return;
    btn.phrases.removeAt(phraseIdx);
    if (phraseIdx < btn.hasAudio.length) btn.hasAudio.removeAt(phraseIdx);
    if (btn.phraseIndex >= btn.phrases.length) {
      btn.phraseIndex = btn.phrases.length - 1;
    }
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
    final hasAudio = idx < btn.hasAudio.length && btn.hasAudio[idx];

    // Show output bar — phrase caption only (never the button label/title);
    // for audio-only buttons clear any lingering text so the waveform shows.
    if (phraseText.isNotEmpty) {
      showOutputBar(phraseText);
    } else if (hasAudio) {
      outputBarText = null;
      _outputBarTimer?.cancel();
      notifyListeners();
    }

    // Play audio or TTS
    if (hasAudio) {
      _playRecordedAudio(btn.id, idx);
    } else if (phraseText.isNotEmpty) {
      _speakTts(phraseText, btnId);
    }

    // Phrase cycling
    final validSlots = <int>[];
    for (int i = 0; i < btn.phrases.length; i++) {
      if (btn.phrases[i].trim().isNotEmpty ||
          (i < btn.hasAudio.length && btn.hasAudio[i])) {
        validSlots.add(i);
      }
    }
    if (validSlots.length > 1) {
      int next = (idx + 1) % btn.phrases.length;
      int safety = 0;
      while (!validSlots.contains(next) && safety++ < btn.phrases.length) {
        next = (next + 1) % btn.phrases.length;
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
      platform.ttsSpeak(text, ttsRate, ttsVolume, selectedVoiceURI, () {
        if (isSpeaking && playingButtonId == btnId) {
          isSpeaking = false;
          playingButtonId = null;
          _onScanSpeechOrAudioComplete();
          notifyListeners();
        }
      });
    } else {
      // Native: apply rate + voice then speak via flutter_tts.
      () async {
        await _tts.setSpeechRate(ttsRate);
        await _tts.setVolume(ttsVolume);
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

  /// Set TTS speaking rate and persist (app-wide).
  void setTtsRate(double rate) {
    ttsRate = rate.clamp(0.25, 2.0);
    saveGlobalSettings();
    notifyListeners();
  }

  /// Set TTS volume and persist (app-wide).
  void setTtsVolume(double vol) {
    ttsVolume = vol.clamp(0.0, 1.0);
    saveGlobalSettings();
    notifyListeners();
  }

  /// Set the selected TTS voice by its URI/name and persist (app-wide).
  void setTtsVoice(String uri) {
    selectedVoiceURI = uri;
    saveGlobalSettings();
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
      final file = platform.audioFilePathSync(btnId, phraseIdx, currentSlot);
      if (!platform.audioFileExistsSync(file)) return;

      isSpeaking = true;
      playingButtonId = btnId;
      notifyListeners();

      final vol = playbackGain.clamp(0.0, 40.0);
      platform.webPlayAudio(file, vol, () {
        if (isSpeaking && playingButtonId == btnId) {
          isSpeaking = false;
          playingButtonId = null;
          _onScanSpeechOrAudioComplete();
          notifyListeners();
        }
      });
    } else {
      // Native: use audioplayers as before
      final file = await platform.audioFilePath(btnId, phraseIdx, currentSlot);
      if (!await platform.audioFileExists(file)) return;

      isSpeaking = true;
      playingButtonId = btnId;
      notifyListeners();

      final vol = playbackGain.clamp(0.0, 40.0);
      await _player.setVolume(vol.clamp(0.0, 1.0));
      await _player.play(DeviceFileSource(file));
    }
  }

  Future<void> playPreview(String btnId, int phraseIdx) async {
    if (!platform.hasFileAudio) return;

    if (kIsWeb) {
      final file = platform.audioFilePathSync(btnId, phraseIdx, currentSlot);
      if (!platform.audioFileExistsSync(file)) return;
      final vol = playbackGain.clamp(0.0, 40.0);
      platform.webPlayAudio(file, vol, () {});
    } else {
      final file = await platform.audioFilePath(btnId, phraseIdx, currentSlot);
      if (!await platform.audioFileExists(file)) return;
      final vol = playbackGain.clamp(0.0, 40.0);
      await _player.setVolume(vol.clamp(0.0, 1.0));
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

    // On web/iOS: synchronously cancel TTS and block _touchPrime so the iOS
    // audio session is free to switch to record mode when getUserMedia fires.
    if (kIsWeb) {
      platform.prepareWebRecording();
      // Give iOS ~150ms to finish any lingering TTS/audio before we request mic.
      await Future.delayed(const Duration(milliseconds: 150));
    }

    if (!await _recorder.hasPermission()) {
      if (kIsWeb) platform.cleanupWebRecording();
      showOutputBar('Microphone permission denied');
      return;
    }

    _currentRecordingBtnId = btnId;
    _currentRecordingIdx = phraseIdx;

    final path = await platform.audioFilePath(btnId, phraseIdx, currentSlot);

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
        // Guard: hasAudio list may be shorter than phrases if data was migrated.
        while (btn.hasAudio.length <= _currentRecordingIdx!) {
          btn.hasAudio.add(false);
        }
        btn.hasAudio[_currentRecordingIdx!] = true;
        // On web, record_web returns a blob URL — store it so playback works.
        platform.storeWebAudioPath(_currentRecordingBtnId!, _currentRecordingIdx!, path);
        // Persist the blob as base64 so it survives page reloads / slot switches.
        await _persistWebAudio(_currentRecordingBtnId!, _currentRecordingIdx!, path);
        saveState();
      }
    }
    _currentRecordingBtnId = null;
    _currentRecordingIdx = null;

    // On web/iOS: re-enable _touchPrime so the next user tap can prime TTS again.
    // Do this after state reset so the UI updates before cleanup runs.
    if (kIsWeb) {
      platform.cleanupWebRecording();
    }

    notifyListeners();
  }

  Future<void> deleteRecording(String btnId, int phraseIdx) async {
    final path = await platform.audioFilePath(btnId, phraseIdx, currentSlot);
    await platform.deleteAudioFile(path);
    platform.clearWebAudioPath(btnId, phraseIdx);
    // Remove the persisted base64 entry for this recording.
    if (kIsWeb) {
      await _prefs!.remove('slot_${currentSlot}_audio_${btnId}_$phraseIdx');
    }
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
    await platform.clearAllAudioFiles(currentSlot);
    // Remove all persisted base64 audio for the current slot.
    if (kIsWeb) {
      final prefix = 'slot_${currentSlot}_audio_';
      for (final key
          in _prefs!.getKeys().where((k) => k.startsWith(prefix)).toList()) {
        await _prefs!.remove(key);
      }
    }
    for (final b in buttons) {
      b.hasAudio = List.filled(b.phrases.length, false);
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
  // Strips control characters and invisible Unicode that render as box-with-X.
  // Covers: C0/C1 controls, soft hyphen (U+00AD), zero-width chars, BOM,
  // replacement character (U+FFFD), and other non-characters (U+FFFE/FFFF).
  static final _badChars = RegExp(
    r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F'
    r'\u00AD'
    r'\u200B\u200C\u200D\u2028\u2029'
    r'\uFEFF\uFFFD\uFFFE\uFFFF]',
  );

  void showOutputBar(String text) {
    final clean = text.replaceAll(_badChars, '').trim();
    outputBarText = clean.isEmpty ? null : clean;
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
    if (scanClickToBegin) {
      _scanPaused = true;
      notifyListeners();
      return;
    }
    _scanPaused = false;
    notifyListeners();
    _startScanTimer();
  }

  // Starts (or restarts) the periodic scan timer without resetting scanIdx.
  void _startScanTimer() {
    _scanTimer?.cancel();
    _scanWaitingForAudio = false;
    _scheduleNextScanTick();
  }

  // Schedules a single one-shot tick after [scanInterval] seconds.
  // Defers immediately if audio is already playing — the completion
  // callback (_onScanSpeechOrAudioComplete) will reschedule.
  void _scheduleNextScanTick() {
    if (isSpeaking) {
      _scanWaitingForAudio = true;
      return;
    }
    _scanTimer = Timer(
      Duration(milliseconds: (scanInterval * 1000).round()),
      _onScanTick,
    );
  }

  // Called by the one-shot timer — advances the scan and announces.
  void _onScanTick() {
    _scanTimer = null;
    if (activationMode != ActivationMode.scan ||
        _scanPaused ||
        showSettings ||
        _inSubScan ||
        buttons.isEmpty) {
      return;
    }

    final total = buttons.length + (scanStopButton ? 1 : 0) + (scanAltButton ? 1 : 0);
    if (total == 0) return;
    scanIdx = (scanIdx + 1) % total;

    if (scanTick) {
      if (kIsWeb) {
        platform.playTick();
      } else {
        SystemSound.play(SystemSoundType.click);
      }
    }

    // Stop button slot
    if (scanStopButton && scanIdx == _stopSlot) {
      if (scanAnnounce && !isSpeaking) _speakTts('Stop', 'scan_stop_btn');
      showOutputBar('Stop');
      notifyListeners();
    // Alt button slot
    } else if (scanAltButton && scanIdx == _altSlot) {
      if (!isSpeaking) _speakTts(scanAltButtonPhrase, 'scan_alt_btn');
      showOutputBar(scanAltButtonPhrase);
      notifyListeners();
    } else {
      if (scanAnnounce) {
        final label = buttons[scanIdx].label;
        if (label.isNotEmpty && !isSpeaking) {
          _speakTts(label, buttons[scanIdx].id);
        }
      }
      showOutputBar(buttons[scanIdx].label);
      notifyListeners();
    }

    // Wait for any active audio (new or pre-existing) before advancing.
    if (isSpeaking) {
      _scanWaitingForAudio = true;
    } else {
      _scheduleNextScanTick();
    }
  }

  // Called from every TTS/audio completion callback.
  // Resumes either the main scan or sub-scan tick chain.
  void _onScanSpeechOrAudioComplete() {
    if (!_scanWaitingForAudio) return;
    if (activationMode != ActivationMode.scan ||
        _scanPaused ||
        showSettings) {
      return;
    }
    _scanWaitingForAudio = false;
    if (_inSubScan) {
      _scheduleNextSubScanTick();
    } else {
      _scheduleNextScanTick();
    }
  }

  void stopScan() {
    _scanTimer?.cancel();
    _scanTimer = null;
    _scanPaused = false;
    _scanWaitingForAudio = false;
    scanIdx = -1; // clear highlight — nothing is selected after stopping
    _exitSubScan();
  }

  void _exitSubScan() {
    _inSubScan = false;
    _subScanBtnId = null;
    _subScanPhraseIdx = 0;
    _subScanValidSlots = [];
  }

  // Brief visual flash to confirm a scan selection.
  void _flashScanConfirm(String btnId) {
    _scanConfirmedBtnId = btnId;
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 650), () {
      if (_scanConfirmedBtnId == btnId) {
        _scanConfirmedBtnId = null;
        notifyListeners();
      }
    });
  }

  // Enters sub-scan mode for [btn], cycling through its valid phrases.
  void _startSubScanTimer(AppButton btn) {
    _scanTimer?.cancel();
    // Build the list of valid phrase slots for this button
    final validSlots = <int>[];
    for (int i = 0; i < btn.phrases.length; i++) {
      if (btn.phrases[i].trim().isNotEmpty ||
          (i < btn.hasAudio.length && btn.hasAudio[i])) {
        validSlots.add(i);
      }
    }
    // Fewer than 2 valid phrases — skip sub-scan, activate directly
    if (validSlots.length < 2) {
      activateButton(btn.id);
      if (scanResetOnActivate) _startScanTimer();
      return;
    }
    _inSubScan = true;
    _subScanBtnId = btn.id;
    _subScanPhraseIdx = 0;
    _subScanValidSlots = validSlots;
    _scanWaitingForAudio = false;
    // Announce first phrase immediately, interrupting any ongoing announcement
    _announceCurrentSubPhrase(btn, force: true);
    notifyListeners();
    // Schedule first advance — wait for the announcement if it started
    if (isSpeaking) {
      _scanWaitingForAudio = true;
    } else {
      _scheduleNextSubScanTick();
    }
  }

  // Schedules the next sub-scan advance (one-shot, audio-aware).
  void _scheduleNextSubScanTick() {
    if (isSpeaking) {
      _scanWaitingForAudio = true;
      return;
    }
    _scanTimer = Timer(
      Duration(milliseconds: (scanInterval * 1000).round()),
      _onSubScanTick,
    );
  }

  // Advances the sub-scan to the next phrase slot.
  void _onSubScanTick() {
    _scanTimer = null;
    if (!_inSubScan) return;
    _subScanPhraseIdx = (_subScanPhraseIdx + 1) % _subScanValidSlots.length;
    if (scanTick) {
      if (kIsWeb) {
        platform.playTick();
      } else {
        SystemSound.play(SystemSoundType.click);
      }
    }
    if (!buttons.any((x) => x.id == _subScanBtnId)) {
      stopScan();
      return;
    }
    final b = buttons.firstWhere((x) => x.id == _subScanBtnId,
        orElse: () => _defaultButton());
    _announceCurrentSubPhrase(b);
    notifyListeners();
    if (isSpeaking) {
      _scanWaitingForAudio = true;
    } else {
      _scheduleNextSubScanTick();
    }
  }

  void _announceCurrentSubPhrase(AppButton btn, {bool force = false}) {
    if (_subScanValidSlots.isEmpty) return;
    final slot = _subScanValidSlots[_subScanPhraseIdx];
    final text = btn.phrases[slot].trim();
    final hasAudio = slot < btn.hasAudio.length && btn.hasAudio[slot];
    if (hasAudio) {
      if (force || !isSpeaking) _playRecordedAudio(btn.id, slot);
      showOutputBar(text.isNotEmpty ? text : '▶ Phrase ${slot + 1}');
    } else if (text.isNotEmpty) {
      if (force || !isSpeaking) _speakTts(text, btn.id);
      showOutputBar(text);
    }
  }

  Future<void> activateScanTarget() async {
    if (buttons.isEmpty) return;
    // Click-to-begin: first switch press starts the scan timer.
    if (_scanPaused) {
      _scanPaused = false;
      notifyListeners();
      // Play a distinct sound to signal scanning has started.
      if (kIsWeb) {
        platform.playScanStartSound();
      } else {
        SystemSound.play(SystemSoundType.click);
        Future.delayed(
          const Duration(milliseconds: 120),
          () => SystemSound.play(SystemSoundType.click),
        );
      }
      _startScanTimer();
      return;
    }
    // Stop button selected: always speak then halt scanning.
    if (scanStopButton && scanIdx == _stopSlot) {
      _speakTts('Stop', 'scan_stop_btn'); // always interrupt & speak
      stopScan();
      notifyListeners();
      return;
    }
    // Alt button selected: always speak phrase and continue scanning.
    if (scanAltButton && scanIdx == _altSlot) {
      _scanAltActivateCount++;
      _speakTts(scanAltButtonPhrase, 'scan_alt_btn'); // always interrupt & speak
      if (scanResetOnActivate) _startScanTimer();
      notifyListeners();
      return;
    }
    // ── Sub-scan: user confirms a phrase within the selected button ──
    if (_inSubScan) {
      final subBtn = buttons.firstWhere((b) => b.id == _subScanBtnId,
          orElse: () => _defaultButton());
      if (!buttons.any((b) => b.id == _subScanBtnId) ||
          _subScanValidSlots.isEmpty) {
        _scanTimer?.cancel();
        _exitSubScan();
        if (scanResetOnActivate) _startScanTimer();
        notifyListeners();
        return;
      }
      final phraseSlot = _subScanValidSlots[_subScanPhraseIdx];
      _scanTimer?.cancel();
      _exitSubScan();
      if (scanConfirmTone) await platform.playConfirmTone();
      // Force the button to play the sub-scanned phrase slot
      subBtn.phraseIndex = phraseSlot;
      activateButton(subBtn.id);
      _flashScanConfirm(subBtn.id);
      if (scanStopOnSelection) {
        stopScan();
        notifyListeners();
        return;
      }
      if (scanResetOnActivate) _startScanTimer();
      return;
    }
    if (scanIdx < 0) {
      // Scan has stopped — restart immediately with one tap (no click-to-begin
      // pause; that only applies on first entry into scan mode).
      if (scanClickToRestart) {
        scanIdx = 0;
        _scanWaitingForAudio = false;
        notifyListeners();
        _startScanTimer();
      }
      return;
    }
    if (scanIdx >= buttons.length + (scanStopButton ? 1 : 0) + (scanAltButton ? 1 : 0)) return;
    final btn = buttons[scanIdx % buttons.length];
    // Sub-scan mode: enter phrase cycling for this button (tone plays on phrase confirm, not here)
    if (scanSubScan) {
      _startSubScanTimer(btn);
      return;
    }
    // Confirmation tone: play and await completion before speaking
    if (scanConfirmTone) {
      await platform.playConfirmTone();
    }
    activateButton(btn.id);
    _flashScanConfirm(btn.id);
    if (scanStopOnSelection) {
      stopScan();
      notifyListeners();
      return;
    }
    // Reset the scan countdown so the user gets a full interval
    // before the scanner moves on — gives time to respond.
    if (scanResetOnActivate) {
      _startScanTimer();
    }
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
      scale = 1.2;
    } else if (n == 2) {
      positions = isLandscape
          ? [const Offset(25, 50), const Offset(75, 50)]
          : [const Offset(50, 27), const Offset(50, 73)];
      scale = 1.0;
    } else if (n == 3) {
      positions = isLandscape
          ? [const Offset(17, 50), const Offset(50, 50), const Offset(83, 50)]
          : [const Offset(30, 25), const Offset(70, 25), const Offset(50, 72)];
      scale = isLandscape ? 0.82 : 0.90;
    } else {
      positions = [
        const Offset(26, 25),
        const Offset(74, 25),
        const Offset(26, 75),
        const Offset(74, 75),
      ];
      scale = 0.85;
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

  Future<void> closeSettings() async {
    if (isRecording) {
      await stopRecording();
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

  // ────────────────────────────────────────────────────────────────
  // FULLSCREEN
  // ────────────────────────────────────────────────────────────────
  void _applyFullscreen() {
    if (kIsWeb) {
      // SystemChrome is a no-op on web — use the browser Fullscreen API.
      platform.setWebFullscreen(isFullscreen);
    } else {
      SystemChrome.setEnabledSystemUIMode(
        isFullscreen ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
      );
    }
  }

  void setFullscreen(bool v) {
    isFullscreen = v;
    _applyFullscreen();
    saveGlobalSettings();
    notifyListeners();
  }

  /// Re-applies the current fullscreen setting — call after navigating back
  /// from any overlay that may have reset the system UI mode.
  void reapplyFullscreen() => _applyFullscreen();

  // ── TTS preview (settings UI) ────────────────────────────────────
  void previewPhraseText(String text) {
    if (text.trim().isEmpty) return;
    _speakTts(text.trim(), '__preview__');
  }

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
