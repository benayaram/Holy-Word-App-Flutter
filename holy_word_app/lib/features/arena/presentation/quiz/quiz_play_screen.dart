import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/language_provider.dart';
import '../../providers/arena_providers.dart';
import '../arena_theme.dart';

class QuizPlayScreen extends ConsumerStatefulWidget {
  final String? category;
  final String difficulty;
  const QuizPlayScreen({super.key, this.category, this.difficulty = 'normal'});

  @override
  ConsumerState<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends ConsumerState<QuizPlayScreen> {
  Timer? _timer;
  int _timeLeft = 15;
  bool _answered = false;
  bool _timerStarted = false;
  int? _selectedAnswer;
  int _questionStartTime = 0;

  @override
  void initState() {
    super.initState();
    // Load questions directly in initState
    ref.read(quizStateProvider.notifier).loadQuestions(
      category: widget.category,
      difficulty: widget.difficulty,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_timerStarted) return;
    _timerStarted = true;

    _timer?.cancel();
    final question = ref.read(quizStateProvider).currentQuestion;
    final isShort = question?.type == 'true_false';
    _timeLeft = isShort ? 6 : 15;
    _questionStartTime = DateTime.now().millisecondsSinceEpoch;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _timeLeft--;
        if (_timeLeft <= 0) {
          _timer?.cancel();
          _autoAdvance();
        }
      });
    });
  }

  void _autoAdvance() {
    if (_answered) return;
    // Time's up — record as unanswered
    final elapsed = DateTime.now().millisecondsSinceEpoch - _questionStartTime;
    ref.read(quizStateProvider.notifier).answerQuestion(-1, elapsed);

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      _moveToNext();
    });
  }

  void _submitAnswer(int answer) {
    if (_answered) return;
    setState(() { _answered = true; _selectedAnswer = answer; });
    _timer?.cancel();

    final elapsed = DateTime.now().millisecondsSinceEpoch - _questionStartTime;
    ref.read(quizStateProvider.notifier).answerQuestion(answer, elapsed);

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _moveToNext();
    });
  }

  void _moveToNext() {
    final state = ref.read(quizStateProvider);
    if (state.isLastQuestion) {
      ref.read(quizStateProvider.notifier).submitQuiz();
    } else {
      ref.read(quizStateProvider.notifier).nextQuestion();
      setState(() {
        _answered = false;
        _selectedAnswer = null;
        _timerStarted = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(quizStateProvider);
    final isTelugu = ref.watch(languageProvider) == 'telugu';

    // Loading state with skeleton
    if (quizState.isLoading && quizState.questions.isEmpty) {
      return Scaffold(
        backgroundColor: ArenaTheme.background,
        appBar: AppBar(
          title: const Text('Bible Quiz'),
          backgroundColor: Colors.transparent, elevation: 0,
        ),
        body: _buildLoadingSkeleton(),
      );
    }

    // Error state
    if (quizState.error != null && quizState.questions.isEmpty) {
      return Scaffold(
        backgroundColor: ArenaTheme.background,
        appBar: AppBar(
          title: const Text('Bible Quiz'),
          backgroundColor: Colors.transparent, elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: ArenaTheme.primary, size: 56),
                const SizedBox(height: 16),
                Text(
                  quizState.error!,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.read(quizStateProvider.notifier).loadQuestions(
                      category: widget.category,
                      difficulty: widget.difficulty,
                    );
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ArenaTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Completed state
    if (quizState.isCompleted && quizState.result != null) {
      return _buildResultScreen(quizState);
    }

    final question = quizState.currentQuestion;
    if (question == null) {
      if (!quizState.isLoading && quizState.questions.isEmpty) {
        return Scaffold(
          backgroundColor: ArenaTheme.background,
          appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
          body: Center(
            child: Text(
              'No questions available.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
          ),
        );
      }
      return Scaffold(
        backgroundColor: ArenaTheme.background,
        body: const Center(child: CircularProgressIndicator(color: ArenaTheme.primary)),
      );
    }

    // Start timer for current question
    if (!_timerStarted && !_answered) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startTimer());
    }

    final questionText = isTelugu
        ? (question.questionTe ?? question.questionEn)
        : question.questionEn;
    final options = List<String>.from(
        isTelugu ? (question.optionsTe ?? question.options) : question.options);

    return Scaffold(
      backgroundColor: ArenaTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white54),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (quizState.currentIndex + 1) / quizState.questions.length,
                        minHeight: 6,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation(ArenaTheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${quizState.currentIndex + 1}/${quizState.questions.length}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

            // Timer
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _timeLeft <= 5
                    ? ArenaTheme.primary.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.1),
                border: Border.all(
                  color: _timeLeft <= 5 ? ArenaTheme.primary : Colors.white24,
                  width: 3),
              ),
              child: Center(child: Text('$_timeLeft',
                  style: TextStyle(
                    color: _timeLeft <= 5 ? ArenaTheme.primary : Colors.white,
                    fontSize: 22, fontWeight: FontWeight.bold))),
            ),
            const SizedBox(height: 16),

            // Question
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Center(child: Text(
                  questionText,
                  style: const TextStyle(color: Colors.white, fontSize: 22,
                      fontWeight: FontWeight.w700, height: 1.4),
                  textAlign: TextAlign.center,
                )),
              ),
            ),

            // Options
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ListView.builder(
                  itemCount: options.length,
                  itemBuilder: (ctx, idx) {
                    final isSelected = _selectedAnswer == idx;
                    final isCorrect = question.correctAnswer == idx;
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
                        onTap: () => _submitAnswer(idx),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Progress bar skeleton
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 32),

          // Timer skeleton
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          const SizedBox(height: 32),

          // Question skeleton
          Container(
            height: 24,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 24,
            width: 200,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 40),

          // Option skeletons
          for (var i = 0; i < 4; i++) ...[
            Container(
              height: 56,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _buildResultScreen(QuizState quizState) {
    final result = quizState.result!;
    return Scaffold(
      backgroundColor: ArenaTheme.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  result.accuracy >= 80
                      ? Icons.emoji_events_rounded
                      : result.accuracy >= 50
                          ? Icons.thumb_up_rounded
                          : Icons.school_rounded,
                  color: ArenaTheme.xpGold,
                  size: 80,
                ),
                const SizedBox(height: 16),
                Text(
                  '${result.score}/${result.total}',
                  style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  '${result.accuracy}% Accuracy',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 18),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: ArenaTheme.xpGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '+${result.xpEarned} XP',
                    style: const TextStyle(color: ArenaTheme.xpGold, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(quizStateProvider.notifier).reset();
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ArenaTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Done', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
