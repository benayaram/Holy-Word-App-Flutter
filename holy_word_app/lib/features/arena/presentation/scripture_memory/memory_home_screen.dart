import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/arena_providers.dart';
import '../../data/models/battle.dart';
import '../arena_theme.dart';
import 'memory_battle_screen.dart';

class MemoryHomeScreen extends ConsumerWidget {
  const MemoryHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(memoryProgressProvider);

    return Scaffold(
      backgroundColor: ArenaTheme.background,
      appBar: AppBar(
        title: const Text('Scripture Memory', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent, elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddVerseDialog(context, ref),
        backgroundColor: ArenaTheme.memoryPurple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Verse', style: TextStyle(color: Colors.white)),
      ),
      body: progressAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: ArenaTheme.memoryPurple)),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.psychology_rounded, color: ArenaTheme.memoryPurple, size: 80),
              const SizedBox(height: 16),
              const Text('Start Your Memory Journey',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Add a verse to begin memorizing',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
            ],
          ),
        ),
        data: (verses) {
          if (verses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.psychology_rounded, color: ArenaTheme.memoryPurple, size: 80),
                  const SizedBox(height: 16),
                  const Text('No Verses Yet',
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Tap + to add a verse from the Bible',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: verses.length,
            itemBuilder: (ctx, idx) {
              final v = verses[idx];
              return _buildVerseCard(context, v);
            },
          );
        },
      ),
    );
  }

  Widget _buildVerseCard(BuildContext context, MemoryVerse verse) {
    final levelColors = [
      ArenaTheme.neutralGray, ArenaTheme.success, ArenaTheme.discipleBlue,
      ArenaTheme.elderPurple, ArenaTheme.xpGold, ArenaTheme.primary,
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: levelColors[verse.currentLevel.clamp(0, 5)].withValues(alpha: 0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => MemoryBattleScreen(verse: verse),
          ));
        },
        title: Text(verse.reference,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(
              verse.verseText.length > 80 ? '${verse.verseText.substring(0, 80)}...' : verse.verseText,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
            ),
            const SizedBox(height: 10),
            // Level progress dots
            Row(
              children: [
                ...List.generate(5, (i) {
                  final completed = i < verse.currentLevel;
                  return Container(
                    width: 28, height: 28,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: completed
                          ? levelColors[(i + 1).clamp(0, 5)]
                          : Colors.white.withValues(alpha: 0.1),
                      border: Border.all(
                        color: completed
                            ? levelColors[(i + 1).clamp(0, 5)]
                            : Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Center(
                      child: completed
                          ? const Icon(Icons.check, color: Colors.white, size: 14)
                          : Text('${i + 1}',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
                    ),
                  );
                }),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: levelColors[verse.currentLevel.clamp(0, 5)].withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    verse.levelName,
                    style: TextStyle(
                      color: levelColors[verse.currentLevel.clamp(0, 5)],
                      fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            if (verse.bestTimeMs != null) ...[
              const SizedBox(height: 6),
              Text(
                '⏱ Best: ${(verse.bestTimeMs! / 1000).toStringAsFixed(1)}s',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAddVerseDialog(BuildContext context, WidgetRef ref) {
    final refController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: ArenaTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Verse to Memory', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Enter a Bible reference (e.g., John 3:16).\nThe verse text will be fetched automatically.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
              const SizedBox(height: 16),
              TextField(
                controller: refController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'e.g., John 3:16',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                final reference = refController.text.trim();
                if (reference.isEmpty) return;

                setDialogState(() => isLoading = true);
                try {
                  final api = ref.read(arenaApiClientProvider);
                  await api.saveMemoryProgress(
                    bookId: 0, chapter: 0, verse: 0,
                    reference: reference,
                    verseText: reference,
                    level: 0,
                  );
                  ref.invalidate(memoryProgressProvider);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Added "$reference" to memory')),
                    );
                  }
                } catch (e) {
                  setDialogState(() => isLoading = false);
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Failed to add verse: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: ArenaTheme.memoryPurple),
              child: isLoading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
