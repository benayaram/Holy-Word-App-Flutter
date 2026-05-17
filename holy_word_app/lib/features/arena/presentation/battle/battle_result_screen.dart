import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/arena_providers.dart';
import '../arena_theme.dart';

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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: Scaffold(
        backgroundColor: ArenaTheme.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Result icon
                  Icon(
                    isTie
                        ? Icons.handshake_rounded
                        : isWinner
                            ? Icons.emoji_events_rounded
                            : Icons.sentiment_dissatisfied_rounded,
                    color: isTie
                        ? ArenaTheme.xpGold
                        : isWinner
                            ? ArenaTheme.xpGold
                            : ArenaTheme.primary,
                    size: 80,
                  ),
                  const SizedBox(height: 16),

                  // Result text
                  Text(
                    isTie ? "It's a Tie!" : isWinner ? 'You Won!' : 'You Lost',
                    style: TextStyle(
                      color: isTie || isWinner ? ArenaTheme.xpGold : ArenaTheme.primary,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Score comparison
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _scoreColumn('You', myScore, ArenaTheme.quizBlue),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text('vs',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 18)),
                      ),
                      _scoreColumn('Opponent', opponentScore, ArenaTheme.primary),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // XP earned
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: ArenaTheme.xpGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: ArenaTheme.xpGold.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: ArenaTheme.xpGold, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          '+$myXp XP',
                          style: const TextStyle(
                            color: ArenaTheme.xpGold,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Navigation buttons
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ArenaTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Back to Arena',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _scoreColumn(String label, int score, Color color) {
    return Column(
      children: [
        Text(
          '$score',
          style: TextStyle(color: color, fontSize: 48, fontWeight: FontWeight.w900),
        ),
        Text(label, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 14)),
      ],
    );
  }
}
