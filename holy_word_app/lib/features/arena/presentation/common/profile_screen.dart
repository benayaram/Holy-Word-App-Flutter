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
          if (user.isPastor) ...[
            const Divider(color: Colors.white12, height: 32),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ArenaTheme.xpGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.church_rounded, color: ArenaTheme.xpGold, size: 22),
              ),
              title: const Text(
                'Church Profile Editor',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              subtitle: const Text(
                'Update location, description and cover photo',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 16),
              onTap: () => _showChurchProfileEditor(context, user.churchIds),
            ),
          ],
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
                return ActionChip(
                  backgroundColor: ArenaTheme.success.withOpacity(0.1),
                  label: Text(church, style: const TextStyle(color: Colors.white, fontSize: 11)),
                  side: BorderSide(color: ArenaTheme.success.withOpacity(0.3)),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  onPressed: () => _showChurchProfileDialog(context, church),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  void _showAddChurchDialog(BuildContext context, List<String> currentChurches) {
    final searchController = TextEditingController();
    List<String> tempChurches = List.from(currentChurches);
    bool isSearchingNear = false;
    List<ChurchLocation> nearbyChurches = [];
    List<String> availableChurches = [];
    List<String> filteredChurches = [];
    bool isLoadingAvailable = true;

    showDialog(
      context: context,
      builder: (ctx) {
        final api = ref.read(arenaApiClientProvider);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Load available registered churches on first open
            if (isLoadingAvailable) {
              api.getChurchesList().then((list) {
                setDialogState(() {
                  availableChurches = list;
                  filteredChurches = list.where((c) => !tempChurches.contains(c)).toList();
                  isLoadingAvailable = false;
                });
              }).catchError((err) {
                setDialogState(() {
                  isLoadingAvailable = false;
                });
              });
            }

            void filterSearch(String query) {
              setDialogState(() {
                filteredChurches = availableChurches
                    .where((c) =>
                        c.toLowerCase().contains(query.toLowerCase()) &&
                        !tempChurches.contains(c))
                    .toList();
              });
            }

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
                      
                      // Active Selection
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
                                  filterSearch(searchController.text);
                                });
                              },
                              deleteIconColor: Colors.redAccent,
                            );
                          }).toList(),
                        ),
                        const Divider(color: Colors.white24, height: 24),
                      ],

                      // Search Dropdown List Input
                      const Text('Search Registered Churches:', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: searchController,
                        style: const TextStyle(color: Colors.white),
                        onChanged: filterSearch,
                        decoration: InputDecoration(
                          hintText: 'Type to search...',
                          hintStyle: const TextStyle(color: Colors.white30),
                          prefixIcon: const Icon(Icons.search, color: Colors.white54),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 8),

                      if (isLoadingAvailable)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(color: ArenaTheme.primary, strokeWidth: 2),
                          ),
                        )
                      else ...[
                        Container(
                          constraints: const BoxConstraints(maxHeight: 150),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: filteredChurches.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'No matching registered churches found.',
                                        style: TextStyle(color: Colors.white38, fontSize: 12),
                                        textAlign: TextAlign.center,
                                      ),
                                      if (searchController.text.trim().isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            final name = searchController.text.trim();
                                            setDialogState(() {
                                              if (!tempChurches.contains(name)) {
                                                tempChurches.add(name);
                                              }
                                              searchController.clear();
                                              filterSearch('');
                                            });
                                          },
                                          icon: const Icon(Icons.add, size: 14),
                                          label: Text('Register "${searchController.text.trim()}"', style: const TextStyle(fontSize: 11)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: ArenaTheme.primary,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: filteredChurches.length,
                                  itemBuilder: (context, idx) {
                                    final item = filteredChurches[idx];
                                    return ListTile(
                                      title: Text(item, style: const TextStyle(color: Colors.white, fontSize: 13)),
                                      trailing: const Icon(Icons.add, color: ArenaTheme.success, size: 16),
                                      dense: true,
                                      onTap: () {
                                        setDialogState(() {
                                          tempChurches.add(item);
                                          searchController.clear();
                                          filterSearch('');
                                        });
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
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

  void _showChurchProfileDialog(BuildContext context, String churchName) {
    showDialog(
      context: context,
      builder: (ctx) {
        final api = ref.read(arenaApiClientProvider);
        return AlertDialog(
          backgroundColor: ArenaTheme.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: EdgeInsets.zero,
          content: FutureBuilder<Map<String, dynamic>>(
            future: api.getChurchProfile(churchName),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 250,
                  child: Center(child: CircularProgressIndicator(color: ArenaTheme.primary)),
                );
              }
              if (snapshot.hasError) {
                return SizedBox(
                  height: 200,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)),
                    ),
                  ),
                );
              }

              final profile = snapshot.data ?? {};
              final desc = profile['description'] ?? 'A welcoming community focused on faith and worship.';
              final loc = profile['location'] ?? 'No address provided';
              final imgUrl = profile['imageUrl'];
              final pastor = profile['pastorName'] ?? 'Lead Pastor';
              final contact = profile['contact'] ?? 'No contact info';

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [
                        Container(
                          height: 140,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                            gradient: const LinearGradient(
                              colors: ArenaTheme.sermonGradients,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            image: imgUrl != null && imgUrl.isNotEmpty
                                ? DecorationImage(image: NetworkImage(imgUrl), fit: BoxFit.cover)
                                : null,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: CircleAvatar(
                            backgroundColor: Colors.black54,
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            churchName,
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.person, color: ArenaTheme.xpGold, size: 16),
                              const SizedBox(width: 6),
                              Text('Pastor: $pastor', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text('ABOUT OUR CHURCH', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
                          const SizedBox(height: 6),
                          Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
                          const Divider(color: Colors.white12, height: 24),
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: ArenaTheme.primary, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(loc, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.phone, color: ArenaTheme.accent, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(contact, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showChurchProfileEditor(BuildContext context, List<String> pastorChurches) {
    if (pastorChurches.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: ArenaTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('No Associated Churches', style: TextStyle(color: Colors.white)),
          content: const Text(
            'You must add at least one church to your active selection first in "My Churches" before you can edit its profile.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK', style: TextStyle(color: ArenaTheme.primary)),
            ),
          ],
        ),
      );
      return;
    }

    String selectedChurch = pastorChurches.first;
    final locationController = TextEditingController();
    final descriptionController = TextEditingController();
    final contactController = TextEditingController();
    final imageController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        final api = ref.read(arenaApiClientProvider);
        return StatefulBuilder(
          builder: (context, setEditorState) {
            return AlertDialog(
              backgroundColor: ArenaTheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Church Profile Editor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: double.maxFinite,
                child: FutureBuilder<Map<String, dynamic>>(
                  future: api.getChurchProfile(selectedChurch),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator(color: ArenaTheme.primary)),
                      );
                    }
                    
                    if (snapshot.hasData) {
                      final p = snapshot.data!;
                      if (locationController.text.isEmpty && descriptionController.text.isEmpty) {
                        locationController.text = p['location'] ?? '';
                        descriptionController.text = p['description'] ?? '';
                        contactController.text = p['contact'] ?? '';
                        imageController.text = p['imageUrl'] ?? '';
                      }
                    }

                    return SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Select which of your churches to customize:',
                            style: TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: selectedChurch,
                            dropdownColor: ArenaTheme.surface,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.05),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: pastorChurches.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setEditorState(() {
                                  selectedChurch = val;
                                  locationController.clear();
                                  descriptionController.clear();
                                  contactController.clear();
                                  imageController.clear();
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          const Text('Location / Address', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: locationController,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'e.g. 123 Faith Lane, Cityville',
                              hintStyle: const TextStyle(color: Colors.white30),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.05),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text('Description', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: descriptionController,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Describe your church history, community focus or vision...',
                              hintStyle: const TextStyle(color: Colors.white30),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.05),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text('Contact Information', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: contactController,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'e.g. info@ourchurch.org or +1 (555) 019-2834',
                              hintStyle: const TextStyle(color: Colors.white30),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.05),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text('Cover Image URL (Optional)', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: imageController,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'e.g. https://images.unsplash.com/photo-...',
                              hintStyle: const TextStyle(color: Colors.white30),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.05),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
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
                      await api.saveChurchProfile(
                        name: selectedChurch,
                        location: locationController.text.trim(),
                        description: descriptionController.text.trim(),
                        imageUrl: imageController.text.trim().isNotEmpty ? imageController.text.trim() : null,
                        contact: contactController.text.trim().isNotEmpty ? contactController.text.trim() : null,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Church profile saved successfully!')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error saving profile: $e')),
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
                  child: const Text('Save Profile', style: TextStyle(color: ArenaTheme.primary, fontWeight: FontWeight.bold)),
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
