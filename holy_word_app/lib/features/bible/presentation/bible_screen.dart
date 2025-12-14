import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:share_plus/share_plus.dart'; // For Share
import 'package:screenshot/screenshot.dart'; // For Share Image
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:holy_word_app/l10n/app_localizations.dart';
import 'package:holy_word_app/core/providers/language_provider.dart';
import '../services/bible_service.dart';
import '../services/highlights_service.dart';
import '../services/notes_service.dart';
import 'bible_search_delegate.dart';
import 'bible_tools_screen.dart';
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
  final ScreenshotController _screenshotController = ScreenshotController();
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  int? _targetScrollVerse;

  bool _isLoading = true;

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

      // Scroll to target verse if set
      if (_targetScrollVerse != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final index = _verses
              .indexWhere((v) => (v['verse'] as int) == _targetScrollVerse);
          if (index != -1) {
            _itemScrollController.jumpTo(index: index);
            // Optional: Highlight briefly?
          }
          _targetScrollVerse = null; // Reset
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('Error loading verses: $e');
    }
  }

  void _onBookChanged(int? newBookId) {
    if (newBookId != null && newBookId != _selectedBookId) {
      setState(() {
        _selectedBookId = newBookId;
        _selectedChapter = 1; // Reset chapter
        _selectedVerse = 1; // Reset verse
      });
      _loadChapters();
    }
  }

  void _onChapterChanged(int? newChapter) {
    if (newChapter != null && newChapter != _selectedChapter) {
      setState(() {
        _selectedChapter = newChapter;
        _selectedVerse = 1; // Reset verse
      });
      _loadVerses();
    }
  }

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

  Future<void> _handleShareImage() async {
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

    try {
      final uint8List = await _screenshotController.captureFromWidget(
        Container(
          padding: const EdgeInsets.all(20),
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...selectedVerses.map((v) {
                final text =
                    isTelugu ? (v['telugu_text'] ?? v['text']) : v['text'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text('${v['verse']} $text',
                      style:
                          const TextStyle(fontSize: 18, color: Colors.black)),
                );
              }),
              const SizedBox(height: 16),
              Text('$bookName $_selectedChapter',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey)),
              const SizedBox(height: 8),
              const Text('Holy Word App',
                  style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
            ],
          ),
        ),
        delay: const Duration(milliseconds: 10),
      );

      final xFile = XFile.fromData(
        uint8List,
        mimeType: 'image/png',
        name: 'verse_share.png',
      );

      await Share.shareXFiles([xFile], text: 'Shared from Holy Word App');
    } catch (e) {
      debugPrint('Error sharing image: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error sharing image: $e')));
    }
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Audio Bible"),
        content: const Text("Playing audio for this chapter..."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _clearSelection() {
    setState(() {
      _selectedVerseIndexes.clear();
      _isSelectionMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isTelugu = ref.watch(languageProvider) == 'telugu';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.bible),
            const Text(
              'Read & Listen',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.headphones),
            onPressed: _handleAudioPlay,
            tooltip: 'Audio Bible',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => showSearch(
              context: context,
              delegate: BibleSearchDelegate(ref),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.grid_view),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BibleToolsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSpinnersRow(isTelugu),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildVerseList(isTelugu),
          ),
          if (_isSelectionMode) _buildContextActionBar(),
        ],
      ),
    );
  }

  Widget _buildSpinnersRow(bool isTelugu) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildSpinnerCard(
              DropdownButton<int>(
                value: _books.any((b) => b['id'] == _selectedBookId)
                    ? _selectedBookId
                    : null,
                isExpanded: true,
                underline: const SizedBox(),
                hint: const Text("Select Book"),
                items: _books.map((book) {
                  return DropdownMenuItem<int>(
                    value: book['id'] as int,
                    child: Text(
                      isTelugu
                          ? (book['telugu_name'] ?? book['name'])
                          : book['name'],
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: _onBookChanged,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 1,
            child: _buildSpinnerCard(
              DropdownButton<int>(
                value: _chapters.contains(_selectedChapter)
                    ? _selectedChapter
                    : null,
                isExpanded: true,
                underline: const SizedBox(),
                hint: const Text("Ch"),
                items: _chapters.map((chapter) {
                  return DropdownMenuItem<int>(
                    value: chapter,
                    child: Text('$chapter'),
                  );
                }).toList(),
                onChanged: _onChapterChanged,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 1,
            child: _buildSpinnerCard(
              DropdownButton<int>(
                value: _selectedVerse,
                isExpanded: true,
                underline: const SizedBox(),
                items: _verses.isEmpty
                    ? [const DropdownMenuItem<int>(value: 1, child: Text('1'))]
                    : _verses.map((v) {
                        final vNum = v['verse'] as int;
                        return DropdownMenuItem<int>(
                          value: vNum,
                          child: Text('$vNum'),
                        );
                      }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedVerse = val;
                      // Close keyboard or other UI if needed? No.
                    });
                    final index = _verses.indexWhere((v) => v['verse'] == val);
                    if (index != -1) {
                      _itemScrollController.jumpTo(index: index);
                    }
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 4),
          Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            color: Theme.of(context).primaryColor,
            child: InkWell(
              onTap: () {
                // 1. Capture current top visible verse
                try {
                  final positions = _itemPositionsListener.itemPositions.value;
                  if (positions.isNotEmpty) {
                    // Find the item with the smallest index that is visible
                    final sorted = positions.toList()
                      ..sort((a, b) => a.index.compareTo(b.index));
                    final topItem = sorted.first;
                    final index = topItem.index;
                    if (index >= 0 && index < _verses.length) {
                      final verseNum = _verses[index]['verse'] as int;
                      _targetScrollVerse = verseNum;
                      _selectedVerse = verseNum; // Also sync dropdown
                    }
                  }
                } catch (e) {
                  debugPrint('Error preserving scroll position: $e');
                }

                final current = ref.read(languageProvider);
                ref
                    .read(languageProvider.notifier)
                    .setLanguage(current == 'english' ? 'telugu' : 'english');
                // Reload on language change. Books are reloaded on build via Consumer/watch,
                // but explicit reload ensures everything syncs.
                _loadBooks();
              },
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(
                  isTelugu ? 'EN' : 'TE',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpinnerCard(Widget child) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: child,
      ),
    );
  }

  Widget _buildVerseList(bool isTelugu) {
    return ScrollablePositionedList.builder(
      itemScrollController: _itemScrollController,
      itemPositionsListener: _itemPositionsListener,
      padding: const EdgeInsets.all(8),
      itemCount: _verses.length,
      itemBuilder: (context, index) {
        final verse = _verses[index];
        final verseNum = verse['verse'];
        final text =
            isTelugu ? (verse['telugu_text'] ?? verse['text']) : verse['text'];
        final isSelected = _selectedVerseIndexes.contains(index);

        final highlightColor = _highlights[verseNum];
        final hasNote = _versesWithNotes.contains(verseNum);

        return InkWell(
          onTap: () => _onVerseSelected(index),
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.all(8),
            // Apply highlight color with opacity, or selection color
            color: isSelected
                ? Colors.blue.withOpacity(0.2)
                : (highlightColor != null
                    ? Color(highlightColor).withOpacity(0.3)
                    : Colors.transparent),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(children: [
                  Text(
                    '$verseNum',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                      fontSize: 14,
                    ),
                  ),
                  if (hasNote)
                    const Padding(
                      padding: EdgeInsets.only(top: 4.0),
                      child: Icon(Icons.note, size: 12, color: Colors.blue),
                    ),
                ]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
