// Milliy Sertifikat skill tree DTOs -- plain manual models (not freezed),
// matching quiz_models.dart's convention for this kind of simple API domain.

class SkillSubject {
  final int id;
  final String slug;
  final String nameUz;
  final String nameRu;
  final String nameEn;
  final String? icon;
  final String? color;

  SkillSubject({
    required this.id,
    required this.slug,
    required this.nameUz,
    required this.nameRu,
    required this.nameEn,
    this.icon,
    this.color,
  });

  factory SkillSubject.fromJson(Map<String, dynamic> json) => SkillSubject(
        id: json['id'] as int,
        slug: json['slug'] as String,
        nameUz: json['name_uz'] as String,
        nameRu: json['name_ru'] as String,
        nameEn: json['name_en'] as String,
        icon: json['icon'] as String?,
        color: json['color'] as String?,
      );

  String nameFor(String language) {
    switch (language) {
      case 'ru':
        return nameRu;
      case 'en':
        return nameEn;
      default:
        return nameUz;
    }
  }
}

enum LessonStatus { locked, unlocked, completed }

LessonStatus _parseStatus(String s) {
  switch (s) {
    case 'completed':
      return LessonStatus.completed;
    case 'unlocked':
      return LessonStatus.unlocked;
    default:
      return LessonStatus.locked;
  }
}

class SkillTreeLesson {
  final int id;
  final String slug;
  final String titleUz;
  final String titleRu;
  final String titleEn;
  final int orderIndex;
  final int xpReward;
  final LessonStatus status;
  final int stars;
  final double? bestScorePct;

  SkillTreeLesson({
    required this.id,
    required this.slug,
    required this.titleUz,
    required this.titleRu,
    required this.titleEn,
    required this.orderIndex,
    required this.xpReward,
    required this.status,
    required this.stars,
    this.bestScorePct,
  });

  factory SkillTreeLesson.fromJson(Map<String, dynamic> json) => SkillTreeLesson(
        id: json['id'] as int,
        slug: json['slug'] as String,
        titleUz: json['title_uz'] as String,
        titleRu: json['title_ru'] as String,
        titleEn: json['title_en'] as String,
        orderIndex: json['order_index'] as int,
        xpReward: json['xp_reward'] as int? ?? 10,
        status: _parseStatus(json['status'] as String? ?? 'locked'),
        stars: json['stars'] as int? ?? 0,
        bestScorePct: (json['best_score_pct'] as num?)?.toDouble(),
      );

  String titleFor(String language) {
    switch (language) {
      case 'ru':
        return titleRu;
      case 'en':
        return titleEn;
      default:
        return titleUz;
    }
  }
}

class SkillTreeUnit {
  final int id;
  final String slug;
  final String titleUz;
  final String titleRu;
  final String titleEn;
  final int orderIndex;
  final List<SkillTreeLesson> lessons;

  SkillTreeUnit({
    required this.id,
    required this.slug,
    required this.titleUz,
    required this.titleRu,
    required this.titleEn,
    required this.orderIndex,
    required this.lessons,
  });

  factory SkillTreeUnit.fromJson(Map<String, dynamic> json) => SkillTreeUnit(
        id: json['id'] as int,
        slug: json['slug'] as String,
        titleUz: json['title_uz'] as String,
        titleRu: json['title_ru'] as String,
        titleEn: json['title_en'] as String,
        orderIndex: json['order_index'] as int,
        lessons: (json['lessons'] as List? ?? []).map((e) => SkillTreeLesson.fromJson(e as Map<String, dynamic>)).toList(),
      );

  String titleFor(String language) {
    switch (language) {
      case 'ru':
        return titleRu;
      case 'en':
        return titleEn;
      default:
        return titleUz;
    }
  }
}

class GamificationSummary {
  final int xpTotal;
  final int streakDays;
  final int todayXp;
  final int dailyGoalXp;

  GamificationSummary({
    required this.xpTotal,
    required this.streakDays,
    this.todayXp = 0,
    this.dailyGoalXp = 20,
  });

