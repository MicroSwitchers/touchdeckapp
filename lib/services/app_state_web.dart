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
// Haptics — Web Vibration API (Android Chrome; iOS Safari does not support it)
// ─────────────────────────────────────────────────────────────────────────

Future<void> vibrateDevice() async {
  try {
    final nav = globalContext['navigator'];
    if (nav != null) {
      // navigator.vibrate(40) — vibrate for 40 ms
      (nav as JSObject).callMethodVarArgs('vibrate'.toJS, [40.toJS]);
    }
  } catch (_) {}
}

// ─────────────────────────────────────────────────────────────────────────
// Audio storage — web uses in-memory blob URL map (ephemeral per session)
// ─────────────────────────────────────────────────────────────────────────

/// Maps 'btnId_idx' → blob URL returned by record_web after stop().
final Map<String, String> _webAudioPaths = {};

AudioRecorder createRecorder() => AudioRecorder();

/// Returns the recorded blob URL for this button/phrase, or '' if none.
Future<String> audioFilePath(String btnId, int idx, [int slot = 0]) async =>
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

Future<void> clearAllAudioFiles([int slot = 0]) async {
  _webAudioPaths.clear();
}

/// Clear all stored blob URL paths (called when switching slots).
/// Does NOT delete audio data from prefs — only clears the in-memory map.
void clearAllWebAudioPaths() {
  _webAudioPaths.clear();
}

/// Convert a blob URL to a base64 data URL via the JS tdAudio.toBase64 helper.
/// Returns null if conversion fails or JS is unavailable.
Future<String?> audioBlobToBase64(String blobUrl) async {
  try {
    final audio = globalContext['tdAudio'];
    if (audio == null) return null;
    final result = (audio as JSObject)
        .callMethodVarArgs('toBase64'.toJS, [blobUrl.toJS]);
    if (result == null) return null;
    final jsStr = await (result as JSPromise<JSString?>).toDart;
    return jsStr?.toDart;
  } catch (_) {
    return null;
  }
}

