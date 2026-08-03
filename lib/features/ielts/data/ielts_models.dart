// Manual DTOs mirroring the FastAPI IELTS schemas (routers/ielts.py). Plain
// models (not freezed) — many simple response shapes, codegen isn't worth it.

class IeltsListening {
  final int id;
  final int section;
  final String title;
  final String? audioUrl;
  final List<String> audioParts;
  final String? transcript;
  final String difficulty;
  final int? durationSeconds;

  IeltsListening({
    required this.id,
    required this.section,
    required this.title,
    this.audioUrl,
    this.audioParts = const [],
    this.transcript,
    required this.difficulty,
    this.durationSeconds,
  });

  factory IeltsListening.fromJson(Map<String, dynamic> j) => IeltsListening(
        id: j['id'] as int,
        section: (j['section'] ?? 0) as int,
        title: (j['title'] ?? '').toString(),
        audioUrl: j['audio_url'] as String?,
        audioParts: ((j['audio_parts'] as List?) ?? []).map((e) => e.toString()).toList(),
        transcript: j['transcript'] as String?,
        difficulty: (j['difficulty'] ?? 'medium').toString(),
        durationSeconds: j['duration_seconds'] as int?,
      );
}

class IeltsReading {
  final int id;
  final int section;
  final String title;
  final String passageText;
  final String difficulty;
  final int? wordCount;

  IeltsReading({
    required this.id,
    required this.section,
    required this.title,
    required this.passageText,
    required this.difficulty,
    this.wordCount,
  });

  factory IeltsReading.fromJson(Map<String, dynamic> j) => IeltsReading(
        id: j['id'] as int,
        section: (j['section'] ?? 0) as int,
        title: (j['title'] ?? '').toString(),
        passageText: (j['passage_text'] ?? '').toString(),
        difficulty: (j['difficulty'] ?? 'medium').toString(),
        wordCount: j['word_count'] as int?,
      );
}

class IeltsWriting {
  final int id;
  final String taskType;
  final String category;
  final String prompt;
  final String? imageUrl;
  final int minWords;
  final int durationMinutes;
  final String difficulty;

  IeltsWriting({
    required this.id,
    required this.taskType,
    required this.category,
    required this.prompt,
    this.imageUrl,
    required this.minWords,
    required this.durationMinutes,
    required this.difficulty,
  });

  factory IeltsWriting.fromJson(Map<String, dynamic> j) => IeltsWriting(
        id: j['id'] as int,
        taskType: (j['task_type'] ?? '').toString(),
        category: (j['category'] ?? '').toString(),
        prompt: (j['prompt'] ?? '').toString(),
        imageUrl: j['image_url'] as String?,
        minWords: (j['min_words'] ?? 150) as int,
        durationMinutes: (j['duration_minutes'] ?? 20) as int,
        difficulty: (j['difficulty'] ?? 'medium').toString(),
      );
}

class IeltsSpeaking {
  final int id;
  final int part;
  final String topic;
  final List<String> questions;
  final String? cueCard;
  final int? prepSeconds;
  final int? speakSeconds;
  final String difficulty;

  IeltsSpeaking({
    required this.id,
    required this.part,
    required this.topic,
    this.questions = const [],
    this.cueCard,
    this.prepSeconds,
    this.speakSeconds,
    required this.difficulty,
  });

  factory IeltsSpeaking.fromJson(Map<String, dynamic> j) => IeltsSpeaking(
        id: j['id'] as int,
        part: (j['part'] ?? 1) as int,
        topic: (j['topic'] ?? '').toString(),
        questions: ((j['questions'] as List?) ?? []).map((e) => e.toString()).toList(),
        cueCard: j['cue_card'] as String?,
        prepSeconds: j['prep_seconds'] as int?,
        speakSeconds: j['speak_seconds'] as int?,
        difficulty: (j['difficulty'] ?? 'medium').toString(),
      );
}

class IeltsQuestion {
  final int id;
  final String skill;
  final String questionType;
  final String questionText;
  final List<String> options;
  final String correctAnswer;
  final String? hint;
  final int orderIndex;

  IeltsQuestion({
    required this.id,
    required this.skill,
    required this.questionType,
    required this.questionText,
    this.options = const [],
    required this.correctAnswer,
    this.hint,
    required this.orderIndex,
  });

  bool get isMcq => options.isNotEmpty;

