import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import '../providers/arena_providers.dart';
import '../data/models/arena_user.dart';
import 'arena_theme.dart';
import 'quiz/quiz_home_screen.dart';
import 'scripture_memory/memory_home_screen.dart';
import 'battle/battle_home_screen.dart';
import 'sermon/sermon_home_screen.dart';
import 'common/leaderboard_screen.dart';
import 'common/profile_screen.dart';
import 'common/arena_help_screen.dart';
import '../../../../core/services/notification_service.dart';

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initPushNotifications();
    });
  }

  Future<void> _initPushNotifications() async {
    final api = ref.read(arenaApiClientProvider);
    
    // Tap callback redirect to SermonHomeScreen
    NotificationService().onNotificationTap = (data) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SermonHomeScreen()),
        );
      }
    };

    await NotificationService().setupFCM(
      onTokenRefresh: (token) async {
        try {
          await api.updateFcmToken(token);
        } catch (e) {
          debugPrint('Failed to save FCM token: $e');
        }
      },
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(firebaseAuthProvider);

    return Scaffold(
      body: authState.when(
        loading: () => Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [ArenaTheme.background, ArenaTheme.surface],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: ArenaTheme.primary),
          ),
        ),
        error: (e, _) => Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [ArenaTheme.background, ArenaTheme.surface],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: ArenaTheme.primary, size: 48),
                const SizedBox(height: 16),
                Text('Something went wrong', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 16)),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.invalidate(firebaseAuthProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (user) => user != null ? _buildArenaHub() : _buildSignInScreen(),
      ),
    );
  }

  Widget _buildSignInScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [ArenaTheme.background, ArenaTheme.surface, Color(0xFF0f3460)],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                        colors: [ArenaTheme.primary, ArenaTheme.accent],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: ArenaTheme.primary.withValues(alpha: 0.4),
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
          colors: [ArenaTheme.background, ArenaTheme.surface],
        ),
      ),
      child: SafeArea(
        child: userAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: ArenaTheme.primary),
          ),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_rounded, color: ArenaTheme.primary, size: 56),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to load profile',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$e',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => ref.read(arenaUserProvider.notifier).refresh(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ArenaTheme.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await fb.FirebaseAuth.instance.signOut();
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text('Sign Out'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white30),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          data: (user) => _buildHubContent(user),
        ),
      ),
    );
  }

  Widget _buildHubContent(ArenaUser? user) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(user)),
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
                gradient: [ArenaTheme.memoryPurple, ArenaTheme.memoryPurpleDark],
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const MemoryHomeScreen())),
              ),
              _buildModeCard(
                title: 'Bible\nQuiz',
                subtitle: 'Solo challenge',
                icon: Icons.quiz_rounded,
                gradient: [ArenaTheme.battlePink, ArenaTheme.battleRed],
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const QuizHomeScreen())),
              ),
              _buildModeCard(
                title: 'Trivia\nBattle',
                subtitle: 'Challenge anyone',
                icon: Icons.sports_esports_rounded,
                gradient: [ArenaTheme.quizBlue, ArenaTheme.quizCyan],
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const BattleHomeScreen())),
              ),
              _buildModeCard(
                title: 'Sermon\nNotes',
                subtitle: 'Test your memory',
                icon: Icons.church_rounded,
                gradient: [ArenaTheme.sermonPink, ArenaTheme.sermonYellow],
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SermonHomeScreen())),
              ),
            ]),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: _buildQuickAction(
                    icon: Icons.leaderboard_rounded,
                    label: 'Leaderboard',
                    color: ArenaTheme.xpGold,
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAction(
                    icon: Icons.person_rounded,
                    label: 'My Profile',
                    color: ArenaTheme.success,
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
    );
  }

  Widget _buildHeader(ArenaUser? user) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: ArenaTheme.primary,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events_rounded, color: ArenaTheme.xpGold, size: 18),
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
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ArenaHelpScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ArenaTheme.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: ArenaTheme.primary.withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.help_outline_rounded, color: ArenaTheme.primary, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (user?.levelProgress ?? 0).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation(ArenaTheme.primary),
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
      case 'Disciple': return ArenaTheme.discipleBlue;
      case 'Elder': return ArenaTheme.elderPurple;
      case 'Apostle': return ArenaTheme.xpGold;
      case 'Living Word': return ArenaTheme.primary;
      default: return ArenaTheme.neutralGray;
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

      if (mounted) {
        await ref.read(arenaUserProvider.notifier).register(
              displayName: account.displayName,
            );
        _initPushNotifications();
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
        _initPushNotifications();
      }
    } catch (e) {
      debugPrint('Anonymous sign-in error: $e');
    }
  }
}
