import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/bible_service.dart';
import '../../../../core/providers/language_provider.dart';

class BiblePickerSheet extends ConsumerStatefulWidget {
  final int initialBookId;
  final int initialChapter;
  final int initialVerse;
  final Function(int bookId, int chapter, int verse, String language)
      onSelectionChanged;
  final bool enableVerseSelection;

  const BiblePickerSheet({
    super.key,
    required this.initialBookId,
    required this.initialChapter,
    required this.initialVerse,
    required this.onSelectionChanged,
    required this.enableVerseSelection,
  });

  @override
  ConsumerState<BiblePickerSheet> createState() => _BiblePickerSheetState();
}

class _BiblePickerSheetState extends ConsumerState<BiblePickerSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _selectedBookId;
  late int _selectedChapter;
  int _selectedVerse = 1;
  String _selectedLanguage = 'telugu'; // Default, will init from provider

  List<Map<String, dynamic>> _books = [];
  List<int> _chapters = [];
  List<Map<String, dynamic>> _verses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: widget.enableVerseSelection ? 3 : 2, vsync: this);
    _selectedBookId = widget.initialBookId;
    _selectedChapter = widget.initialChapter;
    _selectedVerse = widget.initialVerse;

    // Defer provider read to after init or just use safe defaults
    // We'll update language in didChangeDependencies or just force read here if context available?
    // Safer to set default based on general app setting if possible, or defaulting to Telugu.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_books.isEmpty) {
      final currentLang = ref.read(languageProvider);
      _selectedLanguage = currentLang == 'english' ? 'english' : 'telugu';
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final bibleService = ref.read(bibleServiceProvider);
    try {
      // NOTE: We need books for the SELECTED language, not just app language.
      // BibleService.getBooks() relies on its internal language code.
      // We might need to ask BibleService for books of a specific language
      // OR re-instantiate BibleService?
      // Actually BibleService has `getBooks()` which uses `_isTelugu`.
      // We should probably add `language` param to `getBooks` or just create a temporary service?
      // Better: add `language` param to `getBooks` in BibleService.
      // FOR NOW: We will stick to the fact that BibleService is bound to App Language.
      // Use `getRandomVerse` style logic where we can specify language?
      // Let's modify BibleService.getBooks to accept language optional.

      // Assuming we updated BibleService or stick to app language for now.
      // Wait, user wants to switch language IN the picker.
      // So I must act as if the app language is swapped for this picker.

      // Hack: Since BibleService is immutable with lang code, we can read the provider for the OTHER language if needed?
      // No, `bibleServiceProvider` returns a service based on `ref.watch(languageProvider)`.
      // I can manually instantiate `BibleService(selectedLanguage)`!

      final service = BibleService(_selectedLanguage);

      final books = await service.getBooks();
      if (mounted) {
        setState(() {
          _books = books;
          _isLoading = false;
        });
        _loadChapters(_selectedBookId);
      }
    } catch (e) {
      debugPrint('Error loading books: $e');
    }
  }

  Future<void> _loadChapters(int bookId) async {
    final service = BibleService(_selectedLanguage);
    try {
      final chapters = await service.getChapters(bookId);
      if (mounted) {
        setState(() {
          _chapters = chapters;
        });
        if (widget.enableVerseSelection) {
          _loadVerses(bookId, _selectedChapter);
        }
      }
    } catch (e) {
      debugPrint('Error loading chapters: $e');
    }
  }

  Future<void> _loadVerses(int bookId, int chapter) async {
    final service = BibleService(_selectedLanguage);
    try {
      final verses = await service.getVerses(bookId, chapter);
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
    // We use local _selectedLanguage instead of ref.watch(languageProvider) for UI
    final isTelugu = _selectedLanguage == 'telugu';

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header with Drag Handle & Language Toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 48), // Spacer
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Language Toggle
                DropdownButton<String>(
                    value: _selectedLanguage,
                    underline: const SizedBox(),
                    icon: const Icon(Icons.language),
                    items: const [
                      DropdownMenuItem(value: 'telugu', child: Text('Telugu')),
                      DropdownMenuItem(
                          value: 'english', child: Text('English')),
                    ],
                    onChanged: (val) {
                      if (val != null && val != _selectedLanguage) {
                        setState(() {
                          _selectedLanguage = val;
                          // Reset selection potentially?
                          // Keep book ID if possible (1-66 is standard).
                          // Reload data
                          _isLoading = true;
                        });
                        _loadData();
                      }
                    }),
              ],
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabs: [
              const Tab(text: 'Book'),
              const Tab(text: 'Chapter'),
              if (widget.enableVerseSelection) const Tab(text: 'Verse'),
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

                        if (widget.enableVerseSelection) {
                          _loadVerses(_selectedBookId, val);
                          _tabController.animateTo(2); // Move to Verse
                        } else {
                          widget.onSelectionChanged(_selectedBookId,
                              _selectedChapter, 1, _selectedLanguage);
                          Navigator.pop(context);
                        }
                      }, _selectedChapter),
                      if (widget.enableVerseSelection)
                        _buildGrid(
                            _verses.map((v) => v['verse'] as int).toList(),
                            (val) {
                          _selectedVerse = val;
                          widget.onSelectionChanged(
                              _selectedBookId,
                              _selectedChapter,
                              _selectedVerse,
                              _selectedLanguage);
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
        // If isTelugu is true, show Telugu Name, else show English Name (available in book['name'] usually for English DB?)
        // Wait, _books comes from getBooks().
        // If _selectedLanguage is Telugu, getBooks returns Telugu names.
        // If English, getBooks returns keys like 'name' which are English.
        // So just use book['name'].
        // For Telugu, the service logic:
        // if (_isTelugu) return _teluguBooks... name: books[index]
        // So book['name'] is correct for the selected language.

        final name = book['name'];
        // Note: Original code had: isTelugu ? (book['telugu_name'] ?? book['name']) : book['name'];
        // Since we are now using a service instanced with the specific language, 'name' should be correct.

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
                  : Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.5),
                    ),
            ),
            alignment: Alignment.center,
            child: Text(
              '$value',
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
