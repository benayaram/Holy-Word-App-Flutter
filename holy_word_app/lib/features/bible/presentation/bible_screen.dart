import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:share_plus/share_plus.dart'; // For Share
import 'package:screenshot/screenshot.dart'; // For Share Image
import 'package:holy_word_app/l10n/app_localizations.dart';
import 'package:holy_word_app/core/providers/language_provider.dart';
import '../services/bible_service.dart';
import 'bible_search_delegate.dart';
import 'bible_tools_screen.dart';
import 'widgets/cross_references_dialog.dart'; // Import CrossReferencesDialog

class BibleScreen extends ConsumerStatefulWidget {
  const BibleScreen({super.key});

  @override
  ConsumerState<BibleScreen> createState() => _BibleScreenState();
}

class _BibleScreenState extends ConsumerState<BibleScreen> {
  // Selection State
  int _selectedBookId = 1;
  int _selectedChapter = 1;

  // Data State
  List<Map<String, dynamic>> _books = [];
  List<int> _chapters = [];
  List<Map<String, dynamic>> _verses = [];

  // Multi-Selection State
  final Set<int> _selectedVerseIndexes = {};
  bool _isSelectionMode = false;
  final ScreenshotController _screenshotController = ScreenshotController();

  bool _isLoading = true;

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
          // Default to first book if not set or invalid
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
      if (mounted) {
        setState(() {
          _verses = verses;
          _isLoading = false;
          // Clear selection on chapter change
          _selectedVerseIndexes.clear();
          _isSelectionMode = false;
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
      });
      _loadChapters();
    }
  }

  void _onChapterChanged(int? newChapter) {
    if (newChapter != null && newChapter != _selectedChapter) {
      setState(() {
        _selectedChapter = newChapter;
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

    // Add Reference
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

    // Create a widget to capture
    final book = _books.firstWhere((b) => b['id'] == _selectedBookId);
    final isTelugu = ref.read(languageProvider) == 'telugu';
    final bookName =
        isTelugu ? (book['telugu_name'] ?? book['name']) : book['name'];

    // Capture
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
    final bibleService = ref.read(bibleServiceProvider);
    for (var index in _selectedVerseIndexes) {
      final verse = _verses[index];
      await bibleService.saveHighlight(_selectedBookId, _selectedChapter,
          verse['verse'] as int, Colors.yellow.value);
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Verses Highlighted')));
    _clearSelection();
  }

  void _handleAddNote() {
    final TextEditingController noteController = TextEditingController();

    // Construct Default Text
    final selectedVerses = _verses
        .where((v) => _selectedVerseIndexes.contains(_verses.indexOf(v)))
        .toList();
    selectedVerses
        .sort((a, b) => (a['verse'] as int).compareTo(b['verse'] as int));

    final book = _books.firstWhere((b) => b['id'] == _selectedBookId);
    final isTelugu = ref.read(languageProvider) == 'telugu';
    final bookName =
        isTelugu ? (book['telugu_name'] ?? book['name']) : book['name'];
    final reference =
        '$bookName $_selectedChapter:${selectedVerses.map((v) => v['verse']).join(',')}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(reference,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
              decoration:
                  const InputDecoration(hintText: 'Enter your note here...'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () async {
                final note = noteController.text;
                if (note.isNotEmpty) {
                  // Use first verse text as sample
                  final text = isTelugu
                      ? (selectedVerses.first['telugu_text'] ??
                          selectedVerses.first['text'])
                      : selectedVerses.first['text'];

                  await ref
                      .read(bibleServiceProvider)
                      .saveNote(reference, text, note);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Note Saved')));
                    _clearSelection();
                  }
                }
              },
              child: const Text('Save')),
        ],
      ),
    );
  }

  void _handleCrossRef() {
    if (_selectedVerseIndexes.isEmpty) return;
    // Just verify one verse is selected for cross ref or handle first
    final firstIndex = _selectedVerseIndexes.first;
    final verse = _verses[firstIndex];

    // Construct reference string
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

  void _handleAudioPlay() {
    // Placeholder for Audio Player Logic
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
      backgroundColor: Colors.grey[100], // Match native background tone
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.bible ?? 'Bible'),
            const Text(
              'Read & Listen',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          // Audio Action in AppBar
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
          // 1. Top Spinners Row
          _buildSpinnersRow(isTelugu),

          // 2. Verse List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildVerseList(isTelugu),
          ),

          // 3. Audio Player Removed (moved to AppBar)

          // 4. Contextual Action Bar (Overlay or Bottom)
          if (_isSelectionMode) _buildContextActionBar(),
        ],
      ),
    );
  }

  Widget _buildSpinnersRow(bool isTelugu) {
    // ... Existing Spinner Row implementation ...
    // Copying existing implementation to ensure it's preserved
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          // Book Spinner
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
          // Chapter Spinner
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
          // Verse Spinner
          Expanded(
            flex: 1,
            child: _buildSpinnerCard(
              DropdownButton<int>(
                value: 1, // Placeholder
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
                  // TODO: Scroll to verse
                },
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Language Toggle Button
          Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            color: Theme.of(context).primaryColor,
            child: InkWell(
              onTap: () {
                final current = ref.read(languageProvider);
                ref
                    .read(languageProvider.notifier)
                    .setLanguage(current == 'english' ? 'telugu' : 'english');
                // Trigger reload as language changed
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
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _verses.length,
      itemBuilder: (context, index) {
        final verse = _verses[index];
        final verseNum = verse['verse'];
        final text =
            isTelugu ? (verse['telugu_text'] ?? verse['text']) : verse['text'];
        final isSelected = _selectedVerseIndexes.contains(index);

        return InkWell(
          onTap: () => _onVerseSelected(index),
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.all(8),
            color: isSelected
                ? Colors.blue.withOpacity(0.2)
                : Colors.transparent, // Highlight selection
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$verseNum',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey, // Match Native #4A6572
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Color(0xFF333333), // Match Native
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(Icons.highlight, 'Highlight', _handleHighlight),
          _buildActionButton(Icons.note_add, 'Add Note', _handleAddNote),
          _buildActionButton(Icons.share, 'Share Text', _handleShareText),
          _buildActionButton(Icons.image, 'Share Image', _handleShareImage),
          _buildActionButton(Icons.copy, 'Copy', _handleCopy),
          _buildActionButton(Icons.link, 'Cross Ref', _handleCrossRef),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(icon: Icon(icon, color: Colors.blueGrey), onPressed: onTap),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
