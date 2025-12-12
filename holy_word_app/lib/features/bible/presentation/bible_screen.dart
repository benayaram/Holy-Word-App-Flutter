import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holy_word_app/l10n/app_localizations.dart';
import 'package:holy_word_app/core/providers/language_provider.dart';
import '../services/bible_service.dart';
import 'bible_search_delegate.dart';
import 'bible_tools_screen.dart';
import 'widgets/verse_actions_bottom_sheet.dart';

class BibleScreen extends ConsumerStatefulWidget {
  const BibleScreen({super.key});

  @override
  ConsumerState<BibleScreen> createState() => _BibleScreenState();
}

class _BibleScreenState extends ConsumerState<BibleScreen> {
  int? _selectedBookId;
  String? _selectedBookName;
  int? _selectedChapter;

  @override
  Widget build(BuildContext context) {
    if (_selectedBookId == null) {
      return _buildBookList();
    } else if (_selectedChapter == null) {
      return _buildChapterList();
    } else {
      return _buildVerseList();
    }
  }

// ...

  Widget _buildBookList() {
    final bibleService = ref.watch(bibleServiceProvider);
    final isTelugu = ref.watch(languageProvider) == 'telugu';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.bible ?? 'Bible'),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: BibleSearchDelegate(ref),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.grid_view),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BibleToolsScreen(),
                  ),
                );
              },
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: isTelugu ? 'పాత నిబంధన' : 'Old Testament'),
              Tab(text: isTelugu ? 'కొత్త నిబంధన' : 'New Testament'),
            ],
          ),
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: bibleService.getBooks(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No books found'));
            }

            final books = snapshot.data!;
            // Simplified OT/NT split logic (assuming first 39 are OT)
            final otBooks = books.where((b) => (b['id'] as int) <= 39).toList();
            final ntBooks = books.where((b) => (b['id'] as int) > 39).toList();

            return TabBarView(
              children: [
                _buildBookGrid(otBooks, isTelugu),
                _buildBookGrid(ntBooks, isTelugu),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBookGrid(List<Map<String, dynamic>> books, bool isTelugu) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedBookId = book['id'];
                _selectedBookName = isTelugu
                    ? (book['telugu_name'] ?? book['name'])
                    : book['name'];
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  isTelugu
                      ? (book['telugu_name'] ?? book['name'])
                      : book['name'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChapterList() {
    final bibleService = ref.watch(bibleServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedBookName ?? 'Chapters'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _selectedBookId = null;
              _selectedBookName = null;
            });
          },
        ),
      ),
      body: FutureBuilder<List<int>>(
        future: bibleService.getChapters(_selectedBookId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final chapters = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: chapters.length,
            itemBuilder: (context, index) {
              final chapter = chapters[index];
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedChapter = chapter;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$chapter',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildVerseList() {
    final bibleService = ref.watch(bibleServiceProvider);
    final isTelugu = ref.watch(languageProvider) == 'telugu';

    return Scaffold(
      appBar: AppBar(
        title: Text('$_selectedBookName $_selectedChapter'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _selectedChapter = null;
            });
          },
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: bibleService.getVerses(_selectedBookId!, _selectedChapter!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final verses = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: verses.length,
            itemBuilder: (context, index) {
              final verse = verses[index];
              final verseText = isTelugu
                  ? (verse['telugu_text'] ?? verse['text'])
                  : verse['text'];
              final reference =
                  '$_selectedBookName $_selectedChapter:${verse['verse']}';

              return InkWell(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (context) => VerseActionsBottomSheet(
                      text: verseText,
                      reference: reference,
                      bookId: _selectedBookId!,
                      chapter: _selectedChapter!,
                      verse: verse['verse'] as int,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 4.0),
                  child: RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style.copyWith(
                            fontSize: 16,
                            height: 1.5,
                          ),
                      children: [
                        TextSpan(
                          text: '${verse['verse']} ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 12,
                          ),
                        ),
                        TextSpan(
                          text: verseText,
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
    );
  }
}
