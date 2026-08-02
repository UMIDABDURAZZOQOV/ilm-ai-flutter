import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../quiz/data/quiz_models.dart';

class CourseLesson {
  final String title;
  final String summary;
  const CourseLesson({required this.title, required this.summary});
  factory CourseLesson.fromJson(Map<String, dynamic> j) =>
      CourseLesson(title: (j['title'] ?? '').toString(), summary: (j['summary'] ?? '').toString());
}

class CourseChapter {
  final String title;
  final List<CourseLesson> lessons;
  const CourseChapter({required this.title, required this.lessons});
  factory CourseChapter.fromJson(Map<String, dynamic> j) => CourseChapter(
        title: (j['title'] ?? '').toString(),
        lessons: ((j['lessons'] as List?) ?? [])
            .map((e) => CourseLesson.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class Course {
  final String title;
  final List<CourseChapter> chapters;
  final List<String> sources;
  const Course({required this.title, required this.chapters, required this.sources});
  factory Course.fromJson(Map<String, dynamic> j) => Course(
        title: (j['title'] ?? '').toString(),
        chapters: ((j['chapters'] as List?) ?? [])
            .map((e) => CourseChapter.fromJson(e as Map<String, dynamic>))
            .toList(),
        sources: ((j['sources'] as List?) ?? []).map((e) => e.toString()).toList(),
      );

  int get totalLessons => chapters.fold(0, (n, c) => n + c.lessons.length);
}

class CourseState {
  final Course? course;
  final Map<String, bool> completed; // lessonKey -> done
  const CourseState({required this.course, required this.completed});
}

class CourseRepository {
  final Dio _dio;
  const CourseRepository(this._dio);

  Future<CourseState> getCourse(int userId) async {
    final res = await _dio.get('/course/$userId');
    final data = res.data as Map<String, dynamic>;
    final courseJson = data['course'];
    final progress = (data['progress'] as Map?) ?? {};
    final completed = <String, bool>{};
    progress.forEach((k, v) {
      if (v is Map && v['completed'] == true) completed[k.toString()] = true;
    });
    return CourseState(
      course: courseJson == null ? null : Course.fromJson(courseJson as Map<String, dynamic>),
      completed: completed,
    );
  }

  Future<Course> generate(int userId, String language) async {
    final res = await _dio.post('/course/generate', data: {'user_id': userId, 'language': language});
    return Course.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<QuizQuestion>> lessonQuestions({
    required int userId,
    required String chapterTitle,
    required String lessonTitle,
    required String lessonSummary,
    required String language,
  }) async {
    final res = await _dio.post('/course/lesson-questions', data: {
      'user_id': userId,
      'chapter_title': chapterTitle,
      'lesson_title': lessonTitle,
      'lesson_summary': lessonSummary,
      'language': language,
    });
    final data = res.data as Map<String, dynamic>;
    return ((data['questions'] as List?) ?? [])
        .map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> completeLesson(int userId, String lessonKey, int score) async {
    await _dio.post('/course/lesson-complete',
        data: {'user_id': userId, 'lesson_key': lessonKey, 'score': score});
  }
}

final courseRepositoryProvider =
    Provider<CourseRepository>((ref) => CourseRepository(ref.watch(dioProvider)));
