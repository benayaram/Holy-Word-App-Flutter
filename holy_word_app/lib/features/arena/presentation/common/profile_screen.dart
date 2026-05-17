import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../providers/arena_providers.dart';
import '../arena_theme.dart';
import '../widgets/arena_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(arenaUserProvider);

    return Scaffold(
      backgroundColor: ArenaTheme.background,
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent, elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white54),
            tooltip: 'Sign out',
            onPressed: () => _showSignOutDialog(context, ref),
          ),
        ],
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: ArenaTheme.success)),
        error: (e, _) => Center(child: Text('$e', style: const TextStyle(color: Colors.red))),
        data: (user) {
          if (user == null) return const Center(child: Text('Not signed in', style: TextStyle(color: Colors.white)));
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              // Avatar + Name
              CircleAvatar(radius: 48, backgroundColor: ArenaTheme.primary,
                backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                child: user.photoUrl == null ? Text(user.displayName[0],
                    style: const TextStyle(color: Colors.white, fontSize: 32)) : null),
              const SizedBox(height: 12),
              Text(user.displayName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              LevelBadge(level: user.level, fontSize: 13),
              const SizedBox(height: 24),

              // XP Progress
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(16)),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('${user.xp} XP', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    Text('Next: ${user.nextLevel}', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
                  ]),
                  const SizedBox(height: 10),
                  ClipRRect(borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(value: user.levelProgress.clamp(0.0, 1.0),
                      minHeight: 8, backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation(ArenaTheme.primary))),
                  const SizedBox(height: 6),
                  Text('${user.xpToNextLevel} XP to go', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
                ]),
              ),
              const SizedBox(height: 16),

              // Stats Grid
              Row(children: [
                _stat('Battles Won', '${user.battleWins}', ArenaTheme.discipleBlue),
                const SizedBox(width: 12),
                _stat('Win Streak', '${user.winStreak}', ArenaTheme.xpGold),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                _stat('Accuracy', '${user.accuracy}%', ArenaTheme.success),
                const SizedBox(width: 12),
                _stat('Verses', '${user.versesMemorized}', ArenaTheme.elderPurple),
              ]),
              const SizedBox(height: 24),

              // Badges
              if (user.badges.isNotEmpty) ...[
                Align(alignment: Alignment.centerLeft,
                  child: Text('Badges', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 16, fontWeight: FontWeight.w600))),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8,
                  children: user.badges.map((b) => Chip(
                    backgroundColor: ArenaTheme.xpGold.withValues(alpha: 0.2),
                    label: Text(b.name, style: const TextStyle(color: ArenaTheme.xpGold, fontSize: 12)),
                    avatar: const Icon(Icons.star, color: ArenaTheme.xpGold, size: 16),
                  )).toList()),
              ],
            ]),
          );
        },
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ArenaTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to sign out of Bible Arena?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await fb.FirebaseAuth.instance.signOut();
              ref.invalidate(arenaUserProvider);
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            child: const Text('Sign Out', style: TextStyle(color: ArenaTheme.primary)),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        Text(value, style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
      ]),
    ));
  }
}
