import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import '../../providers/arena_providers.dart';

class QuizPlayScreen extends ConsumerStatefulWidget {
  final String? category;
  final String difficulty;

  const QuizPlayScreen({super.key, this.category, this.difficulty = 'normal'});

  @override
  ConsumerState<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends ConsumerState<QuizPlayScreen>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  Timer? _timer;
  int _timeLeft = 15;
  int _questionStartTime = 0;
  bool _answered = false;
  int? _selectedAnswer;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Load questions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(quizStateProvider.notifier).loadQuestions(
            category: widget.category,
            difficulty: widget.difficulty,
          );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _confettiController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _startTimer(int seconds) {
    _timer?.cancel();
    _timeLeft = seconds;
    _questionStartTime = DateTime.now().millisecondsSinceEpoch;
    _answered = false;
    _selectedAnswer = null;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _timeLeft--;
          if (_timeLeft <= 0) {
            timer.cancel();
            _handleTimeUp();
          }
        });
      }
    });
  }

  void _handleTimeUp() {
    if (!_answered) {
      _answered = true;
      final elapsed = DateTime.now().millisecondsSinceEpoch - _questionStartTime;
      ref.read(quizStateProvider.notifier).answerQuestion(-1, elapsed);
    }
  }

  void _selectAnswer(int answer) {
    if (_answered) return;
    _answered = true;
    _selectedAnswer = answer;
    _timer?.cancel();

    final elapsed = DateTime.now().millisecondsSinceEpoch - _questionStartTime;
    ref.read(quizStateProvider.notifier).answerQuestion(answer, elapsed);

    final quizState = ref.read(quizStateProvider);
    final q = quizState.currentQuestion;
    final isCorrect = q != null && answer == q.correctAnswer;

    if (!isCorrect) {
      _shakeController.forward().then((_) => _shakeController.reset());
    }

    setState(() {});

    // Auto-advance after delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        final state = ref.read(quizStateProvider);
        if (state.isLastQuestion) {
          ref.read(quizStateProvider.notifier).submitQuiz();
        } else {
          ref.read(quizStateProvider.notifier).nextQuestion();
          _startTimer(state.questions[state.currentIndex + 1].timeLimit);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(quizStateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: Stack(
        children: [
          if (quizState.isLoading && quizState.questions.isEmpty)
            const Center(child: CircularProgressIndicator(color: Color(0xFFe94560)))
          else if (quizState.error != null)
            Center(child: Text(quizState.error!, style: const TextStyle(color: Colors.red)))
          else if (quizState.isCompleted && quizState.result != null)
            _buildResultScreen(quizState)
          else if (quizState.currentQuestion != null)
            _buildQuestionScreen(quizState)
          else
            const Center(child: Text('No questions available', style: TextStyle(color: Colors.white))),

          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Color(0xFFe94560), Color(0xFFf59e0b), Color(0xFF10b981), Color(0xFF3b82f6)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionScreen(QuizState quizState) {
    final q = quizState.currentQuestion!;
    const isTelugu = false; // TODO: integrate with language provider

    // Start timer on first build
    if (!_answered && _timeLeft == 15) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startTimer(q.timeLimit));
    }

    return SafeArea(
      child: Column(
        children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Question ${quizState.currentIndex + 1}/${quizState.questions.length}',
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (quizState.currentIndex + 1) / quizState.questions.length,
                          minHeight: 4,
                          backgroundColor: Colors.white12,
                          valueColor: const AlwaysStoppedAnimation(Color(0xFFe94560)),
                        ),
                      ),
                    ],
                  ),
                ),
                // Timer
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _timeLeft <= 5
                        ? const Color(0xFFe94560).withOpacity(0.3)
                        : Colors.white.withOpacity(0.1),
                    border: Border.all(
                      color: _timeLeft <= 5 ? const Color(0xFFe94560) : Colors.white24,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$_timeLeft',
                      style: TextStyle(
                        color: _timeLeft <= 5 ? const Color(0xFFe94560) : Colors.white,
                        fontSize: 18, fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Question
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Center(
                child: Text(
                  q.getQuestion(isTelugu),
                  style: const TextStyle(
                    color: Colors.white, fontSize: 22,
                    fontWeight: FontWeight.w700, height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

          // Scripture Reference
          if (q.scriptureRef != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                q.scriptureRef!,
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
              ),
            ),

          // Options
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ListView.builder(
                itemCount: q.getOptions(isTelugu).length,
                itemBuilder: (ctx, idx) {
                  final options = q.getOptions(isTelugu);
                  final isSelected = _selectedAnswer == idx;
                  final isCorrect = q.correctAnswer == idx;
                  final showResult = _answered;

                  Color bgColor = Colors.white.withOpacity(0.08);
                  Color borderColor = Colors.white.withOpacity(0.15);
                  Color textColor = Colors.white;

                  if (showResult) {
                    if (isCorrect) {
                      bgColor = const Color(0xFF10b981).withOpacity(0.2);
                      borderColor = const Color(0xFF10b981);
                    } else if (isSelected && !isCorrect) {
                      bgColor = const Color(0xFFe94560).withOpacity(0.2);
                      borderColor = const Color(0xFFe94560);
                    }
                  } else if (isSelected) {
                    bgColor = const Color(0xFF3b82f6).withOpacity(0.3);
                    borderColor = const Color(0xFF3b82f6);
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () => _selectAnswer(idx),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: showResult && isCorrect
                                    ? const Color(0xFF10b981)
                                    : showResult && isSelected
                                        ? const Color(0xFFe94560)
                                        : Colors.white.withOpacity(0.15),
                              ),
                              child: Center(
                                child: showResult && isCorrect
                                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                                    : showResult && isSelected
                                        ? const Icon(Icons.close, color: Colors.white, size: 18)
                                        : Text(
                                            String.fromCharCode(65 + idx),
                                            style: const TextStyle(
                                              color: Colors.white, fontWeight: FontWeight.bold),
                                          ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                options[idx],
                                style: TextStyle(
                                  color: textColor, fontSize: 16,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Explanation (shown after answering)
          if (_answered && q.getExplanation(isTelugu) != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFf59e0b).withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb, color: Color(0xFFf59e0b), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      q.getExplanation(isTelugu) ?? '',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultScreen(QuizState quizState) {
    final result = quizState.result!;
    final isPerfect = result.score == result.total;

    if (isPerfect) _confettiController.play();

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPerfect ? Icons.emoji_events_rounded : Icons.check_circle_outline,
                color: isPerfect ? const Color(0xFFf59e0b) : const Color(0xFF10b981),
                size: 80,
              ),
              const SizedBox(height: 24),
              Text(
                isPerfect ? 'Perfect Score! 🎉' : 'Quiz Complete!',
                style: const TextStyle(
                  color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Text(
                '${result.score}/${result.total} correct',
                style: const TextStyle(color: Colors.white70, fontSize: 20),
              ),
              const SizedBox(height: 8),
              Text(
                '${result.accuracy}% accuracy',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFf59e0b).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+${result.xpEarned} XP earned!',
                  style: const TextStyle(
                    color: Color(0xFFf59e0b), fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(quizStateProvider.notifier).reset();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFe94560),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Back to Arena',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
