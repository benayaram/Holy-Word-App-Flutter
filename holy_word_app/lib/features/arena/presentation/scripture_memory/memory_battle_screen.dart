import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/memory_battle_service.dart';
import '../../providers/arena_providers.dart';
import '../../data/models/battle.dart';

class MemoryBattleScreen extends ConsumerStatefulWidget {
  final MemoryVerse verse;
  const MemoryBattleScreen({super.key, required this.verse});

  @override
  ConsumerState<MemoryBattleScreen> createState() => _MemoryBattleScreenState();
}

class _MemoryBattleScreenState extends ConsumerState<MemoryBattleScreen>
    with SingleTickerProviderStateMixin {
  final _memoryService = MemoryBattleService();
  final _textController = TextEditingController();
  late AnimationController _progressAnim;

  int _currentLevel = 1;
  bool _levelComplete = false;
  bool _allComplete = false;
  int? _accuracy;
  Timer? _timer;
  int _elapsedMs = 0;
  bool _timerRunning = false;

  @override
  void initState() {
    super.initState();
    _currentLevel = (widget.verse.currentLevel + 1).clamp(1, 5);
    _progressAnim = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _textController.dispose();
    _progressAnim.dispose();
    super.dispose();
  }

  void _startTimer() {
    if (_timerRunning) return;
    _timerRunning = true;
    _elapsedMs = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      setState(() => _elapsedMs += 100);
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timerRunning = false;
  }

  @override
  Widget build(BuildContext context) {
    final levelInfo = MemoryBattleService.levelInfo[_currentLevel - 1];
    final displayText = _memoryService.getTextForLevel(widget.verse.verseText, _currentLevel);

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: Text(widget.verse.reference,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Center(child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(
              '${(_elapsedMs / 1000).toStringAsFixed(1)}s',
              style: const TextStyle(color: Color(0xFFf59e0b), fontSize: 16, fontWeight: FontWeight.bold),
            ),
          )),
        ],
      ),
      body: SafeArea(
        child: _allComplete ? _buildAllCompleteView() : _buildLevelView(levelInfo, displayText),
      ),
    );
  }

  Widget _buildLevelView(Map<String, dynamic> levelInfo, String displayText) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Level progress bar
          Row(
            children: List.generate(5, (i) {
              final level = i + 1;
              final completed = level < _currentLevel;
              final active = level == _currentLevel;
              final colors = [
                const Color(0xFF10b981), const Color(0xFF3b82f6),
                const Color(0xFF8b5cf6), const Color(0xFFf59e0b), const Color(0xFFe94560),
              ];
              return Expanded(
                child: Container(
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: completed ? colors[i] : active
                        ? colors[i].withOpacity(0.5)
                        : Colors.white.withOpacity(0.1),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          // Level info header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFF667eea).withOpacity(0.2),
                  ),
                  child: Center(
                    child: Text('$_currentLevel',
                        style: const TextStyle(color: Color(0xFF667eea), fontSize: 20, fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(levelInfo['name'] as String,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(levelInfo['description'] as String,
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Verse display / input area
          Expanded(
            child: _currentLevel <= 4
                ? _buildReadView(displayText)
                : _buildRecallInput(),
          ),

          // Result or Next button
          if (_levelComplete) _buildLevelResult(),

          if (!_levelComplete)
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _handleLevelAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667eea),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  _currentLevel <= 4 ? 'I\'ve Read It — Next Level' : 'Check My Answer',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReadView(String displayText) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF667eea).withOpacity(0.2)),
          ),
          child: Text(
            displayText,
            style: const TextStyle(
              color: Colors.white, fontSize: 22, height: 1.8,
              fontWeight: FontWeight.w400, letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildRecallInput() {
    return Column(
      children: [
        Text('Type the verse from memory:',
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF667eea).withOpacity(0.3)),
            ),
            child: TextField(
              controller: _textController,
              maxLines: null,
              expands: true,
              style: const TextStyle(color: Colors.white, fontSize: 18, height: 1.6),
              decoration: InputDecoration(
                hintText: 'Start typing...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                border: InputBorder.none,
              ),
              onChanged: (_) {
                if (!_timerRunning) _startTimer();
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLevelResult() {
    final passed = _accuracy != null && _memoryService.isLevelPassed(_currentLevel, _accuracy!);
    final isLastLevel = _currentLevel >= 5;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: passed
            ? const Color(0xFF10b981).withOpacity(0.15)
            : const Color(0xFFe94560).withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: passed ? const Color(0xFF10b981) : const Color(0xFFe94560),
          width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(passed ? Icons.check_circle : Icons.cancel,
                  color: passed ? const Color(0xFF10b981) : const Color(0xFFe94560), size: 28),
              const SizedBox(width: 10),
              Text(
                passed ? 'Level Passed!' : 'Try Again',
                style: TextStyle(
                  color: passed ? const Color(0xFF10b981) : const Color(0xFFe94560),
                  fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (_accuracy != null) ...[
            const SizedBox(height: 8),
            Text('Accuracy: $_accuracy%',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
          ],
          if (_currentLevel == 5 && passed) ...[
            const SizedBox(height: 4),
            Text('Time: ${(_elapsedMs / 1000).toStringAsFixed(1)}s',
                style: const TextStyle(color: Color(0xFFf59e0b), fontSize: 14)),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity, height: 44,
            child: ElevatedButton(
              onPressed: () {
                if (passed) {
                  if (isLastLevel) {
                    setState(() => _allComplete = true);
                  } else {
                    setState(() {
                      _currentLevel++;
                      _levelComplete = false;
                      _accuracy = null;
                      _textController.clear();
                    });
                  }
                } else {
                  setState(() {
                    _levelComplete = false;
                    _accuracy = null;
                    _textController.clear();
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: passed ? const Color(0xFF667eea) : const Color(0xFFe94560),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                passed ? (isLastLevel ? 'Complete!' : 'Next Level →') : 'Retry',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllCompleteView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events_rounded, color: Color(0xFFf59e0b), size: 80),
            const SizedBox(height: 24),
            const Text('Verse Memorized! 🎉',
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Text(widget.verse.reference,
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 18)),
            const SizedBox(height: 8),
            Text('Time: ${(_elapsedMs / 1000).toStringAsFixed(1)}s',
                style: const TextStyle(color: Color(0xFFf59e0b), fontSize: 16)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF10b981).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('+25 XP earned!',
                  style: TextStyle(color: Color(0xFF10b981), fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  // Save progress to server
                  try {
                    final api = ref.read(arenaApiClientProvider);
                    await api.saveMemoryProgress(
                      bookId: widget.verse.bookId,
                      chapter: widget.verse.chapter,
                      verse: widget.verse.verse,
                      reference: widget.verse.reference,
                      verseText: widget.verse.verseText,
                      level: 5,
                      timeMs: _elapsedMs,
                      language: widget.verse.language,
                    );
                    ref.invalidate(memoryProgressProvider);
                  } catch (e) {
                    debugPrint('Failed to save memory progress: $e');
                  }
                  if (mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFe94560),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Back to Verses',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLevelAction() {
    if (_currentLevel <= 4) {
      // Levels 1-4: reading/recognition — auto-pass
      _saveLevel(_currentLevel);
      setState(() {
        _levelComplete = true;
        _accuracy = 100;
      });
    } else {
      // Level 5: validate typed input
      _stopTimer();
      final accuracy = _memoryService.validateRecall(
        widget.verse.verseText, _textController.text);
      _saveLevel(_currentLevel);
      setState(() {
        _levelComplete = true;
        _accuracy = accuracy;
      });
    }
  }

  Future<void> _saveLevel(int level) async {
    try {
      final api = ref.read(arenaApiClientProvider);
      await api.saveMemoryProgress(
        bookId: widget.verse.bookId,
        chapter: widget.verse.chapter,
        verse: widget.verse.verse,
        reference: widget.verse.reference,
        verseText: widget.verse.verseText,
        level: level,
        timeMs: level == 5 ? _elapsedMs : null,
        language: widget.verse.language,
      );
    } catch (e) {
      debugPrint('Save level progress error: $e');
    }
  }
}
