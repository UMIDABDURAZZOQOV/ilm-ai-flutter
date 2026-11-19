// Standalone debug entry point for Samsung visual evidence. No app session,
// local backend, secure storage, or real network calls enter this runner.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ilm_ai_flutter/core/config/phone_qa.dart';
import 'package:ilm_ai_flutter/core/network/dio_client.dart';
import 'package:ilm_ai_flutter/core/providers/app_providers.dart';
import 'package:ilm_ai_flutter/core/storage/prefs_service.dart';
import 'package:ilm_ai_flutter/core/storage/secure_token_storage.dart';
import 'package:ilm_ai_flutter/core/theme/app_theme.dart';
import 'package:ilm_ai_flutter/core/widgets/ai_explain_sheet.dart';
import 'package:ilm_ai_flutter/core/widgets/duo_chrome.dart';
import 'package:ilm_ai_flutter/core/widgets/ilmo_rig.dart';
import 'package:ilm_ai_flutter/features/assistant/data/assistant_repository.dart';
import 'package:ilm_ai_flutter/features/auth/application/auth_controller.dart';
import 'package:ilm_ai_flutter/features/learning/data/assessment_repository.dart';
import 'package:ilm_ai_flutter/features/learning/presentation/assessment_lesson_screen.dart';
import 'package:ilm_ai_flutter/features/onboarding/data/onboarding_draft.dart';
import 'package:ilm_ai_flutter/features/onboarding/presentation/duo_onboarding_screen.dart';
import 'package:ilm_ai_flutter/features/skills/data/curriculum_models.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_extras_repository.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_tree_models.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_tree_repository.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/curriculum_learning_screen.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/learning_invitation_card.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/learning_journey_widgets.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/lesson_completion_view.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/skill_lesson_screen.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/skill_practice_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _uid = 404042;
const _draftName = 'Ilmo QA';
final _subject = SkillSubject(
  id: 1,
  slug: 'biologiya',
  nameUz: 'Biologiya',
  nameRu: 'Биология',
  nameEn: 'Biology',
);
final _lesson = SkillTreeLesson(
  id: 1,
  slug: 'device-visual-audit',
  grade: 7,
  assessmentKey: 'qa-reviewed-flow',
  assessmentSubject: 'kimyo',
  titleUz: 'Dars yakunini sinash',
  titleRu: 'Проверка завершения',
  titleEn: 'Review the finish screen',
  status: LessonStatus.unlocked,
  orderIndex: 1,
  xpReward: 0,
  stars: 0,
);

class _NoAuth extends AuthController {
  @override
  Future<StoredTokens?> build() async => null;
}

class _LocalAi extends AssistantRepository {
  _LocalAi(super.dio, this.wait);
  final bool wait;

  @override
  Future<AssistantAnswer> ask({
    required int userId,
    required String question,
    required String language,
  }) => wait
      ? Completer<AssistantAnswer>().future
      : Future.value(
          const AssistantAnswer(
            answer: 'Bu ekran sinovi uchun kiritilgan namunaviy matn.',
          ),
        );
}

class _AnsweredAssessment extends AssessmentRepository {
  _AnsweredAssessment(Dio dio) : super(dio, 'kimyo');

  @override
  Future<Json> catalog(CancelToken cancel, {required int grade}) async => {};

  @override
  Future<Json> start(String key, String request, CancelToken cancel) async => {
    'expires_at': DateTime.now()
        .add(const Duration(hours: 1))
        .toIso8601String(),
    'title': 'Dars yakunini sinash',
    'questions': [
      {'key': 'checked-question'},
    ],
    'answers': {'checked-question': <String, dynamic>{}},
    'content': {
      'cards': [
        {'title': 'Namuna', 'body': 'Vizual sinov darsi.'},
      ],
      'formulas': [],
      'examples': [],
    },
  };
}

typedef _Scene = ({
  String name,
  IlmoActivity activity,
  Widget Function() view,
  int? onboardingStep,
  bool largeText,
});

_Scene _scene(
  String name,
  IlmoActivity activity,
  Widget Function() view, {
  int? step,
  bool large = false,
}) => (
  name: name,
  activity: activity,
  view: view,
  onboardingStep: step,
  largeText: large,
);

Widget _curriculum() => Scaffold(
  body: CurriculumLearningScreen(subject: _subject, onChangeSubject: () {}),
);

