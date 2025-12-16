import 'package:flutter/material.dart';

class VerseLayout {
  final String name;

  // Background
  final Color backgroundColor;
  final List<Color> backgroundGradient;
  final bool useGradient;
  final bool
      useImage; // Logic to clear image if true not handled here, just style

  // Verse Style
  final String verseFont;
  final double verseTextSize;
  final Color verseColor;
  final TextAlign verseAlign;
  final bool isBold;
  final bool isItalic;
  final bool isUnderlined;
  final bool hasShadow;
  final String verseEffect;
  final double verseEffectVal;
  final Color verseEffectColor;
  final List<Color> verseGradientColors;
  final Alignment verseGradientBegin;
  final Alignment verseGradientEnd;

  // Reference Style
  final String refFont;
  final double refTextSize;
  final Color refColor;
  final TextAlign refAlign;
  final bool refBold;
  final bool refItalic;
  final String refEffect;
  final double refEffectVal;
  final Color refEffectColor;
  final List<Color> refGradientColors;
  final Alignment refGradientBegin;
  final Alignment refGradientEnd;

  // Watermark
  final int watermarkStyle;

  // Text Width Factor
  final double textWidthFactor;

  const VerseLayout({
    required this.name,
    this.backgroundColor = Colors.black,
    this.backgroundGradient = const [Colors.blue, Colors.purple],
    this.useGradient = true,
    this.useImage = false,
    this.verseFont = 'Inter',
    this.verseTextSize = 24.0,
    this.verseColor = Colors.white,
    this.verseAlign = TextAlign.center,
    this.isBold = true,
    this.isItalic = false,
    this.isUnderlined = false,
    this.hasShadow = true,
    this.verseEffect = 'None',
    this.verseEffectVal = 0.5,
    this.verseEffectColor = Colors.black,
    this.verseGradientColors = const [Colors.yellow, Colors.orange],
    this.verseGradientBegin = Alignment.topLeft,
    this.verseGradientEnd = Alignment.bottomRight,
    this.refFont = 'Inter',
    this.refTextSize = 16.0,
    this.refColor = Colors.white70,
    this.refAlign = TextAlign.center,
    this.refBold = true,
    this.refItalic = false,
    this.refEffect = 'None',
    this.refEffectVal = 0.5,
    this.refEffectColor = Colors.black,
    this.refGradientColors = const [Colors.orange, Colors.red],
    this.refGradientBegin = Alignment.topLeft,
    this.refGradientEnd = Alignment.bottomRight,
    this.watermarkStyle = 0,
    this.textWidthFactor = 0.85,
  });
}

class LayoutPresets {
  static const List<VerseLayout> layouts = [
    VerseLayout(
      name: 'Classic',
      backgroundColor: Colors.black,
      useGradient: false,
      verseFont: 'Inter',
      verseTextSize: 24.0,
      verseColor: Colors.white,
      verseAlign: TextAlign.center,
      isBold: true,
      hasShadow: false,
      verseEffect: 'None',
      refFont: 'Inter',
      refTextSize: 16.0,
      refColor: Colors.grey,
      refAlign: TextAlign.center,
    ),
    VerseLayout(
      name: 'Modern Gradient',
      useGradient: true,
      backgroundGradient: [
        Color(0xFF8E2DE2),
        Color(0xFF4A00E0)
      ], // Purple to Deep Purple
      verseFont: 'Roboto',
      verseTextSize: 26.0,
      verseColor: Colors.white,
      verseAlign: TextAlign.left,
      isBold: true,
      hasShadow: true,
      verseEffect: 'Glow',
      verseEffectVal: 0.2, // Subtle glow
      verseEffectColor: Colors.black54,
      refFont: 'Roboto',
      refAlign: TextAlign.left,
      refColor: Colors.white70,
      watermarkStyle: 1, // Custom badge
    ),
    VerseLayout(
      name: 'Golden Glory',
      useGradient: true,
      backgroundGradient: [
        Color(0xFF232526),
        Color(0xFF414345)
      ], // Metallic Dark
      verseFont: 'Merriweather',
      verseTextSize: 28.0,
      verseColor: Colors.white,
      verseAlign: TextAlign.center,
      isBold: true,
      hasShadow: true,
      verseEffect: 'Gold',
      verseEffectVal: 1.0,
      refFont: 'Merriweather',
      refColor: Color(0xFFFFD700), // Gold Color
      refEffect: 'Gold',
      refEffectVal: 1.0,
      watermarkStyle: 2,
    ),
    VerseLayout(
      name: 'Serene Nature',
      useGradient: true,
      backgroundGradient: [Color(0xFF11998e), Color(0xFF38ef7d)], // Green
      verseFont: 'Playfair',
      verseTextSize: 28.0,
      verseColor: Colors.white,
      verseAlign: TextAlign.center,
      isItalic: true,
      isBold: false,
      hasShadow: true,
      verseEffect: 'Gradient',
      verseGradientColors: [Colors.white, Color(0xFFE0F2F1)],
      refFont: 'Playfair',
      refColor: Colors.white,
      refItalic: true,
      watermarkStyle: 0,
    ),
    VerseLayout(
      name: 'Bold Statement',
      useGradient: true,
      backgroundGradient: [Color(0xFFff9966), Color(0xFFff5e62)], // Orange/Red
      verseFont: 'NTR',
      verseTextSize: 32.0,
      verseColor: Colors.white,
      verseAlign: TextAlign.center,
      isBold: true,
      hasShadow: true,
      verseEffect: '3D',
      verseEffectVal: 0.8,
      verseEffectColor: Color(0xFFB71C1C),
      refFont: 'NTR',
      refColor: Colors.white,
      refEffect: 'None',
      textWidthFactor: 0.95,
    ),
  ];
}
