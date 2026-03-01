import 'package:flutter/material.dart';

/// Button colour definitions matching the HTML5 version.
class ButtonColorDef {
  final String name;
  final Color primary;
  final Color light;
  final Color dark;
  final Color textColor;

  const ButtonColorDef({
    required this.name,
    required this.primary,
    required this.light,
    required this.dark,
    required this.textColor,
  });

  List<Color> get gradient => [light, primary, dark];

  Color get glowColor => primary.withValues(alpha: 0.65);

  Map<String, dynamic> toJson() => {'name': name};

  static ButtonColorDef fromJson(Map<String, dynamic> json) {
    return kColors.firstWhere(
      (c) => c.name == json['name'],
      orElse: () => kColors[0],
    );
  }
}

const List<ButtonColorDef> kColors = [
  ButtonColorDef(
    name: 'Red',
    primary: Color(0xFFFF3B30),
    light: Color(0xFFFF6B6B),
    dark: Color(0xFFC92A2A),
    textColor: Colors.white,
  ),
  ButtonColorDef(
    name: 'Blue',
    primary: Color(0xFF007AFF),
    light: Color(0xFF5AC8FA),
    dark: Color(0xFF0056B3),
    textColor: Colors.white,
  ),
  ButtonColorDef(
    name: 'Green',
    primary: Color(0xFF34C759),
    light: Color(0xFF68E07A),
    dark: Color(0xFF248A3D),
    textColor: Colors.white,
  ),
  ButtonColorDef(
    name: 'Yellow',
    primary: Color(0xFFFFCC00),
    light: Color(0xFFFFDF70),
    dark: Color(0xFFD4A000),
    textColor: Colors.black,
  ),
  ButtonColorDef(
    name: 'Orange',
    primary: Color(0xFFFF9500),
    light: Color(0xFFFFB347),
    dark: Color(0xFFCC7700),
    textColor: Colors.white,
  ),
  ButtonColorDef(
    name: 'Purple',
    primary: Color(0xFFAF52DE),
    light: Color(0xFFD484F2),
    dark: Color(0xFF7A36A0),
    textColor: Colors.white,
  ),
  ButtonColorDef(
    name: 'Pink',
    primary: Color(0xFFFF2D55),
    light: Color(0xFFFF6984),
    dark: Color(0xFFC7153D),
    textColor: Colors.white,
  ),
  ButtonColorDef(
    name: 'Slate',
    primary: Color(0xFF4A5568),
    light: Color(0xFF718096),
    dark: Color(0xFF2D3748),
    textColor: Colors.white,
  ),
];

/// Scan outline colours.
class ScanColorDef {
  final String name;
  final Color ring;
  final Color glow;
  final Color swatch;

  const ScanColorDef({
    required this.name,
    required this.ring,
    required this.glow,
    required this.swatch,
  });
}

const List<ScanColorDef> kScanColors = [
  ScanColorDef(name: 'Yellow', ring: Color(0xF2FFCC00), glow: Color(0x73FFCC00), swatch: Color(0xFFFFCC00)),
  ScanColorDef(name: 'White', ring: Color(0xF2FFFFFF), glow: Color(0x59FFFFFF), swatch: Color(0xFFFFFFFF)),
  ScanColorDef(name: 'Red', ring: Color(0xF2FF3B30), glow: Color(0x73FF3B30), swatch: Color(0xFFFF3B30)),
  ScanColorDef(name: 'Blue', ring: Color(0xF2007AFF), glow: Color(0x73007AFF), swatch: Color(0xFF007AFF)),
  ScanColorDef(name: 'Green', ring: Color(0xF234C759), glow: Color(0x7334C759), swatch: Color(0xFF34C759)),
  ScanColorDef(name: 'Orange', ring: Color(0xF2FF9500), glow: Color(0x73FF9500), swatch: Color(0xFFFF9500)),
  ScanColorDef(name: 'Purple', ring: Color(0xF2AF52DE), glow: Color(0x73AF52DE), swatch: Color(0xFFAF52DE)),
  ScanColorDef(name: 'Pink', ring: Color(0xF2FF2D55), glow: Color(0x73FF2D55), swatch: Color(0xFFFF2D55)),
];

/// Activation modes.
enum ActivationMode { press, release, scan }

/// Label position.
enum LabelPosition { on, under, off }

/// Background color presets the user can choose.
class BackgroundColorDef {
  final String name;
  final Color color;
  const BackgroundColorDef({required this.name, required this.color});
}

const List<BackgroundColorDef> kBgColors = [
  BackgroundColorDef(name: 'White',      color: Color(0xFFFFFFFF)),
  BackgroundColorDef(name: 'Buff',       color: Color(0xFFE8DCC8)),
  BackgroundColorDef(name: 'Dark Grey',  color: Color(0xFF2E2E2E)),
  BackgroundColorDef(name: 'Black',      color: Color(0xFF000000)),
  BackgroundColorDef(name: 'Very Dark',  color: Color(0xFF06080D)), // default
  BackgroundColorDef(name: 'Charcoal',   color: Color(0xFF1C1C2E)),
  BackgroundColorDef(name: 'Navy',       color: Color(0xFF051830)),
  BackgroundColorDef(name: 'Forest',     color: Color(0xFF061A09)),
  BackgroundColorDef(name: 'Plum',       color: Color(0xFF1A0630)),
  BackgroundColorDef(name: 'Midnight',   color: Color(0xFF0D0520)),
];

/// Background color for the app (legacy, kept for compatibility).
const Color kBackgroundColor = Color(0xFF06080D);
