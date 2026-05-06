import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/arena_providers.dart';

class BattleHomeScreen extends ConsumerWidget {
  const BattleHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        title: const Text('Trivia Battle', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent, elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMode(context, 'Solo vs AI', 'Practice against AI', Icons.smart_toy_rounded,
              [const Color(0xFF667eea), const Color(0xFF764ba2)], () {}),
          const SizedBox(height: 16),
          _buildMode(context, 'Challenge Friend', 'Share battle invite', Icons.person_add_rounded,
              [const Color(0xFF4facfe), const Color(0xFF00f2fe)], () => _challenge(context, ref)),
          const SizedBox(height: 16),
          _buildMode(context, 'Random Opponent', 'Battle your level', Icons.shuffle_rounded,
              [const Color(0xFFfa709a), const Color(0xFFfee140)], () => _matchmake(context, ref)),
          const SizedBox(height: 16),
          _buildMode(context, 'Church Tournament', 'Bracket competition', Icons.emoji_events_rounded,
              [const Color(0xFFf093fb), const Color(0xFFf5576c)], () {}),
          const SizedBox(height: 24),
          // Join code section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06), borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Column(children: [
              Text('Have an invite code?', style: TextStyle(color: Colors.white.withOpacity(0.7))),
              const SizedBox(height: 12),
              TextField(
                style: const TextStyle(color: Colors.white, letterSpacing: 4, fontSize: 18),
                textAlign: TextAlign.center, textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'ENTER CODE', hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                  filled: true, fillColor: Colors.white.withOpacity(0.08),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                onSubmitted: (code) => _join(context, ref, code),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildMode(BuildContext ctx, String title, String sub, IconData icon, List<Color> g, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(colors: g),
          boxShadow: [BoxShadow(color: g[0].withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: Colors.white, size: 28)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            Text(sub, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
          ])),
          const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 24),
        ]),
      ),
    );
  }

  Future<void> _challenge(BuildContext ctx, WidgetRef ref) async {
    try {
      final api = ref.read(arenaApiClientProvider);
      final result = await api.createBattle(type: 'friend');
      final code = result['inviteCode'] as String;
      if (ctx.mounted) {
        showDialog(context: ctx, builder: (c) => AlertDialog(
          backgroundColor: const Color(0xFF16213e),
          title: const Text('Battle Created! ⚔️', style: TextStyle(color: Colors.white)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Text(code, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 6))),
            const SizedBox(height: 16),
            const Text('Share with friend:', style: TextStyle(color: Colors.white54)),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Close')),
            ElevatedButton.icon(
              onPressed: () => Share.share('⚔️ Bible Battle! Code: $code\nJoin in Holy Word > Arena'),
              icon: const Icon(Icons.share, color: Colors.white, size: 18),
              label: const Text('Share', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366))),
          ],
        ));
      }
    } catch (e) {
      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _matchmake(BuildContext ctx, WidgetRef ref) async {
    try {
      final api = ref.read(arenaApiClientProvider);
      await api.matchmake();
      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Searching...')));
    } catch (e) {
      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _join(BuildContext ctx, WidgetRef ref, String code) async {
    if (code.isEmpty) return;
    try {
      final api = ref.read(arenaApiClientProvider);
      await api.joinBattle(code);
      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Joined!')));
    } catch (e) {
      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