final _scenes = [
  for (final (name, activity) in [
    ('legacy-thinking', IlmoActivity.thinking),
    ('legacy-reply', IlmoActivity.explaining),
  ])
    _scene(
      name,
      activity,
      () => const Scaffold(
        body: SafeArea(
          child: AiExplainSheet(
            question: 'Namuna savoli',
            correctAnswer: 'Namuna',
          ),
        ),
      ),
    ),
  for (final (step, name, activity) in [
    (11, 'speech-header', IlmoActivity.greeting),
    (1, 'onboarding-greeting', IlmoActivity.greeting),
    (2, 'onboarding-intro', IlmoActivity.explaining),
    (6, 'onboarding-confidence', IlmoActivity.success),
    (8, 'onboarding-pace', IlmoActivity.thinking),
    (12, 'onboarding-ready', IlmoActivity.success),
  ])
    _scene(
      name,
      activity,
      DuoOnboardingScreen.new,
      step: step,
      large: step == 11,
    ),
  _scene(
    'assessment-wait',
    IlmoActivity.listening,
    () => AssessmentLessonScreen(lesson: _lesson),
  ),
  _scene('curriculum-error', IlmoActivity.thinking, _curriculum),
  _scene('curriculum-preparing', IlmoActivity.explaining, _curriculum),
  _scene(
    'empty-profile-invitation',
    IlmoActivity.greeting,
    () => Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            LearningInvitationCard(
              title: 'Birinchi darsdan boshlaymiz',
              message: 'Darsni yakunlang. Bu yerda natijalar ko‘rinadi.',
              actionLabel: 'Dars yo‘liga o‘tish',
              onOpenLearning: () {},
            ),
          ],
        ),
      ),
    ),
    large: true,
  ),
  _scene(
    'lesson-error',
    IlmoActivity.encouraging,
    () => SkillLessonScreen(lesson: _lesson),
  ),
  _scene(
    'practice-not-found',
    IlmoActivity.thinking,
    () => const SkillPracticeScreen(
      subjectSlug: 'biologiya',
      mode: PracticeMode.placement,
    ),
  ),
  _scene(
    'compact-goal',
    IlmoActivity.greeting,
    () => Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            LearningContinueCard(
              language: 'uz',
              title: 'Kunlik maqsad',
              todayXp: 0,
              goalXp: 20,
              compact: true,
              onGoal: () {},
            ),
          ],
        ),
      ),
    ),
    large: true,
  ),
  _scene(
    'failed-lesson-result',
    IlmoActivity.encouraging,
    () => Scaffold(
      body: LessonCompletionView(
        language: 'uz',
        title: 'Yana mashq qilamiz',
        lessonTitle: 'Sinov darsi',
        xp: 0,
        correct: 1,
        total: 8,
        stars: 0,
        streakDays: 0,
        elapsed: const Duration(seconds: 50),
        passed: false,
        onReview: () {},
        onBack: () {},
      ),
    ),
  ),
];

void main() {
  requirePhoneQaConfiguration(const String.fromEnvironment('API_URL'));
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _Audit());
}

class _Audit extends StatefulWidget {
  const _Audit();

  @override
  State<_Audit> createState() => _AuditState();
}

class _AuditState extends State<_Audit> {
  final _boundary = GlobalKey();
  final _errors = <String>[];
  final _reports = <Map<String, dynamic>>[];
  final _dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8925'));
  PrefsService? _prefs;
  _Scene? _active;

