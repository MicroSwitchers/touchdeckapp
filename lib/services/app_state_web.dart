//
// Web-specific platform helpers for TouchDeck.
// Uses dart:js_interop and dart:js_interop_unsafe (both Dart-SDK built-ins,
// no deprecated dart:html or dart:js_util needed).
//
// The JS-side counterpart is window.tdTTS defined in web/index.html.

import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:record/record.dart';

// ─────────────────────────────────────────────────────────────────────────
// Feature flags
// ─────────────────────────────────────────────────────────────────────────

bool get hasFileAudio => true;
bool get hasRecording => true;

// ─────────────────────────────────────────────────────────────────────────
// Haptics — Web Vibration API
// ─────────────────────────────────────────────────────────────────────────

Future<void> vibrateDevice() async {
  try {
    final nav = globalContext['navigator'];
    if (nav != null) (nav as JSObject).callMethodVarArgs('vibrate'.toJS, [50.toJS]);
  } catch (_) {}
}

// ─────────────────────────────────────────────────────────────────────────
// Audio storage — web uses in-memory blob URL map (ephemeral per session)
// ─────────────────────────────────────────────────────────────────────────

/// Maps 'btnId_idx' → blob URL returned by record_web after stop().
final Map<String, String> _webAudioPaths = {};

AudioRecorder createRecorder() => AudioRecorder();

/// Returns the recorded blob URL for this button/phrase, or '' if none.
Future<String> audioFilePath(String btnId, int idx) async =>
    _webAudioPaths['${btnId}_$idx'] ?? '';

/// A path is valid if it's a non-empty blob (or data) URL we recorded.
Future<bool> audioFileExists(String path) async =>
    path.isNotEmpty && _webAudioPaths.containsValue(path);

/// Store the blob URL returned by record_web when a recording finishes.
void storeWebAudioPath(String btnId, int idx, String blobUrl) {
  _webAudioPaths['${btnId}_$idx'] = blobUrl;
}

/// Discard the stored blob URL for a deleted recording.
void clearWebAudioPath(String btnId, int idx) {
  _webAudioPaths.remove('${btnId}_$idx');
}

Future<void> deleteAudioFile(String path) async {
  _webAudioPaths.removeWhere((_, v) => v == path);
}

Future<int> getAudioStorageSize() async => 0;

Future<void> clearAllAudioFiles() async {
  _webAudioPaths.clear();
}

// ─────────────────────────────────────────────────────────────────────────
// TTS — delegates to window.tdTTS JS helper (see web/index.html)
// ─────────────────────────────────────────────────────────────────────────

/// Pending Dart callback to fire when the current utterance ends.
void Function()? _webTtsOnComplete;

bool _callbackRegistered = false;

/// Register window.tdTTSDone as a Dart callback bridge.
/// Must be called once at app startup.
void initWebTtsCallback() {
  if (_callbackRegistered) return;
  _callbackRegistered = true;
  globalContext['tdTTSDone'] = () {
    final cb = _webTtsOnComplete;
    _webTtsOnComplete = null;
    cb?.call();
  }.toJS;
}

/// Unlock the iOS Safari SpeechSynthesis audio context.
/// MUST be called synchronously inside a user-gesture handler.
void unlockTtsForMobileBrowser(dynamic ignored) {
  try {
    final tts = globalContext['tdTTS'];
    if (tts != null) (tts as JSObject).callMethodVarArgs('unlock'.toJS, []);
  } catch (_) {}
}

/// Speak [text] at [rate] using the voice identified by [voiceURI].
/// Passes the voiceURI to JS so it can select the matching SpeechSynthesisVoice.
/// Fires [onComplete] when the utterance finishes.
void ttsSpeak(String text, double rate, String voiceURI, void Function() onComplete) {
  _webTtsOnComplete = onComplete;
  try {
    final tts = globalContext['tdTTS'];
    if (tts != null) {
      (tts as JSObject).callMethodVarArgs('speak'.toJS, [text.toJS, rate.toJS, voiceURI.toJS]);
    } else {
      // tdTTS not available — complete immediately so the app doesn't hang
      _webTtsOnComplete = null;
      onComplete();
    }
  } catch (_) {
    _webTtsOnComplete = null;
    onComplete();
  }
}

/// Returns the list of available SpeechSynthesisVoices from the browser.
/// Each entry has keys: name, uri, lang, local (string 'true'/'false').
Future<List<Map<String, dynamic>>> getWebVoices() async {
  try {
    final tts = globalContext['tdTTS'];
    if (tts == null) return [];
    final jsResult = (tts as JSObject).callMethodVarArgs('getVoices'.toJS, []);
    if (jsResult == null) return [];
    final jsonStr = (jsResult as JSString).toDart;
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  } catch (_) {
    return [];
  }
}

/// Stop any active speech and discard the pending callback.
void ttsStop() {
  _webTtsOnComplete = null;
  try {
    final tts = globalContext['tdTTS'];
    if (tts != null) (tts as JSObject).callMethodVarArgs('stop'.toJS, []);
  } catch (_) {}
}
