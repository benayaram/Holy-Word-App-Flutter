import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:holy_word_app/features/bible/services/highlights_service.dart';
import 'package:holy_word_app/features/bible/services/bible_service.dart';
import 'bible_screen.dart';

class HighlightsScreen extends ConsumerStatefulWidget {
  const HighlightsScreen({super.key});

  @override
  ConsumerState<HighlightsScreen> createState() => _HighlightsScreenState();
}

enum SortOrder { dateDesc, dateAsc, bookOrder }

class _HighlightsScreenState extends ConsumerState<HighlightsScreen> {
  final HighlightsService _highlightsService = HighlightsService();

  List<Map<String, dynamic>> _allHighlights = [];
  List<Map<String, dynamic>> _filteredHighlights = [];
  bool _isLoading = true;

  // Filter & Sort State
  int? _selectedColorFilter;
  SortOrder _startOrder = SortOrder.dateDesc;

  // Cache for fetched texts to avoid re-fetching on simple potential filter changes if we optimized
  // But for now we fetch on load.

  @override
  void initState() {
    super.initState();
    _loadHighlights();
  }

  Future<void> _loadHighlights() async {
    setState(() => _isLoading = true);
    try {
      final rawHighlights = await _highlightsService.getAllHighlights();
      final bibleService = ref.read(bibleServiceProvider);

      // Fetch text for each highlight
      // We do this in parallel for speed
      final List<Map<String, dynamic>> enrichedHighlights =
          await Future.wait(rawHighlights.map((h) async {
        try {
          final bookId = h['book_id'] as int;
          final chapter = h['chapter'] as int;
          final verse = h['verse'] as int;

          // Get verse text in current language
          // Note: If user switches language, they might expect highlights to change language?
          // Yes, usually.
          // Using getVerseForSelection which respects app language usually or returns specific?
          // getVerseForSelection uses "getVerse" logic potentially or DB.
          // Let's use getVerseForSelection(bookId, chapter, verse)
          // Check service: getVerseForSelection takes optional lang. Defaults to app lang?
          // Actually currently getVerseForSelection returns {text, reference, etc}
          final verseData =
              await bibleService.getVerseForSelection(bookId, chapter, verse);

          return {
            ...h,
            'text': verseData['text'] ?? 'Loading...',
            'reference': verseData['reference'] ?? 'Verse $verse', // Fallback
            'book_name': (verseData['reference'] ?? '')
                .split(' ')
                .first, // Rough extraction if needed or rely on reference
          };
        } catch (e) {
          return {
            ...h,
            'text': 'Error loading text',
            'reference': '${h['book_id']}:${h['chapter']}:${h['verse']}',
          };
        }
      }));

      _allHighlights = enrichedHighlights;
      _applyFilterAndSort();
    } catch (e) {
      debugPrint('Error loading highlights: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilterAndSort() {
    var result = List<Map<String, dynamic>>.from(_allHighlights);

    // Filter
    if (_selectedColorFilter != null) {
      result = result.where((h) => h['color'] == _selectedColorFilter).toList();
    }

    // Sort
    switch (_startOrder) {
      case SortOrder.dateDesc:
        result.sort((a, b) => b['created_at'].compareTo(a['created_at']));
        break;
      case SortOrder.dateAsc:
        result.sort((a, b) => a['created_at'].compareTo(b['created_at']));
        break;
      case SortOrder.bookOrder:
        // Sort by BookId, then Chapter, then Verse
        result.sort((a, b) {
          int cmp = (a['book_id'] as int).compareTo(b['book_id'] as int);
          if (cmp != 0) return cmp;
          cmp = (a['chapter'] as int).compareTo(b['chapter'] as int);
          if (cmp != 0) return cmp;
          return (a['verse'] as int).compareTo(b['verse'] as int);
        });
        break;
    }

    setState(() {
      _filteredHighlights = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Highlights'),
        actions: [
          // Sort Button
          PopupMenuButton<SortOrder>(
            icon: const Icon(Icons.sort),
            onSelected: (val) {
              setState(() => _startOrder = val);
              _applyFilterAndSort();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: SortOrder.dateDesc,
                child: Text('Newest First'),
              ),
              const PopupMenuItem(
                value: SortOrder.dateAsc,
                child: Text('Oldest First'),
              ),
              const PopupMenuItem(
                value: SortOrder.bookOrder,
                child: Text('Canonical Order'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredHighlights.isEmpty
                    ? const Center(child: Text('No highlights found'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredHighlights.length,
                        itemBuilder: (context, index) {
                          return _buildHighlightItem(
                              _filteredHighlights[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final colors = [
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.pink,
      Colors.orange
    ];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ActionChip(
            label: const Text('All'),
            backgroundColor: _selectedColorFilter == null
                ? Theme.of(context).primaryColor.withOpacity(0.2)
                : null,
            onPressed: () {
              setState(() => _selectedColorFilter = null);
              _applyFilterAndSort();
            },
          ),
          const SizedBox(width: 8),
          ...colors.map((c) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: const Text('  '),
                  backgroundColor: c.withOpacity(0.3),
                  selectedColor: c,
                  selected: _selectedColorFilter == c.value,
                  onSelected: (val) {
                    setState(() => _selectedColorFilter = val ? c.value : null);
                    _applyFilterAndSort();
                  },
                  shape: CircleBorder(
                      side: BorderSide(
                          color: _selectedColorFilter == c.value
                              ? Colors.black
                              : Colors.transparent,
                          width: 2)),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildHighlightItem(Map<String, dynamic> h) {
    final color = Color(h['color'] as int);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => BibleScreen(
                    initialBookId: h['book_id'],
                    initialChapter: h['chapter'],
                    initialVerse: h['verse'])),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(h['reference'],
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const Spacer(),
                  // Action Buttons
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(
                          text: '${h['text']}\n${h['reference']}'));
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied')));
                    },
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share, size: 20),
                    onPressed: () {
                      Share.share('${h['text']}\n${h['reference']}');
                    },
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),
                  IconButton(
                    icon:
                        const Icon(Icons.delete, size: 20, color: Colors.grey),
                    onPressed: () => _deleteHighlight(h['id']),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(8),
                  ),
                ],
              ),
              const Divider(),
              // Verse Text
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    h['text'],
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      fontFamily: 'Roboto', // Default
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteHighlight(int id) async {
    await _highlightsService.deleteHighlight(id);
    // Reload
    _loadHighlights();
  }
}
