import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/app_providers.dart';
import '../splash/splash_screen.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/onboarding/presentation/language_select_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/auth/presentation/verify_email_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/assistant/presentation/assistant_screen.dart';
import '../../features/live_voice/presentation/live_voice_screen.dart';
import '../../features/focus/presentation/focus_screen.dart';
import '../../features/insights/presentation/insights_screen.dart';
import '../../features/files/presentation/knowledge_base_screen.dart';
import '../../features/quiz/data/quiz_models.dart';
import '../../features/quiz/presentation/quiz_home_screen.dart';
import '../../features/skills/data/skill_tree_models.dart';
import '../../features/skills/presentation/skills_hub_screen.dart';
import '../../features/skills/presentation/skill_path_screen.dart';
import '../../features/skills/presentation/skill_lesson_screen.dart';
import '../../features/skills/presentation/skill_practice_screen.dart';
import '../../features/skills/presentation/mock_exam_screen.dart';
import '../../features/skills/presentation/class_mode_screen.dart';
import '../../features/skills/presentation/parent_dashboard_screen.dart';
import '../../features/skills/presentation/skill_profile_screen.dart';
import '../../features/skills/presentation/skill_leaderboard_screen.dart';
import '../../features/skills/presentation/skill_achievements_screen.dart';
import '../../features/skills/presentation/skill_referral_screen.dart';
import '../../features/quiz/presentation/quiz_session_screen.dart';
import '../../features/quiz/presentation/quiz_result_screen.dart';
import '../../features/quiz/presentation/quiz_stats_screen.dart';
import '../../features/quiz/presentation/flashcard_screen.dart';
import '../../features/quiz/presentation/review_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/subscription/presentation/subscription_screen.dart';
import '../../features/learning_plan/presentation/learning_plan_screen.dart';
import '../../features/gaps/presentation/gaps_report_screen.dart';
import '../../features/telegram/presentation/telegram_screen.dart';
import '../../features/feedback/presentation/feedback_screen.dart';
import '../../features/college/presentation/college_list_screen.dart';
import '../../features/college/presentation/college_detail_screen.dart';
import '../../features/math_solver/presentation/math_solver_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../widgets/main_shell.dart';

const _preAuthRoutes = {'/language-select', '/onboarding'};
const _authRoutes = {'/login', '/signup', '/verify-email', '/forgot-password'};

