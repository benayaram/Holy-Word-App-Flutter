import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/arena_providers.dart';
import 'battle_result_screen.dart';

class BattlePlayScreen extends ConsumerStatefulWidget {
  final String battleId;
  final Map<String, dynamic> firstQuestion;
  const BattlePlayScreen({super.key, required this.battleId, required this.firstQuestion});

  @override
  ConsumerState<BattlePlayScreen> createState() => _BattlePlayScreenState();
}

class _BattlePlayScreenState extends ConsumerState<BattlePlayScreen> {
  int _myScore = 0;
  int _opponentScore = 0;
  int _currentIndex = 0;
  int _totalQuestions = 10;
  Map<String, dynamic> _currentQuestion = {};
  int _timeLeft = 15;
  Timer? _timer;
  bool _answered = false;
  int? _selectedAnswer;
  int? _correctAnswer;
  bool _opponentAnswered = false;
  int _questionStartTime = 0;
  StreamSubscription? _wsSub;

  @override
  void initState() {
    super.initState();
    _currentQuestion = widget.firstQuestion;
    _currentIndex = widget.firstQuestion['questionIndex'] ?? 0;
    _totalQuestions = widget.firstQuestion['totalQuestions'] ?? 10;
    _startTimer(widget.firstQuestion['timeLimit'] ?? 15000);
    _listenToWebSocket();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _wsSub?.cancel();
    super.dispose();
  }

  void _listenToWebSocket() {
    final ws = ref.read(arenaWsClientProvider);
    _wsSub = ws.messages.listen((msg) {
      final event = msg['event'];
      final data = msg['data'] ?? {};

      if (!mounted) return;

      switch (event) {
        case 'battle:answer_result':
          setState(() {
            _correctAnswer = data['correctAnswer'];
            final scores = data['scores'] as Map<String, dynamic>? ?? {};
            final user = ref.read(arenaUserProvider).value;
            if (user != null) {
              _myScore = scores[user.firebaseUid] ?? _myScore;
              scores.forEach((k, v) {
                if (k != user.firebaseUid) _opponentScore = v;
              });
            }
          });
          break;
        case 'battle:opponent_answered':
          setState(() => _opponentAnswered = true);
          break;
        case 'battle:score_update':
          final scores = data['scores'] as Map<String, dynamic>? ?? {};
          final user = ref.read(arenaUserProvider).value;
          if (user != null) {
            setState(() {
              _myScore = scores[user.firebaseUid] ?? _myScore;
              scores.forEach((k, v) {
                if (k != user.firebaseUid) _opponentScore = v;
              });
            });
          }
          break;
        case 'battle:question':
          setState(() {
            _currentQuestion = data;
            _currentIndex = data['questionIndex'] ?? _currentIndex + 1;
            _answered = false;
            _selectedAnswer = null;
            _correctAnswer = null;
            _opponentAnswered = false;
          });
          _startTimer(data['timeLimit'] ?? 15000);
          break;
        case 'battle:time_up':
          setState(() {
            _correctAnswer = data['correctAnswer'];
            final scores = data['scores'] as Map<String, dynamic>? ?? {};
            final user = ref.read(arenaUserProvider).value;
            if (user != null) {
              _myScore = scores[user.firebaseUid] ?? _myScore;
              scores.forEach((k, v) {
                if (k != user.firebaseUid) _opponentScore = v;
              });
            }
          });
          break;
        case 'battle:complete':
          _timer?.cancel();
          if (mounted) {
            Navigator.pushReplacement(context, MaterialPageRoute(
              builder: (_) => BattleResultScreen(resultData: data)));
          }
          break;
        case 'battle:player_disconnected':
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Opponent disconnected!')));
          break;
      }
    });
  }

  void _startTimer(int timeLimitMs) {
    _timer?.cancel();
    _timeLeft = (timeLimitMs / 1000).ceil();
    _questionStartTime = DateTime.now().millisecondsSinceEpoch;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
        _timeLeft--;
        if (_timeLeft <= 0) { _timer?.cancel(); }
      });
      }
    });
  }

  void _submitAnswer(int answer) {
    if (_answered) return;
    setState(() { _answered = true; _selectedAnswer = answer; });
    _timer?.cancel();
    final elapsed = DateTime.now().millisecondsSinceEpoch - _questionStartTime;
    final ws = ref.read(arenaWsClientProvider);
    ws.sendAnswer(widget.battleId, _currentIndex, answer, elapsed);
  }

  @override
  Widget build(BuildContext context) {
    const isTelugu = false;
    final question = isTelugu
        ? (_currentQuestion['questionTe'] ?? _currentQuestion['questionEn'] ?? '')
        : (_currentQuestion['questionEn'] ?? '');
    final options = List<String>.from(
        isTelugu ? (_currentQuestion['optionsTe'] ?? _currentQuestion['options'] ?? [])
            : (_currentQuestion['options'] ?? []));

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: SafeArea(
        child: Column(
          children: [
            // Score bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
              ),
              child: Row(
                children: [
                  _scoreChip('You', _myScore, const Color(0xFF4facfe)),
                  Expanded(
                    child: Column(children: [
                      Text('Q${_currentIndex + 1}/$_totalQuestions',
                          style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      const Text('VS', style: TextStyle(
                          color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
                    ]),
                  ),
                  _scoreChip('Opponent', _opponentScore, const Color(0xFFe94560)),
                ],
              ),
            ),

            // Timer
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _timeLeft <= 5
                          ? const Color(0xFFe94560).withOpacity(0.3)
                          : Colors.white.withOpacity(0.1),
                      border: Border.all(
                        color: _timeLeft <= 5 ? const Color(0xFFe94560) : Colors.white24,
                        width: 3),
                    ),
                    child: Center(child: Text('$_timeLeft',
                        style: TextStyle(
                          color: _timeLeft <= 5 ? const Color(0xFFe94560) : Colors.white,
                          fontSize: 22, fontWeight: FontWeight.bold))),
                  ),
                  if (_opponentAnswered) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFf59e0b).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8)),
                      child: const Text('⚡ Opponent answered',
                          style: TextStyle(color: Color(0xFFf59e0b), fontSize: 12)),
                    ),
                  ],
                ],
              ),
            ),

            // Question
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Center(child: Text(question.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 22,
                        fontWeight: FontWeight.w700, height: 1.4),
                    textAlign: TextAlign.center)),
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
                    final isCorrect = _correctAnswer == idx;
                    final showResult = _correctAnswer != null;

                    Color bg = Colors.white.withOpacity(0.08);
                    Color border = Colors.white.withOpacity(0.15);

                    if (showResult) {
                      if (isCorrect) {
                        bg = const Color(0xFF10b981).withOpacity(0.2);
                        border = const Color(0xFF10b981);
                      } else if (isSelected && !isCorrect) {
                        bg = const Color(0xFFe94560).withOpacity(0.2);
                        border = const Color(0xFFe94560);
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
                                    ? const Color(0xFF10b981)
                                    : showResult && isSelected
                                        ? const Color(0xFFe94560)
                                        : Colors.white.withOpacity(0.15)),
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

  Widget _scoreChip(String label, int score, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3))),
      child: Column(children: [
        Text('$score', style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900)),
        Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 11)),
      ]),
    );
  }
}
