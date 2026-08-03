// Manual DTOs mirroring the FastAPI SAT schemas (routers/sat_ielts.py, prefix
// /sat-ielts). Plain models — display-only shapes, codegen isn't worth it.

class SatQuestion {
  final int id;
  final String domain;
  final String? skill;
  final String difficulty;
  final String questionType;
  final String questionText;
  final List<String> options;
  final String correctAnswer;
  final String? rubric;

  SatQuestion({
    required this.id,
    required this.domain,
    this.skill,
    required this.difficulty,
    required this.questionType,
    required this.questionText,
    this.options = const [],
    required this.correctAnswer,
    this.rubric,
  });

  bool get isMcq => options.isNotEmpty;

  factory SatQuestion.fromJson(Map<String, dynamic> j) => SatQuestion(
        id: j['id'] as int,
        domain: (j['domain'] ?? '').toString(),
        skill: j['skill'] as String?,
        difficulty: (j['difficulty'] ?? 'medium').toString(),
        questionType: (j['question_type'] ?? '').toString(),
        questionText: (j['question_text'] ?? '').toString(),
        options: ((j['options'] as List?) ?? []).map((e) => e.toString()).toList(),
        correctAnswer: (j['correct_answer'] ?? '').toString(),
        rubric: j['rubric'] as String?,
      );
}

class SatSkill {
  final String skill;
  final int questionCount;
  final int attempted;
  final int correct;
  SatSkill({required this.skill, required this.questionCount, required this.attempted, required this.correct});
  factory SatSkill.fromJson(Map<String, dynamic> j) => SatSkill(
        skill: (j['skill'] ?? '').toString(),
        questionCount: (j['question_count'] ?? 0) as int,
        attempted: (j['attempted'] ?? 0) as int,
        correct: (j['correct'] ?? 0) as int,
      );
  double get accuracy => attempted == 0 ? 0 : correct / attempted;
}

class SatDomain {
  final String domain;
  final int questionCount;
  final int attempted;
  final int correct;
  final List<SatSkill> skills;
  SatDomain({required this.domain, required this.questionCount, required this.attempted, required this.correct, required this.skills});
  factory SatDomain.fromJson(Map<String, dynamic> j) => SatDomain(
        domain: (j['domain'] ?? '').toString(),
        questionCount: (j['question_count'] ?? 0) as int,
        attempted: (j['attempted'] ?? 0) as int,
        correct: (j['correct'] ?? 0) as int,
        skills: ((j['skills'] as List?) ?? []).map((e) => SatSkill.fromJson(e as Map<String, dynamic>)).toList(),
      );
  double get accuracy => attempted == 0 ? 0 : correct / attempted;
}

class SatSection {
  final String section;
  final List<SatDomain> domains;
  SatSection({required this.section, required this.domains});
  factory SatSection.fromJson(Map<String, dynamic> j) => SatSection(
        section: (j['section'] ?? '').toString(),
        domains: ((j['domains'] as List?) ?? []).map((e) => SatDomain.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

class SatSkillTree {
  final List<SatSection> sections;
  SatSkillTree({required this.sections});
  factory SatSkillTree.fromJson(Map<String, dynamic> j) => SatSkillTree(
        sections: ((j['sections'] as List?) ?? []).map((e) => SatSection.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

class SatSessionStart {
  final int sessionId;
  final List<SatQuestion> questions;
  SatSessionStart({required this.sessionId, required this.questions});
  factory SatSessionStart.fromJson(Map<String, dynamic> j) => SatSessionStart(
        sessionId: j['session_id'] as int,
        questions: ((j['questions'] as List?) ?? []).map((e) => SatQuestion.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

class SatSessionResult {
  final int? score;
  final int? total;
  final double? scorePct;
  final Map<String, double> sectionScores;
  SatSessionResult({this.score, this.total, this.scorePct, this.sectionScores = const {}});
  factory SatSessionResult.fromJson(Map<String, dynamic> j) => SatSessionResult(
        score: j['score'] as int?,
        total: j['total'] as int?,
        scorePct: (j['score_pct'] as num?)?.toDouble(),
        sectionScores: ((j['section_scores'] as Map?) ?? {})
            .map((k, v) => MapEntry(k.toString(), (v as num).toDouble())),
      );
}

class SatScore {
  final int? predictedScore;
  final bool available;
  final String? message;
  SatScore({this.predictedScore, required this.available, this.message});
  factory SatScore.fromJson(Map<String, dynamic> j) => SatScore(
        predictedScore: j['predicted_score'] as int?,
        available: j['prediction_available'] == true,
        message: j['message'] as String?,
      );
}
