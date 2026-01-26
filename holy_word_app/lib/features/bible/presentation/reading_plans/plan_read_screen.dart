import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:holy_word_app/features/bible/services/bible_service.dart';
import '../../services/reading_plan_service.dart';
import 'reading_plan_constants.dart';

class PlanReadScreen extends StatefulWidget {
  final String planId;
  final int dayIndex;
  final List<String> readings;

  const PlanReadScreen({
    super.key,
    required this.planId,
    required this.dayIndex,
    required this.readings,
  });

  @override
  State<PlanReadScreen> createState() => _PlanReadScreenState();
}

class ReadingItem {
  final String originalString;
  final String bookName;
  final int bookId;
  final int chapter;
  final int? startVerse;
  final int? endVerse;

  ReadingItem({
    required this.originalString,
    required this.bookName,
    required this.bookId,
    required this.chapter,
    this.startVerse,
    this.endVerse,
  });
}

class _PlanReadScreenState extends State<PlanReadScreen> {
  final ReadingPlanService _planService = ReadingPlanService();
  late BibleService _bibleService;
  late ConfettiController _confettiController;

  bool _isDayCompleted = false;

  // Parsed list of chapters/segments to read
  List<ReadingItem> _readingItems = [];
  // Tracks completed items in this session by index
  final Set<int> _completedItemIndices = {};

  // Page controller for swiping
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _bibleService = BibleService('telugu');
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
    _checkStatus();
    _parseReadings();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _parseReadings() {
    List<ReadingItem> items = [];

    for (String reading in widget.readings) {
      final lastSpace = reading.lastIndexOf(' ');
      if (lastSpace == -1) continue; // Skip invalid

      final englishBook = reading.substring(0, lastSpace);
      final referencePart = reading.substring(lastSpace + 1);
      final bookId = ReadingPlanConstants.englishBookToId[englishBook];

      if (bookId == null) continue;

      // Case 1: Multi-Chapter Verse Range (e.g., "1:1-3:24")
      if (referencePart.contains('-') && referencePart.split(':').length > 2) {
        final parts = referencePart.split('-');
        final startPart = parts[0]; // "1:1"
        final endPart = parts[1]; // "3:24"

        final startChapter = int.tryParse(startPart.split(':')[0]) ?? 1;
        final startVerse = int.tryParse(startPart.split(':')[1]) ?? 1;
        final endChapter = int.tryParse(endPart.split(':')[0]) ?? startChapter;
        final endVerse = int.tryParse(endPart.split(':')[1]);

        for (int c = startChapter; c <= endChapter; c++) {
          int? sVerse;
          int? eVerse;

          if (c == startChapter) {
            sVerse = startVerse;
          }
          if (c == endChapter) {
            eVerse = endVerse;
          }

          items.add(ReadingItem(
            originalString: reading,
            bookName: englishBook,
            bookId: bookId,
            chapter: c,
            startVerse: sVerse,
            endVerse: eVerse,
          ));
        }
      }
      // Case 2: Verse Range within single chapter (e.g., "1:1-5")
      else if (referencePart.contains(':')) {
        final parts = referencePart.split(':');
        final chapter = int.tryParse(parts[0]) ?? 1;
        final versePart = parts[1];

        int? startVerse;
        int? endVerse;

        if (versePart.contains('-')) {
          final vParts = versePart.split('-');
          startVerse = int.tryParse(vParts[0]);
          endVerse = int.tryParse(vParts[1]);
        } else {
          startVerse = int.tryParse(versePart);
          endVerse = startVerse;
        }

        items.add(ReadingItem(
          originalString: reading,
          bookName: englishBook,
          bookId: bookId,
          chapter: chapter,
          startVerse: startVerse,
          endVerse: endVerse,
        ));
      }
      // Case 3: Chapter Range (e.g., "9-10")
      else if (referencePart.contains('-')) {
        final parts = referencePart.split('-');
        final startChapter = int.tryParse(parts[0]) ?? 1;
        final endChapter = int.tryParse(parts[1]) ?? startChapter;

        for (int c = startChapter; c <= endChapter; c++) {
          items.add(ReadingItem(
            originalString: reading,
            bookName: englishBook,
            bookId: bookId,
            chapter: c,
          ));
        }
      }
      // Case 4: Single Chapter (e.g., "1")
      else {
        final chapter = int.tryParse(referencePart) ?? 1;
        items.add(ReadingItem(
          originalString: reading,
          bookName: englishBook,
          bookId: bookId,
          chapter: chapter,
        ));
      }
    }

    if (mounted) {
      setState(() {
        _readingItems = items;
      });
    }
  }

