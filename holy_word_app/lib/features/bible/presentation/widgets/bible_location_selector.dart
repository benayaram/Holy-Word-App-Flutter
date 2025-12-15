import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/bible_service.dart';
import '../../../../core/providers/language_provider.dart';

class BibleLocationSelector extends ConsumerWidget {
  final int bookId;
  final int chapter;
  final int verse;
  final String bookName;
  final Function(int bookId, int chapter, int verse) onSelectionChanged;

  const BibleLocationSelector({
    super.key,
    required this.bookId,
    required this.chapter,
    required this.verse,
    required this.bookName,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => _BibleBottomSheet(
            initialBookId: bookId,
            initialChapter: chapter,
            initialVerse: verse,
            onSelectionChanged: onSelectionChanged,
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$bookName $chapter:$verse',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _BibleBottomSheet extends ConsumerStatefulWidget {
  final int initialBookId;
  final int initialChapter;
  final int initialVerse;
  final Function(int bookId, int chapter, int verse) onSelectionChanged;

  const _BibleBottomSheet({
    required this.initialBookId,
    required this.initialChapter,
    required this.initialVerse,
    required this.onSelectionChanged,
  });

  @override
  ConsumerState<_BibleBottomSheet> createState() => _BibleBottomSheetState();
}

class _BibleBottomSheetState extends ConsumerState<_BibleBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _selectedBookId;
  late int _selectedChapter;
  int _selectedVerse = 1;

  List<Map<String, dynamic>> _books = [];
  List<int> _chapters = [];
  List<Map<String, dynamic>> _verses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedBookId = widget.initialBookId;
    _selectedChapter = widget.initialChapter;
    _selectedVerse = widget.initialVerse;
    _loadData();
  }

  Future<void> _loadData() async {
    final bibleService = ref.read(bibleServiceProvider);
    try {
      final books = await bibleService.getBooks();
      if (mounted) {
        setState(() {
          _books = books;
          _isLoading = false;
        });
        // Pre-load chapters for current book
        _loadChapters(_selectedBookId);
      }
    } catch (e) {
      debugPrint('Error loading books: $e');
    }
  }

  Future<void> _loadChapters(int bookId) async {
    final bibleService = ref.read(bibleServiceProvider);
    try {
      final chapters = await bibleService.getChapters(bookId);
      if (mounted) {
        setState(() {
          _chapters = chapters;
        });
        // Pre-load verses for current chapter
        _loadVerses(bookId, _selectedChapter);
      }
    } catch (e) {
      debugPrint('Error loading chapters: $e');
    }
  }

  Future<void> _loadVerses(int bookId, int chapter) async {
    final bibleService = ref.read(bibleServiceProvider);
    try {
      final verses = await bibleService.getVerses(bookId, chapter);
      if (mounted) {
        setState(() {
          _verses = verses;
        });
      }
    } catch (e) {
      debugPrint('Error loading verses: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTelugu = ref.watch(languageProvider) == 'telugu';

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabs: const [
              Tab(text: 'Book'),
              Tab(text: 'Chapter'),
              Tab(text: 'Verse'),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBookList(isTelugu),
                      _buildGrid(_chapters, (val) {
                        setState(() => _selectedChapter = val);
                        _loadVerses(_selectedBookId, val);
                        _tabController.animateTo(2); // Move to Verse
                      }, _selectedChapter),
                      _buildGrid(_verses.map((v) => v['verse'] as int).toList(),
                          (val) {
                        _selectedVerse = val;
                        widget.onSelectionChanged(
                            _selectedBookId, _selectedChapter, _selectedVerse);
                        Navigator.pop(context);
                      }, _selectedVerse),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookList(bool isTelugu) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _books.length,
      itemBuilder: (context, index) {
        final book = _books[index];
        final bookId = book['id'] as int;
        final name =
            isTelugu ? (book['telugu_name'] ?? book['name']) : book['name'];
        final isSelected = bookId == _selectedBookId;

        return ListTile(
          title: Text(
            name,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
          selected: isSelected,
          onTap: () {
            setState(() {
              _selectedBookId = bookId;
              _selectedChapter = 1; // Reset chapter
            });
            _loadChapters(bookId);
            _tabController.animateTo(1); // Move to Chapter
          },
        );
      },
    );
  }

  Widget _buildGrid(List<int> items, Function(int) onTap, int selectedValue) {
    if (items.isEmpty) {
      return const Center(child: Text("Loading..."));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final value = items[index];
        final isSelected = value == selectedValue;
        return InkWell(
          onTap: () => onTap(value),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context)
                      .colorScheme
                      .surfaceVariant
                      .withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? null
                  : Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            alignment: Alignment.center,
            child: Text(
              '$value',
              style: TextStyle(
                color: isSelected ? Colors.white : null,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
