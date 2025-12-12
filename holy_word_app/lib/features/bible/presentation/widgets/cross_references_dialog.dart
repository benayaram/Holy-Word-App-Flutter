import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holy_word_app/features/bible/services/bible_service.dart';

class CrossReferencesDialog extends ConsumerWidget {
  final int bookId; // We need IDs to query refs
  final int chapter;
  final int verse;
  final String verseReference;

  const CrossReferencesDialog({
    super.key,
    required this.bookId,
    required this.chapter,
    required this.verse,
    required this.verseReference,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bibleService = ref.read(bibleServiceProvider);

    return AlertDialog(
      title: Text('Cross References: $verseReference'),
      content: SizedBox(
        width: double.maxFinite,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: bibleService.getCrossReferences(bookId, chapter, verse),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No cross references found.'));
            }

            final refs = snapshot.data!;
            return ListView.builder(
              shrinkWrap: true,
              itemCount: refs.length,
              itemBuilder: (context, index) {
                final r = refs[index];
                final refString =
                    '${r['ref_book_name']} ${r['ref_chapter']}:${r['ref_verse']}';
                return ListTile(
                  title: Text(
                    refString,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(r['ref_text'] ?? ''),
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
