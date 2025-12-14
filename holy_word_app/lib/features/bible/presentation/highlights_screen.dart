import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holy_word_app/features/bible/services/highlights_service.dart';
import 'package:holy_word_app/features/bible/services/bible_service.dart';
import 'bible_screen.dart';

class HighlightsScreen extends StatefulWidget {
  const HighlightsScreen({super.key});

  @override
  State<HighlightsScreen> createState() => _HighlightsScreenState();
}

class _HighlightsScreenState extends State<HighlightsScreen> {
  final HighlightsService _highlightsService = HighlightsService();
  // We need BibleService to look up book names if we only have IDs
  // Since we are in a StatefulWidget, we might need a consumer or just use ref in a ConsumerWidget.
  // Converting to ConsumerStatefulWidget for easier provider access.

  late Future<List<Map<String, dynamic>>> _highlightsFuture;

  @override
  void initState() {
    super.initState();
    _loadHighlights();
  }

  void _loadHighlights() {
    setState(() {
      _highlightsFuture = _highlightsService.getAllHighlights();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Highlights')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _highlightsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No highlights yet'));
          }

          final highlights = snapshot.data!;

          // We need to resolve book names.
          // For now, we will display Book ID if we can't easily sync.
          // Better approach: Consumer wrapper to get BibleService

          return Consumer(
            builder: (context, ref, child) {
              final bibleService = ref.read(bibleServiceProvider);

              return ListView.builder(
                itemCount: highlights.length,
                itemBuilder: (context, index) {
                  final h = highlights[index];
                  final bookId = h['book_id'] as int;
                  final chapter = h['chapter'] as int;
                  final verse = h['verse'] as int;
                  final colorValue = h['color'] as int;

                  // Helper to get book name would be nice, but async in separate future?
                  // Just showing ID/Chapter/Verse for now or using a helper if existing.

                  return Dismissible(
                    key: Key(h['id'].toString()),
                    background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white)),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) async {
                      await _highlightsService.deleteHighlight(h['id']);
                    },
                    child: ListTile(
                      leading: CircleAvatar(
                          backgroundColor: Color(colorValue), radius: 10),
                      title: FutureBuilder<List<Map<String, dynamic>>>(
                          future: bibleService.getBooks(),
                          builder: (context, bookSnap) {
                            if (bookSnap.hasData) {
                              final books = bookSnap.data!;
                              final bookName = books.firstWhere(
                                  (b) => b['id'] == bookId,
                                  orElse: () =>
                                      {'name': 'Book $bookId'})['name'];
                              return Text('$bookName $chapter:$verse');
                            }
                            return Text('Book $bookId $chapter:$verse');
                          }),
                      subtitle: const Text('Tap to view'),
                      onTap: () {
                        // Navigate to BibleScreen with arguments
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => BibleScreen(
                                    initialBookId: bookId,
                                    initialChapter: chapter)));
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
