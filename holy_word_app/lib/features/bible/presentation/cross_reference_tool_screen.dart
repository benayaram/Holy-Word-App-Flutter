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

  @override
  void initState() {
    super.initState();
    _loadBooks();
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
      // Mock verses count or fetch real ones?
      // Fetch real verses to get accurate count
      _loadVerses();
    }
  }

  Future<void> _loadVerses() async {
    final bibleService = ref.read(bibleServiceProvider);
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
          _selectedBookId, _selectedChapter, _selectedVerse);
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

  @override
  Widget build(BuildContext context) {
    final isTelugu = ref.watch(languageProvider) == 'telugu';

    return Scaffold(
      appBar: AppBar(title: const Text('Cross References')),
      body: Column(
        children: [
          _buildSelector(isTelugu),
          const Divider(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? const Center(
                        child: Text('Select a verse to see references'))
                    : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final r = _results[index];
                          final refString =
                              '${r['reference_book']} ${r['reference_chapter']}:${r['reference_verse']}';
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            child: ListTile(
                              leading:
                                  const Icon(Icons.link, color: Colors.blue),
                              title: Text(
                                refString,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(r['reference_text'] ?? ''),
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<int>(
                  value: _books.any((b) => b['id'] == _selectedBookId)
                      ? _selectedBookId
                      : null,
                  decoration: const InputDecoration(
                      labelText: 'Book', border: OutlineInputBorder()),
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
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<int>(
                  value: _chapters.contains(_selectedChapter)
                      ? _selectedChapter
                      : null,
                  decoration: const InputDecoration(
                      labelText: 'Ch', border: OutlineInputBorder()),
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
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<int>(
                  value:
                      _verses.contains(_selectedVerse) ? _selectedVerse : null,
                  decoration: const InputDecoration(
                      labelText: 'Vs', border: OutlineInputBorder()),
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
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _searchReferences,
              icon: const Icon(Icons.search),
              label: const Text('Find Cross References'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
