import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/arena_providers.dart';
import '../arena_theme.dart';
import 'sermon_quiz_screen.dart';
import 'sermon_composer_screen.dart';

class SermonHomeScreen extends ConsumerWidget {
  const SermonHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sermonsAsync = ref.watch(pendingSermonsProvider);
    final user = ref.watch(arenaUserProvider).value;

    return Scaffold(
      backgroundColor: ArenaTheme.background,
      appBar: AppBar(
        title: const Text('Sermon Notes', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent, elevation: 0,
        actions: [
          if (user?.isPastor == true)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const SermonComposerScreen(),
                ));
              },
            ),
        ],
      ),
      body: sermonsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: ArenaTheme.sermonPink)),
        error: (e, _) => Center(child: Text('$e', style: const TextStyle(color: Colors.red))),
        data: (quizzes) {
          if (quizzes.isEmpty) {
            return Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.church_rounded, color: ArenaTheme.sermonPink, size: 80),
                const SizedBox(height: 16),
                const Text('No Sermon Quizzes', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Your pastor will post quizzes here after sermons',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6)), textAlign: TextAlign.center),
              ],
            ));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: quizzes.length,
            itemBuilder: (ctx, idx) {
              final q = quizzes[idx];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [ArenaTheme.sermonPink.withValues(alpha: 0.15), ArenaTheme.xpGold.withValues(alpha: 0.05)]),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ArenaTheme.sermonPink.withValues(alpha: 0.3)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const CircleAvatar(backgroundColor: ArenaTheme.sermonPink,
                      child: Icon(Icons.church, color: Colors.white)),
                  title: Text(q.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text('${q.questionCount} questions • ${q.completedCount} completed',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => SermonQuizScreen(sermonId: q.id, title: q.title),
                    ));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final pointCtrls = List.generate(5, (_) => TextEditingController());
    final user = ref.read(arenaUserProvider).value;
    String? selectedChurch = user?.churchIds.isNotEmpty == true
        ? user!.churchIds.first
        : user?.churchId;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: ArenaTheme.surface,
              title: const Text('Create Sermon Quiz', style: TextStyle(color: Colors.white)),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (user != null && user.churchIds.length > 1) ...[
                        DropdownButtonFormField<String>(
                          value: selectedChurch,
                          dropdownColor: ArenaTheme.surface,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDec('Select Church to Post to'),
                          items: user.churchIds.map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c),
                          )).toList(),
                          onChanged: (val) {
                            setDialogState(() {
                              selectedChurch = val;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextField(
                        controller: titleCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDec('Sermon Title'),
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(5, (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TextField(
                          controller: pointCtrls[i],
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDec('Key Point ${i + 1}'),
                        ),
                      )),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    final points = pointCtrls.map((c) => c.text).where((t) => t.isNotEmpty).toList();
                    if (titleCtrl.text.isEmpty || points.isEmpty) return;
                    try {
                      final api = ref.read(arenaApiClientProvider);
                      await api.createSermonQuiz(
                        title: titleCtrl.text,
                        keyPoints: points,
                        churchId: selectedChurch ?? user?.churchId ?? '',
                      );
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sermon quiz created! 📖')),
                        );
                        ref.invalidate(pendingSermonsProvider);
                      }
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: ArenaTheme.sermonPink),
                  child: const Text('Create', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  InputDecoration _inputDec(String hint) => InputDecoration(
    hintText: hint, hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
    filled: true, fillColor: Colors.white.withValues(alpha: 0.08),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  );
}
