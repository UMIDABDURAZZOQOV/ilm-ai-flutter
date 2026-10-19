import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/config/product_mode.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/duo_chrome.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/mascot_image.dart';
import '../../../core/widgets/onboarding_illustration.dart';
import '../../skills/presentation/skill_ui.dart';
import 'duo_onboarding_screen.dart';

/// Ported from ilm-ai-mobile's OnboardingScreen.tsx: swipeable PageView
/// carousel with custom illustrations per slide.
const _slides = [
  (
    IllustrationVariant.materials,
    'onboarding.step1.title',
    'onboarding.step1.desc',
  ),
  (IllustrationVariant.chat, 'onboarding.step2.title', 'onboarding.step2.desc'),
  (
    IllustrationVariant.quiz,
    'onboarding.step7.title',
    'onboarding.step7.desc',
  ), // SAT
  (
    IllustrationVariant.plan,
    'onboarding.step8.title',
    'onboarding.step8.desc',
  ), // Milliy Sertifikat
  (IllustrationVariant.math, 'onboarding.step5.title', 'onboarding.step5.desc'),
  (IllustrationVariant.quiz, 'onboarding.step3.title', 'onboarding.step3.desc'),
  (IllustrationVariant.plan, 'onboarding.step4.title', 'onboarding.step4.desc'),
];

const _subjectSlides = [
  (
    IllustrationVariant.plan,
    'subject.intro.choose',
    'subject.intro.choose.desc',
  ),
  (IllustrationVariant.quiz, 'subject.intro.learn', 'subject.intro.learn.desc'),
  (IllustrationVariant.plan, 'subject.intro.habit', 'subject.intro.habit.desc'),
];

String _slideText(String key, String lang) {
  const copy = {
    'subject.intro.choose': [
      'Fanlarni oson o‘rganing',
      'Изучайте предметы легко',
      'Make subjects feel simple',
    ],
    'subject.intro.choose.desc': [
      'O‘zingizga qiziq fanni tanlang va bilim yo‘lingizni boshlang.',
      'Выберите интересный предмет и начните свой путь.',
      'Choose a subject you care about and start your learning path.',
    ],
    'subject.intro.learn': [
      'Kichik dars. Katta qadam.',
      'Короткий урок. Большой шаг.',
      'Small lessons. Real progress.',
    ],
    'subject.intro.learn.desc': [
      'Avval tushuning, keyin mashq qiling. Har javobdan yangi narsa o‘rganing.',
      'Разберитесь в теме, затем практикуйтесь. Учитесь с каждым ответом.',
      'Understand the idea, then practise. Learn something from every answer.',
    ],
    'subject.intro.habit': [
      'Har kuni bir qadam',
      'Шаг вперёд каждый день',
      'A little learning every day',
    ],
    'subject.intro.habit.desc': [
      'Kunlik maqsadga erishing, xatolaringizni takrorlang va yutuqlaringizni kuzating.',
      'Достигайте цели дня, повторяйте ошибки и следите за успехами.',
      'Reach your daily goal, review mistakes and celebrate your progress.',
    ],
  };
  return copy[key]?[lang == 'ru'
          ? 1
          : lang == 'en'
          ? 2
          : 0] ??
      t(key, lang);
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _activeSlides = subjectsOnly ? _subjectSlides : _slides;
  final _controller = PageController();
  int _index = 0;
  bool _startedOnboarding = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _complete() {
    ref.read(onboardingCompleteProvider.notifier).complete();
    context.go('/login');
  }

  void _next() {
    if (_index == _activeSlides.length - 1) {
      _complete();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final language = ref.watch(languageProvider);
    if (subjectsOnly) {
      if (_startedOnboarding) {
        return DuoOnboardingScreen(
          initialStep: 1,
          onBackToWelcome: () => setState(() => _startedOnboarding = false),
        );
      }
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      final nextLang = language == 'uz'
                          ? 'ru'
                          : language == 'ru'
                              ? 'en'
                              : 'uz';
                      ref.read(languageProvider.notifier).setLanguage(nextLang);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colors.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colors.border, width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            language == 'ru'
                                ? '🇷🇺 RU'
                                : language == 'en'
                                    ? '🇬🇧 EN'
                                    : '🇺🇿 UZ',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: colors.text,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.keyboard_arrow_down_rounded,
                              size: 18, color: colors.textMuted),
                        ],
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                const MascotImage(pose: MascotPose.hello, size: 140),
                const SizedBox(height: 24),
                Text(
                  'Ilm AI',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  str3(
                    language,
                    'Fanlarni oson o‘rganing. Har doim.',
                    'Учитесь легко. Всегда.',
                    'Learn subjects easily. Always.',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const Spacer(),
                Duo3DButton(
                  key: const ValueKey('welcome_start_btn'),
                  color: BrandPalette.indigo,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    setState(() => _startedOnboarding = true);
                  },
                  child: Text(
                    str3(language, 'BOSHLASH', 'НАЧАТЬ', 'GET STARTED'),
                  ),
                ),
                const SizedBox(height: 14),
                Duo3DButton(
                  key: const ValueKey('welcome_have_account_btn'),
                  color: colors.card,
                  textColor: BrandPalette.indigo,
                  borderColor: colors.border,
                  shadowColor: colors.border,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _complete();
                  },
                  child: Text(
                    str3(
                      language,
                      'MENDA AKKAUNT BOR',
                      'У МЕНЯ УЖЕ ЕСТЬ АККАУНТ',
                      'I ALREADY HAVE AN ACCOUNT',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      );
    }

    final isLast = _index == _activeSlides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _complete,
                child: Text(
                  t('onboarding.skip', language),
                  style: TextStyle(color: colors.textMuted),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _activeSlides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final (variant, titleKey, descKey) = _activeSlides[i];
                  final tint = colors.cardTints[i % colors.cardTints.length];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OnboardingIllustration(
                          variant: variant,
                          size: 190,
                          tintBg: tint.bg,
                          tintBorder: tint.border,
                          accent: colors.primary,
                        ),
                        const SizedBox(height: 32),
                        Text(
                          _slideText(titleKey, language),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: colors.text,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _slideText(descKey, language),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: colors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _activeSlides.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _index ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _index ? colors.primary : colors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              child: GradientButton(
                onPressed: _next,
                child: Text(
                  isLast
                      ? t('onboarding.getstarted', language)
                      : t('onboarding.next', language),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
