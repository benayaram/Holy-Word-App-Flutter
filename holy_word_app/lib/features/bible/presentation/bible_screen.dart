import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:share_plus/share_plus.dart';
// For Share Image
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
// import 'package:holy_word_app/l10n/app_localizations.dart'; // Unused

import 'package:holy_word_app/core/providers/language_provider.dart';
import '../services/bible_service.dart';
import '../services/highlights_service.dart';
import '../services/notes_service.dart';
import 'bible_search_delegate.dart';
import 'bible_tools_screen.dart';
import 'widgets/bible_location_selector.dart';
import 'widgets/audio_player_widget.dart'; // Import Audio Widget
import 'share_verse_screen.dart'; // Import Share Screen
import 'widgets/cross_references_dialog.dart';
import 'widgets/add_note_dialog.dart';

class BibleScreen extends ConsumerStatefulWidget {
  final int? initialBookId;
  final int? initialChapter;
  final int? initialVerse;

  const BibleScreen(
      {super.key, this.initialBookId, this.initialChapter, this.initialVerse});

  @override
  ConsumerState<BibleScreen> createState() => _BibleScreenState();
}

class _BibleScreenState extends ConsumerState<BibleScreen> {
  // Selection State
  int _selectedBookId = 1;
  int _selectedChapter = 1;
  int _selectedVerse = 1;

  // Data State
  List<Map<String, dynamic>> _books = [];
  List<int> _chapters = [];
  List<Map<String, dynamic>> _verses = [];

  // User Data State
  final HighlightsService _highlightsService = HighlightsService();
  final NotesService _notesService = NotesService();
  Map<int, int> _highlights = {}; // Verse -> Color
  Set<int> _versesWithNotes = {};

  // Multi-Selection State
  final Set<int> _selectedVerseIndexes = {};
  bool _isSelectionMode = false;

  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  int? _targetScrollVerse;

  bool _isLoading = true;
  bool _isAudioPlayerVisible = false; // Audio State

  @override
  void initState() {
    super.initState();
    if (widget.initialBookId != null) _selectedBookId = widget.initialBookId!;
    if (widget.initialChapter != null)
      _selectedChapter = widget.initialChapter!;
    if (widget.initialVerse != null) {
      _targetScrollVerse = widget.initialVerse;
      _selectedVerse = widget.initialVerse!;
    }
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    final bibleService = ref.read(bibleServiceProvider);
    try {
      final books = await bibleService.getBooks();
      if (mounted) {
        setState(() {
          _books = books;
          if (_selectedBookId > books.length) _selectedBookId = 1;
        });
        await _loadChapters();
      }
    } catch (e) {
      debugPrint('Error loading books: $e');
    }
  }

  Future<void> _loadChapters() async {
    final bibleService = ref.read(bibleServiceProvider);
    try {
      final chapters = await bibleService.getChapters(_selectedBookId);
      if (mounted) {
        setState(() {
          _chapters = chapters;
          if (!_chapters.contains(_selectedChapter)) _selectedChapter = 1;
        });
        await _loadVerses();
      }
    } catch (e) {
      debugPrint('Error loading chapters: $e');
    }
  }

