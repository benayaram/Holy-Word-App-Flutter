import 'package:flutter/material.dart';
// import 'package:flutter/services.dart' show rootBundle; // Unused now
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:auto_size_text/auto_size_text.dart';

// Data model for a single page
class NotePageData {
  final String title;
  final String date;
  final Map<String, dynamic>? verse; // Single verse for verse pages
  final String contentChunk; // Content for content pages
  final int pageIndex;
  final int totalPages;
  final bool isVersePage;

  NotePageData({
    required this.title,
    required this.date,
    this.verse,
    required this.contentChunk,
    required this.pageIndex,
    required this.totalPages,
    required this.isVersePage,
  });
}

class ShareNoteScreen extends StatefulWidget {
  final Map<String, dynamic> noteData;

  const ShareNoteScreen({super.key, required this.noteData});

  @override
  State<ShareNoteScreen> createState() => _ShareNoteScreenState();
}

class _ShareNoteScreenState extends State<ShareNoteScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.85);
  final ScreenshotController _screenshotController = ScreenshotController();
  List<NotePageData> _pages = [];
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _generatePages();
  }

  void _generatePages() {
    final title = widget.noteData['title'] ?? 'Untitled'; // Safety check
    final rawContent = widget.noteData['content'] ?? '';
    final verses = widget.noteData['verses'] is List
        ? widget.noteData['verses'] as List<dynamic>
        : [];

    final dateStr = widget.noteData['created_at']?.toString();
    final date = dateStr != null
        ? DateTime.parse(dateStr).toLocal().toString().split(' ')[0]
        : 'Unknown Date';

    List<NotePageData> pages = [];
    int pageIndex = 1;

    // 1. Generate Verse Pages (One per verse)
    for (var verse in verses) {
      if (verse is Map<String, dynamic>) {
        pages.add(NotePageData(
          title: title,
          date: date,
          verse: verse,
          contentChunk: '',
          pageIndex: pageIndex++,
          totalPages: 0, // Placeholder
          isVersePage: true,
        ));
      }
    }

    // 2. Generate Content Pages
    if (rawContent.isNotEmpty) {
      // Reduced char count to prevent overflow
      const int charsPerPage = 350;
      for (int i = 0; i < rawContent.length; i += charsPerPage) {
        int end = (i + charsPerPage < rawContent.length)
            ? i + charsPerPage
            : rawContent.length;
        String chunk = rawContent.substring(i, end);
        pages.add(NotePageData(
          title: title,
          date: date,
          verse: null,
          contentChunk: chunk,
          pageIndex: pageIndex++,
          totalPages: 0, // Placeholder
          isVersePage: false,
        ));
      }
    } else if (pages.isEmpty) {
      // Empty Note (No verses, no content) - Should be rare but handle safely
      pages.add(NotePageData(
        title: title,
        date: date,
        verse: null,
        contentChunk: '',
        pageIndex: 1,
        totalPages: 1,
        isVersePage: false,
      ));
    }

    // Update total pages
    int total = pages.length;
    _pages = pages
        .map((p) => NotePageData(
              title: p.title,
              date: p.date,
              verse: p.verse,
              contentChunk: p.contentChunk,
              pageIndex: p.pageIndex,
              totalPages: total,
              isVersePage: p.isVersePage,
            ))
        .toList();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Share Preview'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: NoteCardWidget(data: _pages[index]),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildActionButton(
                      icon: Icons.picture_as_pdf,
                      label: 'PDF',
                      onTap: _sharePdf),
                  const SizedBox(width: 20),
                  _buildActionButton(
                      icon: Icons.image, label: 'Images', onTap: _shareImages),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return ElevatedButton.icon(
      onPressed: _isExporting ? null : onTap,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }

  Future<void> _shareImages() async {
    setState(() => _isExporting = true);
    try {
      final tempDir = await getTemporaryDirectory();
      List<XFile> files = [];

      for (int i = 0; i < _pages.length; i++) {
        // Capture image with increased delay and proper context wrapper
        final imageBytes = await _screenshotController.captureFromWidget(
            Material(
              type: MaterialType.transparency,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: NoteCardWidget(data: _pages[i]),
              ),
            ),
            pixelRatio: 2.0,
            delay: const Duration(milliseconds: 100), // Increased to 100ms
            context: context,
            targetSize: const Size(600, 1066) // 9:16 approximate HD
            );

        // Write to temp file
        final fileName =
            'note_page_${i + 1}_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(imageBytes);

        files.add(XFile(file.path));
      }

      if (files.isNotEmpty) {
        await Share.shareXFiles(files, text: 'Shared via Holy Word App');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No images generated')));
        }
      }
    } catch (e) {
      debugPrint('Error sharing images: $e');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _sharePdf() async {
    setState(() => _isExporting = true);
    try {
      final pdf = pw.Document();

      // We will capture each page as an image and place it in the PDF.
      // This ensures exact visual fidelity including Telugu text.

      for (int i = 0; i < _pages.length; i++) {
        final imageBytes = await _screenshotController.captureFromWidget(
            Material(
              type: MaterialType.transparency,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: NoteCardWidget(data: _pages[i]),
              ),
            ),
            pixelRatio: 2.0,
            delay: const Duration(milliseconds: 100), // Increased delay
            context: context,
            targetSize: const Size(600, 1066));
        final image = pw.MemoryImage(imageBytes);
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Image(image, fit: pw.BoxFit.contain),
              );
            },
          ),
        );
      }

      // Save PDF
      final pdfBytes = await pdf.save();
      final file = XFile.fromData(
        pdfBytes,
        name: 'note_shared.pdf',
        mimeType: 'application/pdf',
      );

      await Share.shareXFiles([file], text: 'Shared via Holy Word App');
    } catch (e) {
      debugPrint('Error sharing PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }
}

class NoteCardWidget extends StatelessWidget {
  final NotePageData data;

  const NoteCardWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 9 / 16,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2C3E50), Color(0xFF4CA1AF)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('AUTO NOTES',
                    style: TextStyle(
                        color: Colors.white54,
                        letterSpacing: 1.5,
                        fontSize: 10)),
                Text(data.date,
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 10)),
              ],
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              data.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Serif',
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white24),
                ),
                child: data.isVersePage && data.verse != null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Center(
                              child: AutoSizeText(
                                '"${data.verse!['verse_text'] ?? ''}"',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 40,
                                  fontFamily: 'Serif',
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w600,
                                ),
                                minFontSize: 16,
                                maxLines: 10,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            data.verse!['reference'] ?? '',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.amberAccent,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      )
                    : SingleChildScrollView(
                        // Allow scroll in preview if needed, though export is static
                        child: Text(
                          data.contentChunk,
                          textAlign: TextAlign.center, // Centered content
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16, height: 1.6),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Holy Word App',
                    style: TextStyle(color: Colors.white30, fontSize: 12)),
                Text('${data.pageIndex} / ${data.totalPages}',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
