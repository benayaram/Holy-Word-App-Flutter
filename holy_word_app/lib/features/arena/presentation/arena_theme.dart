import 'package:flutter/material.dart';

/// Centralized premium color theme for all Bible Arena screens.
/// Elevates the design with a highly-tuned dark-mode palette,
/// harmonious gradients, and modern visual styling properties.
class ArenaTheme {
  ArenaTheme._();

  // Premium Core Colors (Tailwind inspired high-fidelity dark mode)
  static const Color background = Color(0xFF0B0F19); // Ultra-deep slate
  static const Color surface = Color(0xFF151D30);    // Elegant elevated card blue-slate
  static const Color surfaceLight = Color(0xFF1F2B48); // Slightly lighter slate for input/borders
  
  static const Color primary = Color(0xFFF43F5E);    // Radiant Rose-Pink
  static const Color accent = Color(0xFF3B82F6);     // Electric Blue
  static const Color success = Color(0xFF10B981);    // Vibrant Emerald Green
  static const Color xpGold = Color(0xFFF59E0B);     // Pure Amber Gold
  static const Color danger = Color(0xFFEF4444);     // Intense Red

  // Text Hierarchy
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF94A3B8); // Cool Gray
  static const Color textMuted = Color(0xFF64748B);     // Deep Muted Gray

  // Harmony Gradients for Feature Cards
  static const List<Color> memoryGradients = [Color(0xFF6366F1), Color(0xFF4F46E5)]; // Indigo & Violet
  static const List<Color> quizGradients = [Color(0xFFEC4899), Color(0xFFF43F5E)];   // Pink & Rose
  static const List<Color> battleGradients = [Color(0xFF06B6D4), Color(0xFF3B82F6)]; // Cyan & Blue
  static const List<Color> sermonGradients = [Color(0xFFF59E0B), Color(0xFFD97706)]; // Amber & Orange

  // Legacy variables kept for compatibility but pointed to the new palette
  static const Color quizBlue = Color(0xFF06B6D4);
  static const Color quizCyan = Color(0xFF3B82F6);
  static const Color memoryPurple = Color(0xFF6366F1);
  static const Color memoryPurpleDark = Color(0xFF4F46E5);
  static const Color sermonPink = Color(0xFFF59E0B);
  static const Color sermonYellow = Color(0xFFD97706);
  static const Color battlePink = Color(0xFFEC4899);
  static const Color battleRed = Color(0xFFF43F5E);
  static const Color elderPurple = Color(0xFF8B5CF6);
  static const Color discipleBlue = Color(0xFF3B82F6);
  static const Color neutralGray = Color(0xFF64748B);
  static const Color shareGreen = Color(0xFF22C55E);

  // Modern Box Decoration Utilities
  static BoxDecoration cardDecoration({
    Color? color,
    BorderRadius? borderRadius,
    Border? border,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      color: color ?? surface,
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      border: border ?? Border.all(color: Colors.white.withValues(alpha: 0.05)),
      boxShadow: boxShadow ?? [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 10,
          offset: const Offset(0, 4),
        )
      ],
    );
  }

  // Premium text styles
  static const TextStyle headingLarge = TextStyle(
    color: textPrimary,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );

  static const TextStyle headingMedium = TextStyle(
    color: textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
  );

  static const TextStyle bodyMedium = TextStyle(
    color: textSecondary,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
}
