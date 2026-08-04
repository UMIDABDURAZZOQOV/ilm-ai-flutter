import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/onboarding_illustration.dart';

/// Ported from ilm-ai-mobile's OnboardingScreen.tsx: swipeable PageView
/// carousel with custom illustrations per slide.
const _slides = [
  (IllustrationVariant.materials, 'onboarding.step1.title', 'onboarding.step1.desc'),
  (IllustrationVariant.chat, 'onboarding.step2.title', 'onboarding.step2.desc'),
  (IllustrationVariant.quiz, 'onboarding.step7.title', 'onboarding.step7.desc'),   // SAT
  (IllustrationVariant.plan, 'onboarding.step8.title', 'onboarding.step8.desc'),   // Milliy Sertifikat
  (IllustrationVariant.math, 'onboarding.step5.title', 'onboarding.step5.desc'),
  (IllustrationVariant.quiz, 'onboarding.step3.title', 'onboarding.step3.desc'),
  (IllustrationVariant.plan, 'onboarding.step4.title', 'onboarding.step4.desc'),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

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
    if (_index == _slides.length - 1) {
      _complete();
      return;
    }
    _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final language = ref.watch(languageProvider);
    final isLast = _index == _slides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _complete,
                child: Text(t('onboarding.skip', language), style: TextStyle(color: colors.textMuted)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  final (variant, titleKey, descKey) = _slides[i];
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
                        Text(t(titleKey, language), textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: colors.text)),
                        const SizedBox(height: 10),
                        Text(t(descKey, language), textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: colors.textSecondary, height: 1.4)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _slides.length; i++)
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
                child: Text(isLast ? t('onboarding.getstarted', language) : t('onboarding.next', language)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
