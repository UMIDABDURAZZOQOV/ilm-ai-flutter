// Ported from ilm-ai-mobile's src/api/quiz.ts + src/types/api.ts. Plain
// manual models (not freezed) -- this domain has many simple DTOs and
// codegen overhead isn't worth it here; freezed is reserved for auth's
// core, stable types and anywhere union types are genuinely useful.

class QuizQuestion {
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String explanation;
  final String? type;
  final String? topic;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    this.type,
    this.topic,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(
        question: json['question'] as String,
        options: (json['options'] as List? ?? []).map((e) => e.toString()).toList(),
        correctAnswer: json['correct_answer'] as String,
        explanation: json['explanation'] as String? ?? '',
        type: json['type'] as String?,
        topic: json['topic'] as String?,
      );
}

class QuizResultItem {
  final String question;
  final String userAnswer;
  final String correctAnswer;
  final bool isCorrect;
  final String? topic;
  final String? explanation;

  QuizResultItem({
    required this.question,
    required this.userAnswer,
    required this.correctAnswer,
    required this.isCorrect,
    this.topic,
    this.explanation,
  });

  Map<String, dynamic> toJson() => {
        'question': question,
        'user_answer': userAnswer,
        'correct_answer': correctAnswer,
        'is_correct': isCorrect,
        if (topic != null) 'topic': topic,
        if (explanation != null) 'explanation': explanation,
      };
}

class ScoreTrendItem {
  final int sessionId;
  final String date;
  final double scorePct;

  ScoreTrendItem({required this.sessionId, required this.date, required this.scorePct});

  factory ScoreTrendItem.fromJson(Map<String, dynamic> json) => ScoreTrendItem(
        sessionId: json['session_id'] as int,
        date: json['date'] as String,
        scorePct: (json['score_pct'] as num).toDouble(),
      );
}

class QuizStats {
  final int sessionsCompleted;
  final int totalQuestions;
  final int correctAnswers;
  final double averageScore;
  final List<String> topicsCovered;
  final List<ScoreTrendItem> scoreTrend;

  QuizStats({
    required this.sessionsCompleted,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.averageScore,
    required this.topicsCovered,
    required this.scoreTrend,
  });

  factory QuizStats.fromJson(Map<String, dynamic> json) => QuizStats(
        sessionsCompleted: json['sessions_completed'] as int? ?? 0,
        totalQuestions: json['total_questions'] as int? ?? 0,
        correctAnswers: json['correct_answers'] as int? ?? 0,
        averageScore: (json['average_score'] as num?)?.toDouble() ?? 0,
        topicsCovered: (json['topics_covered'] as List? ?? []).map((e) => e.toString()).toList(),
        scoreTrend: (json['score_trend'] as List? ?? []).map((e) => ScoreTrendItem.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

class Flashcard {
  final String front;
  final String back;
  Flashcard({required this.front, required this.back});
  factory Flashcard.fromJson(Map<String, dynamic> json) => Flashcard(front: json['front'] as String, back: json['back'] as String);
}

class ReviewItem {
  final int id;
  final int userId;
  final String topic;
  final String sourceMaterial;
  final String nextReviewDate;
  final int intervalStage;
  final String? lastResult;

  ReviewItem({
    required this.id,
    required this.userId,
    required this.topic,
    required this.sourceMaterial,
    required this.nextReviewDate,
    required this.intervalStage,
    this.lastResult,
  });

  factory ReviewItem.fromJson(Map<String, dynamic> json) => ReviewItem(
        id: json['id'] as int,
        userId: json['user_id'] as int,
        topic: json['topic'] as String,
        sourceMaterial: json['source_material'] as String? ?? '',
        nextReviewDate: json['next_review_date'] as String? ?? '',
        intervalStage: json['interval_stage'] as int? ?? 0,
        lastResult: json['last_result'] as String?,
      );
}
