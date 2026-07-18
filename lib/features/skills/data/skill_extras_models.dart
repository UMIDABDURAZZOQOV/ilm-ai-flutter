// DTOs for the Milliy Sertifikat extras: practice modes, mock exam, class mode,
// parent dashboard, profile, league, referral, leaderboard, achievements.
// Plain manual models, matching skill_tree_models.dart's convention.

class PracticeQuestion {
  final int id;
  final String questionText;
  final List<String> options;
  final String correctAnswer;
  final String? explanation;

  PracticeQuestion({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    this.explanation,
  });

  factory PracticeQuestion.fromJson(Map<String, dynamic> json) => PracticeQuestion(
        id: json['id'] as int,
        questionText: json['question_text'] as String,
        options: (json['options'] as List? ?? []).map((e) => e.toString()).toList(),
        correctAnswer: json['correct_answer'] as String? ?? '',
        explanation: json['explanation'] as String?,
      );
}

class DailyChallenge {
  final bool completed;
  final int? score;
  final int? total;
  final int? xpAwarded;
  final List<PracticeQuestion> questions;

  DailyChallenge({required this.completed, this.score, this.total, this.xpAwarded, required this.questions});

  factory DailyChallenge.fromJson(Map<String, dynamic> json) => DailyChallenge(
        completed: json['completed'] as bool? ?? false,
        score: json['score'] as int?,
        total: json['total'] as int?,
        xpAwarded: json['xp_awarded'] as int?,
        questions: (json['questions'] as List? ?? []).map((e) => PracticeQuestion.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

// ─── Mock exam ─────────────────────────────────────────────────────────────────

class MockPrediction {
  final double predictedPct;
  final String predictedGrade;
  final String confidence;
  final int basedOnExams;
  final bool usedMastery;

  MockPrediction({
    required this.predictedPct,
    required this.predictedGrade,
    required this.confidence,
    required this.basedOnExams,
    required this.usedMastery,
  });

  factory MockPrediction.fromJson(Map<String, dynamic> json) => MockPrediction(
        predictedPct: (json['predicted_pct'] as num?)?.toDouble() ?? 0,
        predictedGrade: json['predicted_grade'] as String? ?? '',
        confidence: json['confidence'] as String? ?? 'low',
        basedOnExams: json['based_on_exams'] as int? ?? 0,
        usedMastery: json['used_mastery'] as bool? ?? false,
      );
}

class MockAttempt {
  final int id;
  final double? percentage;
  final String? grade;
  final int? score;
  final int? total;
  final String? completedAt;

  MockAttempt({required this.id, this.percentage, this.grade, this.score, this.total, this.completedAt});

  factory MockAttempt.fromJson(Map<String, dynamic> json) => MockAttempt(
        id: json['id'] as int,
        percentage: (json['percentage'] as num?)?.toDouble(),
        grade: json['grade'] as String?,
        score: json['score'] as int?,
        total: json['total'] as int?,
        completedAt: json['completed_at'] as String?,
      );
}

class MockOverview {
  final String subjectSlug;
  final int availableQuestions;
  final int size;
  final int durationSeconds;
  final double? bestPercentage;
  final String? bestGrade;
  final List<MockAttempt> attempts;
  final MockPrediction? prediction;

  MockOverview({
    required this.subjectSlug,
    required this.availableQuestions,
    required this.size,
    required this.durationSeconds,
    this.bestPercentage,
    this.bestGrade,
    required this.attempts,
    this.prediction,
  });

  factory MockOverview.fromJson(Map<String, dynamic> json) {
    final best = json['best'] as Map<String, dynamic>?;
    return MockOverview(
      subjectSlug: json['subject_slug'] as String? ?? '',
      availableQuestions: json['available_questions'] as int? ?? 0,
      size: json['size'] as int? ?? 0,
      durationSeconds: json['duration_seconds'] as int? ?? 1800,
      bestPercentage: (best?['percentage'] as num?)?.toDouble(),
      bestGrade: best?['grade'] as String?,
      attempts: (json['attempts'] as List? ?? []).map((e) => MockAttempt.fromJson(e as Map<String, dynamic>)).toList(),
      prediction: json['prediction'] == null ? null : MockPrediction.fromJson(json['prediction'] as Map<String, dynamic>),
    );
  }
}

class MockExamQuestion {
  final int id;
  final String questionText;
  final List<String> options;

  MockExamQuestion({required this.id, required this.questionText, required this.options});

  factory MockExamQuestion.fromJson(Map<String, dynamic> json) => MockExamQuestion(
        id: json['id'] as int,
        questionText: json['question_text'] as String,
        options: (json['options'] as List? ?? []).map((e) => e.toString()).toList(),
      );
}

class MockStartResult {
  final int examId;
  final int durationSeconds;
  final List<MockExamQuestion> questions;

  MockStartResult({required this.examId, required this.durationSeconds, required this.questions});

  factory MockStartResult.fromJson(Map<String, dynamic> json) => MockStartResult(
        examId: json['exam_id'] as int,
        durationSeconds: json['duration_seconds'] as int? ?? 1800,
        questions: (json['questions'] as List? ?? []).map((e) => MockExamQuestion.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

class MockReviewItem {
  final String questionText;
  final List<String> options;
  final String correctAnswer;
  final String? explanation;
  final String userAnswer;
  final bool isCorrect;

  MockReviewItem({
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    this.explanation,
    required this.userAnswer,
    required this.isCorrect,
  });

  factory MockReviewItem.fromJson(Map<String, dynamic> json) => MockReviewItem(
        questionText: json['question_text'] as String? ?? '',
        options: (json['options'] as List? ?? []).map((e) => e.toString()).toList(),
        correctAnswer: json['correct_answer'] as String? ?? '',
        explanation: json['explanation'] as String?,
        userAnswer: json['user_answer'] as String? ?? '',
        isCorrect: json['is_correct'] as bool? ?? false,
      );
}

class MockResult {
  final int score;
  final int total;
  final double? percentage;
  final String grade;
  final bool certificate;
  final String predictedGrade;
  final double predictedPct;
  final MockPrediction? prediction;
  final int xpAwarded;
  final int xpTotal;
  final List<MockReviewItem> review;

  MockResult({
    required this.score,
    required this.total,
    this.percentage,
    required this.grade,
    required this.certificate,
    required this.predictedGrade,
    required this.predictedPct,
    this.prediction,
    required this.xpAwarded,
    required this.xpTotal,
    required this.review,
  });

  factory MockResult.fromJson(Map<String, dynamic> json) => MockResult(
        score: json['score'] as int? ?? 0,
        total: json['total'] as int? ?? 0,
        percentage: (json['percentage'] as num?)?.toDouble(),
        grade: json['grade'] as String? ?? '',
        certificate: json['certificate'] as bool? ?? false,
        predictedGrade: json['predicted_grade'] as String? ?? '',
        predictedPct: (json['predicted_pct'] as num?)?.toDouble() ?? 0,
        prediction: json['prediction'] == null ? null : MockPrediction.fromJson(json['prediction'] as Map<String, dynamic>),
        xpAwarded: json['xp_awarded'] as int? ?? 0,
        xpTotal: json['xp_total'] as int? ?? 0,
        review: (json['review'] as List? ?? []).map((e) => MockReviewItem.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

// ─── Subject progress (shared by profile + parent) ─────────────────────────────

class SubjectProgress {
  final String slug;
  final String nameUz;
  final String nameRu;
  final String nameEn;
  final String? color;
  final int completed;
  final int total;
  final int stars;
  final int pct;

  SubjectProgress({
    required this.slug,
    required this.nameUz,
    required this.nameRu,
    required this.nameEn,
    this.color,
    required this.completed,
    required this.total,
    required this.stars,
    required this.pct,
  });

  factory SubjectProgress.fromJson(Map<String, dynamic> json) => SubjectProgress(
        slug: json['slug'] as String? ?? '',
        nameUz: json['name_uz'] as String? ?? '',
        nameRu: json['name_ru'] as String? ?? '',
        nameEn: json['name_en'] as String? ?? '',
        color: json['color'] as String?,
        completed: json['completed'] as int? ?? 0,
        total: json['total'] as int? ?? 0,
        stars: json['stars'] as int? ?? 0,
        pct: json['pct'] as int? ?? 0,
      );

  String nameFor(String language) => language == 'ru' ? nameRu : language == 'en' ? nameEn : nameUz;
}

// ─── League ────────────────────────────────────────────────────────────────────

class LeagueTier {
  final String id;
  final String nameUz;
  final String nameRu;
  final String nameEn;
  final int minXp;
  final String color;

  LeagueTier({required this.id, required this.nameUz, required this.nameRu, required this.nameEn, required this.minXp, required this.color});

  factory LeagueTier.fromJson(Map<String, dynamic> json) => LeagueTier(
        id: json['id'] as String? ?? '',
        nameUz: json['name_uz'] as String? ?? '',
        nameRu: json['name_ru'] as String? ?? '',
        nameEn: json['name_en'] as String? ?? '',
        minXp: json['min_xp'] as int? ?? 0,
        color: json['color'] as String? ?? '#CD7F32',
      );

  String nameFor(String language) => language == 'ru' ? nameRu : language == 'en' ? nameEn : nameUz;
}

class LeagueResponse {
  final LeagueTier league;
  final int weeklyXp;
  final LeagueTier? nextLeague;
  final int xpToNext;
  final List<LeagueTier> allTiers;

  LeagueResponse({required this.league, required this.weeklyXp, this.nextLeague, required this.xpToNext, required this.allTiers});

  factory LeagueResponse.fromJson(Map<String, dynamic> json) => LeagueResponse(
        league: LeagueTier.fromJson(json['league'] as Map<String, dynamic>),
        weeklyXp: json['weekly_xp'] as int? ?? 0,
        nextLeague: json['next_league'] == null ? null : LeagueTier.fromJson(json['next_league'] as Map<String, dynamic>),
        xpToNext: json['xp_to_next'] as int? ?? 0,
        allTiers: (json['all_tiers'] as List? ?? []).map((e) => LeagueTier.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

// ─── Profile ───────────────────────────────────────────────────────────────────

class SkillProfile {
  final String name;
  final String? profilePicture;
  final int xpTotal;
  final int streakDays;
  final int lessonsCompleted;
  final List<SubjectProgress> subjects;
  final SubjectProgress? strongest;
  final SubjectProgress? weakest;
  final Map<String, int> activity;
  final LeagueTier league;

  SkillProfile({
    required this.name,
    this.profilePicture,
    required this.xpTotal,
    required this.streakDays,
    required this.lessonsCompleted,
    required this.subjects,
    this.strongest,
    this.weakest,
    required this.activity,
    required this.league,
  });

  factory SkillProfile.fromJson(Map<String, dynamic> json) => SkillProfile(
        name: json['name'] as String? ?? '',
        profilePicture: json['profile_picture'] as String?,
        xpTotal: json['xp_total'] as int? ?? 0,
        streakDays: json['streak_days'] as int? ?? 0,
        lessonsCompleted: json['lessons_completed'] as int? ?? 0,
        subjects: (json['subjects'] as List? ?? []).map((e) => SubjectProgress.fromJson(e as Map<String, dynamic>)).toList(),
        strongest: json['strongest'] == null ? null : SubjectProgress.fromJson(json['strongest'] as Map<String, dynamic>),
        weakest: json['weakest'] == null ? null : SubjectProgress.fromJson(json['weakest'] as Map<String, dynamic>),
        activity: (json['activity'] as Map?)?.map((k, v) => MapEntry(k.toString(), v as int)) ?? {},
        league: LeagueTier.fromJson(json['league'] as Map<String, dynamic>),
      );
}

// ─── Referral ──────────────────────────────────────────────────────────────────

class ReferralInfo {
  final String code;
  final int invitedCount;
  final int bonusPerInvite;
  final int bonusEarned;

  ReferralInfo({required this.code, required this.invitedCount, required this.bonusPerInvite, required this.bonusEarned});

  factory ReferralInfo.fromJson(Map<String, dynamic> json) => ReferralInfo(
        code: json['code'] as String? ?? '',
        invitedCount: json['invited_count'] as int? ?? 0,
        bonusPerInvite: json['bonus_per_invite'] as int? ?? 50,
        bonusEarned: json['bonus_earned'] as int? ?? 0,
      );
}

// ─── Leaderboard ───────────────────────────────────────────────────────────────

class LeaderboardEntry {
  final int rank;
  final int userId;
  final String name;
  final String? profilePicture;
  final int weeklyXp;
  final String league;
  final bool isMe;

  LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.name,
    this.profilePicture,
    required this.weeklyXp,
    required this.league,
    required this.isMe,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => LeaderboardEntry(
        rank: json['rank'] as int? ?? 0,
        userId: json['user_id'] as int? ?? 0,
        name: json['name'] as String? ?? '...',
        profilePicture: json['profile_picture'] as String?,
        weeklyXp: json['weekly_xp'] as int? ?? 0,
        league: json['league'] as String? ?? 'bronze',
        isMe: json['is_me'] as bool? ?? false,
      );
}

class LeaderboardResponse {
  final List<LeaderboardEntry> entries;
  final int? ownRank;
  final int totalParticipants;

  LeaderboardResponse({required this.entries, this.ownRank, required this.totalParticipants});

  factory LeaderboardResponse.fromJson(Map<String, dynamic> json) => LeaderboardResponse(
        entries: (json['entries'] as List? ?? []).map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>)).toList(),
        ownRank: json['own_rank'] as int?,
        totalParticipants: json['total_participants'] as int? ?? 0,
      );
}

// ─── Achievements ──────────────────────────────────────────────────────────────

class Achievement {
  final String id;
  final String group;
  final int target;
  final int progress;
  final bool earned;

  Achievement({required this.id, required this.group, required this.target, required this.progress, required this.earned});

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
        id: json['id'] as String? ?? '',
        group: json['group'] as String? ?? '',
        target: json['target'] as int? ?? 0,
        progress: json['progress'] as int? ?? 0,
        earned: json['earned'] as bool? ?? false,
      );
}

// ─── Class mode ────────────────────────────────────────────────────────────────

class ClassBrief {
  final int id;
  final String name;
  final String? subjectSlug;
  final String joinCode;
  final int memberCount;

  ClassBrief({required this.id, required this.name, this.subjectSlug, required this.joinCode, required this.memberCount});

  factory ClassBrief.fromJson(Map<String, dynamic> json) => ClassBrief(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        subjectSlug: json['subject_slug'] as String?,
        joinCode: json['join_code'] as String? ?? '',
        memberCount: json['member_count'] as int? ?? 0,
      );
}

class EnrolledClass {
  final int id;
  final String name;
  final String? subjectSlug;
  final String teacherName;

  EnrolledClass({required this.id, required this.name, this.subjectSlug, required this.teacherName});

  factory EnrolledClass.fromJson(Map<String, dynamic> json) => EnrolledClass(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        subjectSlug: json['subject_slug'] as String?,
        teacherName: json['teacher_name'] as String? ?? '...',
      );
}

class MyClasses {
  final List<ClassBrief> teaching;
  final List<EnrolledClass> enrolled;
  MyClasses({required this.teaching, required this.enrolled});

  factory MyClasses.fromJson(Map<String, dynamic> json) => MyClasses(
        teaching: (json['teaching'] as List? ?? []).map((e) => ClassBrief.fromJson(e as Map<String, dynamic>)).toList(),
        enrolled: (json['enrolled'] as List? ?? []).map((e) => EnrolledClass.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

class StudentRow {
  final int userId;
  final String name;
  final String? profilePicture;
  final int xpTotal;
  final int weeklyXp;
  final int streakDays;
  final int lessonsCompleted;
  final String? lastActive;
  final bool activeToday;

  StudentRow({
    required this.userId,
    required this.name,
    this.profilePicture,
    required this.xpTotal,
    required this.weeklyXp,
    required this.streakDays,
    required this.lessonsCompleted,
    this.lastActive,
    required this.activeToday,
  });

  factory StudentRow.fromJson(Map<String, dynamic> json) => StudentRow(
        userId: json['user_id'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        profilePicture: json['profile_picture'] as String?,
        xpTotal: json['xp_total'] as int? ?? 0,
        weeklyXp: json['weekly_xp'] as int? ?? 0,
        streakDays: json['streak_days'] as int? ?? 0,
        lessonsCompleted: json['lessons_completed'] as int? ?? 0,
        lastActive: json['last_active'] as String?,
        activeToday: json['active_today'] as bool? ?? false,
      );
}

class ClassAssignment {
  final int id;
  final String title;
  final String? subjectSlug;
  final int? lessonId;
  final String? dueDate;

  ClassAssignment({required this.id, required this.title, this.subjectSlug, this.lessonId, this.dueDate});

  factory ClassAssignment.fromJson(Map<String, dynamic> json) => ClassAssignment(
        id: json['id'] as int,
        title: json['title'] as String? ?? '',
        subjectSlug: json['subject_slug'] as String?,
        lessonId: json['lesson_id'] as int?,
        dueDate: json['due_date'] as String?,
      );
}

class ClassDetail {
  final int id;
  final String name;
  final String? subjectSlug;
  final String joinCode;
  final List<StudentRow> roster;
  final List<ClassAssignment> assignments;

  ClassDetail({
    required this.id,
    required this.name,
    this.subjectSlug,
    required this.joinCode,
    required this.roster,
    required this.assignments,
  });

  factory ClassDetail.fromJson(Map<String, dynamic> json) => ClassDetail(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        subjectSlug: json['subject_slug'] as String?,
        joinCode: json['join_code'] as String? ?? '',
        roster: (json['roster'] as List? ?? []).map((e) => StudentRow.fromJson(e as Map<String, dynamic>)).toList(),
        assignments: (json['assignments'] as List? ?? []).map((e) => ClassAssignment.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

// ─── Parent dashboard ──────────────────────────────────────────────────────────

class ChildDetail {
  final int userId;
  final String name;
  final String? profilePicture;
  final int xpTotal;
  final int weeklyXp;
  final int streakDays;
  final int lessonsCompleted;
  final String? lastActive;
  final bool activeToday;
  final List<SubjectProgress> subjects;
  final SubjectProgress? strongest;
  final SubjectProgress? weakest;
  final Map<String, int> activity;

  ChildDetail({
    required this.userId,
    required this.name,
    this.profilePicture,
    required this.xpTotal,
    required this.weeklyXp,
    required this.streakDays,
    required this.lessonsCompleted,
    this.lastActive,
    required this.activeToday,
    required this.subjects,
    this.strongest,
    this.weakest,
    required this.activity,
  });

  factory ChildDetail.fromJson(Map<String, dynamic> json) => ChildDetail(
        userId: json['user_id'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        profilePicture: json['profile_picture'] as String?,
        xpTotal: json['xp_total'] as int? ?? 0,
        weeklyXp: json['weekly_xp'] as int? ?? 0,
        streakDays: json['streak_days'] as int? ?? 0,
        lessonsCompleted: json['lessons_completed'] as int? ?? 0,
        lastActive: json['last_active'] as String?,
        activeToday: json['active_today'] as bool? ?? false,
        subjects: (json['subjects'] as List? ?? []).map((e) => SubjectProgress.fromJson(e as Map<String, dynamic>)).toList(),
        strongest: json['strongest'] == null ? null : SubjectProgress.fromJson(json['strongest'] as Map<String, dynamic>),
        weakest: json['weakest'] == null ? null : SubjectProgress.fromJson(json['weakest'] as Map<String, dynamic>),
        activity: (json['activity'] as Map?)?.map((k, v) => MapEntry(k.toString(), v as int)) ?? {},
      );
}

class FamilyCodeInfo {
  final String code;
  final List<String> linkedParentNames;

  FamilyCodeInfo({required this.code, required this.linkedParentNames});

  factory FamilyCodeInfo.fromJson(Map<String, dynamic> json) => FamilyCodeInfo(
        code: json['code'] as String? ?? '',
        linkedParentNames: (json['linked_parents'] as List? ?? []).map((e) => (e as Map)['name'].toString()).toList(),
      );
}