  factory GamificationSummary.fromJson(Map<String, dynamic> json) => GamificationSummary(
        xpTotal: json['xp_total'] as int? ?? 0,
        streakDays: json['streak_days'] as int? ?? 0,
        todayXp: json['today_xp'] as int? ?? 0,
        dailyGoalXp: json['daily_goal_xp'] as int? ?? 20,
      );
}

class SkillTreeResponse {
  final SkillSubject subject;
  final List<SkillTreeUnit> units;
  final GamificationSummary user;

  SkillTreeResponse({required this.subject, required this.units, required this.user});

  factory SkillTreeResponse.fromJson(Map<String, dynamic> json) => SkillTreeResponse(
        subject: SkillSubject.fromJson(json['subject'] as Map<String, dynamic>),
        units: (json['units'] as List? ?? []).map((e) => SkillTreeUnit.fromJson(e as Map<String, dynamic>)).toList(),
        user: GamificationSummary.fromJson(json['user'] as Map<String, dynamic>),
      );
}

class SkillQuestion {
  final int id;
  final String questionText;
  final List<String> options;
  final String correctAnswer;
  final String? explanation;
  final int orderIndex;

  SkillQuestion({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    this.explanation,
    required this.orderIndex,
  });

  factory SkillQuestion.fromJson(Map<String, dynamic> json) => SkillQuestion(
        id: json['id'] as int,
        questionText: json['question_text'] as String,
        options: (json['options'] as List? ?? []).map((e) => e.toString()).toList(),
        correctAnswer: json['correct_answer'] as String,
        explanation: json['explanation'] as String?,
        orderIndex: json['order_index'] as int,
      );
}

/// Duolingo-style teaching card shown before the questions.
class TheoryCard {
  final String title;
  final String body;
  final String? example;

  TheoryCard({required this.title, required this.body, this.example});

  factory TheoryCard.fromJson(Map<String, dynamic> json) => TheoryCard(
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        example: json['example'] as String?,
      );
}

class LessonStartResult {
  final int attemptId;
  final List<TheoryCard> theory;
  final List<SkillQuestion> questions;
  LessonStartResult({required this.attemptId, required this.theory, required this.questions});

  factory LessonStartResult.fromJson(Map<String, dynamic> json) => LessonStartResult(
        attemptId: json['attempt_id'] as int,
        theory: (json['theory'] as List? ?? []).map((e) => TheoryCard.fromJson(e as Map<String, dynamic>)).toList(),
        questions: (json['questions'] as List? ?? []).map((e) => SkillQuestion.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

class LessonResultItem {
  final int questionId;
  final String userAnswer;
  final bool isCorrect;
  LessonResultItem({required this.questionId, required this.userAnswer, required this.isCorrect});

  Map<String, dynamic> toJson() => {
        'question_id': questionId,
        'user_answer': userAnswer,
        'is_correct': isCorrect,
      };
}

class LessonCompleteResult {
  final int stars;
  final int score;
  final int total;
  final int xpAwarded;
  final int xpTotal;
  final int streakDays;
  final List<int> newlyUnlockedLessonIds;

  LessonCompleteResult({
    required this.stars,
    required this.score,
    required this.total,
    required this.xpAwarded,
    required this.xpTotal,
    required this.streakDays,
    required this.newlyUnlockedLessonIds,
  });

  factory LessonCompleteResult.fromJson(Map<String, dynamic> json) => LessonCompleteResult(
        stars: json['stars'] as int? ?? 0,
        score: json['score'] as int? ?? 0,
        total: json['total'] as int? ?? 0,
        xpAwarded: json['xp_awarded'] as int? ?? 0,
        xpTotal: json['xp_total'] as int? ?? 0,
        streakDays: json['streak_days'] as int? ?? 0,
        newlyUnlockedLessonIds: (json['newly_unlocked_lesson_ids'] as List? ?? []).map((e) => e as int).toList(),
      );
}

class LessonLockedException implements Exception {}