  @override
  void initState() {
    super.initState();
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // A local synthetic HTTP failure, even if a provider unexpectedly
          // attempts a request. It never reaches a real transport.
          handler.reject(
            DioException.badResponse(
              statusCode: 404,
              requestOptions: options,
              response: Response(requestOptions: options, statusCode: 404),
            ),
          );
        },
      ),
    );
    final prior = FlutterError.onError;
    FlutterError.onError = (details) {
      _errors.add(details.exceptionAsString());
      prior?.call(details);
    };
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_run()));
  }

  Iterable<T> _elements<T extends Widget>(Element root) sync* {
    if (root.widget is T) yield root.widget as T;
    final children = <Element>[];
    root.visitChildren(children.add);
    for (final child in children) {
      yield* _elements<T>(child);
    }
  }

  Future<void> _run() async {
    final cache = await getTemporaryDirectory();
    final dir = await Directory('${cache.path}/ilmo-device-audit').create();
    for (final scene in _scenes) {
      final errorStart = _errors.length;
      final frames = <ui.Image>[];
      try {
        SharedPreferences.setMockInitialValues({PrefsKeys.language: 'uz'});
        final prefs = await PrefsService.create();
        if (scene.onboardingStep != null) {
          await OnboardingDraftStore(prefs).save(null, {
            'step': scene.onboardingStep == 12 ? 11 : scene.onboardingStep,
            'name': _draftName,
            'age': '25',
          });
        }
        setState(() {
          _active = scene;
          _prefs = prefs;
        });
        await WidgetsBinding.instance.endOfFrame;
        if (scene.onboardingStep == 12) {
          final submit =
              _elements<Duo3DButton>(
                _boundary.currentContext! as Element,
              ).singleWhere(
                (button) =>
                    button.key == const ValueKey('onboarding_continue_btn'),
              );
          submit.onPressed!();
        }
        final progress = <double>[];
        final root = _boundary.currentContext! as Element;
        for (var retry = 0; retry < 15 && progress.length < 3; retry++) {
          await Future<void>.delayed(const Duration(milliseconds: 60));
          await WidgetsBinding.instance.endOfFrame;
          final rig = _elements<IlmoRig>(
            root,
          ).where((rig) => rig.activity == scene.activity).firstOrNull;
          if (rig == null || rig.progress <= 0 || rig.progress >= 1) continue;
          final render = root.findRenderObject()! as RenderRepaintBoundary;
          if (!render.hasSize ||
              render.size.isEmpty ||
              render.debugNeedsPaint) {
            continue;
          }
          final phase = rig.progress;
          frames.add(await render.toImage(pixelRatio: 1.5));
          progress.add(phase);
        }
        // Take all snapshots before PNG encoding so a short-lived screen does
        // not advance while the screenshot is being exported.
        for (final (index, image) in frames.indexed) {
          final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
          await File(
            '${dir.path}/${scene.name}-${index + 1}.png',
          ).writeAsBytes(png.buffer.asUint8List());
        }
        final errors = _errors.sublist(errorStart);
        _reports.add({
          'scene': scene.name,
          'activity': scene.activity.name,
          'text_scale': scene.largeText ? 2 : 1,
          'progress': progress,
          'errors': errors,
          'passed': progress.toSet().length == 3 && errors.isEmpty,
        });
      } catch (error) {
        _reports.add({
          'scene': scene.name,
          'passed': false,
          'error': error.toString(),
        });
      } finally {
        for (final image in frames) {
          image.dispose();
        }
      }
    }
    final payload = jsonEncode(_reports);
    await File('${dir.path}/report.json').writeAsString(payload);
    debugPrint(
      'ILMO_DEVICE_AUDIT_FINISHED ${_reports.where((r) => r['passed'] == true).length}/${_scenes.length}',
    );
    setState(() => _active = null);
  }

  @override
  Widget build(BuildContext context) {
    final scene = _active;
    if (scene == null) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              _reports.isEmpty
                  ? 'Ilmo QA'
                  : 'Ilmo QA • ${_reports.length} holat',
            ),
          ),
        ),
      );
    }
    return RepaintBoundary(
      key: _boundary,
      child: ProviderScope(
        key: ValueKey(scene.name),
        overrides: [
          prefsServiceProvider.overrideWithValue(_prefs!),
          dioProvider.overrideWithValue(_dio),
          authControllerProvider.overrideWith(_NoAuth.new),
          currentUserIdProvider.overrideWithValue(
            scene.onboardingStep != null ? null : _uid,
          ),
          assistantRepositoryProvider.overrideWithValue(
            _LocalAi(_dio, scene.name == 'legacy-thinking'),
          ),
          skillTreeRepositoryProvider.overrideWithValue(
            SkillTreeRepository(_dio),
          ),
          skillExtrasRepositoryProvider.overrideWithValue(
            SkillExtrasRepository(_dio, 'uz'),
          ),
          assessmentRepositoryProvider.overrideWith(
            (ref, slug) => _AnsweredAssessment(_dio),
          ),
          curriculumGradesProvider.overrideWith((ref, slug) async {
            if (scene.name == 'curriculum-error') {
              throw StateError('Sinov ulanish xatosi');
            }
            return const [
              CurriculumGrade(
                grade: 7,
                title: '7-sinf',
                status: 'blocked_source',
                readyLessons: 0,
              ),
            ];
          }),
          selectedCurriculumGradeProvider.overrideWith((ref, slug) {
            return scene.name == 'curriculum-preparing' ? 7 : null;
          }),
        ],
        child: MaterialApp(
          theme: buildAppTheme(lightColors),
          darkTheme: buildAppTheme(darkColors),
          themeMode: scene.largeText ? ThemeMode.dark : ThemeMode.light,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scene.largeText ? 2 : 1),
              disableAnimations: false,
            ),
            child: child!,
          ),
          home: scene.view(),
        ),
      ),
    );
  }
}
