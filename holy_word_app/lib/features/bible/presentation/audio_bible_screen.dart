import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holy_word_app/core/providers/language_provider.dart';
import '../services/bible_service.dart';
import '../services/audio_bible_service.dart';
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
  int _selectedVerse = 1;

  List<Map<String, dynamic>> _books = [];

  @override
  void initState() {
    super.initState();
    _loadInitialState();
    _loadBooks();
  }

  void _loadInitialState() {
    final audioService = ref.read(audioBibleServiceProvider);
    if (audioService.currentBookId > 0) {
      _selectedBookId = audioService.currentBookId;
      _selectedChapter = audioService.currentChapter;
    }
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
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: _books.isEmpty
            ? const Text('Audio Bible')
            : Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: BibleLocationSelector(
                  bookId: _selectedBookId,
                  chapter: _selectedChapter,
                  verse: _selectedVerse,
                  bookName: _getBookName(_selectedBookId, isTelugu),
                  enableVerseSelection: false,
                  onSelectionChanged: (bookId, chapter, verse) {
                    setState(() {
                      _selectedBookId = bookId;
                      _selectedChapter = chapter;
                      _selectedVerse = verse;
                    });
                  },
                ),
              ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.translate, color: primaryColor),
              onPressed: () {
                final current = ref.read(languageProvider);
                ref
                    .read(languageProvider.notifier)
                    .setLanguage(current == 'english' ? 'telugu' : 'english');
                _loadBooks();
              },
              tooltip: 'Switch Language',
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 1),

              // Album Art / Visualizer Placeholder
              Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  color: primaryColor.withOpacity(0.05),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor.withOpacity(0.1),
                      ),
                      width: 200,
                      height: 200,
                    ),
                    Icon(
                      Icons.headphones,
                      size: 120,
                      color: primaryColor.withOpacity(0.8),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // Player Widget
              // Using Align to dock it to bottom if desired, or just part of column
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: AudioPlayerWidget(
                  bookId: _selectedBookId,
                  chapter: _selectedChapter,
                  bookName: _getBookName(_selectedBookId, isTelugu),
                  isTelugu: isTelugu,
                  onClose: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
