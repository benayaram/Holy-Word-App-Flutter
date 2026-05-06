import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/arena_providers.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 2, vsync: this); }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        title: const Text('Leaderboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent, elevation: 0,
        bottom: TabBar(controller: _tabCtrl, indicatorColor: const Color(0xFFf59e0b),
          tabs: const [Tab(text: '🌍 Global'), Tab(text: '⛪ Church')]),
      ),
      body: TabBarView(controller: _tabCtrl, children: [
        _buildLeaderboardList('global'),
        _buildLeaderboardList('church'),
      ]),
    );
  }

  Widget _buildLeaderboardList(String type) {
    final lbAsync = ref.watch(leaderboardProvider(type));
    return lbAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFf59e0b))),
      error: (e, _) => Center(child: Text('$e', style: const TextStyle(color: Colors.red))),
      data: (entries) {
        if (entries.isEmpty) {
          return Center(child: Text('No data yet', style: TextStyle(color: Colors.white.withOpacity(0.5))));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: entries.length,
          itemBuilder: (ctx, idx) {
            final e = entries[idx];
            final isTop3 = idx < 3;
            final colors = [const Color(0xFFf59e0b), const Color(0xFFc0c0c0), const Color(0xFFcd7f32)];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isTop3 ? colors[idx].withOpacity(0.1) : Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isTop3 ? colors[idx].withOpacity(0.3) : Colors.transparent),
              ),
              child: Row(children: [
                SizedBox(width: 36, child: Text(
                  isTop3 ? ['🥇','🥈','🥉'][idx] : '#${e.rank}',
                  style: TextStyle(fontSize: isTop3 ? 22 : 16, color: Colors.white, fontWeight: FontWeight.bold),
                )),
                CircleAvatar(radius: 18, backgroundColor: const Color(0xFF3b82f6),
                  backgroundImage: e.photoUrl != null ? NetworkImage(e.photoUrl!) : null,
                  child: e.photoUrl == null ? Text(e.displayName[0], style: const TextStyle(color: Colors.white)) : null),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(e.displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  Text(e.level, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text('${e.xp} XP', style: const TextStyle(color: Color(0xFFf59e0b), fontWeight: FontWeight.bold)),
                  Text('${e.battleWins} wins', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                ]),
              ]),
            );
          },
        );
      },
    );
  }
}
