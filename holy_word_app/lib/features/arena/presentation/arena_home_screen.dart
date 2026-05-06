import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import '../providers/arena_providers.dart';
import '../data/models/arena_user.dart';
import 'quiz/quiz_home_screen.dart';
import 'scripture_memory/memory_home_screen.dart';
import 'battle/battle_home_screen.dart';
import 'sermon/sermon_home_screen.dart';
import 'common/leaderboard_screen.dart';
import 'common/profile_screen.dart';

class ArenaHomeScreen extends ConsumerStatefulWidget {
  const ArenaHomeScreen({super.key});

  @override
  ConsumerState<ArenaHomeScreen> createState() => _ArenaHomeScreenState();
}

class _ArenaHomeScreenState extends ConsumerState<ArenaHomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(firebaseAuthProvider);
    final isAuth = authState.value != null;

    return Scaffold(
      body: isAuth ? _buildArenaHub() : _buildSignInScreen(),
    );
  }

  Widget _buildSignInScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Arena Logo
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + _pulseController.value * 0.05,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFe94560), Color(0xFFf97316)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFe94560).withValues(alpha: 0.4),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.sports_esports_rounded,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Bible Arena',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Test your Bible knowledge • Challenge friends',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                // Google Sign In
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _signInWithGoogle,
                    icon: const Icon(Icons.account_circle, size: 24),
                    label: const Text(
                      'Sign in with Google',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Anonymous Sign In
                TextButton(
                  onPressed: _signInAnonymously,
                  child: Text(
                    'Play as Guest',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArenaHub() {
    final userAsync = ref.watch(arenaUserProvider);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header with XP and profile
            SliverToBoxAdapter(
              child: userAsync.when(
                data: (user) => _buildHeader(user),
                loading: () => const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator(color: Colors.white)),
                ),
                error: (e, _) => _buildHeader(null),
              ),
            ),

            // Game Mode Cards
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                delegate: SliverChildListDelegate([
                  _buildModeCard(
                    title: 'Scripture\nMemory',
                    subtitle: '5 levels to memorize',
                    icon: Icons.psychology_rounded,
                    gradient: [const Color(0xFF667eea), const Color(0xFF764ba2)],
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const MemoryHomeScreen())),
                  ),
                  _buildModeCard(
                    title: 'Bible\nQuiz',
                    subtitle: 'Solo challenge',
                    icon: Icons.quiz_rounded,
                    gradient: [const Color(0xFFf093fb), const Color(0xFFf5576c)],
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const QuizHomeScreen())),
                  ),
                  _buildModeCard(
                    title: 'Trivia\nBattle',
                    subtitle: 'Challenge anyone',
                    icon: Icons.sports_esports_rounded,
                    gradient: [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const BattleHomeScreen())),
                  ),
                  _buildModeCard(
                    title: 'Sermon\nNotes',
                    subtitle: 'Test your memory',
                    icon: Icons.church_rounded,
                    gradient: [const Color(0xFFfa709a), const Color(0xFFfee140)],
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const SermonHomeScreen())),
                  ),
                ]),
              ),
            ),

            // Quick Actions
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: _buildQuickAction(
                        icon: Icons.leaderboard_rounded,
                        label: 'Leaderboard',
                        color: const Color(0xFFf59e0b),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickAction(
                        icon: Icons.person_rounded,
                        label: 'My Profile',
                        color: const Color(0xFF10b981),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const ProfileScreen())),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ArenaUser? user) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFe94560),
                backgroundImage: user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
                child: user?.photoUrl == null
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ?? 'Welcome!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getLevelColor(user?.level ?? 'Seeker'),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            user?.level ?? 'Seeker',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${user?.xp ?? 0} XP',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Battle wins badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events_rounded, color: Color(0xFFf59e0b), size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${user?.battleWins ?? 0}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // XP Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (user?.levelProgress ?? 0).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation(Color(0xFFe94560)),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                user?.level ?? 'Seeker',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
              ),
              Text(
                '${user?.xpToNextLevel ?? 500} XP to ${user?.nextLevel ?? 'Disciple'}',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'Disciple': return const Color(0xFF3b82f6);
      case 'Elder': return const Color(0xFF8b5cf6);
      case 'Apostle': return const Color(0xFFf59e0b);
      case 'Living Word': return const Color(0xFFe94560);
      default: return const Color(0xFF6b7280);
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final account = await googleSignIn.signIn();
      if (account == null) return;

      final auth = await account.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );

      await fb.FirebaseAuth.instance.signInWithCredential(credential);

      // Register on backend
      if (mounted) {
        await ref.read(arenaUserProvider.notifier).register(
              displayName: account.displayName,
            );
      }
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign in failed: $e')),
        );
      }
    }
  }

  Future<void> _signInAnonymously() async {
    try {
      await fb.FirebaseAuth.instance.signInAnonymously();
      if (mounted) {
        await ref.read(arenaUserProvider.notifier).register(
              displayName: 'Guest Player',
            );
      }
    } catch (e) {
      debugPrint('Anonymous sign-in error: $e');
    }
  }
}