  Future<void> _checkStatus() async {
    final progress = await _planService.getPlanProgress(widget.planId);
    final isDone = progress.any(
        (p) => p['day_index'] == widget.dayIndex && p['is_completed'] == 1);

    if (mounted) {
      setState(() {
        _isDayCompleted = isDone;
        if (isDone) {
          // If day is done, mark all items as done for visual consistency
          for (int i = 0; i < _readingItems.length; i++) {
            _completedItemIndices.add(i);
          }
        }
      });
    }
  }

  Future<void> _markItemComplete(int index) async {
    setState(() {
      _completedItemIndices.add(index);
    });

    // Check if all items are completed
    if (_completedItemIndices.length == _readingItems.length) {
      await _toggleDayComplete(true);
    } else {
      // Auto-advance to next page if not last
      if (index < _readingItems.length - 1) {
        // Small delay for user to see the check
        Future.delayed(const Duration(milliseconds: 300), () {
          _pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut);
        });
      }
    }
  }

  Future<void> _toggleDayComplete(bool complete) async {
    if (complete) {
      await _planService.markDayComplete(widget.planId, widget.dayIndex);
      if (mounted) {
        setState(() => _isDayCompleted = true);
        _confettiController.play();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Day Completed! Great job! 🎉')),
        );
      }
    } else {
      await _planService.markDayIncomplete(widget.planId, widget.dayIndex);
      if (mounted) setState(() => _isDayCompleted = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_readingItems.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Day ${widget.dayIndex + 1}')),
        body: const Center(child: Text("No readings found for this day.")),
      );
    }

    return Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Day ${widget.dayIndex + 1}',
                  style: const TextStyle(fontSize: 16)),
              if (_readingItems.isNotEmpty)
                Text(
                  '${_currentPage + 1}/${_readingItems.length} - ${ReadingPlanConstants.getTeluguBookName(_readingItems[_currentPage].bookName)} ${_readingItems[_currentPage].chapter}',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.normal),
                ),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(_isDayCompleted
                  ? Icons.check_circle
                  : Icons.check_circle_outline),
              onPressed: () => _toggleDayComplete(!_isDayCompleted),
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: _readingItems.length,
                    itemBuilder: (context, index) {
                      final item = _readingItems[index];
                      return _buildReadingPage(item, index);
                    },
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.center,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple
                ],
              ),
            ),
          ],
        ));
  }

  Widget _buildReadingPage(ReadingItem item, int index) {
    debugPrint(
        'PlanReadScreen: Building page for ${item.bookName} ${item.chapter}');

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _bibleService.getChapterText(item.bookId, item.chapter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          final error = snapshot.error.toString();
          if (error.contains('no such table')) {
            return const Center(
                child: Text('Database Error: Please restart app.'));
          }
          return Center(child: Text('Error loading chapter: $error'));
        }

        final verses = snapshot.data ?? [];

        // Filter verses if range is specified
        final filteredVerses = verses.where((v) {
          final vNum = v['verse'] as int;
          if (item.startVerse != null && vNum < item.startVerse!) return false;
          if (item.endVerse != null && vNum > item.endVerse!) return false;
          return true;
        }).toList();

        if (filteredVerses.isEmpty) {
          return Center(
              child:
                  Text("No verses found for ${item.bookName} ${item.chapter}"));
        }

        return Column(
          children: [
            // HEADER: Reference Title
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Column(
                children: [
                  Text(
                    '${ReadingPlanConstants.getTeluguBookName(item.bookName)} ${item.chapter}${item.startVerse != null ? ":${item.startVerse}-${item.endVerse}" : ""}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Reading ${index + 1} of ${_readingItems.length}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredVerses.length + 1,
                itemBuilder: (context, i) {
                  if (i == filteredVerses.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32.0),
                      child: Center(
                        child: ElevatedButton.icon(
                          onPressed: _completedItemIndices.contains(index)
                              ? null
                              : () => _markItemComplete(index),
                          icon: const Icon(Icons.check),
                          label: Text(_completedItemIndices.contains(index)
                              ? 'Completed'
                              : 'Mark as Read'),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 48, vertical: 16),
                            backgroundColor:
                                _completedItemIndices.contains(index)
                                    ? Colors.grey.shade200
                                    : Theme.of(context).primaryColor,
                            foregroundColor:
                                _completedItemIndices.contains(index)
                                    ? Colors.grey
                                    : Colors.white,
                          ),
                        ),
                      ),
                    );
                  }

                  final verse = filteredVerses[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: RichText(
                      textAlign: TextAlign.justify,
                      text: TextSpan(
                        style: DefaultTextStyle.of(context).style.copyWith(
                              fontSize: 20, // Increased font size
                              height: 1.8, // Increased line height
                              color: Colors.black87,
                            ),
                        children: [
                          TextSpan(
                            text: '${verse['verse']}  ',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          TextSpan(
                            text: verse['text'],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