/// Convert a base64 data URL back to a fresh blob URL via tdAudio.fromBase64.
/// Returns null if conversion fails.
String? audioBase64ToBlobUrl(String base64) {
  try {
    final audio = globalContext['tdAudio'];
    if (audio == null) return null;
    final result = (audio as JSObject)
        .callMethodVarArgs('fromBase64'.toJS, [base64.toJS]);
    if (result == null) return null;
    return (result as JSString).toDart;
  } catch (_) {
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────
// TTS — delegates to window.tdTTS JS helper (see web/index.html)
// ─────────────────────────────────────────────────────────────────────────

/// Pending Dart callback to fire when the current utterance ends.
void Function()? _webTtsOnComplete;

bool _callbackRegistered = false;

/// Register window.tdTTSDone and window.tdAudioDone as Dart callback bridges.
/// Must be called once at app startup.
void initWebTtsCallback() {
  if (_callbackRegistered) return;
  _callbackRegistered = true;
  globalContext['tdTTSDone'] = () {
    final cb = _webTtsOnComplete;
    _webTtsOnComplete = null;
    cb?.call();
  }.toJS;
  globalContext['tdAudioDone'] = () {
    final cb = _webAudioOnComplete;
    _webAudioOnComplete = null;
    cb?.call();
  }.toJS;
}

/// Unlock is now handled at the raw DOM level (touchstart/click)
/// in index.html. This is a no-op kept for API compatibility.
void unlockTtsForMobileBrowser(dynamic ignored) {
  // No-op — global unlock happens at the DOM level
}

/// Speak [text] at [rate] using the voice identified by [voiceURI].
/// Passes the voiceURI to JS so it can select the matching SpeechSynthesisVoice.
/// Fires [onComplete] when the utterance finishes.
void ttsSpeak(String text, double rate, double volume, String voiceURI, void Function() onComplete) {
  _webTtsOnComplete = onComplete;
  try {
    final tts = globalContext['tdTTS'];
    if (tts != null) {
      (tts as JSObject).callMethodVarArgs('speak'.toJS, [text.toJS, rate.toJS, volume.toJS, voiceURI.toJS]);
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

// ─────────────────────────────────────────────────────────────────────────
// Direct JS audio playback — bypasses audioplayers which breaks on iOS
// because its async gaps lose the user-gesture context.
// Uses window.tdAudio defined in web/index.html.
// ─────────────────────────────────────────────────────────────────────────

void Function()? _webAudioOnComplete;

/// Play recorded audio directly via JS <audio> element.
/// [url] is a blob URL from recording. [volume] should be 0.0–1.0.
/// Fires [onComplete] when playback ends.
void webPlayAudio(String url, double volume, void Function() onComplete) {
  _webAudioOnComplete = onComplete;
  try {
    final audio = globalContext['tdAudio'];
    if (audio != null) {
      (audio as JSObject).callMethodVarArgs('play'.toJS, [url.toJS, volume.toJS]);
    } else {
      _webAudioOnComplete = null;
      onComplete();
    }
  } catch (_) {
    _webAudioOnComplete = null;
    onComplete();
  }
}

/// Stop any currently playing recorded audio.
void webStopAudio() {
  _webAudioOnComplete = null;
  try {
    final audio = globalContext['tdAudio'];
    if (audio != null) (audio as JSObject).callMethodVarArgs('stop'.toJS, []);
  } catch (_) {}
}

/// Synchronous path lookup — no async gaps, keeps iOS gesture context.
String audioFilePathSync(String btnId, int idx, [int slot = 0]) =>
    _webAudioPaths['${btnId}_$idx'] ?? '';

/// Synchronous existence check.
bool audioFileExistsSync(String path) =>
    path.isNotEmpty && _webAudioPaths.containsValue(path);

// ─────────────────────────────────────────────────────────────────────────
// Recording coordination — synchronously signal the JS side so it can
// gate _touchPrime and clear TTS state around getUserMedia calls.
// ─────────────────────────────────────────────────────────────────────────

/// Call synchronously BEFORE starting a recording.
/// Cancels any pending TTS and prevents _touchPrime from firing during mic use.
void prepareWebRecording() {
  try {
    final rec = globalContext['tdRecord'];
    if (rec != null) (rec as JSObject).callMethodVarArgs('prepare'.toJS, []);
  } catch (_) {}
}

/// Call AFTER recording is fully stopped.
/// Re-enables _touchPrime so subsequent TTS taps work normally.
void cleanupWebRecording() {
  try {
    final rec = globalContext['tdRecord'];
    if (rec != null) (rec as JSObject).callMethodVarArgs('cleanup'.toJS, []);
  } catch (_) {}
}

// ─────────────────────────────────────────────────────────────────────────
// Fullscreen — uses the browser Fullscreen API
// ─────────────────────────────────────────────────────────────────────────

void setWebFullscreen(bool value) {
  try {
    final doc = globalContext['document'] as JSObject?;
    if (doc == null) return;
    if (value) {
      final docEl = doc['documentElement'] as JSObject?;
      docEl?.callMethodVarArgs('requestFullscreen'.toJS, []);
    } else {
      // Only call exitFullscreen if the document currently has a fullscreen element
      final fullscreenEl = doc['fullscreenElement'];
      if (fullscreenEl != null) {
        doc.callMethodVarArgs('exitFullscreen'.toJS, []);
      }
    }
  } catch (_) {}
}

// ─────────────────────────────────────────────────────────────────────────
// Scan tick sounds — delegates to window.tdTick (see web/index.html)
// ─────────────────────────────────────────────────────────────────────────

void playTick() {
  try {
    final t = globalContext['tdTick'];
    if (t != null) (t as JSObject).callMethodVarArgs('tick'.toJS, []);
  } catch (_) {}
}

void playScanStartSound() {
  try {
    final t = globalContext['tdTick'];
    if (t != null) (t as JSObject).callMethodVarArgs('start'.toJS, []);
  } catch (_) {}
}

// Plays the confirm tone and returns a Future that resolves once it has finished.
// The start() tone: note 1 at 0ms (90ms), note 2 at 85ms (110ms) — total ~280ms.
Future<void> playConfirmTone() async {
  playScanStartSound();
  await Future.delayed(const Duration(milliseconds: 310));
}
