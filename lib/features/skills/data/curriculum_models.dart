class CurriculumGrade {
  final int grade;
  final String title;
  final String status;
  final int readyLessons;
  const CurriculumGrade({
    required this.grade,
    required this.title,
    required this.status,
    required this.readyLessons,
  });
  bool get sourceBlocked => status.startsWith('blocked_');
  factory CurriculumGrade.fromJson(Map<String, dynamic> json) =>
      CurriculumGrade(
        grade: json['grade'] as int,
        title: json['title_uz'] as String,
        status: json['status'] as String,
        readyLessons: json['ready_lessons'] as int? ?? 0,
      );
}

class CurriculumTopicSummary {
  final String title;
  final String kind;
  final bool ready;
  final bool completed;
  final int? printedStart;
  final int? printedEnd;
  const CurriculumTopicSummary({
    required this.title,
    required this.kind,
    required this.ready,
    required this.completed,
    this.printedStart,
    this.printedEnd,
  });
  factory CurriculumTopicSummary.fromJson(Map<String, dynamic> json) {
    final source = json['source'] as Map<String, dynamic>? ?? {};
    return CurriculumTopicSummary(
      title: json['title_uz'] as String,
      kind: json['kind'] as String,
      ready: json['ready'] == true,
      completed: json['completed'] == true,
      printedStart: source['printed_start'] as int?,
      printedEnd: source['printed_end'] as int?,
    );
  }
}

class CurriculumChapterSummary {
  final String title;
  final List<CurriculumTopicSummary> topics;
  const CurriculumChapterSummary({required this.title, required this.topics});
  factory CurriculumChapterSummary.fromJson(Map<String, dynamic> json) =>
      CurriculumChapterSummary(
        title: json['title_uz'] as String,
        topics: (json['topics'] as List)
            .map(
              (t) => CurriculumTopicSummary.fromJson(t as Map<String, dynamic>),
            )
            .toList(),
      );
}

class CurriculumOutline {
  final List<CurriculumChapterSummary> chapters;
  final bool completed;
  final int? nextGrade;
  const CurriculumOutline({
    required this.chapters,
    required this.completed,
    this.nextGrade,
  });
  factory CurriculumOutline.fromJson(Map<String, dynamic> json) =>
      CurriculumOutline(
        chapters: (json['chapters'] as List)
            .map(
              (c) =>
                  CurriculumChapterSummary.fromJson(c as Map<String, dynamic>),
            )
            .toList(),
        completed: json['completed'] == true,
        nextGrade: json['next_grade'] as int?,
      );
}
