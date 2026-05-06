import 'package:flutter/material.dart';

/// A shareable victory/milestone card widget for screenshots.
/// Used with the `screenshot` package to generate images for WhatsApp sharing.
class ShareCardWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final String stat;
  final String statLabel;
  final Color accentColor;
  final IconData icon;

  const ShareCardWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.stat,
    required this.statLabel,
    this.accentColor = const Color(0xFFf59e0b),
    this.icon = Icons.emoji_events_rounded,
  });

  /// Factory for victory card
  factory ShareCardWidget.victory({
    required int myScore,
    required int opponentScore,
    required String playerName,
  }) {
    return ShareCardWidget(
      title: '🏆 Victory!',
      subtitle: playerName,
      stat: '$myScore - $opponentScore',
      statLabel: 'Bible Trivia Battle',
      accentColor: const Color(0xFFf59e0b),
      icon: Icons.emoji_events_rounded,
    );
  }

  /// Factory for milestone card
  factory ShareCardWidget.milestone({
    required String milestoneName,
    required String playerName,
    required int count,
    required String unit,
  }) {
    return ShareCardWidget(
      title: '🎉 $milestoneName',
      subtitle: playerName,
      stat: '$count',
      statLabel: unit,
      accentColor: const Color(0xFF10b981),
      icon: Icons.star_rounded,
    );
  }

  /// Factory for quiz result card
  factory ShareCardWidget.quizResult({
    required int score,
    required int total,
    required String category,
  }) {
    return ShareCardWidget(
      title: '📖 Bible Quiz',
      subtitle: category,
      stat: '$score/$total',
      statLabel: 'correct answers',
      accentColor: const Color(0xFFe94560),
      icon: Icons.quiz_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withOpacity(0.3), width: 2),
        boxShadow: [BoxShadow(
          color: accentColor.withOpacity(0.2), blurRadius: 20, spreadRadius: 2)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // App branding
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.sports_esports_rounded, color: accentColor, size: 20),
              const SizedBox(width: 6),
              const Text('Bible Arena',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 20),

          // Icon
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [accentColor, accentColor.withOpacity(0.6)]),
              boxShadow: [BoxShadow(
                color: accentColor.withOpacity(0.4), blurRadius: 20)],
            ),
            child: Icon(icon, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 18),

          // Title
          Text(title, style: const TextStyle(
            color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(subtitle, style: TextStyle(
            color: Colors.white.withOpacity(0.6), fontSize: 15)),
          const SizedBox(height: 20),

          // Stat
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accentColor.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Text(stat, style: TextStyle(
                  color: accentColor, fontSize: 36, fontWeight: FontWeight.w900)),
                Text(statLabel, style: TextStyle(
                  color: accentColor.withOpacity(0.7), fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // CTA
          Text('Play Bible Arena in Holy Word app!',
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
        ],
      ),
    );
  }
}
