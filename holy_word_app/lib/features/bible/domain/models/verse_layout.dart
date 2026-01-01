import 'package:flutter/material.dart';

enum LayoutStrategy {
  uniform, // Standard single style
  multiLineColors, // Each line gets a different color from a list
  alternatingSize, // Alternate big/small lines
  emphasisCenter, // Middle line is big/colored, others small
  emphasisEnd, // First part normal, last part emphasized (different font/size/color)
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

  // Emphasis Style (for strategies like emphasisEnd)
  final String? emphasisFont;
  final double? emphasisTextSize;
  final Color? emphasisColor;
  final bool? emphasisBold;

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
    this.emphasisFont,
    this.emphasisTextSize,
    this.emphasisColor,
    this.emphasisBold,
  });
}

class LayoutPresets {
  static const List<VerseLayout> layouts = [
    VerseLayout(
      name: 'Layout 1',
      strategy: LayoutStrategy.emphasisEnd, // Use new strategy
      backgroundColor: Colors.white,
      useGradient: false,

      // Intro Style (Small, Black, Simple)
      verseFont: 'Inter',
      verseTextSize: 18.0,
      verseColor: Colors.black,
      verseAlign: TextAlign.right,
      isBold: false, // Normal weight for intro

      // Emphasis Style (Big, Gold, Serif)
      emphasisFont: 'Merriweather',
      emphasisTextSize: 42.0, // Huge size
      emphasisColor: Color(0xFF997A49), // Gold
      emphasisBold: true,

      hasShadow: false,
      verseEffect: 'None',

      // Reference Style (Pill)
      refFont: 'Inter',
      refTextSize: 14.0,
      refColor: Colors.white,
      refAlign: TextAlign.right,
      refBackgroundColor: Color(0xFF997A49),
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
  ];
}
