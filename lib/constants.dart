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
    primary: Color(0xFFEF4444),
    light: Color(0xFFFCA5A5),
    dark: Color(0xFF991B1B),
    textColor: Colors.white,
  ),
  ButtonColorDef(
    name: 'Blue',
    primary: Color(0xFF3B82F6),
    light: Color(0xFF93C5FD),
    dark: Color(0xFF1E3A8A),
    textColor: Colors.white,
  ),
  ButtonColorDef(
    name: 'Green',
    primary: Color(0xFF10B981),
    light: Color(0xFF6EE7B7),
    dark: Color(0xFF064E3B),
    textColor: Colors.white,
  ),
  ButtonColorDef(
    name: 'Yellow',
    primary: Color(0xFFEAB308),
    light: Color(0xFFFEF08A),
    dark: Color(0xFF713F12),
    textColor: Colors.black,
  ),
  ButtonColorDef(
    name: 'Orange',
    primary: Color(0xFFF97316),
    light: Color(0xFFFDBA74),
    dark: Color(0xFF7C2D12),
    textColor: Colors.white,
  ),
  ButtonColorDef(
    name: 'Purple',
    primary: Color(0xFFA855F7),
    light: Color(0xFFD8B4FE),
    dark: Color(0xFF4C1D95),
    textColor: Colors.white,
  ),
  ButtonColorDef(
    name: 'Pink',
    primary: Color(0xFFEC4899),
    light: Color(0xFFF9A8D4),
    dark: Color(0xFF831843),
    textColor: Colors.white,
  ),
  ButtonColorDef(
    name: 'Gray',
    primary: Color(0xFF71717A),
    light: Color(0xFFD4D4D8),
    dark: Color(0xFF18181B),
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
  ScanColorDef(name: 'Yellow', ring: Color(0xF2FACC15), glow: Color(0x73FACC15), swatch: Color(0xFFFACC15)),
  ScanColorDef(name: 'White', ring: Color(0xF2FFFFFF), glow: Color(0x59FFFFFF), swatch: Color(0xFFFFFFFF)),
  ScanColorDef(name: 'Red', ring: Color(0xF2EF4444), glow: Color(0x73EF4444), swatch: Color(0xFFEF4444)),
  ScanColorDef(name: 'Blue', ring: Color(0xF23B82F6), glow: Color(0x733B82F6), swatch: Color(0xFF3B82F6)),
  ScanColorDef(name: 'Green', ring: Color(0xF210B981), glow: Color(0x7310B981), swatch: Color(0xFF10B981)),
  ScanColorDef(name: 'Orange', ring: Color(0xF2F97316), glow: Color(0x73F97316), swatch: Color(0xFFF97316)),
  ScanColorDef(name: 'Purple', ring: Color(0xF2A855F7), glow: Color(0x73A855F7), swatch: Color(0xFFA855F7)),
  ScanColorDef(name: 'Pink', ring: Color(0xF2EC4899), glow: Color(0x73EC4899), swatch: Color(0xFFEC4899)),
];

/// Activation modes.
enum ActivationMode { press, release, scan }

/// Label position.
enum LabelPosition { on, under, off }

/// Background color for the app.
const Color kBackgroundColor = Color(0xFF08080F);
