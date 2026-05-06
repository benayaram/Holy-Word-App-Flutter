import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/arena_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(arenaUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent, elevation: 0,
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF10b981))),
        error: (e, _) => Center(child: Text('$e', style: const TextStyle(color: Colors.red))),
        data: (user) {
          if (user == null) return const Center(child: Text('Not signed in', style: TextStyle(color: Colors.white)));
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              // Avatar + Name
              CircleAvatar(radius: 48, backgroundColor: const Color(0xFFe94560),
                backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                child: user.photoUrl == null ? Text(user.displayName[0],
                    style: const TextStyle(color: Colors.white, fontSize: 32)) : null),
              const SizedBox(height: 12),
              Text(user.displayName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFf59e0b).withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                child: Text(user.level, style: const TextStyle(color: Color(0xFFf59e0b), fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),

              // XP Progress
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(16)),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('${user.xp} XP', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('Next: ${user.nextLevel}', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                  ]),
                  const SizedBox(height: 10),
                  ClipRRect(borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(value: user.levelProgress.clamp(0.0, 1.0),
                      minHeight: 8, backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation(Color(0xFFe94560)))),
                  const SizedBox(height: 6),
                  Text('${user.xpToNextLevel} XP to go', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                ]),
              ),
              const SizedBox(height: 16),

              // Stats Grid
              Row(children: [
                _stat('Battles Won', '${user.battleWins}', const Color(0xFF3b82f6)),
                const SizedBox(width: 12),
                _stat('Win Streak', '${user.winStreak}', const Color(0xFFf59e0b)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                _stat('Accuracy', '${user.accuracy}%', const Color(0xFF10b981)),
                const SizedBox(width: 12),
                _stat('Verses', '${user.versesMemorized}', const Color(0xFF8b5cf6)),
              ]),
              const SizedBox(height: 24),

              // Badges
              if (user.badges.isNotEmpty) ...[
                Align(alignment: Alignment.centerLeft,
                  child: Text('Badges', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16, fontWeight: FontWeight.w600))),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8,
                  children: user.badges.map((b) => Chip(
                    backgroundColor: const Color(0xFFf59e0b).withOpacity(0.2),
                    label: Text(b.name, style: const TextStyle(color: Color(0xFFf59e0b), fontSize: 12)),
                    avatar: const Icon(Icons.star, color: Color(0xFFf59e0b), size: 16),
                  )).toList()),
              ],
            ]),
          );
        },
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(children: [
        Text(value, style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
      ]),
    ));
  }
}
