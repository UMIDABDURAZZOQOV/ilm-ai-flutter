import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/providers/app_providers.dart' show languageProvider;
import 'skill_extras_models.dart';

/// Repository for all the Milliy Sertifikat extras beyond the core lesson path:
/// practice modes, mock exam, class mode, parent dashboard, profile, league,
/// referral, leaderboard, achievements, and the AI tutor.
class SkillExtrasRepository {
  final Dio _dio;
  final String _lang;
  const SkillExtrasRepository(this._dio, this._lang);

  // ── Practice modes ────────────────────────────────────────────────────────
  Future<DailyChallenge> getDailyChallenge(int userId) async {
    final res = await _dio.get('/skills/$userId/daily-challenge', queryParameters: {'language': _lang});
    return DailyChallenge.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> completeDailyChallenge(int userId, List<Map<String, dynamic>> results) async {
    final res = await _dio.post('/skills/daily-challenge/complete', data: {'user_id': userId, 'results': results});
    return res.data as Map<String, dynamic>;
  }

  Future<List<PracticeQuestion>> getMistakes(int userId) async {
    final res = await _dio.get('/skills/$userId/mistakes', queryParameters: {'language': _lang});
    return ((res.data as Map)['questions'] as List? ?? []).map((e) => PracticeQuestion.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> completeMistakes(int userId, List<Map<String, dynamic>> results) async {
    final res = await _dio.post('/skills/mistakes/complete', data: {'user_id': userId, 'results': results});
    return res.data as Map<String, dynamic>;
  }

  Future<List<PracticeQuestion>> getLightning(int userId) async {
    final res = await _dio.get('/skills/$userId/lightning', queryParameters: {'language': _lang});
    return ((res.data as Map)['questions'] as List? ?? []).map((e) => PracticeQuestion.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> completeLightning(int userId, int score, int total) async {
    final res = await _dio.post('/skills/lightning/complete', data: {'user_id': userId, 'score': score, 'total': total});
    return res.data as Map<String, dynamic>;
  }

  Future<List<PracticeQuestion>> getMarathon(int userId, String subjectSlug) async {
    final res = await _dio.get('/skills/$userId/marathon', queryParameters: {'subject': subjectSlug, 'language': _lang});
    return ((res.data as Map)['questions'] as List? ?? []).map((e) => PracticeQuestion.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> completeMarathon(int userId, int score, int total) async {
    final res = await _dio.post('/skills/marathon/complete', data: {'user_id': userId, 'score': score, 'total': total});
    return res.data as Map<String, dynamic>;
  }

  // ── Mock exam ─────────────────────────────────────────────────────────────
  Future<MockOverview> getMockOverview(int userId, String subjectSlug) async {
    final res = await _dio.get('/skills/$userId/mock-exam', queryParameters: {'subject': subjectSlug});
    return MockOverview.fromJson(res.data as Map<String, dynamic>);
  }

  Future<MockStartResult> startMockExam(int userId, String subjectSlug) async {
    final res = await _dio.post('/skills/mock-exam/start', data: {'user_id': userId, 'subject': subjectSlug, 'language': _lang});
    return MockStartResult.fromJson(res.data as Map<String, dynamic>);
  }

  Future<MockResult> completeMockExam(int userId, int examId, List<Map<String, dynamic>> answers) async {
    final res = await _dio.post('/skills/mock-exam/$examId/complete', data: {'user_id': userId, 'answers': answers});
    return MockResult.fromJson(res.data as Map<String, dynamic>);
  }

  // ── Profile / league / referral / leaderboard / achievements ──────────────
  Future<SkillProfile> getProfile(int userId) async {
    final res = await _dio.get('/skills/$userId/profile');
    return SkillProfile.fromJson(res.data as Map<String, dynamic>);
  }

  Future<LeagueResponse> getLeague(int userId) async {
    final res = await _dio.get('/skills/$userId/league');
    return LeagueResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<ReferralInfo> getReferral(int userId) async {
    final res = await _dio.get('/skills/$userId/referral');
    return ReferralInfo.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> applyReferral(int userId, String code) async {
    final res = await _dio.post('/skills/referral/apply', data: {'user_id': userId, 'code': code});
    return res.data as Map<String, dynamic>;
  }

  Future<LeaderboardResponse> getLeaderboard() async {
    final res = await _dio.get('/skills/leaderboard/weekly');
    return LeaderboardResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<Achievement>> getAchievements(int userId) async {
    final res = await _dio.get('/skills/$userId/achievements');
    return ((res.data as Map)['achievements'] as List? ?? []).map((e) => Achievement.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── AI tutor ──────────────────────────────────────────────────────────────
  Future<String> explain({
    required String questionText,
    List<String>? options,
    required String correctAnswer,
    String? userAnswer,
    required String lang,
  }) async {
    final res = await _dio.post('/skills/tutor/explain', data: {
      'question_text': questionText,
      'options': options,
      'correct_answer': correctAnswer,
      'user_answer': userAnswer,
      'lang': lang,
    });
    return (res.data as Map)['explanation'] as String? ?? '';
  }

  // ── Class mode ────────────────────────────────────────────────────────────
  Future<MyClasses> getMyClasses() async {
    final res = await _dio.get('/classes/mine');
    return MyClasses.fromJson(res.data as Map<String, dynamic>);
  }

  Future<ClassBrief> createClass(String name, String? subjectSlug) async {
    final res = await _dio.post('/classes', data: {'name': name, 'subject_slug': subjectSlug});
    return ClassBrief.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> joinClass(String code) async {
    final res = await _dio.post('/classes/join', data: {'code': code});
    return res.data as Map<String, dynamic>;
  }

  Future<ClassDetail> getClassDetail(int classId) async {
    final res = await _dio.get('/classes/$classId');
    return ClassDetail.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> createAssignment(int classId, String title, String? subjectSlug) async {
    await _dio.post('/classes/$classId/assign', data: {'title': title, 'subject_slug': subjectSlug});
  }

  Future<void> deleteAssignment(int classId, int assignmentId) async {
    await _dio.delete('/classes/$classId/assignments/$assignmentId');
  }

  Future<void> removeMember(int classId, int studentId) async {
    await _dio.delete('/classes/$classId/members/$studentId');
  }

  // ── Parent dashboard ──────────────────────────────────────────────────────
  Future<FamilyCodeInfo> getFamilyCode() async {
    final res = await _dio.get('/parent/my-code');
    return FamilyCodeInfo.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> linkChild(String code) async {
    final res = await _dio.post('/parent/link', data: {'code': code});
    return res.data as Map<String, dynamic>;
  }

  Future<List<ChildDetail>> getChildren() async {
    final res = await _dio.get('/parent/children');
    return ((res.data as Map)['children'] as List? ?? []).map((e) => ChildDetail.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> unlinkChild(int childId) async {
    await _dio.post('/parent/unlink', data: {'child_id': childId});
  }
}

final skillExtrasRepositoryProvider =
    Provider<SkillExtrasRepository>((ref) => SkillExtrasRepository(ref.watch(dioProvider), ref.watch(languageProvider)));
