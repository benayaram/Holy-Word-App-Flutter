/// Quiz Question Model
class QuizQuestion {
  final String id;
  final String type; // multiple_choice, true_false, fill_blank
  final String category;
  final String difficulty;
  final String questionEn;
  final String questionTe;
  final List<String> options;
  final List<String> optionsTe;
  final int? correctAnswer; // null when fetched without answers (battle mode)
  final String? explanation;
  final String? explanationTe;
  final String? scriptureRef;

  QuizQuestion({
    required this.id,
    required this.type,
    required this.category,
    required this.difficulty,
    required this.questionEn,
    required this.questionTe,
    required this.options,
    required this.optionsTe,
    this.correctAnswer,
    this.explanation,
    this.explanationTe,
    this.scriptureRef,
  });

  String getQuestion(bool isTelugu) => isTelugu ? questionTe : questionEn;
  List<String> getOptions(bool isTelugu) => isTelugu ? optionsTe : options;
  String? getExplanation(bool isTelugu) =>
      isTelugu ? (explanationTe ?? explanation) : explanation;

  bool get isMultipleChoice => type == 'multiple_choice';
  bool get isTrueFalse => type == 'true_false';
  bool get isFillBlank => type == 'fill_blank';

  int get timeLimit {
    if (isTrueFalse) return 6;
    return 15;
  }

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'] ?? '',
      type: json['type'] ?? 'multiple_choice',
      category: json['category'] ?? '',
      difficulty: json['difficulty'] ?? 'normal',
      questionEn: json['questionEn'] ?? '',
      questionTe: json['questionTe'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      optionsTe: List<String>.from(json['optionsTe'] ?? []),
      correctAnswer: json['correctAnswer'],
      explanation: json['explanation'],
      explanationTe: json['explanationTe'],
      scriptureRef: json['scriptureRef'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'category': category,
        'difficulty': difficulty,
        'questionEn': questionEn,
        'questionTe': questionTe,
        'options': options,
        'optionsTe': optionsTe,
        'correctAnswer': correctAnswer,
        'explanation': explanation,
        'explanationTe': explanationTe,
        'scriptureRef': scriptureRef,
      };
}

/// Answer result from server after checking
class AnswerResult {
  final String questionId;
  final bool correct;
  final int correctAnswer;
  final String? explanation;
  final String? explanationTe;
  final String? scriptureRef;

  AnswerResult({
    required this.questionId,
    required this.correct,
    required this.correctAnswer,
    this.explanation,
    this.explanationTe,
    this.scriptureRef,
  });

  factory AnswerResult.fromJson(Map<String, dynamic> json) => AnswerResult(
        questionId: json['questionId'] ?? '',
        correct: json['correct'] ?? false,
        correctAnswer: json['correctAnswer'] ?? 0,
        explanation: json['explanation'],
        explanationTe: json['explanationTe'],
        scriptureRef: json['scriptureRef'],
      );
}

/// Quiz result summary
class QuizResult {
  final int score;
  final int total;
  final int accuracy;
  final int xpEarned;
  final List<AnswerResult> results;

  QuizResult({
    required this.score,
    required this.total,
    required this.accuracy,
    required this.xpEarned,
    required this.results,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) => QuizResult(
        score: json['score'] ?? 0,
        total: json['total'] ?? 0,
        accuracy: json['accuracy'] ?? 0,
        xpEarned: json['xpEarned'] ?? 0,
        results: (json['results'] as List<dynamic>?)
                ?.map((r) => AnswerResult.fromJson(r))
                .toList() ??
            [],
      );
}
