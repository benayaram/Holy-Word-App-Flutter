import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/bible_service.dart';
import 'widgets/bible_location_selector.dart';
import 'share_verse_screen.dart';
import 'batch_posts_screen.dart';
import '../../../../core/providers/language_provider.dart';

class ImageGeneratorDashboard extends ConsumerStatefulWidget {
  const ImageGeneratorDashboard({super.key});

  @override
  ConsumerState<ImageGeneratorDashboard> createState() =>
      _ImageGeneratorDashboardState();
}

class _ImageGeneratorDashboardState
    extends ConsumerState<ImageGeneratorDashboard> {
  // Selection State
  int _selectedBookId = 1; // Default Genesis
  int _selectedChapter = 1;
  int _selectedVerse = 1;
  String _selectedBookName = 'Genesis'; // Default
  bool _isLoading = false;

  final TextEditingController _batchCountController =
      TextEditingController(text: '10');

  // Batch Settings
  String _batchVerseFont = 'Mandali';
  String _batchReferenceFont = 'Mandali';
  String _batchSecondaryFont = 'Roboto';
  String _batchSecondaryRefFont = 'Roboto';
  int _batchOrientation = 0; // 0: Portrait, 1: Square, 2: Landscape

  // New Customizations
  bool _showWatermark = true;
  bool _enableDarkTint = false;
  bool _generateSeparately = false; // For "Both" mode
  String _language = 'Both'; // 'Telugu', 'English', 'Both'

  // Font List - synced with ShareVerseScreen implicitly (should be centralized ideally)
  // Font Lists
  final List<String> _teluguFonts = [
    'Mandali',
    'Ramabhadra',
    'Chathura',
    'Annamayya',
    'Dhurjati',
    'Gidugu',
    'Gurajada',
    'Jims',
    'Kanakadurga',
    'LakkiReddy',
    'Mallanna',
    'Nandakam',
    'NATS',
    'NTR',
    'Peddana',
    'Potti Sreeramulu',
    'Purushothamaa',
    'Ramaneeyawin',
    'RaviPrakash',
    'Seelaveerraju',
    'SPBalasubrahmanyam',
    'Sree Krushnadevaraya'
  ];

  final List<String> _englishFonts = [
    'Inter',
    'Roboto',
    'Lato',
    'Merriweather',
    'Oswald',
    'Raleway',
    'Montserrat',
    'Poppins',
    'Playfair Display',
    'Open Sans',
    'Nunito',
    'Source Sans Pro',
    'Slabo 27px',
    'PT Sans',
    'Lora',
    'Rubik',
    'Work Sans',
    'Quicksand',
    'Karla',
    'Josefin Sans',
    'Cabin',
    'Arvo',
    'Pacifico',
    'Dancing Script'
  ];

  // Background Settings
  String _bgType = 'Random'; // Random, Gradient, Image
  int _selectedGradientIndex = 0;
  final List<List<Color>> _gradients = [
    [Colors.blue, Colors.purple],
    [Colors.orange, Colors.red],
    [Colors.teal, Colors.blueGrey],
    [Colors.pink, Colors.deepPurple],
    [Colors.indigo, Colors.cyan],
    [Colors.deepOrange, Colors.yellow],
    [Colors.black87, Colors.grey],
  ];

  File? _customImage;

  @override
  void initState() {
    super.initState();
    _initDefaults();
  }

  void _initDefaults() {
    final isTelugu = ref.read(languageProvider) == 'telugu';
    _selectedBookName = isTelugu ? 'ఆదికాండము' : 'Genesis';
    // _selectedBookId implies 1
  }

  @override
  Widget build(BuildContext context) {
    // final isTelugu = ref.watch(languageProvider) == 'telugu';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Generator Studio'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionHeader(Icons.edit, 'Manual Selection', Colors.blue),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('Select a verse to design:',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 16),
                    BibleLocationSelector(
                      bookId: _selectedBookId,
                      chapter: _selectedChapter,
                      verse: _selectedVerse,
                      bookName: _selectedBookName,
                      onSelectionChanged: (bookId, chapter, verse) async {
                        setState(() {
                          _selectedBookId = bookId;
                          _selectedChapter = chapter;
                          _selectedVerse = verse;
                        });
                        // Selection only updates ID, text is fetched on Create
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _createFromSelection,
                      icon: const Icon(Icons.create),
                      label: const Text('Design Post'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionHeader(
                Icons.shuffle, 'Quick Random Post', Colors.purple),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              color: Colors.purple.shade50,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: InkWell(
                onTap: _isLoading ? null : _createRandom,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Icon(Icons.auto_awesome,
                          size: 40, color: Colors.purple),
                      const SizedBox(height: 12),
                      const Text(
                        'Surprise Me!',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Get a random verse and start designing',
                        style: TextStyle(color: Colors.purple.shade700),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildSectionHeader(
                Icons.copy_all, 'Batch Generator', Colors.orange),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Generate Multiple Posts at Once',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                        'Create a grid of random verse posts. Tap any to customize.'),
                    const SizedBox(height: 16),
                    // Settings Row
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Language Selection (Moved Top)
                        const Text('Language:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _language,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'Telugu', child: Text('Telugu Only')),
                            DropdownMenuItem(
                                value: 'English', child: Text('English Only')),
                            DropdownMenuItem(
                                value: 'Both', child: Text('Both (Parallel)')),
                          ],
                          onChanged: (v) {
                            setState(() {
                              _language = v!;
                              // Reset fonts based on language
                              if (_language == 'Telugu') {
                                _batchVerseFont = 'Mandali';
                                _batchReferenceFont = 'Mandali';
                              } else if (_language == 'English') {
                                _batchVerseFont = 'Roboto';
                                _batchReferenceFont = 'Roboto';
                              } else {
                                _batchVerseFont = 'Mandali';
                                _batchSecondaryFont = 'Roboto';
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        const Text('Fonts:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),

                        // PRIMARY ROW
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _batchVerseFont,
                                decoration: InputDecoration(
                                    labelText: _language == 'English'
                                        ? 'Verse (Eng)'
                                        : 'Verse (Tel)',
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    border: const OutlineInputBorder()),
                                items: (_language == 'English'
                                        ? _englishFonts
                                        : _teluguFonts)
                                    .map((f) => DropdownMenuItem(
                                        value: f,
                                        child: Text(f,
                                            style: TextStyle(fontFamily: f))))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _batchVerseFont = v!),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _batchReferenceFont,
                                decoration: InputDecoration(
                                    labelText: _language == 'English'
                                        ? 'Ref (Eng)'
                                        : 'Ref (Tel)',
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    border: const OutlineInputBorder()),
                                items: (_language == 'English'
                                        ? _englishFonts
                                        : _teluguFonts)
                                    .map((f) => DropdownMenuItem(
                                        value: f,
                                        child: Text(f,
                                            style: TextStyle(fontFamily: f))))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _batchReferenceFont = v!),
                              ),
                            ),
                          ],
                        ),

                        // SECONDARY ROW (Only if BOTH)
                        if (_language == 'Both') ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _batchSecondaryFont,
                                  decoration: const InputDecoration(
                                      labelText: 'Verse 2 (Eng)',
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      border: OutlineInputBorder()),
                                  items: _englishFonts
                                      .map((f) => DropdownMenuItem(
                                          value: f,
                                          child: Text(f,
                                              style: TextStyle(fontFamily: f))))
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _batchSecondaryFont = v!),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _batchSecondaryRefFont,
                                  decoration: const InputDecoration(
                                      labelText: 'Ref 2 (Eng)',
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      border: OutlineInputBorder()),
                                  items: _englishFonts
                                      .map((f) => DropdownMenuItem(
                                          value: f,
                                          child: Text(f,
                                              style: TextStyle(fontFamily: f))))
                                      .toList(),
                                  onChanged: (v) => setState(
                                      () => _batchSecondaryRefFont = v!),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                                'Split: Separate Telugu & English Posts'),
                            subtitle: const Text(
                                'Generates independent cards for each language'),
                            value: _generateSeparately,
                            onChanged: (v) =>
                                setState(() => _generateSeparately = v!),
                          ),
                        ],

                        const SizedBox(height: 12),
                        const Text('Background & Layout:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: _batchOrientation,
                                decoration: const InputDecoration(
                                    labelText: 'Orientation',
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    border: OutlineInputBorder()),
                                items: const [
                                  DropdownMenuItem(
                                      value: 0, child: Text('Portrait (9:16)')),
                                  DropdownMenuItem(
                                      value: 1, child: Text('Square (1:1)')),
                                  DropdownMenuItem(
                                      value: 2,
                                      child: Text('Landscape (16:9)')),
                                ],
                                onChanged: (v) =>
                                    setState(() => _batchOrientation = v!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Background Selector
                        DropdownButtonFormField<String>(
                          value: _bgType,
                          decoration: const InputDecoration(
                              labelText: 'Background Style',
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              border: OutlineInputBorder()),
                          items: const [
                            DropdownMenuItem(
                                value: 'Random', child: Text('Random Colors')),
                            DropdownMenuItem(
                                value: 'Gradient',
                                child: Text('Select Gradient')),
                            DropdownMenuItem(
                                value: 'Image', child: Text('Custom Image')),
                          ],
                          onChanged: (v) {
                            setState(() => _bgType = v!);
                            if (v == 'Image' && _customImage == null) {
                              _pickImage();
                            }
                          },
                        ),

                        // Language & Customization
                        const SizedBox(height: 16),

                        const SizedBox(height: 8),
                        CheckboxListTile(
                          title: const Text('Show Watermark'),
                          value: _showWatermark,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (v) => setState(() => _showWatermark = v!),
                        ),
                        if (_bgType == 'Image')
                          CheckboxListTile(
                            title: const Text('Enable Dark Tint'),
                            subtitle: const Text(
                                'Improves text readability on images'),
                            value: _enableDarkTint,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (v) =>
                                setState(() => _enableDarkTint = v!),
                          ),

                        const SizedBox(height: 24),
                        // Count Field
                        if (_bgType == 'Image' && _customImage != null) ...[
                          const SizedBox(height: 8),
                          Stack(children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(_customImage!,
                                  height: 100,
                                  width: double.infinity,
                                  fit: BoxFit.cover),
                            ),
                            Positioned(
                                right: 4,
                                top: 4,
                                child: CircleAvatar(
                                    backgroundColor: Colors.white,
                                    child: IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: _pickImage)))
                          ]),
                        ],
                        if (_bgType == 'Gradient') ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 50,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _gradients.length,
                              itemBuilder: (context, index) {
                                final gradient = _gradients[index];
                                return GestureDetector(
                                  onTap: () => setState(
                                      () => _selectedGradientIndex = index),
                                  child: Container(
                                    width: 50,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      gradient:
                                          LinearGradient(colors: gradient),
                                      borderRadius: BorderRadius.circular(8),
                                      border: _selectedGradientIndex == index
                                          ? Border.all(
                                              color: Colors.black, width: 2)
                                          : null,
                                    ),
                                    child: _selectedGradientIndex == index
                                        ? const Icon(Icons.check,
                                            color: Colors.white)
                                        : null,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _batchCountController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Quantity (e.g., 10)',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : _generateBatch,
                                icon: const Icon(Icons.grid_view),
                                label: const Text('Generate Grid'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 56),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _customImage = File(pickedFile.path);
        _bgType = 'Image'; // Force type if they just picked one
      });
    } else {
      // If they cancelled and we had no image, revert to Random?
      if (_customImage == null && _bgType == 'Image') {
        setState(() => _bgType = 'Random');
      }
    }
  }

  Widget _buildSectionHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Future<void> _createFromSelection() async {
    setState(() => _isLoading = true);
    try {
      final bibleService = ref.read(bibleServiceProvider);
      // Fetch text for selected location
      final verses =
          await bibleService.getVerses(_selectedBookId, _selectedChapter);

      // We only have the first verse ID from selector, and no "end" verse.
      // Selector selects ONE verse start usually.
      // Let's find the verse text.
      final verseData = verses.firstWhere(
        (v) => v['verse'] == _selectedVerse,
        orElse: () => <String, Object>{},
      );

      if (verseData.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Verse not found!')));
        }
        return;
      }

      final text = verseData['text'] ?? '';
      // We need book name.
      final books = await bibleService.getBooks();
      final book = books.firstWhere((b) => b['id'] == _selectedBookId);
      final bookName = book['name'];

      final reference = '$bookName $_selectedChapter:$_selectedVerse';

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ShareVerseScreen(
            verseText: text,
            verseReference: reference,
            bookId: _selectedBookId,
            chapter: _selectedChapter,
            verseNumbers: [_selectedVerse],
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error loading verse: $e');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createRandom() async {
    setState(() => _isLoading = true);
    try {
      final bibleService = ref.read(bibleServiceProvider);
      final data = await bibleService.getRandomVerse();

      if (data.isEmpty) return;

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ShareVerseScreen(
            verseText: data['text'],
            verseReference: data['reference'],
            bookId: data['book_id'],
            chapter: data['chapter'],
            verseNumbers: [data['verse']],
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error random verse: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _generateBatch() {
    final count = int.tryParse(_batchCountController.text) ?? 10;
    if (count <= 0 || count > 50) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please enter a number between 1 and 50')));
      return;
    }

    if (_bgType == 'Image' && _customImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an image first')));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BatchPostsScreen(
          count: count,
          verseFont: _batchVerseFont,
          referenceFont: _batchReferenceFont,
          orientation: _batchOrientation,
          bgType: _bgType,
          selectedGradient:
              _bgType == 'Gradient' ? _gradients[_selectedGradientIndex] : null,
          customImage: _customImage,
          showWatermark: _showWatermark,
          enableDarkTint: _enableDarkTint,
          language: _language,
          secondaryFont: _batchSecondaryFont,
          secondaryRefFont: _batchSecondaryRefFont,
          generateSeparately: _generateSeparately,
        ),
      ),
    );
  }
}
