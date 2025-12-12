import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:holy_word_app/features/bible/services/notes_service.dart';
import 'cross_references_dialog.dart';
import 'verse_image_generator.dart';

class VerseActionsBottomSheet extends StatelessWidget {
  final String text;
  final String reference;
  final int bookId;
  final int chapter;
  final int verse;

  const VerseActionsBottomSheet({
    super.key,
    required this.text,
    required this.reference,
    required this.bookId,
    required this.chapter,
    required this.verse,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            reference,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildActionButton(
                context,
                icon: Icons.copy,
                label: 'Copy',
                onTap: () {
                  Clipboard.setData(ClipboardData(text: '$text\n\n$reference'));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Verse copied to clipboard')),
                  );
                },
              ),
              _buildActionButton(
                context,
                icon: Icons.share,
                label: 'Share',
                onTap: () {
                  Share.share('$text\n\n$reference');
                  Navigator.pop(context);
                },
              ),
              _buildActionButton(
                context,
                icon: Icons.image,
                label: 'Image',
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => VerseImageGenerator(
                      text: text,
                      reference: reference,
                    ),
                  );
                },
              ),
              _buildActionButton(
                context,
                icon: Icons.note_add,
                label: 'Note',
                onTap: () async {
                  Navigator.pop(context);
                  final notesService = NotesService();
                  try {
                    await notesService.addNote(text, reference, '');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Verse added to Notes')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error adding note: $e')),
                      );
                    }
                  }
                },
              ),
              _buildActionButton(
                context,
                icon: Icons.compare_arrows,
                label: 'Refs',
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => CrossReferencesDialog(
                      bookId: bookId,
                      chapter: chapter,
                      verse: verse,
                      verseReference: reference,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}
