import 'package:flutter/material.dart';

/// Animated XP progress bar with level label
class XpProgressBar extends StatelessWidget {
  final int currentXp;
  final int nextLevelXp;
  final String currentLevel;
  final String nextLevel;

  const XpProgressBar({
    super.key,
    required this.currentXp,
    required this.nextLevelXp,
    required this.currentLevel,
    required this.nextLevel,
  });

  @override
  Widget build(BuildContext context) {
    final progress = nextLevelXp > 0 ? (currentXp / nextLevelXp).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            builder: (ctx, val, _) => LinearProgressIndicator(
              value: val,
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFe94560)),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(currentLevel,
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
            Text('${nextLevelXp - currentXp} XP to $nextLevel',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
          ],
        ),
      ],
    );
  }
}

/// Circular countdown timer widget
class CountdownTimer extends StatelessWidget {
  final int seconds;
  final int maxSeconds;

  const CountdownTimer({
    super.key,
    required this.seconds,
    this.maxSeconds = 15,
  });

  @override
  Widget build(BuildContext context) {
    final isUrgent = seconds <= 5;
    return Container(
      width: 48, height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isUrgent
            ? const Color(0xFFe94560).withOpacity(0.3)
            : Colors.white.withOpacity(0.1),
        border: Border.all(
          color: isUrgent ? const Color(0xFFe94560) : Colors.white24,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          '$seconds',
          style: TextStyle(
            color: isUrgent ? const Color(0xFFe94560) : Colors.white,
            fontSize: 18, fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// Animated score indicator that pulses on change
class ScoreIndicator extends StatelessWidget {
  final int score;
  final Color color;
  final String label;

  const ScoreIndicator({
    super.key,
    required this.score,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: score),
            duration: const Duration(milliseconds: 500),
            builder: (ctx, val, _) => Text(
              '$val',
              style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900),
            ),
          ),
          Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 11)),
        ],
      ),
    );
  }
}

/// Level badge chip widget
class LevelBadge extends StatelessWidget {
  final String level;
  final double fontSize;

  const LevelBadge({super.key, required this.level, this.fontSize = 11});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _getColor(level), borderRadius: BorderRadius.circular(8)),
      child: Text(level, style: TextStyle(
          color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.w600)),
    );
  }

  Color _getColor(String level) {
    switch (level) {
      case 'Disciple': return const Color(0xFF3b82f6);
      case 'Elder': return const Color(0xFF8b5cf6);
      case 'Apostle': return const Color(0xFFf59e0b);
      case 'Living Word': return const Color(0xFFe94560);
      default: return const Color(0xFF6b7280);
    }
  }
}

/// Animated mode card for Arena home
class ArenaGradientCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  const ArenaGradientCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight, colors: gradient),
          boxShadow: [BoxShadow(
            color: gradient[0].withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, height: 1.2)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(
                    color: Colors.white.withOpacity(0.8), fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty state placeholder
class ArenaEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const ArenaEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.color = const Color(0xFF667eea),
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 80),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(
            color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.6)),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