  Future<void> _loadVerses() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final bibleService = ref.read(bibleServiceProvider);
    try {
      final verses =
          await bibleService.getVerses(_selectedBookId, _selectedChapter);

      // Load User Data (Highlights & Notes)
      final highlightsData = await _highlightsService.getHighlights(
          _selectedBookId, _selectedChapter);

      final notesVerses = await _notesService.getAllNoteVerses();

      final Map<int, int> highlightMap = {};
      for (var h in highlightsData) {
        highlightMap[h['verse'] as int] = h['color'] as int;
      }

      // Populate _versesWithNotes from V2 table
      final Set<int> noteSet = {};

      // Filter for current book/chapter
      for (var nv in notesVerses) {
        if (nv['book_id'] == _selectedBookId &&
            nv['chapter'] == _selectedChapter) {
          noteSet.add(nv['verse'] as int);
        }
      }

      setState(() {
        _verses = verses;
        _highlights = highlightMap;
        _versesWithNotes = noteSet;
        _isLoading = false;
        _selectedVerseIndexes.clear();
        _isSelectionMode = false;
        // Reset selected verse if out of bounds (though unlikely with default 1) or keep it if valid?
        // Let's ensure it's valid.
        if (_verses.isNotEmpty) {
          final exists = _verses.any((v) => v['verse'] == _selectedVerse);
          if (!exists) _selectedVerse = 1;
        }
      });

      // Scroll to target verse if set (Robust implementation)
      if (_targetScrollVerse != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_verses.isNotEmpty && _itemScrollController.isAttached) {
            final index = _verses
                .indexWhere((v) => (v['verse'] as int) == _targetScrollVerse);
            if (index != -1) {
              _itemScrollController.jumpTo(index: index);
            }
          }
          _targetScrollVerse = null; // Reset
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('Error loading verses: $e');
    }
  }

  // Removed unused _onBookChanged and _onChapterChanged

  void _onVerseSelected(int index) {
    setState(() {
      if (_selectedVerseIndexes.contains(index)) {
        _selectedVerseIndexes.remove(index);
      } else {
        _selectedVerseIndexes.add(index);
      }
      _isSelectionMode = _selectedVerseIndexes.isNotEmpty;
    });
  }

  // --- Action Bar Functions ---

  void _handleCopy() {
    final selectedVerses = _verses
        .where((v) => _selectedVerseIndexes.contains(_verses.indexOf(v)))
        .toList();
    selectedVerses
        .sort((a, b) => (a['verse'] as int).compareTo(b['verse'] as int));

    final textBuffer = StringBuffer();
    for (var v in selectedVerses) {
      final isTelugu = ref.read(languageProvider) == 'telugu';
      final text = isTelugu ? (v['telugu_text'] ?? v['text']) : v['text'];
      textBuffer.write('${v['verse']} $text\n');
    }

    // Add Reference
    final book = _books.firstWhere((b) => b['id'] == _selectedBookId);
    final isTelugu = ref.read(languageProvider) == 'telugu';
    final bookName =
        isTelugu ? (book['telugu_name'] ?? book['name']) : book['name'];
    textBuffer.write('\n$bookName $_selectedChapter');

    Clipboard.setData(ClipboardData(text: textBuffer.toString()));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Verses copied to clipboard')),
    );
    _clearSelection();
  }

  void _handleShareText() {
    final selectedVerses = _verses
        .where((v) => _selectedVerseIndexes.contains(_verses.indexOf(v)))
        .toList();
    selectedVerses
        .sort((a, b) => (a['verse'] as int).compareTo(b['verse'] as int));

    final textBuffer = StringBuffer();
    for (var v in selectedVerses) {
      final isTelugu = ref.read(languageProvider) == 'telugu';
      final text = isTelugu ? (v['telugu_text'] ?? v['text']) : v['text'];
      textBuffer.write('${v['verse']} $text\n');
    }

    final book = _books.firstWhere((b) => b['id'] == _selectedBookId);
    final isTelugu = ref.read(languageProvider) == 'telugu';
    final bookName =
        isTelugu ? (book['telugu_name'] ?? book['name']) : book['name'];
    textBuffer.write('\n$bookName $_selectedChapter');

    Share.share(textBuffer.toString());
    _clearSelection();
  }

  void _handleHighlight() async {
    // Show Color Picker Dialog
    final color = await showDialog<int>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Select Color',
                  style: TextStyle(
                    color: Colors.blueGrey,
                    fontWeight: FontWeight.bold,
                  )),
              content: Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  Colors.yellow,
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange
                ]
                    .map((c) => InkWell(
                          onTap: () => Navigator.pop(context, c.value),
                          child: CircleAvatar(backgroundColor: c, radius: 24),
                        ))
                    .toList(),
              ),
            ));

    if (color == null) return;

    for (var index in _selectedVerseIndexes) {
      final verse = _verses[index];
      final verseNum = verse['verse'] as int;
      // Remove existing first to avoid dupes or simple insert
      await _highlightsService.removeHighlight(
          _selectedBookId, _selectedChapter, verseNum);
      await _highlightsService.addHighlight(
          _selectedBookId, _selectedChapter, verseNum, color);
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Verses Highlighted')));

    _loadVerses(); // Refresh highlights
  }

  void _handleAddNote() {
    final selectedVerses = _verses
        .where((v) => _selectedVerseIndexes.contains(_verses.indexOf(v)))
        .toList();
    selectedVerses
        .sort((a, b) => (a['verse'] as int).compareTo(b['verse'] as int));

    if (selectedVerses.isEmpty) return;

    final book = _books.firstWhere((b) => b['id'] == _selectedBookId);
    final isTelugu = ref.read(languageProvider) == 'telugu';
    final bookName =
        isTelugu ? (book['telugu_name'] ?? book['name']) : book['name'];
    final reference =
        '$bookName $_selectedChapter:${selectedVerses.map((v) => v['verse']).join(',')}';

    // Prepare verse data for the dialog
    final verseData = {
      'book_id': _selectedBookId,
      'chapter': _selectedChapter,
      'verse': selectedVerses.first[
          'verse'], // For now associate with first selected verse logic or loop
      // If multiple verses selected, we might want to handle differently,
      // but current logic maps 1:1 or 1:N but DB stores individual rows per verse-note link.
      // Let's add the FIRST selected verse for simplicity of the prompt,
      // or loop and add all? The Dialog expects single verseData map.
      // Let's pass the text of all selected variants.
      'text': isTelugu
          ? selectedVerses
              .map((v) => '${v['verse']} ${v['telugu_text'] ?? v['text']}')
              .join('\n')
          : selectedVerses.map((v) => '${v['verse']} ${v['text']}').join('\n'),
      'reference': reference,
    };

    // IMPORTANT: The Dialog logic in AddNoteDialog currently writes to note_verses table.
    // It expects a single 'verse' int. If we selected multiple, we technically should enable the dialog
    // to handle list or we just associate with the primary verse start.
    // Enhanced AddNoteDialog to handle this?
    // For now, let's just pass the first verse ID but the full text.
    // Re-check AddNoteDialog logic: it calls addVerseToNote once.

    showDialog(
      context: context,
      builder: (context) => AddNoteDialog(
        verseData: verseData,
        onSuccess: () {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Note Saved')));
          _clearSelection();
          _loadVerses(); // Refresh icons
        },
      ),
    );
  }

  void _shareVerse() {
    if (_selectedVerseIndexes.isEmpty) return;

    final verses = _selectedVerseIndexes.map((index) {
      final verse = _verses[index];
      // final verseNum = verse['verse'];
      final text = ref.read(languageProvider) == 'telugu'
          ? (verse['telugu_text'] ?? verse['text'])
          : verse['text'];
      return text;
      // return '$verseNum. $text'; // Should we include numbers in image? Maybe not.
      // Native app just sends text.
    }).toList();

    final bookName =
        _getBookName(_selectedBookId, ref.read(languageProvider) == 'telugu');

    // Construct reference (e.g., John 3:16)
    // If multiple verses: John 3:16-18
    // Simplify for now, just list verses logic if needed, but let's take first and last.
    final firstParams = _verses[_selectedVerseIndexes.first];
    final lastParams = _verses[_selectedVerseIndexes.last];
    final firstNum = firstParams['verse'];
    final lastNum = lastParams['verse'];

    String reference = '$bookName $_selectedChapter:$firstNum';
    if (firstNum != lastNum) {
      reference += '-$lastNum';
    }

    final textToShare = verses.join('\n');

    final verseNumbers =
        _selectedVerseIndexes.map((i) => _verses[i]['verse'] as int).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShareVerseScreen(
          verseText: textToShare,
          verseReference: reference,
          bookId: _selectedBookId,
          chapter: _selectedChapter,
          verseNumbers: verseNumbers,
        ),
      ),
    );
  }

  void _handleShareImage() {
    _shareVerse();
  }

  void _handleCrossRef() {
    if (_selectedVerseIndexes.isEmpty) return;
    final firstIndex = _selectedVerseIndexes.first;
    final verse = _verses[firstIndex];

    final book = _books.firstWhere((b) => b['id'] == _selectedBookId);
    final isTelugu = ref.read(languageProvider) == 'telugu';
    final bookName =
        isTelugu ? (book['telugu_name'] ?? book['name']) : book['name'];
    final refString = '$bookName $_selectedChapter:${verse['verse']}';

    showDialog(
      context: context,
      builder: (context) => CrossReferencesDialog(
          bookId: _selectedBookId,
          chapter: _selectedChapter,
          verse: verse['verse'] as int,
          verseReference: refString),
    );
    _clearSelection();
  }

  void _handleRemoveHighlight() async {
    for (var index in _selectedVerseIndexes) {
      final verse = _verses[index];
      final verseNum = verse['verse'] as int;
      await _highlightsService.removeHighlight(
          _selectedBookId, _selectedChapter, verseNum);
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Highlights Removed')));
    _loadVerses();
  }

  void _handleAudioPlay() {
    setState(() {
      _isAudioPlayerVisible = !_isAudioPlayerVisible;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedVerseIndexes.clear();
      _isSelectionMode = false;
    });
  }

  // --- Navigation Logic ---

  void _goToNextChapter() async {
    if (_chapters.isEmpty) return;

    final currentMaxChapter = _chapters.last;
    if (_selectedChapter < currentMaxChapter) {
      setState(() {
        _selectedChapter++;
        _selectedVerse = 1;
        _targetScrollVerse = 1;
      });
      _loadVerses();
    } else {
      // Go to next book
      if (_selectedBookId < _books.length) {
        setState(() {
          _selectedBookId++;
          _selectedChapter = 1;
          _selectedVerse = 1;
          _targetScrollVerse = 1;
        });
        _loadChapters();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You are at the end of the Bible')));
      }
    }
  }

  void _goToPreviousChapter() async {
    if (_selectedChapter > 1) {
      setState(() {
        _selectedChapter--;
        _selectedVerse = 1; // Or ideally to last verse? defaulting to 1 for now
        _targetScrollVerse = 1;
      });
      _loadVerses();
    } else {
      // Go to previous book
      if (_selectedBookId > 1) {
        setState(() {
          _selectedBookId--;
          // We need to fetch chapters to know the last chapter.
          // This breaks the sync flow slightly, but _loadChapters handles it.
          // We set chapter to 1 initially, but we want last.
          // A minor limitation - better to default to 1 or implement specific logic.
          // Let's implement specific logic to go to LAST chapter.
          _isLoading = true;
        });

        // Custom loadChapters logic for Previous Book transition
        final bibleService = ref.read(bibleServiceProvider);
        final chapters = await bibleService.getChapters(_selectedBookId);
        if (mounted) {
          setState(() {
            _chapters = chapters;
            _selectedChapter = chapters.isNotEmpty ? chapters.last : 1;
            _selectedVerse = 1;
            _targetScrollVerse = 1;
          });
          _loadVerses();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You are at the start of the Bible')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTelugu = ref.watch(languageProvider) == 'telugu';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
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
        title: _books.isEmpty
            ? const SizedBox()
            : BibleLocationSelector(
                bookId: _selectedBookId,
                chapter: _selectedChapter,
                verse: _selectedVerse,
                bookName: _getBookName(_selectedBookId, isTelugu),
                onSelectionChanged: (bookId, chapter, verse) {
                  final previousBookId = _selectedBookId;
                  final previousChapter = _selectedChapter;

                  setState(() {
                    _selectedBookId = bookId;
                    _selectedChapter = chapter;
                    _selectedVerse = verse;
                    _targetScrollVerse = verse; // prepare to scroll
                  });
                  // Reload if book/chapter changed
                  if (bookId != previousBookId) {
                    _loadChapters();
                  } else if (chapter != previousChapter) {
                    _loadVerses();
                  } else {
                    _scrollToVerse(verse); // Just scroll
                  }
                },
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.headphones_outlined),
            onPressed: _handleAudioPlay,
            color: Colors.black87,
            tooltip: 'Audio Bible',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => showSearch(
              context: context,
              delegate: BibleSearchDelegate(ref),
            ),
            color: Colors.black87,
          ),
          IconButton(
            icon: const Icon(Icons.grid_view),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BibleToolsScreen()),
            ),
            color: Colors.black87,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : GestureDetector(
                        onHorizontalDragEnd: (details) {
                          // Swipe Logic
                          // Primary Velocity: +ve (Right) -> Prev, -ve (Left) -> Next
                          if (details.primaryVelocity! < 0) {
                            _goToNextChapter();
                          } else if (details.primaryVelocity! > 0) {
                            _goToPreviousChapter();
                          }
                        },
                        child: _buildVerseList(isTelugu),
                      ),
              ),
              if (_isSelectionMode) _buildContextActionBar(),
              if (_isAudioPlayerVisible)
                AudioPlayerWidget(
                  bookId: _selectedBookId,
                  chapter: _selectedChapter,
                  bookName: _getBookName(_selectedBookId, isTelugu),
                  isTelugu: isTelugu,
                  onClose: () => setState(() => _isAudioPlayerVisible = false),
                ),
            ],
          ),
          // Navigation Arrows (Floating Bottom Bar style)
          if (!_isSelectionMode)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, size: 20),
                        onPressed: _goToPreviousChapter,
                        tooltip: 'Previous Chapter',
                        color: Colors.grey[800],
                      ),
                      Container(
                        width: 1,
                        height: 24,
                        color: Colors.grey[300],
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 20),
                        onPressed: _goToNextChapter,
                        tooltip: 'Next Chapter',
                        color: Colors.grey[800],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Removed _buildSpinnersRow

  // Removed _buildSpinnerCard

  Widget _buildVerseList(bool isTelugu) {
    return ScrollablePositionedList.builder(
      itemScrollController: _itemScrollController,
      itemPositionsListener: _itemPositionsListener,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _verses.length,
      itemBuilder: (context, index) {
        final verse = _verses[index];
        final verseNum = verse['verse'];
        final text =
            isTelugu ? (verse['telugu_text'] ?? verse['text']) : verse['text'];
        final isSelected = _selectedVerseIndexes.contains(index);

        final highlightColor = _highlights[verseNum];
        final hasNote = _versesWithNotes.contains(verseNum);

        return GestureDetector(
          onTap: () {
            if (_isSelectionMode) {
              _onVerseSelected(index);
            } else {
              // Toggle context mode or simple tap
            }
          },
          onLongPress: () => _onVerseSelected(index),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                  : (highlightColor != null
                      ? Color(highlightColor).withOpacity(0.3)
                      : Colors.white),
              borderRadius: BorderRadius.circular(8),
              boxShadow: isSelected
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$verseNum',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (hasNote)
                      const Icon(Icons.note, size: 16, color: Colors.amber),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.6,
                    color: Colors.grey[800],
                    fontFamily: 'Roboto', // Or standard clean font
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getBookName(int bookId, bool isTelugu) {
    final book = _books.firstWhere((b) => b['id'] == bookId, orElse: () => {});
    if (book.isEmpty) return '';
    return isTelugu ? (book['telugu_name'] ?? book['name']) : book['name'];
  }

  void _scrollToVerse(int verse) {
    if (_verses.isEmpty) return;
    final index = _verses.indexWhere((v) => v['verse'] == verse);
    if (index != -1 && _itemScrollController.isAttached) {
      _itemScrollController.jumpTo(index: index);
    }
  }

  Widget _buildContextActionBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(Icons.highlight, 'Highlight', _handleHighlight),
            const SizedBox(width: 12),
            _buildActionButton(Icons.format_color_reset, 'Clear Color',
                _handleRemoveHighlight),
            const SizedBox(width: 12),
            _buildActionButton(Icons.note_add, 'Add Note', _handleAddNote),
            const SizedBox(width: 12),
            _buildActionButton(Icons.share, 'Share Text', _handleShareText),
            const SizedBox(width: 12),
            _buildActionButton(Icons.image, 'Share Image', _handleShareImage),
            const SizedBox(width: 12),
            _buildActionButton(Icons.copy, 'Copy', _handleCopy),
            const SizedBox(width: 12),
            _buildActionButton(Icons.link, 'Cross Ref', _handleCrossRef),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.blueGrey),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}