/// Subtle fade + upward slide on every push/pop, replacing the platform
/// default so navigation feels consistent across Android/iOS.
CustomTransitionPage<void> _fadeSlidePage(Widget child, GoRouterState state) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Bridges Riverpod state changes into a Listenable so go_router's
/// `refreshListenable` re-evaluates `redirect` whenever auth/onboarding
/// state flips (login, logout, onboarding completion).
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen(onboardingCompleteProvider, (_, _) => notifyListeners());
    ref.listen(authControllerProvider, (_, _) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final authState = ref.read(authControllerProvider);

      // Still restoring tokens from secure storage -- stay on splash rather
      // than flashing the login screen before we know the real session state.
      if (authState.isLoading) {
        return loc == '/splash' ? null : '/splash';
      }

      final onboardingDone = ref.read(onboardingCompleteProvider);
      final authed = authState.valueOrNull != null;

      if (!onboardingDone) {
        return _preAuthRoutes.contains(loc) ? null : '/language-select';
      }
      if (!authed) {
        return _authRoutes.contains(loc) ? null : '/login';
      }
      if (_preAuthRoutes.contains(loc) || _authRoutes.contains(loc) || loc == '/splash') {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/language-select', pageBuilder: (context, state) => _fadeSlidePage(const LanguageSelectScreen(), state)),
      GoRoute(path: '/onboarding', pageBuilder: (context, state) => _fadeSlidePage(const OnboardingScreen(), state)),
      GoRoute(path: '/login', pageBuilder: (context, state) => _fadeSlidePage(const LoginScreen(), state)),
      GoRoute(path: '/signup', pageBuilder: (context, state) => _fadeSlidePage(const SignUpScreen(), state)),
      GoRoute(
        path: '/verify-email',
        pageBuilder: (context, state) => _fadeSlidePage(VerifyEmailScreen(email: state.uri.queryParameters['email'] ?? ''), state),
      ),
      GoRoute(path: '/forgot-password', pageBuilder: (context, state) => _fadeSlidePage(const ForgotPasswordScreen(), state)),

      // Root-level full-screen modal, outside the tab shell (matches RN's
      // LiveVoiceScreen presented as a root-stack fullScreenModal).
      GoRoute(
        path: '/live-voice',
        pageBuilder: (context, state) => const MaterialPage(
          fullscreenDialog: true,
          child: LiveVoiceScreen(),
        ),
      ),

      GoRoute(
        path: '/focus',
        pageBuilder: (context, state) => _fadeSlidePage(const FocusScreen(), state),
      ),

      GoRoute(
        path: '/insights',
        pageBuilder: (context, state) => _fadeSlidePage(const InsightsScreen(), state),
      ),

      // Milliy Sertifikat skill tree -- top-level, outside the tab shell, so
      // the whole flow (subject picker, path, lesson) is a fully immersive
      // experience with no bottom nav, matching Duolingo's lesson flow.
      GoRoute(
        path: '/skills',
        pageBuilder: (context, state) => _fadeSlidePage(const SkillsHubScreen(), state),
        routes: [
          GoRoute(
            path: 'path',
            pageBuilder: (context, state) => _fadeSlidePage(SkillPathScreen(subject: state.extra as SkillSubject), state),
          ),
          GoRoute(
            path: 'lesson',
            pageBuilder: (context, state) => _fadeSlidePage(SkillLessonScreen(lesson: state.extra as SkillTreeLesson), state),
          ),
          GoRoute(
            path: 'practice',
            pageBuilder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              return _fadeSlidePage(SkillPracticeScreen(mode: extra['mode'] as PracticeMode), state);
            },
          ),
          GoRoute(
            path: 'marathon',
            pageBuilder: (context, state) {
              final s = state.extra as SkillSubject;
              return _fadeSlidePage(SkillPracticeScreen(mode: PracticeMode.marathon, subjectSlug: s.slug, subjectName: s.nameUz), state);
            },
          ),
          GoRoute(
            path: 'mock',
            pageBuilder: (context, state) => _fadeSlidePage(MockExamScreen(subject: state.extra as SkillSubject), state),
          ),
          GoRoute(path: 'classes', pageBuilder: (context, state) => _fadeSlidePage(const ClassModeScreen(), state)),
          GoRoute(path: 'parent', pageBuilder: (context, state) => _fadeSlidePage(const ParentDashboardScreen(), state)),
          GoRoute(path: 'profile', pageBuilder: (context, state) => _fadeSlidePage(const SkillProfileScreen(), state)),
          GoRoute(path: 'leaderboard', pageBuilder: (context, state) => _fadeSlidePage(const SkillLeaderboardScreen(), state)),
          GoRoute(path: 'achievements', pageBuilder: (context, state) => _fadeSlidePage(const SkillAchievementsScreen(), state)),
          GoRoute(path: 'referral', pageBuilder: (context, state) => _fadeSlidePage(const SkillReferralScreen(), state)),
        ],
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (context, state) => const DashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/chat', builder: (context, state) => const ChatScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/assistant', builder: (context, state) => const AssistantScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/files', builder: (context, state) => const KnowledgeBaseScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/quiz',
              builder: (context, state) => const QuizHomeScreen(),
              routes: [
                GoRoute(
                  path: 'session',
                  pageBuilder: (context, state) {
                    final extra = state.extra as Map<String, dynamic>;
                    return _fadeSlidePage(
                      QuizSessionScreen(
                        questions: extra['questions'] as List<QuizQuestion>,
                        difficulty: extra['difficulty'] as String,
                        language: extra['language'] as String,
                        reviewItemId: extra['reviewItemId'] as int?,
                      ),
                      state,
                    );
                  },
                ),
                GoRoute(
                  path: 'result',
                  pageBuilder: (context, state) {
                    final extra = state.extra as Map<String, dynamic>;
                    return _fadeSlidePage(
                      QuizResultScreen(
                        score: extra['score'] as int,
                        total: extra['total'] as int,
                        results: extra['results'] as List<QuizResultItem>,
                      ),
                      state,
                    );
                  },
                ),
                GoRoute(path: 'stats', pageBuilder: (context, state) => _fadeSlidePage(const QuizStatsScreen(), state)),
                GoRoute(path: 'flashcards', pageBuilder: (context, state) => _fadeSlidePage(const FlashcardScreen(), state)),
                GoRoute(path: 'review', pageBuilder: (context, state) => _fadeSlidePage(const ReviewScreen(), state)),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
              routes: [
                GoRoute(path: 'subscription', pageBuilder: (context, state) => _fadeSlidePage(const SubscriptionScreen(), state)),
                GoRoute(path: 'learning-plan', pageBuilder: (context, state) => _fadeSlidePage(const LearningPlanScreen(), state)),
                GoRoute(path: 'gaps', pageBuilder: (context, state) => _fadeSlidePage(const GapsReportScreen(), state)),
                GoRoute(path: 'telegram', pageBuilder: (context, state) => _fadeSlidePage(const TelegramScreen(), state)),
                GoRoute(path: 'feedback', pageBuilder: (context, state) => _fadeSlidePage(const FeedbackScreen(), state)),
                GoRoute(
                  path: 'college',
                  pageBuilder: (context, state) => _fadeSlidePage(const CollegeListScreen(), state),
                  routes: [
                    GoRoute(
                      path: ':id',
                      pageBuilder: (context, state) => _fadeSlidePage(CollegeDetailScreen(id: state.pathParameters['id']!), state),
                    ),
                  ],
                ),
                GoRoute(path: 'math-solver', pageBuilder: (context, state) => _fadeSlidePage(const MathSolverScreen(), state)),
                GoRoute(path: 'settings', pageBuilder: (context, state) => _fadeSlidePage(const SettingsScreen(), state)),
              ],
            ),
          ]),
        ],
      ),
    ],
  );
});
