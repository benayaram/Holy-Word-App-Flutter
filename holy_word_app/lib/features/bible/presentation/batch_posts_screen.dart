import 'dart:math';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import '../services/bible_service.dart';
import 'share_verse_screen.dart';
import 'package:screenshot/screenshot.dart';

import 'package:pdf/widgets.dart' as pw;
import 'package:auto_size_text/auto_size_text.dart';

class BatchPostsScreen extends ConsumerStatefulWidget {
  final int count;
  final String verseFont;
  final String referenceFont;
  final int orientation; // 0: Portrait, 1: Square, 2: Landscape
  final String? bgType;
  final List<Color>? selectedGradient;
  final File? customImage;

  const BatchPostsScreen({
    super.key,
    required this.count,
    required this.verseFont,
    required this.referenceFont,
    required this.orientation,
    this.bgType,
    this.selectedGradient,
    this.customImage,
    this.showWatermark = true,
    this.enableDarkTint = false,
    this.language,
    this.secondaryFont,
    this.secondaryRefFont,
    this.generateSeparately = false,
  });

  final bool showWatermark;
  final bool enableDarkTint;
  final String? language;
  final String? secondaryFont;
  final String? secondaryRefFont;
  final bool generateSeparately;

  @override
  ConsumerState<BatchPostsScreen> createState() => _BatchPostsScreenState();
}

class _BatchPostsScreenState extends ConsumerState<BatchPostsScreen> {
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;
  bool _isExporting = false;
  bool _isGridView = true; // Toggle between Grid and ViewPager
  final ScreenshotController _screenshotController = ScreenshotController();

  final List<List<Color>> _randomGradients = [
    [Colors.blue, Colors.purple],
    [Colors.orange, Colors.red],
    [Colors.teal, Colors.blueGrey],
    [Colors.pink, Colors.deepPurple],
    [Colors.indigo, Colors.cyan],
    [Colors.deepOrange, Colors.yellow],
    [Colors.black87, Colors.grey],
  ];

  @override
  void initState() {
    super.initState();
    _generatePosts();
  }

