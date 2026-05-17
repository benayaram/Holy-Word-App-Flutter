import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../providers/arena_providers.dart';
import '../arena_theme.dart';
import 'battle_play_screen.dart';

class BattleLobbyScreen extends ConsumerStatefulWidget {
  final String? battleId;
  final String? inviteCode;

  const BattleLobbyScreen({super.key, this.battleId, this.inviteCode});

  @override
  ConsumerState<BattleLobbyScreen> createState() => _BattleLobbyScreenState();
}

class _BattleLobbyScreenState extends ConsumerState<BattleLobbyScreen> {
  StreamSubscription<Map<String, dynamic>>? _wsSub;
  String _status = 'Connecting...';
  String? _opponentName;
  bool _isConnecting = true;
  String? _resolvedBattleId;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    try {
      // If we have an invite code but no battle ID, join first
      if (widget.inviteCode != null && widget.battleId == null) {
        final api = ref.read(arenaApiClientProvider);
        final result = await api.joinBattle(widget.inviteCode!);
        _resolvedBattleId = result['battleId'] as String;
        _opponentName = result['opponent']?['displayName'] as String?;
      } else {
        _resolvedBattleId = widget.battleId;
      }

      if (!mounted) return;

      // Get Firebase ID token for WebSocket auth
      final fbUser = fb.FirebaseAuth.instance.currentUser;
      if (fbUser == null) {
        setState(() {
          _status = 'Not authenticated';
          _isConnecting = false;
        });
        return;
      }

      final token = await fbUser.getIdToken(true);
      if (token == null || !mounted) return;

      final ws = ref.read(arenaWsClientProvider);
      await ws.connect(token);

      _wsSub = ws.messages.listen((msg) {
        if (!mounted) return;

        final event = msg['event'];
        final data = msg['data'] ?? {};

        switch (event) {
          case 'auth:success':
            ws.joinBattle(_resolvedBattleId!);
            setState(() => _status = 'Waiting for opponent...');
            break;

          case 'auth:error':
            setState(() {
              _status = 'Authentication failed';
              _isConnecting = false;
            });
            break;

          case 'connection:failed':
            setState(() {
              _status = 'Connection failed. Please check your network.';
              _isConnecting = false;
            });
            break;

          case 'battle:player_joined':
            setState(() {
              _status = '${data['playerCount']}/2 players connected';
            });
            break;

          case 'battle:ready_check':
            ws.sendReady(_resolvedBattleId!);
            setState(() => _status = 'Starting battle...');
            break;

          case 'battle:question':
            // Battle started — navigate to play screen
            _wsSub?.cancel();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => BattlePlayScreen(battleId: _resolvedBattleId!),
              ),
            );
            break;

          case 'battle:player_disconnected':
            setState(() {
              _status = 'Opponent disconnected';
              _isConnecting = false;
            });
            break;

          case 'error':
            setState(() {
              _status = data['message'] ?? 'An error occurred';
              _isConnecting = false;
            });
            break;
        }
      });

      if (mounted) setState(() => _isConnecting = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = 'Failed to connect: ${e.toString().replaceAll('Exception: ', '')}';
        _isConnecting = false;
      });
    }
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    ref.read(arenaWsClientProvider).disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArenaTheme.background,
      appBar: AppBar(
        title: const Text('Battle Lobby'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isConnecting || _status.contains('Waiting'))
                const CircularProgressIndicator(color: ArenaTheme.primary)
              else
                const Icon(Icons.sports_esports_rounded, color: ArenaTheme.primary, size: 64),
              const SizedBox(height: 24),
              Text(
                _status,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              if (_opponentName != null) ...[
                const SizedBox(height: 8),
                Text(
                  'vs $_opponentName',
                  style: TextStyle(color: ArenaTheme.xpGold.withValues(alpha: 0.8), fontSize: 16),
                ),
              ],
              if (_status.contains('failed') || _status.contains('disconnected')) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ArenaTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
