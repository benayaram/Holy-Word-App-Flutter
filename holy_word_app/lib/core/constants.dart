import 'package:flutter/material.dart';

class AppConstants {
  // Supabase Configuration
  static const String supabaseUrl = 'https://bevjjtmmkeduivbbsmur.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJldmpqdG1ta2VkdWl2YmJzbXVyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ1MDU3MjksImV4cCI6MjA4MDA4MTcyOX0.d8CK7sf5GYaSOMp4nxPWkwxjuy2Tq81QZyFYoJ8CNdk';

  // App Colors - From Android Project
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color primaryDarkColor = Color(0xFF1D4ED8);
  static const Color primaryLightColor = Color(0xFF3B82F6);

  static const Color secondaryColor = Color(0xFF059669);
  static const Color secondaryDarkColor = Color(0xFF047857);
  static const Color secondaryLightColor = Color(0xFF10B981);

  static const Color accentColor = Color(0xFFF59E0B);

  // Backgrounds
  static const Color backgroundColor = Color(0xFFFFFFFF);
  static const Color backgroundSecondaryColor = Color(0xFFF8FAFC);
  static const Color darkBackgroundColor = Color(0xFF1F2937);

  // Text
  static const Color textPrimaryColor = Color(0xFF1F2937);
  static const Color textSecondaryColor = Color(0xFF6B7280);
  static const Color textWhiteColor = Color(0xFFFFFFFF);

  // Status
  static const Color successColor = Color(0xFF10B981);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color warningColor = Color(0xFFF59E0B);

  // Bible Theme
  static const Color bibleGold = Color(0xFFD4AF37);
  static const Color bibleMaroon = Color(0xFF800020);

  // Bible Arena Colors
  static const Color arenaRed = Color(0xFFe94560);
  static const Color arenaOrange = Color(0xFFf97316);
  static const Color arenaPurple = Color(0xFF764ba2);
  static const Color arenaBlue = Color(0xFF4facfe);
  static const Color arenaDark = Color(0xFF1a1a2e);
  static const Color arenaDarkSecondary = Color(0xFF16213e);

  // Arena API (override via --dart-define for production)
  static const String arenaApiUrl = String.fromEnvironment(
    'ARENA_API_URL',
    defaultValue: 'http://10.0.2.2:3000/api',
  );
  static const String arenaWsUrl = String.fromEnvironment(
    'ARENA_WS_URL',
    defaultValue: 'ws://10.0.2.2:3000/ws',
  );
}
