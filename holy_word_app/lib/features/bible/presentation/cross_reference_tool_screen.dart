import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holy_word_app/core/providers/language_provider.dart';
import 'package:holy_word_app/features/bible/services/bible_service.dart';

class CrossReferenceToolScreen extends ConsumerStatefulWidget {
  const CrossReferenceToolScreen({super.key});

  @override
  ConsumerState<CrossReferenceToolScreen> createState() =>
      _CrossReferenceToolScreenState();
}

class _CrossReferenceToolScreenState
    extends ConsumerState<CrossReferenceToolScreen> {
  int _selectedBookId = 1;
  int _selectedChapter = 1;
  int _selectedVerse = 1;

  List<Map<String, dynamic>> _books = [];
  List<int> _chapters = [];
  List<int> _verses = []; // Just numbers for simplicity
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;

  String? _targetLanguage;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  // Initialize _targetLanguage based on provider if not set
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_targetLanguage == null) {
      final lang = ref.read(languageProvider);
      // Default to app language
      _targetLanguage = lang;
    }
  }

  Future<void> _loadBooks() async {
    final bibleService = ref.read(bibleServiceProvider);
    final books = await bibleService.getBooks();
    if (mounted) {
      setState(() {
        _books = books;
        if (_selectedBookId > books.length) _selectedBookId = 1;
      });
      _loadChapters();
    }
  }

  Future<void> _loadChapters() async {
    final bibleService = ref.read(bibleServiceProvider);
    final chapters = await bibleService.getChapters(_selectedBookId);
    if (mounted) {
      setState(() {
        _chapters = chapters;
        if (!_chapters.contains(_selectedChapter)) _selectedChapter = 1;
      });
      _loadVerses();
    }
  }

  Future<void> _loadVerses() async {
    final bibleService = ref.read(bibleServiceProvider);
    // Use target language for verses? No, input selector usually follows App Language or Book.
    // Stick to default behavior for selector.
    final versesData =
        await bibleService.getVerses(_selectedBookId, _selectedChapter);
    if (mounted) {
      setState(() {
        // Extract verse numbers
        _verses = versesData.map((v) => v['verse'] as int).toList();
        if (!_verses.contains(_selectedVerse)) _selectedVerse = 1;
      });
    }
  }

  Future<void> _searchReferences() async {
    setState(() => _isLoading = true);
    final bibleService = ref.read(bibleServiceProvider);
    try {
      final results = await bibleService.getCrossReferences(
          _selectedBookId, _selectedChapter, _selectedVerse,
          targetLanguage: _targetLanguage);
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _toggleLanguage() {
    setState(() {
      if (_targetLanguage == 'telugu') {
        _targetLanguage = 'english';
      } else {
        _targetLanguage = 'telugu';
      }
    });
    // Auto-refresh if we have results
    if (_results.isNotEmpty) {
      _searchReferences();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTeluguAppLang = ref.watch(languageProvider) == 'telugu';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cross References'),
        actions: [
          IconButton(
            icon: Icon(Icons.g_translate),
            tooltip: 'Translate References',
            onPressed: _toggleLanguage,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                _targetLanguage == 'telugu' ? 'TEL' : 'ENG',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          _buildSelector(isTeluguAppLang),
          // const Divider(), // Removed Divider, using container styling
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.library_books_outlined,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Select a verse to explore connections',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final r = _results[index];
                          final refString =
                              '${r['reference_book']} ${r['reference_chapter']}:${r['reference_verse']}';
                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                // Optional: Navigate to verse
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .primaryColor
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Icon(Icons.bookmark_border,
                                              color: Theme.of(context)
                                                  .primaryColor,
                                              size: 20),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            refString,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Theme.of(context)
                                                  .primaryColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (r['reference_text'] != null) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        r['reference_text'],
                                        style: const TextStyle(
                                            fontSize: 15, height: 1.5),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelector(bool isTelugu) {
    // Premium styling for selector
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildDropdown<int>(
                  label: 'Book',
                  value: _books.any((b) => b['id'] == _selectedBookId)
                      ? _selectedBookId
                      : null,
                  items: _books.map((book) {
                    return DropdownMenuItem<int>(
                      value: book['id'] as int,
                      child: Text(
                        isTelugu
                            ? (book['telugu_name'] ?? book['name'])
                            : book['name'],
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedBookId = val;
                        _selectedChapter = 1;
                      });
                      _loadChapters();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: _buildDropdown<int>(
                  label: 'Ch',
                  value: _chapters.contains(_selectedChapter)
                      ? _selectedChapter
                      : null,
                  items: _chapters
                      .map((c) => DropdownMenuItem(value: c, child: Text('$c')))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedChapter = val);
                      _loadVerses();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: _buildDropdown<int>(
                  label: 'Vs',
                  value:
                      _verses.contains(_selectedVerse) ? _selectedVerse : null,
                  items: _verses
                      .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedVerse = val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _searchReferences,
              icon: const Icon(Icons.manage_search),
              label: const Text('Find Cross References',
                  style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              items: items,
              onChanged: onChanged,
              icon: Icon(Icons.keyboard_arrow_down,
                  color: Theme.of(context).primaryColor),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
