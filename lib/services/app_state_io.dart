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
    Vibration.vibrate(duration: 50);
  } catch (_) {}
}

// ─────────────────────────────────────────────────────────────────────────
// File / audio storage
// ─────────────────────────────────────────────────────────────────────────

Future<String> audioFilePath(String btnId, int idx) async {
  final dir = await getApplicationDocumentsDirectory();
  return '${dir.path}/td_audio_${btnId}_$idx.m4a';
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

Future<void> clearAllAudioFiles() async {
  final dir = await getApplicationDocumentsDirectory();
  for (final f in dir.listSync()) {
    if (f is File && f.path.contains('td_audio_')) {
      await f.delete();
    }
  }
}

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
String audioFilePathSync(String btnId, int idx) => '';

/// No-op: synchronous existence check is only needed on web.
bool audioFileExistsSync(String path) => false;

/// No-op: recording coordination is only needed on web.
void prepareWebRecording() {}

/// No-op: recording coordination is only needed on web.
void cleanupWebRecording() {}

