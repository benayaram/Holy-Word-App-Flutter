import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/arena_providers.dart';

class BattleResultScreen extends ConsumerWidget {
  final Map<String, dynamic> resultData;
  const BattleResultScreen({super.key, required this.resultData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(arenaUserProvider).value;
    final winnerId = resultData['winnerId'];
    final scores = resultData['scores'] as Map<String, dynamic>? ?? {};
    final xpEarned = resultData['xpEarned'] as Map<String, dynamic>? ?? {};
    final isWinner = user != null && winnerId == user.firebaseUid;
    final isTie = winnerId == null;

    int myScore = 0;
    int opponentScore = 0;
    int myXp = 0;

    if (user != null) {
      myScore = scores[user.firebaseUid] ?? 0;
      myXp = xpEarned[user.firebaseUid] ?? 0;
      scores.forEach((k, v) {
        if (k != user.firebaseUid) opponentScore = v as int;
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Victory/Defeat icon
                Container(
                  width: 120, height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: isWinner
                        ? [const Color(0xFFf59e0b), const Color(0xFFf97316)]
                        : isTie
                            ? [const Color(0xFF3b82f6), const Color(0xFF8b5cf6)]
                            : [const Color(0xFF6b7280), const Color(0xFF4b5563)]),
                    boxShadow: [BoxShadow(
                      color: (isWinner ? const Color(0xFFf59e0b) : const Color(0xFF3b82f6))
                          .withOpacity(0.4),
                      blurRadius: 30, spreadRadius: 5)],
                  ),
                  child: Icon(
                    isWinner ? Icons.emoji_events_rounded
                        : isTie ? Icons.handshake_rounded : Icons.shield_rounded,
                    color: Colors.white, size: 56),
                ),
                const SizedBox(height: 28),

                Text(
                  isWinner ? 'Victory! 🏆' : isTie ? 'It\'s a Tie! 🤝' : 'Defeat 😔',
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 20),

                // Score comparison
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _scoreBlock('You', myScore, const Color(0xFF4facfe)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text('vs',
                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 18)),
                    ),
                    _scoreBlock('Opponent', opponentScore, const Color(0xFFe94560)),
                  ],
                ),
                const SizedBox(height: 24),

                // XP earned
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFf59e0b).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFf59e0b).withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFf59e0b), size: 22),
                      const SizedBox(width: 8),
                      Text('+$myXp XP',
                          style: const TextStyle(color: Color(0xFFf59e0b),
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Share button
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final text = isWinner
                          ? '🏆 I won a Bible Trivia Battle! Score: $myScore-$opponentScore\n'
                              'Challenge me in Holy Word Bible Arena!'
                          : '⚔️ Just battled in Bible Trivia! Score: $myScore-$opponentScore\n'
                              'Play Bible Arena in Holy Word app!';
                      Share.share(text);
                    },
                    icon: const Icon(Icons.share_rounded, color: Colors.white),
                    label: const Text('Share Result',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Back button
                SizedBox(
                  width: double.infinity, height: 52,
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(arenaUserProvider.notifier).refresh();
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Back to Arena',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _scoreBlock(String label, int score, Color color) {
    return Container(
      width: 100, padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3))),
      child: Column(children: [
        Text('$score', style: TextStyle(color: color, fontSize: 36, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 13)),
      ]),
    );
  }
}
