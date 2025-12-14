import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holy_word_app/features/bible/services/bible_service.dart';
import '../bible_screen.dart';

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
                    '${r['reference_book']} ${r['reference_chapter']}:${r['reference_verse']}';
                final refText = r['reference_text'] ?? 'Text unavailble';
                final refBookId = r['reference_book_id'] as int?;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  elevation: 2,
                  child: InkWell(
                    onTap: refBookId != null
                        ? () {
                            // Navigate to the reference
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BibleScreen(
                                  initialBookId: refBookId,
                                  initialChapter: r['reference_chapter'] as int,
                                  initialVerse: r['reference_verse'] as int,
                                ),
                              ),
                            );
                          }
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            refString,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            refText,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
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
