// Native (non-web) platform helpers for TouchDeck.
// File I/O, recording, and vibration are all available here.
// TTS stubs exist for API compatibility but TTS is handled directly by
// flutter_tts in app_state.dart on native platforms.

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:vibration/vibration.dart';

// Fullscreen on native is handled by SystemChrome in app_state.dart.
void setWebFullscreen(bool value) {} // no-op

// Scan tick sounds are handled directly by SystemSound in app_state.dart.
void playTick() {} // no-op
void playScanStartSound() {} // no-op
Future<void> playConfirmTone() async {
  SystemSound.play(SystemSoundType.click);
  await Future.delayed(const Duration(milliseconds: 150));
  SystemSound.play(SystemSoundType.click);
  await Future.delayed(const Duration(milliseconds: 160));
}

// ─────────────────────────────────────────────────────────────────────────
// Feature flags
// ─────────────────────────────────────────────────────────────────────────

bool get hasFileAudio => true;
bool get hasRecording => true;

// ─────────────────────────────────────────────────────────────────────────
// Haptics
// ─────────────────────────────────────────────────────────────────────────

Future<void> vibrateDevice() async {
  try {
    // HapticFeedback uses the Taptic Engine on iOS and the vibrator on Android.
    // It is the most reliable haptic path across both platforms.
    await HapticFeedback.mediumImpact();
  } catch (_) {
    // Fallback for devices where system haptics are unavailable.
    try {
      Vibration.vibrate(duration: 40);
    } catch (_) {}
  }
}

// ─────────────────────────────────────────────────────────────────────────
// File / audio storage
// ─────────────────────────────────────────────────────────────────────────

Future<String> audioFilePath(String btnId, int idx, [int slot = 0]) async {
  final dir = await getApplicationDocumentsDirectory();
  // Slot 0 keeps the original filename format for backward compatibility.
  if (slot == 0) {
    return '${dir.path}/td_audio_${btnId}_$idx.m4a';
  }
  return '${dir.path}/td_audio_s${slot}_${btnId}_$idx.m4a';
}

Future<bool> audioFileExists(String path) async => File(path).exists();

Future<void> deleteAudioFile(String path) async {
  final f = File(path);
  if (await f.exists()) await f.delete();
}

Future<int> getAudioStorageSize() async {
  final dir = await getApplicationDocumentsDirectory();
  int total = 0;
  for (final f in dir.listSync()) {
    if (f is File && f.path.contains('td_audio_')) {
      total += await f.length();
    }
  }
  return total;
}

Future<void> clearAllAudioFiles([int slot = 0]) async {
  final dir = await getApplicationDocumentsDirectory();
  for (final f in dir.listSync()) {
    if (f is! File) continue;
    final name = f.path.split(Platform.pathSeparator).last;
    if (slot == 0) {
      // Slot-0 files use legacy format: td_audio_<btnId>_<idx>.m4a
      // (no s<N>_ prefix). Keep any slotted files (s1_, s2_, …) untouched.
      if (name.startsWith('td_audio_') &&
          !RegExp(r'^td_audio_s\d+_').hasMatch(name)) {
        await f.delete();
      }
    } else {
      if (name.startsWith('td_audio_s${slot}_')) await f.delete();
    }
  }
}

/// No-op: web audio paths are only tracked in the web platform.
void clearAllWebAudioPaths() {}

/// No-op: base64 audio conversion is only needed on web.
Future<String?> audioBlobToBase64(String blobUrl) async => null;

/// No-op: base64→blob conversion is only needed on web.
String? audioBase64ToBlobUrl(String base64) => null;

AudioRecorder createRecorder() => AudioRecorder();

// ─────────────────────────────────────────────────────────────────────────
// TTS stubs — native TTS is handled by flutter_tts in app_state.dart
// ─────────────────────────────────────────────────────────────────────────

/// No-op: only needed on web to set up the JS→Dart callback bridge.
void initWebTtsCallback() {}

/// No-op: iOS Safari unlock is not needed on native platforms.
void unlockTtsForMobileBrowser(dynamic ignored) {}

/// Not called on native (flutter_tts is used instead).
void ttsSpeak(String text, double rate, double volume, String voiceURI, void Function() onComplete) {
  // On native, app_state.dart uses flutter_tts directly.
  // This stub should never be reached, but call onComplete defensively.
  onComplete();
}

/// Not needed on native; voices are fetched via flutter_tts directly.
Future<List<Map<String, dynamic>>> getWebVoices() async => [];

/// Not called on native (flutter_tts is used instead).
void ttsStop() {}

/// No-op: blob URL tracking is only needed on web.
void storeWebAudioPath(String btnId, int idx, String blobUrl) {}

/// No-op: blob URL tracking is only needed on web.
void clearWebAudioPath(String btnId, int idx) {}

/// No-op: JS audio playback is only needed on web.
void webPlayAudio(String url, double volume, void Function() onComplete) {
  onComplete();
}

/// No-op: JS audio stop is only needed on web.
void webStopAudio() {}

/// No-op: synchronous path lookup is only needed on web.
String audioFilePathSync(String btnId, int idx, [int slot = 0]) => '';

/// No-op: synchronous existence check is only needed on web.
bool audioFileExistsSync(String path) => false;

/// No-op: recording coordination is only needed on web.
void prepareWebRecording() {}

/// No-op: recording coordination is only needed on web.
void cleanupWebRecording() {}

