import 'package:flutter/material.dart';

enum LayoutStrategy {
  uniform, // Standard single style
  multiLineColors, // Each line gets a different color from a list
  alternatingSize, // Alternate big/small lines
  emphasisCenter, // Middle line is big/colored, others small
}

class VerseLayout {
  final String name;
  final LayoutStrategy strategy;

  // Background
  final Color backgroundColor;
  final List<Color> backgroundGradient;
  final bool useGradient;
  final bool useImage;

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

  // Multi-Style Properties
  final List<Color> multiColors;
  final List<double> multiSizes;

  // New: Stroke / Outline
  final Color? verseStrokeColor;
  final double verseStrokeWidth;

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

  // New: Reference Background (Pill)
  final Color? refBackgroundColor;
  final double refBorderRadius;

  // Watermark
  final int watermarkStyle;

  // Text Width Factor
  final double textWidthFactor;

  const VerseLayout({
    required this.name,
    this.strategy = LayoutStrategy.uniform,
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
    this.verseStrokeColor,
    this.verseStrokeWidth = 0.0,
    this.multiColors = const [],
    this.multiSizes = const [],
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
    this.refBackgroundColor,
    this.refBorderRadius = 0.0,
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
      refColor: Colors.black, // Dark text
      refAlign: TextAlign.center,
      refBackgroundColor: Colors.white, // White Pill
      refBorderRadius: 20.0,
    ),
    VerseLayout(
      name: 'Modern Gradient',
      useGradient: true,
      backgroundGradient: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
      verseFont: 'Roboto',
      verseTextSize: 26.0,
      verseColor: Colors.white,
      verseAlign: TextAlign.left,
      isBold: true,
      hasShadow: true,
      verseEffect: 'Glow',
      verseEffectVal: 0.2,
      verseEffectColor: Colors.black54,
      refFont: 'Roboto',
      refAlign: TextAlign.left,
      refColor: Colors.white70,
      watermarkStyle: 1,
    ),
    VerseLayout(
      name: 'Golden Glory',
      useGradient: true,
      backgroundGradient: [Color(0xFF232526), Color(0xFF414345)],
      verseFont: 'Merriweather',
      verseTextSize: 28.0,
      verseColor: Colors.white,
      verseAlign: TextAlign.center,
      isBold: true,
      hasShadow: true,
      verseEffect: 'Gold',
      verseEffectVal: 1.0,
      refFont: 'Merriweather',
      refColor: Color(0xFFFFD700),
      refEffect: 'Gold',
      refEffectVal: 1.0,
      watermarkStyle: 2,
    ),
    VerseLayout(
      name: 'Promise Board',
      strategy: LayoutStrategy.multiLineColors,
      useGradient: true,
      backgroundGradient: [Color(0xFF141E30), Color(0xFF243B55)], // Deep Blue
      verseFont: 'Gidugu', // Decorative Telugu-ish font
      verseTextSize: 32.0,
      verseColor: Colors.white,
      verseAlign: TextAlign.right,
      isBold: true,
      hasShadow: true,
      verseEffect: 'None',
      verseStrokeColor: Colors.black,
      verseStrokeWidth: 2.0,
      multiColors: [
        Color(0xFFFFD700), // Gold
        Colors.white,
        Color(0xFF00BFA5), // Teal
        Color(0xFFFF4081), // Pink
      ],
      refFont: 'Gidugu',
      refColor: Color(0xFF141E30), // Dark text
      refAlign: TextAlign.right,
      refBackgroundColor: Colors.white, // White Pill
      refBorderRadius: 20.0,
      watermarkStyle: 3,
    ),
    VerseLayout(
      name: 'Morning Grace',
      strategy: LayoutStrategy.emphasisCenter, // Middle line big
      useGradient: true,
      backgroundGradient: [Color(0xFFff9966), Color(0xFFff5e62)], // Sunrise
      verseFont: 'Mandali',
      verseTextSize: 22.0,
      verseColor: Colors.white,
      verseAlign: TextAlign.center,
      isBold: true,
      hasShadow: false,
      verseEffect: 'None',
      verseStrokeColor: Color(0xFF8B0000), // Dark Red Outline
      verseStrokeWidth: 1.5,
      multiColors: [Colors.yellowAccent], // Emphasis color
      multiSizes: [40.0], // Emphasis size
      refFont: 'Mandali',
      refColor: Colors.white,
      refEffect: 'None',
      refBackgroundColor:
          Color(0x80434343), // Semi-transparent pill (0.5 opacity)
      refBorderRadius: 8.0,
      watermarkStyle: 0,
    ),
    VerseLayout(
      name: 'Shadow Hand',
      strategy: LayoutStrategy.alternatingSize,
      useGradient: true,
      backgroundGradient: [Colors.black, Color(0xFF434343)],
      verseFont: 'Ramabhadra',
      verseTextSize: 24.0,
      verseColor: Colors.white,
      verseAlign: TextAlign.center,
      isBold: true,
      hasShadow: true,
      verseEffect: 'Glow',
      verseEffectVal: 0.5,
      verseEffectColor: Colors.blue,
      multiSizes: [24.0, 36.0], // Small, Big, Small...
      multiColors: [Colors.white70, Colors.white],
      refFont: 'Ramabhadra',
      refColor: Colors.orangeAccent,
      refAlign: TextAlign.center,
    ),
  ];
}
