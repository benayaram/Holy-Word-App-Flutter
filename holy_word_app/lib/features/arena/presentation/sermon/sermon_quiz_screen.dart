import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/arena_providers.dart';
import '../arena_theme.dart';

class SermonQuizScreen extends ConsumerStatefulWidget {
  final String sermonId;
  final String title;
  const SermonQuizScreen({super.key, required this.sermonId, required this.title});

  @override
  ConsumerState<SermonQuizScreen> createState() => _SermonQuizScreenState();
}

class _SermonQuizScreenState extends ConsumerState<SermonQuizScreen> {
  List<Map<String, dynamic>> _questions = [];
  List<int> _userAnswers = [];
  int _currentIndex = 0;
  bool _loading = true;
  bool _answered = false;
  int? _selectedAnswer;
  int _score = 0;
  bool _completed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    try {
      final api = ref.read(arenaApiClientProvider);
      final res = await api.getSermonQuiz(widget.sermonId);
      final qList = res['quiz']?['questions'] as List? ?? [];
      if (!mounted) return;
      setState(() {
        _questions = qList.map((q) => Map<String, dynamic>.from(q as Map)).toList();
        _userAnswers = List<int>.filled(_questions.length, -1);
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _selectAnswer(int answer) {
    if (_answered) return;
    setState(() {
      _answered = true;
      _selectedAnswer = answer;
      _userAnswers[_currentIndex] = answer;
      final correct = _questions[_currentIndex]['correctAnswer'] as int? ?? 0;
      if (answer == correct) _score++;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (_currentIndex < _questions.length - 1) {
        setState(() {
          _currentIndex++;
          _answered = false;
          _selectedAnswer = null;
        });
      } else {
        _submitQuiz();
      }
    });
  }

  Future<void> _submitQuiz() async {
    try {
      final api = ref.read(arenaApiClientProvider);
      await api.submitSermon(widget.sermonId, _userAnswers);
    } catch (_) {}
    if (!mounted) return;
    setState(() => _completed = true);
    ref.invalidate(pendingSermonsProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArenaTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: ArenaTheme.sermonPink))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _completed
                  ? _buildResultView()
                  : _questions.isEmpty
                      ? const Center(child: Text('No questions', style: TextStyle(color: Colors.white)))
                      : _buildQuestionView(),
    );
  }

  Widget _buildQuestionView() {
    final q = _questions[_currentIndex];
    final options = List<String>.from(q['options'] ?? []);
    final correct = q['correctAnswer'] as int? ?? 0;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Progress
          Row(
            children: [
              Text('Question ${_currentIndex + 1}/${_questions.length}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
              const Spacer(),
              Text('Score: $_score',
                  style: const TextStyle(color: Color(0xFFfa709a), fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / _questions.length,
              minHeight: 4, backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation(Color(0xFFfa709a)),
            ),
          ),
          const SizedBox(height: 32),

          // Question
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                q['question']?.toString() ?? '',
                style: const TextStyle(color: Colors.white, fontSize: 22,
                    fontWeight: FontWeight.w700, height: 1.4),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Options
          Expanded(
            flex: 3,
            child: ListView.builder(
              itemCount: options.length,
              itemBuilder: (ctx, idx) {
                final isSelected = _selectedAnswer == idx;
                final isCorrect = correct == idx;
                final showResult = _answered;

                Color bg = Colors.white.withValues(alpha: 0.08);
                Color border = Colors.white.withValues(alpha: 0.15);

                if (showResult) {
                  if (isCorrect) {
                    bg = ArenaTheme.success.withValues(alpha: 0.2);
                    border = ArenaTheme.success;
                  } else if (isSelected) {
                    bg = ArenaTheme.primary.withValues(alpha: 0.2);
                    border = ArenaTheme.primary;
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => _selectAnswer(idx),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: bg, borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: border, width: 1.5)),
                      child: Row(children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: showResult && isCorrect
                                ? ArenaTheme.success
                                : showResult && isSelected
                                    ? ArenaTheme.primary
                                    : Colors.white.withValues(alpha: 0.15)),
                          child: Center(child: showResult && isCorrect
                              ? const Icon(Icons.check, color: Colors.white, size: 18)
                              : showResult && isSelected
                                  ? const Icon(Icons.close, color: Colors.white, size: 18)
                                  : Text(String.fromCharCode(65 + idx),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Text(options[idx],
                            style: const TextStyle(color: Colors.white, fontSize: 16))),
                      ]),
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

  Widget _buildResultView() {
    final total = _questions.length;
    final pct = total > 0 ? ((_score / total) * 100).round() : 0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(pct >= 80 ? Icons.church_rounded : Icons.check_circle_outline,
                color: pct >= 80 ? const Color(0xFFfa709a) : const Color(0xFF10b981), size: 80),
            const SizedBox(height: 24),
            Text(pct >= 80 ? 'Excellent! 🎉' : 'Quiz Complete!',
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Text('$_score/$total correct',
                style: const TextStyle(color: Colors.white70, fontSize: 20)),
            Text('$pct% accuracy',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 16)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: ArenaTheme.sermonPink.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12)),
              child: Text('+${_score * 10} XP', style: const TextStyle(
                  color: ArenaTheme.sermonPink, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ArenaTheme.sermonPink,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: const Text('Done', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
