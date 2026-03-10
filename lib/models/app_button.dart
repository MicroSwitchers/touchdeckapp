import 'dart:convert';
import 'package:flutter/material.dart';
import '../constants.dart';

/// A single app button with its phrases, audio, color, position, and scale.
class AppButton {
  final String id;
  String label;
  List<String> phrases;
  List<bool> hasAudio;
  ButtonColorDef color;
  Offset position; // percentage-based (0–100)
  double scale;
  int phraseIndex;

  AppButton({
    required this.id,
    this.label = '',
    List<String>? phrases,
    List<bool>? hasAudio,
    ButtonColorDef? color,
    Offset? position,
    this.scale = 1.0,
    this.phraseIndex = 0,
  })  : phrases = phrases ?? [''],
        hasAudio = hasAudio ?? [false],
        color = color ?? kColors[0],
        position = position ?? const Offset(50, 50);

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'phrases': phrases,
        'hasAudio': hasAudio,
        'color': color.toJson(),
        'posX': position.dx,
        'posY': position.dy,
        'scale': scale,
        'phraseIndex': phraseIndex,
      };

  factory AppButton.fromJson(Map<String, dynamic> json) {
    final parsedPhrases = (json['phrases'] as List<dynamic>?)?.cast<String>() ?? ['', '', ''];
    final parsedHasAudio = (json['hasAudio'] as List<dynamic>?)?.cast<bool>() ?? [false, false, false];
    final parsedIndex = (json['phraseIndex'] as num?)?.toInt() ?? 0;
    return AppButton(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      label: json['label'] as String? ?? '',
      phrases: parsedPhrases,
      hasAudio: parsedHasAudio,
      color: json['color'] != null
          ? ButtonColorDef.fromJson(json['color'] as Map<String, dynamic>)
          : kColors[0],
      position: Offset(
        (json['posX'] as num?)?.toDouble() ?? 50,
        (json['posY'] as num?)?.toDouble() ?? 50,
      ),
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      // Clamp phraseIndex so stale saved values never cause a RangeError
      // if phrases were deleted since the last save.
      phraseIndex: parsedIndex.clamp(0, (parsedPhrases.length - 1).clamp(0, 9)),
    );
  }

  AppButton copyWith({
    String? id,
    String? label,
    List<String>? phrases,
    List<bool>? hasAudio,
    ButtonColorDef? color,
    Offset? position,
    double? scale,
    int? phraseIndex,
  }) =>
      AppButton(
        id: id ?? this.id,
        label: label ?? this.label,
        phrases: phrases ?? List.from(this.phrases),
        hasAudio: hasAudio ?? List.from(this.hasAudio),
        color: color ?? this.color,
        position: position ?? this.position,
        scale: scale ?? this.scale,
        phraseIndex: phraseIndex ?? this.phraseIndex,
      );

  static String encodeList(List<AppButton> buttons) =>
      jsonEncode(buttons.map((b) => b.toJson()).toList());

  static List<AppButton> decodeList(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list
        .map((e) => AppButton.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
