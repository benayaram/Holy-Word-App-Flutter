import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/arena_providers.dart';
import 'battle_play_screen.dart';

class BattleLobbyScreen extends ConsumerStatefulWidget {
  final String battleId;
  final bool isCreator;
  const BattleLobbyScreen({super.key, required this.battleId, this.isCreator = false});

  @override
  ConsumerState<BattleLobbyScreen> createState() => _BattleLobbyScreenState();
}

class _BattleLobbyScreenState extends ConsumerState<BattleLobbyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  String _status = 'Connecting...';
  int _playerCount = 1;
  StreamSubscription? _wsSub;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _connectAndJoin();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _wsSub?.cancel();
    super.dispose();
  }

  Future<void> _connectAndJoin() async {
    final ws = ref.read(arenaWsClientProvider);
    final user = ref.read(arenaUserProvider).value;
    if (user == null) return;

    await ws.connect(user.firebaseUid);

    _wsSub = ws.messages.listen((msg) {
      final event = msg['event'];
      final data = msg['data'] ?? {};

      switch (event) {
        case 'auth:success':
          ws.joinBattle(widget.battleId);
          setState(() => _status = 'Waiting for opponent...');
          break;
        case 'battle:player_joined':
          setState(() {
            _playerCount = data['playerCount'] ?? _playerCount;
            if (_playerCount >= 2) _status = 'Opponent found!';
          });
          break;
        case 'battle:ready_check':
          setState(() => _status = 'Both players connected! Starting...');
          ws.sendReady(widget.battleId);
          break;
        case 'battle:question':
          // Battle started! Navigate to play screen
          if (mounted) {
            Navigator.pushReplacement(context, MaterialPageRoute(
              builder: (_) => BattlePlayScreen(
                battleId: widget.battleId, firstQuestion: data)));
          }
          break;
        case 'error':
          setState(() => _status = 'Error: ${data['message']}');
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: const Text('Battle Lobby', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated searching icon
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (ctx, child) => Transform.scale(
                scale: 1.0 + _pulseCtrl.value * 0.1, child: child),
              child: Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4facfe), Color(0xFF00f2fe)]),
                  boxShadow: [BoxShadow(
                    color: const Color(0xFF4facfe).withOpacity(0.4),
                    blurRadius: 30, spreadRadius: 5)],
                ),
                child: const Icon(Icons.search_rounded, color: Colors.white, size: 56),
              ),
            ),
            const SizedBox(height: 32),
            Text(_status, style: const TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Text('$_playerCount/2 players',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16)),
            const SizedBox(height: 32),
            if (_playerCount < 2)
              const SizedBox(width: 200, child: LinearProgressIndicator(
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation(Color(0xFF4facfe)),
              )),
            const SizedBox(height: 40),
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white54),
              label: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
          ],
        ),
      ),
    );
  }
}
