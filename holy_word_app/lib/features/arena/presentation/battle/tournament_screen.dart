import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/arena_providers.dart';
import '../arena_theme.dart';

class TournamentScreen extends ConsumerStatefulWidget {
  final String? tournamentId;
  const TournamentScreen({super.key, this.tournamentId});

  @override
  ConsumerState<TournamentScreen> createState() => _TournamentScreenState();
}

class _TournamentScreenState extends ConsumerState<TournamentScreen> {
  Map<String, dynamic>? _tournament;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.tournamentId != null) {
      _loadTournament();
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadTournament() async {
    try {
      final api = ref.read(arenaApiClientProvider);
      final res = await api.getTournament(widget.tournamentId!);
      if (!mounted) return;
      setState(() { _tournament = res['tournament']; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArenaTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: Text(_tournament?['name'] ?? 'Tournament',
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: ArenaTheme.xpGold))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _tournament == null
                  ? _buildCreateOrJoin()
                  : _buildBracketView(),
    );
  }

  Widget _buildCreateOrJoin() {
    final codeCtrl = TextEditingController();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events_rounded, color: ArenaTheme.xpGold, size: 80),
          const SizedBox(height: 24),
          const Text('Church Tournament',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),

          // Join
          TextField(
            controller: codeCtrl,
            style: const TextStyle(color: Colors.white, letterSpacing: 4, fontSize: 20),
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'ENTER CODE',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2), letterSpacing: 4),
              filled: true, fillColor: Colors.white.withValues(alpha: 0.08),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: () async {
                if (codeCtrl.text.isEmpty) return;
                try {
                  final api = ref.read(arenaApiClientProvider);
                  final res = await api.joinTournament(codeCtrl.text.trim());
                  if (!mounted) return;
                  setState(() { _tournament = res['tournament']; });
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ArenaTheme.discipleBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: const Text('Join Tournament',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 24),

          // Divider
          Row(children: [
            Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.2))),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('or', style: TextStyle(color: Colors.white.withValues(alpha: 0.4)))),
            Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.2))),
          ]),
          const SizedBox(height: 24),

          // Create (pastor only)
          SizedBox(
            width: double.infinity, height: 52,
            child: OutlinedButton.icon(
              onPressed: () => _showCreateDialog(),
              icon: const Icon(Icons.add, color: ArenaTheme.xpGold),
              label: const Text('Create Tournament (Pastors)',
                  style: TextStyle(color: ArenaTheme.xpGold, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: ArenaTheme.xpGold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBracketView() {
    final status = _tournament!['status'] ?? 'registration';
    final brackets = _tournament!['brackets'] as List? ?? [];
    final participants = _tournament!['participants'] as List? ?? [];
    final code = _tournament!['code'] ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tournament header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [ArenaTheme.xpGold.withValues(alpha: 0.15), Colors.transparent]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ArenaTheme.xpGold.withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.emoji_events_rounded, color: ArenaTheme.xpGold, size: 36),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Code: $code', style: const TextStyle(
                    color: ArenaTheme.xpGold, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 3)),
                Text('${participants.length} players • ${status.toUpperCase()}',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(status).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8)),
                child: Text(status.toUpperCase(),
                    style: TextStyle(color: _statusColor(status), fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ]),
          ),
          const SizedBox(height: 24),

          // Bracket rounds
          if (brackets.isEmpty && status == 'registration')
            Center(child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(children: [
                const Icon(Icons.people_rounded, color: Colors.white38, size: 48),
                const SizedBox(height: 12),
                Text('Waiting for more players...',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16)),
                Text('Share code $code to invite players',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13)),
              ]),
            ))
          else
            ...brackets.asMap().entries.map((entry) {
              final roundIdx = entry.key;
              final round = entry.value as Map<String, dynamic>;
              final matches = round['matches'] as List? ?? [];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Round ${round['round'] ?? roundIdx + 1}',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...matches.map((match) => _buildMatchCard(match as Map<String, dynamic>)),
                  const SizedBox(height: 20),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> match) {
    final p1 = match['player1']?.toString() ?? 'TBD';
    final p2 = match['player2']?.toString() ?? 'TBD';
    final winnerId = match['winnerId'];
    final p1Win = winnerId != null && winnerId == match['player1'];
    final p2Win = winnerId != null && winnerId == match['player2'];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(children: [
        Expanded(child: _playerTile(p1, p1Win)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: ArenaTheme.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(6)),
          child: const Text('VS', style: TextStyle(
              color: ArenaTheme.primary, fontSize: 11, fontWeight: FontWeight.w900)),
        ),
        Expanded(child: _playerTile(p2, p2Win)),
      ]),
    );
  }

  Widget _playerTile(String name, bool isWinner) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(children: [
        CircleAvatar(radius: 16, backgroundColor: isWinner
            ? ArenaTheme.xpGold : Colors.white.withValues(alpha: 0.1),
          child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))),
        const SizedBox(height: 4),
        Text(name.length > 8 ? '${name.substring(0, 8)}...' : name,
            style: TextStyle(
              color: isWinner ? ArenaTheme.xpGold : Colors.white,
              fontSize: 12, fontWeight: isWinner ? FontWeight.bold : FontWeight.normal)),
        if (isWinner)
          const Text('🏆', style: TextStyle(fontSize: 14)),
      ]),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'registration': return ArenaTheme.discipleBlue;
      case 'active': return ArenaTheme.success;
      case 'completed': return ArenaTheme.xpGold;
      default: return Colors.white54;
    }
  }

  void _showCreateDialog() {
    final nameCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: ArenaTheme.surface,
      title: const Text('Create Tournament', style: TextStyle(color: Colors.white)),
      content: TextField(
        controller: nameCtrl, style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Tournament Name',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          filled: true, fillColor: Colors.white.withValues(alpha: 0.08),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
        ElevatedButton(
          onPressed: () async {
            if (nameCtrl.text.isEmpty) return;
            try {
              final api = ref.read(arenaApiClientProvider);
              final user = ref.read(arenaUserProvider).value;
              final res = await api.createTournament(nameCtrl.text, user?.churchId ?? '');
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                setState(() { _tournament = res['tournament']; });
              }
            } catch (e) {
              if (ctx.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')));
              }
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: ArenaTheme.xpGold),
          child: const Text('Create', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      ],
    ));
  }
}
