import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:geolocator/geolocator.dart';
import '../../providers/arena_providers.dart';
import '../arena_theme.dart';
import '../widgets/arena_widgets.dart';
import 'package:holy_word_app/features/community/services/church_service.dart';
import 'package:holy_word_app/features/arena/data/models/arena_user.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(arenaUserProvider);

    return Scaffold(
      backgroundColor: ArenaTheme.background,
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white54),
            tooltip: 'Sign out',
            onPressed: () => _showSignOutDialog(context, ref),
          ),
        ],
      ),
      body: Stack(
        children: [
          userAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: ArenaTheme.success)),
            error: (e, _) => Center(child: Text('$e', style: const TextStyle(color: Colors.red))),
            data: (user) {
              if (user == null) return const Center(child: Text('Not signed in', style: TextStyle(color: Colors.white)));
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Avatar + Name
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: ArenaTheme.primary,
                      backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                      child: user.photoUrl == null
                          ? Text(user.displayName[0], style: const TextStyle(color: Colors.white, fontSize: 32))
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(user.displayName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    LevelBadge(level: user.level, fontSize: 13),
                    const SizedBox(height: 24),

                    // XP Progress
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${user.xp} XP', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                              Text('Next: ${user.nextLevel}', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: user.levelProgress.clamp(0.0, 1.0),
                              minHeight: 8,
                              backgroundColor: Colors.white12,
                              valueColor: const AlwaysStoppedAnimation(ArenaTheme.primary),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text('${user.xpToNextLevel} XP to go', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stats Grid
                    Row(
                      children: [
                        _stat('Battles Won', '${user.battleWins}', ArenaTheme.discipleBlue),
                        const SizedBox(width: 12),
                        _stat('Win Streak', '${user.winStreak}', ArenaTheme.xpGold),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _stat('Accuracy', '${user.accuracy}%', ArenaTheme.success),
                        const SizedBox(width: 12),
                        _stat('Verses', '${user.versesMemorized}', ArenaTheme.elderPurple),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Pastor & Church Settings Card
                    _buildChurchSettingsCard(context, user),
                    const SizedBox(height: 24),

                    // Badges
                    if (user.badges.isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Badges',
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: user.badges.map((b) => Chip(
                          backgroundColor: ArenaTheme.xpGold.withOpacity(0.2),
                          label: Text(b.name, style: const TextStyle(color: ArenaTheme.xpGold, fontSize: 12)),
                          avatar: const Icon(Icons.star, color: ArenaTheme.xpGold, size: 16),
                        )).toList(),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          if (_isSaving)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: ArenaTheme.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChurchSettingsCard(BuildContext context, ArenaUser user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.psychology, color: ArenaTheme.primary, size: 24),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pastor Mode',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        user.isPastor ? 'Enabled - Can add sermon notes' : 'Disabled',
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              Switch(
                value: user.isPastor,
                activeColor: ArenaTheme.primary,
                activeTrackColor: ArenaTheme.primary.withOpacity(0.4),
                inactiveThumbColor: Colors.white24,
                inactiveTrackColor: Colors.white10,
                onChanged: (val) async {
                  setState(() {
                    _isSaving = true;
                  });
                  try {
                    final api = ref.read(arenaApiClientProvider);
                    await api.togglePastor(val);
                    ref.invalidate(arenaUserProvider);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(val ? 'Pastor mode enabled!' : 'Pastor mode disabled.')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error updating status: $e')),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isSaving = false;
                      });
                    }
                  }
                },
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.church, color: ArenaTheme.success, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'My Churches',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.edit_location_alt_outlined, color: ArenaTheme.success),
                onPressed: () => _showAddChurchDialog(context, user.churchIds),
                tooltip: 'Manage churches',
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (user.churchIds.isEmpty)
            Text(
              'No churches selected yet. Tap the edit button to follow or manage churches!',
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, fontStyle: FontStyle.italic),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: user.churchIds.map((church) {
                return Chip(
                  backgroundColor: ArenaTheme.success.withOpacity(0.1),
                  label: Text(church, style: const TextStyle(color: Colors.white, fontSize: 11)),
                  side: BorderSide(color: ArenaTheme.success.withOpacity(0.3)),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  void _showAddChurchDialog(BuildContext context, List<String> currentChurches) {
    final textController = TextEditingController();
    List<String> tempChurches = List.from(currentChurches);
    bool isSearchingNear = false;
    List<ChurchLocation> nearbyChurches = [];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: ArenaTheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Manage Churches', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Select churches to associate with your profile. Pastors can post quizzes to these, and members can view sermon notes from them.',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      // Currently selected
                      if (tempChurches.isNotEmpty) ...[
                        const Text('Active Selection:', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: tempChurches.map((church) {
                            return Chip(
                              backgroundColor: ArenaTheme.primary.withOpacity(0.2),
                              label: Text(church, style: const TextStyle(color: Colors.white, fontSize: 12)),
                              onDeleted: () {
                                setDialogState(() {
                                  tempChurches.remove(church);
                                });
                              },
                              deleteIconColor: Colors.redAccent,
                            );
                          }).toList(),
                        ),
                        const Divider(color: Colors.white24, height: 24),
                      ],
                      // Manual Add
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: textController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Enter custom church name...',
                                hintStyle: const TextStyle(color: Colors.white30),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.05),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            style: IconButton.styleFrom(backgroundColor: ArenaTheme.primary),
                            onPressed: () {
                              if (textController.text.trim().isNotEmpty) {
                                setDialogState(() {
                                  final name = textController.text.trim();
                                  if (!tempChurches.contains(name)) {
                                    tempChurches.add(name);
                                  }
                                  textController.clear();
                                });
                              }
                            },
                            icon: const Icon(Icons.add, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Search Nearby
                      ElevatedButton.icon(
                        onPressed: isSearchingNear
                            ? null
                            : () async {
                                setDialogState(() {
                                  isSearchingNear = true;
                                });
                                try {
                                  final permission = await Geolocator.checkPermission();
                                  if (permission == LocationPermission.denied) {
                                    await Geolocator.requestPermission();
                                  }
                                  final pos = await Geolocator.getCurrentPosition(
                                    desiredAccuracy: LocationAccuracy.low,
                                  );
                                  final results = await ChurchService().fetchChurches(pos.latitude, pos.longitude);
                                  setDialogState(() {
                                    nearbyChurches = results;
                                    isSearchingNear = false;
                                  });
                                } catch (e) {
                                  setDialogState(() {
                                    isSearchingNear = false;
                                  });
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Could not get nearby churches: $e')),
                                    );
                                  }
                                }
                              },
                        icon: isSearchingNear
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.my_location),
                        label: const Text('Find Nearby Churches'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      if (nearbyChurches.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text('Tap to Add Nearby Churches:', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 180),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: nearbyChurches.length,
                            itemBuilder: (context, index) {
                              final church = nearbyChurches[index];
                              final alreadyAdded = tempChurches.contains(church.name);
                              return ListTile(
                                dense: true,
                                title: Text(church.name, style: const TextStyle(color: Colors.white)),
                                subtitle: church.address.isNotEmpty
                                    ? Text(church.address, style: const TextStyle(color: Colors.white38), maxLines: 1, overflow: TextOverflow.ellipsis)
                                    : null,
                                trailing: Icon(
                                  alreadyAdded ? Icons.check_circle : Icons.add_circle_outline,
                                  color: alreadyAdded ? ArenaTheme.success : Colors.white30,
                                ),
                                onTap: () {
                                  setDialogState(() {
                                    if (alreadyAdded) {
                                      tempChurches.remove(church.name);
                                    } else {
                                      tempChurches.add(church.name);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    setState(() {
                      _isSaving = true;
                    });
                    try {
                      final api = ref.read(arenaApiClientProvider);
                      await api.updateChurches(tempChurches);
                      ref.invalidate(arenaUserProvider);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Churches updated successfully!')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error updating churches: $e')),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isSaving = false;
                        });
                      }
                    }
                  },
                  child: const Text('Save Selection', style: TextStyle(color: ArenaTheme.primary, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ArenaTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to sign out of Bible Arena?', style: TextStyle(color: Colors.white70)),
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
