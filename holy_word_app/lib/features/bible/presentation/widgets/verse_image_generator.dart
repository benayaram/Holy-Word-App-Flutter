import 'dart:io';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class VerseImageGenerator extends StatefulWidget {
  final String text;
  final String reference;

  const VerseImageGenerator({
    super.key,
    required this.text,
    required this.reference,
  });

  @override
  State<VerseImageGenerator> createState() => _VerseImageGeneratorState();
}

class _VerseImageGeneratorState extends State<VerseImageGenerator> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSharing = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Screenshot(
            controller: _screenshotController,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.shade800,
                    Colors.purple.shade800,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.format_quote,
                    color: Colors.white54,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 1.5,
                      fontFamily: 'Serif', // Use a nice font if available
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.reference,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Holy Word App',
                    style: TextStyle(
                      color: Colors.white30,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _isSharing ? null : _shareImage,
                icon: _isSharing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.share),
                label: Text(_isSharing ? 'Generating...' : 'Share Image'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _shareImage() async {
    setState(() {
      _isSharing = true;
    });

    try {
      final image = await _screenshotController.capture();
      if (image == null) return;

      final directory = await getTemporaryDirectory();
      final imagePath =
          await File('${directory.path}/verse_share.png').create();
      await imagePath.writeAsBytes(image);

      await Share.shareXFiles(
        [XFile(imagePath.path)],
        text: 'Check out this verse from Holy Word App!',
      );
    } catch (e) {
      debugPrint('Error sharing image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }
}