  Future<void> _generatePosts() async {
    final bibleService = ref.read(bibleServiceProvider);
    final List<Map<String, dynamic>> generated = [];

    // Safety Cap
    int target = widget.count;
    if (target > 50) target = 50;

    int index = 0;
    int attempts = 0;
    while (generated.length < target && attempts < target * 3) {
      attempts++;
      // Fetch Random Verse with Language
      final data = await bibleService.getRandomVerse(language: widget.language);
      if (data.isNotEmpty) {
        // SPLIT GENERATION CHECK
        if (widget.language == 'Both' && widget.generateSeparately) {
          // 1. Telugu Post
          if (data['text_telugu'] != null) {
            generated.add({
              ...data,
              'text': data['text_telugu'],
              'reference': data['reference_telugu'] ?? data['reference'],
              'style': _generateStyle(index,
                  overrideFont: widget.verseFont,
                  overrideRefFont: widget.referenceFont),
            });
            index++;
          }

          // 2. English Post
          if (data['text_english'] != null) {
            generated.add({
              ...data,
              'text': data['text_english'],
              'reference': data['reference_english'] ?? data['reference'],
              'style': _generateStyle(index,
                  overrideFont: widget.secondaryFont,
                  overrideRefFont: widget.secondaryRefFont),
            });
            index++;
          }
        } else {
          // Standard / Parallel Generation
          final style = _generateStyle(index);
          generated.add({
            ...data,
            'style': style,
          });
          index++;
        }
      }
    }

    if (mounted) {
      setState(() {
        _posts = generated;
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshVerse(int index) async {
    final bibleService = ref.read(bibleServiceProvider);
    final data = await bibleService.getRandomVerse(language: widget.language);

    if (data.isNotEmpty) {
      setState(() {
        // Keep style, update text/ref
        final oldStyle = _posts[index]['style'];

        // If in Split mode, we need to pick the correct language text based on the font of the current card
        // This is a bit tricky as we don't strictly know if this specific card was "English" or "Telugu"
        // But we can guess from the style font or just use the primary text if available.
        // Simple approach: Use standard replacement. If split, refreshing might mix languages unless we are careful.
        // For now, standard refresh.

        if (widget.generateSeparately && widget.language == 'Both') {
          // Decide language based on current text content? Or just style?
          // Actually, getRandomVerse(language: 'Both') returns both.
          // If the current post has 'text_english', we should probably update it with 'text_english'.
        }

        // Simplified Logic: Just update 'text' and 'reference'.
        // If it was a split post, 'text' holds the content.
        // We will prioritize 'text_telugu' if the original font suggests Telugu (e.g. Mandali), else English.

        String newText = data['text'];
        String newRef = data['reference'];

        if (widget.generateSeparately && widget.language == 'Both') {
          // Heuristic: Check if current font is a Telugu font
          final font = oldStyle['verseFont'];
          // This list check is not robust if we don't have access to the lists here.
          // Better: Check if the original text contained Telugu characters?
          // Or simpler: If we are splitting, we likely want to maintain the language of the card.
          // If data has parallel, we pick one.

          final isTeluguFont = [
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
          ].contains(font);

          if (isTeluguFont) {
            newText = data['text_telugu'] ?? data['text'];
            newRef = data['reference_telugu'] ?? data['reference'];
          } else {
            newText = data['text_english'] ?? data['text'];
            newRef = data['reference_english'] ?? data['reference'];
          }
        }

        _posts[index] = {
          ...data,
          'text': newText,
          'reference': newRef,
          'style': oldStyle,
          'edited_image': null,
        };
      });
    }
  }

  Map<String, dynamic> _generateStyle(int index,
      {String? overrideFont, String? overrideRefFont}) {
    // If Custom Image is present, use it
    if (widget.bgType == 'Image' && widget.customImage != null) {
      return {
        'type': 'image',
        'image': widget.customImage,
        'verseFont': overrideFont ?? widget.verseFont,
        'refFont': overrideRefFont ?? widget.referenceFont,
        'secFont': widget.secondaryFont ?? 'Roboto',
        'secRefFont': widget.secondaryRefFont ?? 'Roboto',
      };
    }

    // If specific gradient selected
    if (widget.bgType == 'Gradient' && widget.selectedGradient != null) {
      return {
        'type': 'gradient',
        'gradient': widget.selectedGradient,
        'verseFont': overrideFont ?? widget.verseFont,
        'refFont': overrideRefFont ?? widget.referenceFont,
        'secFont': widget.secondaryFont ?? 'Roboto',
        'secRefFont': widget.secondaryRefFont ?? 'Roboto',
      };
    }

    // Random Gradients
    final random = Random();
    final colors = _randomGradients[random.nextInt(_randomGradients.length)];

    return {
      'type': 'gradient',
      'gradient': colors,
      'verseFont': overrideFont ?? widget.verseFont,
      'refFont': overrideRefFont ?? widget.referenceFont,
      'secFont': widget.secondaryFont ?? 'Roboto',
      'secRefFont': widget.secondaryRefFont ?? 'Roboto',
    };
  }

  double get _aspectRatio {
    switch (widget.orientation) {
      case 1:
        return 1.0; // Square
      case 2:
        return 16 / 9; // Landscape
      default:
        return 9 / 16; // Portrait
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Generated ${widget.count} Posts'),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_carousel : Icons.grid_view),
            tooltip:
                _isGridView ? 'Switch to Slide View' : 'Switch to Grid View',
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export PDF',
            onPressed: _isExporting || _isLoading ? null : _exportPdf,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export ZIP',
            onPressed: _isExporting || _isLoading ? null : _exportZip,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generating creative posts...'),
                ],
              ),
            )
          : Stack(
              children: [
                _isGridView ? _buildGridView() : _buildPageView(),
                if (_isExporting)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text('Creating ZIP archive...',
                              style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: _aspectRatio,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _posts.length,
      itemBuilder: (context, index) => _buildPostItem(index, isGrid: true),
    );
  }

  Widget _buildPageView() {
    return PageView.builder(
      itemCount: _posts.length,
      controller: PageController(viewportFraction: 0.85),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
          child: Center(
            child: AspectRatio(
              aspectRatio: _aspectRatio,
              child: _buildPostItem(index, isGrid: false),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPostItem(int index, {required bool isGrid}) {
    final post = _posts[index];
    final Uint8List? editedImage = post['edited_image'];

    // If we have an edited image, display it directly
    if (editedImage != null) {
      return GestureDetector(
        onTap: () => _openEditor(post),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            image: DecorationImage(
              image: MemoryImage(editedImage),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              // Overlay Edit Icon
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                      color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.edit, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Refresh Handler
    final onRefresh = () => _refreshVerse(index);

    final style = post['style'];
    final type = style['type'];
    final colors = style['gradient'] as List<Color>?;
    final image = style['image'] as File?;
    final vFont = style['verseFont'] as String;
    final rFont = style['refFont'] as String;

    return GestureDetector(
      onTap: () => _openEditor(post),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          image: (type == 'image' && image != null)
              ? DecorationImage(
                  image: FileImage(image),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Gradient if no image
            if (type == 'gradient' && colors != null)
              Container(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                  colors: colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )),
              ),

            // Dark Tint for better text visibility if image
            if (type == 'image' && widget.enableDarkTint)
              Container(color: Colors.black.withOpacity(0.4)),

            // Content
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: (_aspectRatio > 1.2 && isGrid) ? 6 : 16,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        AutoSizeText(
                          post['text'],
                          maxLines: post['secondary_text'] != null
                              ? (_aspectRatio > 1.2 ? 2 : 3)
                              : (isGrid ? (_aspectRatio > 1.2 ? 3 : 6) : 10),
                          minFontSize: 8,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: vFont,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: isGrid ? 12 : 20,
                            shadows: const [
                              Shadow(
                                color: Colors.black45,
                                offset: Offset(1, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        if (post['secondary_text'] != null) ...[
                          SizedBox(
                              height: (_aspectRatio > 1.2 && isGrid) ? 4 : 8),
                          AutoSizeText(
                            post['secondary_text'],
                            maxLines: _aspectRatio > 1.2 ? 2 : 3,
                            minFontSize: 8,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: vFont, // Use same font? Or default?
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: isGrid ? 12 : 20,
                              shadows: const [
                                Shadow(
                                  color: Colors.black45,
                                  offset: Offset(1, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ]
                      ]),
                    ),
                  ),
                  SizedBox(height: (_aspectRatio > 1.2 && isGrid) ? 2 : 8),
                  Text(
                    post['secondary_reference'] != null
                        ? '${post['reference']} | ${post['secondary_reference']}'
                        : post['reference'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: rFont,
                      color: Colors.white70,
                      fontSize: isGrid ? 10 : 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Edit Indicator overlay
            Positioned(
              top: 8,
              right: 8,
              child: const Icon(Icons.edit, color: Colors.white70, size: 16),
            ),
            // Refresh Button Overlay
            Positioned(
              top: 8,
              left: 8,
              child: GestureDetector(
                onTap: onRefresh,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                      color: Colors.black45, shape: BoxShape.circle),
                  child:
                      const Icon(Icons.refresh, color: Colors.white, size: 16),
                ),
              ),
            ),

            // Watermark (if needed)
            if (widget.showWatermark)
              Positioned(
                  bottom: 8,
                  right: 8,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Image.asset('assets/images/logo.png',
                        width: 20,
                        height: 20,
                        errorBuilder: (c, e, s) => const SizedBox()),
                    const SizedBox(width: 4),
                    const Text('Holy Word',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            shadows: [
                              Shadow(color: Colors.black54, blurRadius: 2)
                            ]))
                  ]))
          ],
        ),
      ),
    );
  }

  Future<void> _openEditor(Map<String, dynamic> post) async {
    final style = post['style'];
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShareVerseScreen(
          verseText: post['text'],
          verseReference: post['reference'],
          bookId: post['book_id'],
          chapter: post['chapter'],
          verseNumbers: [post['verse']],
          initialGradient: style['gradient'], // Null if image
          initialVerseFont: style['verseFont'],
          initialReferenceFont: style['refFont'],
          initialBackgroundImage: style['image'],
          initialShowWatermark: widget.showWatermark,
          initialEnableTint: widget.enableDarkTint,
          initialAspectRatio: _aspectRatio,
          parallelText: post['secondary_text'],
          parallelReference: post['secondary_reference'],
          initialSecondaryFont: style['secFont'],
          initialSecondaryReferenceFont: style['secRefFont'],
        ),
      ),
    );

    // If user saved changes, update the post
    if (result != null && result is Uint8List) {
      setState(() {
        post['edited_image'] = result;
      });
    }
  }

  Future<void> _exportZip() async {
    final confirmed = await _showExportPreview('ZIP');
    if (!confirmed) return;

    setState(() => _isExporting = true);
    try {
      final archive = Archive();
      final tempDir = await getTemporaryDirectory();

      for (int i = 0; i < _posts.length; i++) {
        final post = _posts[i];
        final bytes = post['edited_image'] ?? await _capturePost(post);

        if (bytes != null) {
          final fileName = 'verse_$i.png';
          final file = ArchiveFile(fileName, bytes.length, bytes);
          archive.addFile(file);
        }
      }

      final zipEncoder = ZipEncoder();
      final encodedZip = zipEncoder.encode(archive);
      // if (encodedZip == null) return;

      final zipFile = File('${tempDir.path}/verses.zip');
      await zipFile.writeAsBytes(encodedZip);

      if (!mounted) return;

      // Share the ZIP
      await Share.shareXFiles([XFile(zipFile.path)],
          text: 'Here are your verse images!');
    } catch (e) {
      debugPrint('Export Error: $e');
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Export failed: $e')));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportPdf() async {
    final confirmed = await _showExportPreview('PDF');
    if (!confirmed) return;

    setState(() => _isExporting = true);
    try {
      final pdf = pw.Document();
      final tempDir = await getTemporaryDirectory();

      for (int i = 0; i < _posts.length; i++) {
        final post = _posts[i];
        final bytes = post['edited_image'] ?? await _capturePost(post);

        if (bytes != null) {
          final image = pw.MemoryImage(bytes);
          pdf.addPage(
            pw.Page(
              build: (pw.Context context) {
                return pw.Center(
                  child: pw.Image(image),
                );
              },
            ),
          );
        }
      }

      final pdfFile = File('${tempDir.path}/verses.pdf');
      await pdfFile.writeAsBytes(await pdf.save());

      if (!mounted) return;

      // Share the PDF
      await Share.shareXFiles([XFile(pdfFile.path)],
          text: 'Here are your verse images in PDF!');
    } catch (e) {
      debugPrint('PDF Export Error: $e');
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('PDF Export failed: $e')));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<bool> _showExportPreview(String type) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Preview $type Export'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: Scrollbar(
                thumbVisibility: true,
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: _aspectRatio,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _posts.length,
                  itemBuilder: (context, index) =>
                      _buildPostItem(index, isGrid: true),
                ),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Export')),
            ],
          ),
        ) ??
        false;
  }

  Future<Uint8List?> _capturePost(Map<String, dynamic> post) {
    final style = post['style'];
    final colors = style['gradient'] as List<Color>?;
    final image = style['image'] as File?;
    final vFont = style['verseFont'] as String;
    final rFont = style['refFont'] as String;

    // High Res Capture Widget
    // Aspect Ratio Fix:
    // Portrait (0) -> 9/16 -> height = width / (9/16) = width * (16/9)
    // Square (1) -> 1/1 -> height = width
    // Landscape (2) -> 16/9 -> height = width / (16/9) = width * (9/16)

    double aspectRatio = 9 / 16;
    if (widget.orientation == 1) aspectRatio = 1.0;
    if (widget.orientation == 2) aspectRatio = 16 / 9;

    Widget widgetToCapture = Container(
      width: 1080,
      height: 1080 / aspectRatio,
      decoration: BoxDecoration(
        color: Colors.black, // Fallback
        image: image != null
            ? DecorationImage(image: FileImage(image), fit: BoxFit.cover)
            : null,
        gradient: (image == null && colors != null)
            ? LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (image != null && widget.enableDarkTint)
            Container(color: Colors.black.withOpacity(0.4)),
          Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      AutoSizeText(
                        post['text'],
                        textAlign: TextAlign.center,
                        maxLines: post['secondary_text'] != null
                            ? (_aspectRatio > 1.2 ? 2 : 4)
                            : (_aspectRatio > 1.2 ? 4 : 8),
                        style: TextStyle(
                          fontFamily: vFont,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 48,
                          shadows: const [
                            Shadow(
                              color: Colors.black45,
                              offset: Offset(2, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      if (post['secondary_text'] != null) ...[
                        const SizedBox(height: 24),
                        AutoSizeText(
                          post['secondary_text'],
                          textAlign: TextAlign.center,
                          maxLines: _aspectRatio > 1.2 ? 2 : 4,
                          style: TextStyle(
                            fontFamily: vFont,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 48,
                            shadows: const [
                              Shadow(
                                color: Colors.black45,
                                offset: Offset(2, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ]
                    ]),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  post['secondary_reference'] != null
                      ? '${post['reference']} | ${post['secondary_reference']}'
                      : post['reference'],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: rFont,
                    color: Colors.white70,
                    fontSize: 32,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (widget.showWatermark)
            Positioned(
                bottom: 32,
                right: 32,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Image.asset('assets/images/logo.png',
                      width: 40,
                      height: 40,
                      errorBuilder: (c, e, s) => const SizedBox()),
                  const SizedBox(width: 12),
                  const Text('Holy Word',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 4)
                          ]))
                ])),
        ],
      ),
    );

    return _screenshotController.captureFromWidget(
      widgetToCapture,
      delay: const Duration(milliseconds: 10),
      pixelRatio: 2.0,
    );
  }
}
