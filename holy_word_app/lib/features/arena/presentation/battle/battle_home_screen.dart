import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/arena_providers.dart';
import '../arena_theme.dart';
import 'battle_lobby_screen.dart';

class BattleHomeScreen extends ConsumerStatefulWidget {
  const BattleHomeScreen({super.key});

  @override
  ConsumerState<BattleHomeScreen> createState() => _BattleHomeScreenState();
}

class _BattleHomeScreenState extends ConsumerState<BattleHomeScreen> {
  final _inviteCodeController = TextEditingController();
  bool _isCreating = false;
  bool _isMatchmaking = false;

  @override
  void dispose() {
    _inviteCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArenaTheme.background,
      appBar: AppBar(
        title: const Text('Trivia Battle', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Challenge a Friend
            _buildModeCard(
              icon: Icons.person_add_rounded,
              title: 'Challenge a Friend',
              subtitle: 'Create a room and share the invite code',
              gradient: [ArenaTheme.quizBlue, ArenaTheme.quizCyan],
              isLoading: _isCreating,
              onTap: _createBattle,
            ),
            const SizedBox(height: 16),

            // Random Matchmaking
            _buildModeCard(
              icon: Icons.shuffle_rounded,
              title: 'Random Opponent',
              subtitle: 'Get matched with another player',
              gradient: [ArenaTheme.memoryPurple, ArenaTheme.memoryPurpleDark],
              isLoading: _isMatchmaking,
              onTap: _startMatchmaking,
            ),
            const SizedBox(height: 24),

            // Coming Soon banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Icon(Icons.construction_rounded, color: ArenaTheme.xpGold.withValues(alpha: 0.7), size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'More modes coming soon!',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Solo vs AI and Church Tournaments are on the way.',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Join with Invite Code
            Text(
              'Join with Invite Code',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inviteCodeController,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(color: Colors.white, letterSpacing: 2, fontSize: 18),
                    decoration: InputDecoration(
                      hintText: 'Enter code',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _joinBattle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ArenaTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Join', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(colors: gradient),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 18),
          ],
        ),
      ),
    );
  }

  Future<void> _createBattle() async {
    setState(() => _isCreating = true);
    try {
      final api = ref.read(arenaApiClientProvider);
      final result = await api.createBattle(type: 'friend');
      final inviteCode = result['inviteCode'] as String;
      final battleId = result['battleId'] as String;

      if (!mounted) return;

      // Show invite code dialog with share
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: ArenaTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Battle Created!', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Share this code with your friend:',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: ArenaTheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  inviteCode,
                  style: const TextStyle(
                    color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 4),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: inviteCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Code copied!')),
                      );
                    },
                    icon: const Icon(Icons.copy, color: Colors.white54),
                    tooltip: 'Copy code',
                  ),
                  IconButton(
                    onPressed: () {
                      Share.share(
                        '⚔️ I challenge you to a Bible Trivia Battle!\n\n'
                        'Join with code: $inviteCode\n\n'
                        'Download Holy Word and test your Bible knowledge!',
                      );
                    },
                    icon: const Icon(Icons.share, color: Colors.white54),
                    tooltip: 'Share invite',
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _navigateToLobby(battleId);
              },
              child: const Text('Enter Lobby', style: TextStyle(color: ArenaTheme.primary)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create battle: $e')),
      );
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _startMatchmaking() async {
    setState(() => _isMatchmaking = true);
    try {
      final api = ref.read(arenaApiClientProvider);
      final result = await api.matchmake();
      final battleId = result['battleId'] as String;

      if (!mounted) return;
      _navigateToLobby(battleId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Matchmaking failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isMatchmaking = false);
    }
  }

  void _joinBattle() {
    final code = _inviteCodeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an invite code')),
      );
      return;
    }
    _navigateToLobby(code, isCode: true);
  }

  void _navigateToLobby(String id, {bool isCode = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BattleLobbyScreen(
          battleId: isCode ? null : id,
          inviteCode: isCode ? id : null,
        ),
      ),
    );
  }
}
