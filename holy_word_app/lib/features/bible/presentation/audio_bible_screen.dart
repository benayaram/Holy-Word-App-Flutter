import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holy_word_app/core/providers/language_provider.dart';
import '../services/bible_service.dart';
import 'widgets/bible_location_selector.dart';
import 'widgets/audio_player_widget.dart';

class AudioBibleScreen extends ConsumerStatefulWidget {
  const AudioBibleScreen({super.key});

  @override
  ConsumerState<AudioBibleScreen> createState() => _AudioBibleScreenState();
}

class _AudioBibleScreenState extends ConsumerState<AudioBibleScreen> {
  int _selectedBookId = 1;
  int _selectedChapter = 1;
  // We don't strictly need verse for Audio but the selector might require it?
  // Checking selector signature: requires verse but we can ignore it or pass 1.
  int _selectedVerse = 1;

  List<Map<String, dynamic>> _books = [];

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    final bibleService = ref.read(bibleServiceProvider);
    try {
      final books = await bibleService.getBooks();
      if (mounted) {
        setState(() {
          _books = books;
        });
      }
    } catch (e) {
      debugPrint('Error loading books: $e');
    }
  }

  String _getBookName(int bookId, bool isTelugu) {
    if (_books.isEmpty) return '';
    final book = _books.firstWhere((b) => b['id'] == bookId, orElse: () => {});
    if (book.isEmpty) return '';
    return isTelugu ? (book['telugu_name'] ?? book['name']) : book['name'];
  }

  @override
  Widget build(BuildContext context) {
    final isTelugu = ref.watch(languageProvider) == 'telugu';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: _books.isEmpty
            ? const Text('Audio Bible')
            : BibleLocationSelector(
                bookId: _selectedBookId,
                chapter: _selectedChapter,
                verse: _selectedVerse,
                bookName: _getBookName(_selectedBookId, isTelugu),
                onSelectionChanged: (bookId, chapter, verse) {
                  setState(() {
                    _selectedBookId = bookId;
                    _selectedChapter = chapter;
                    _selectedVerse =
                        verse; // Not used for audio seeking yet, but kept for state
                  });
                },
              ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: Icon(Icons.translate,
                color: Theme.of(context).colorScheme.primary),
            onPressed: () {
              final current = ref.read(languageProvider);
              ref
                  .read(languageProvider.notifier)
                  .setLanguage(current == 'english' ? 'telugu' : 'english');
              _loadBooks();
            },
            tooltip: 'Switch Language',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Big Icon or Graphic
            Icon(
              Icons.headphones,
              size: 100,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            ),
            const SizedBox(height: 20),
            Text(
              "Access the Holy Word in Audio",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 40),

            // The Player Widget
            // We wrap it in a card or padding effectively
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AudioPlayerWidget(
                bookId: _selectedBookId,
                chapter: _selectedChapter,
                bookName: _getBookName(_selectedBookId, isTelugu),
                isTelugu: isTelugu,
                onClose: () {
                  // In standalone screen, close might mean stop?
                  // Or simply do nothing / hide?
                  // Given it's a dedicated screen, maybe we don't need a close button inside the widget?
                  // But the widget has one. Let's just pop the screen or stop playback.
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