  factory IeltsQuestion.fromJson(Map<String, dynamic> j) => IeltsQuestion(
        id: j['id'] as int,
        skill: (j['skill'] ?? '').toString(),
        questionType: (j['question_type'] ?? '').toString(),
        questionText: (j['question_text'] ?? '').toString(),
        options: ((j['options'] as List?) ?? []).map((e) => e.toString()).toList(),
        correctAnswer: (j['correct_answer'] ?? '').toString(),
        hint: j['hint'] as String?,
        orderIndex: (j['order_index'] ?? 0) as int,
      );
}

class IeltsWritingSubmission {
  final int id;
  final int taskId;
  final int? wordCount;
  final double? bandScore;
  final String? feedback;
  final String? taskResponse;
  final String? coherence;
  final String? lexical;
  final String? grammar;
  final String submittedAt;

  IeltsWritingSubmission({
    required this.id,
    required this.taskId,
    this.wordCount,
    this.bandScore,
    this.feedback,
    this.taskResponse,
    this.coherence,
    this.lexical,
    this.grammar,
    required this.submittedAt,
  });

  factory IeltsWritingSubmission.fromJson(Map<String, dynamic> j) => IeltsWritingSubmission(
        id: j['id'] as int,
        taskId: (j['task_id'] ?? 0) as int,
        wordCount: j['word_count'] as int?,
        bandScore: (j['band_score'] as num?)?.toDouble(),
        feedback: j['feedback'] as String?,
        taskResponse: j['task_response'] as String?,
        coherence: j['coherence'] as String?,
        lexical: j['lexical'] as String?,
        grammar: j['grammar'] as String?,
        submittedAt: (j['submitted_at'] ?? '').toString(),
      );
}

class IeltsSpeakingSubmission {
  final int id;
  final int topicId;
  final String audioUrl;
  final int? durationSeconds;
  final double? bandScore;
  final String? transcript;
  final String? feedback;
  final String? fluency;
  final String? lexical;
  final String? grammar;
  final String? pronunciation;
  final String submittedAt;

  IeltsSpeakingSubmission({
    required this.id,
    required this.topicId,
    required this.audioUrl,
    this.durationSeconds,
    this.bandScore,
    this.transcript,
    this.feedback,
    this.fluency,
    this.lexical,
    this.grammar,
    this.pronunciation,
    required this.submittedAt,
  });

  factory IeltsSpeakingSubmission.fromJson(Map<String, dynamic> j) => IeltsSpeakingSubmission(
        id: j['id'] as int,
        topicId: (j['topic_id'] ?? 0) as int,
        audioUrl: (j['audio_url'] ?? '').toString(),
        durationSeconds: j['duration_seconds'] as int?,
        bandScore: (j['band_score'] as num?)?.toDouble(),
        transcript: j['transcript'] as String?,
        feedback: j['feedback'] as String?,
        fluency: j['fluency'] as String?,
        lexical: j['lexical'] as String?,
        grammar: j['grammar'] as String?,
        pronunciation: j['pronunciation'] as String?,
        submittedAt: (j['submitted_at'] ?? '').toString(),
      );
}

class IeltsMockTest {
  final int id;
  final String testType;
  final String status;
  final double? listeningScore;
  final double? readingScore;
  final double? writingScore;
  final double? speakingScore;
  final double? overallBand;
  final String startedAt;
  final String? completedAt;

  IeltsMockTest({
    required this.id,
    required this.testType,
    required this.status,
    this.listeningScore,
    this.readingScore,
    this.writingScore,
    this.speakingScore,
    this.overallBand,
    required this.startedAt,
    this.completedAt,
  });

  factory IeltsMockTest.fromJson(Map<String, dynamic> j) => IeltsMockTest(
        id: j['id'] as int,
        testType: (j['test_type'] ?? '').toString(),
        status: (j['status'] ?? '').toString(),
        listeningScore: (j['listening_score'] as num?)?.toDouble(),
        readingScore: (j['reading_score'] as num?)?.toDouble(),
        writingScore: (j['writing_score'] as num?)?.toDouble(),
        speakingScore: (j['speaking_score'] as num?)?.toDouble(),
        overallBand: (j['overall_band'] as num?)?.toDouble(),
        startedAt: (j['started_at'] ?? '').toString(),
        completedAt: j['completed_at'] as String?,
      );
}
