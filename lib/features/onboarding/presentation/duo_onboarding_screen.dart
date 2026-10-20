import '../../../core/widgets/motion.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/product_mode.dart';
import '../../../core/network/error_message.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/duo_chrome.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/mascot_image.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/data/auth_repository.dart';
import '../data/onboarding_draft.dart';
import '../../skills/presentation/daily_goal_bottom_sheet.dart';
import '../../skills/application/learning_preferences.dart';
import '../../skills/presentation/skill_ui.dart';
import '../../skills/presentation/subject_home_screen.dart';

class DuoOnboardingScreen extends ConsumerStatefulWidget {
  final int initialStep;
  final VoidCallback? onBackToWelcome;
  const DuoOnboardingScreen({
    super.key,
    this.initialStep = 0,
    this.onBackToWelcome,
  });

  @override
  ConsumerState<DuoOnboardingScreen> createState() =>
      _DuoOnboardingScreenState();
}

class _DuoOnboardingScreenState extends ConsumerState<DuoOnboardingScreen> {
  late int _step;
  String? _selectedSubject;
  String? _selectedClass = 'all';
  String? _selectedSource;
  int? _selectedLevel;
  final Set<String> _selectedReasons = {};
  int? _selectedDailyGoal;
  late OnboardingDraftStore _drafts;
  int? _draftUser;

  Map<String, dynamic> get _draft => {
    'step': _step, 'subject': _selectedSubject, 'class': _selectedClass,
    'source': _selectedSource, 'level': _selectedLevel,
    'reason': _selectedReasons.join(','), 'daily_goal': _selectedDailyGoal,
    'name': _nameController.text, 'age': _ageController.text,
    'completed': _step == 12,
  };

  void _persist() { unawaited(_drafts.save(_draftUser, _draft).catchError((Object _) {})); }
  void _change(VoidCallback change) { setState(change); _persist(); }


  final _nameController = TextEditingController();
  final _ageController = TextEditingController();

  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _drafts = OnboardingDraftStore(ref.read(prefsServiceProvider));
    _draftUser = ref.read(currentUserIdProvider);
    final draft = _drafts.read(_draftUser);
    _step = (draft?['step'] as int? ?? (_draftUser == null ? widget.initialStep : 11)).clamp(0, 11);
    _selectedSubject = draft?['subject'] as String?;
    _selectedClass = draft?['class'] as String? ?? 'all';
    _selectedSource = draft?['source'] as String?;
    _selectedLevel = draft?['level'] as int?;
    _selectedDailyGoal = draft?['daily_goal'] as int?;
    _selectedReasons.addAll((draft?['reason'] as String? ?? '').split(',').where((s) => s.isNotEmpty));
    _nameController.text = draft?['name'] as String? ?? '';
    _ageController.text = '${draft?['age'] ?? ''}';
    _nameController.addListener(_persist);
    _ageController.addListener(_persist);
    final authName =
        ref.read(authControllerProvider).valueOrNull?.name?.trim() ?? '';
    if (authName.isNotEmpty && _nameController.text.isEmpty) {
      _nameController.text = authName;
    }
    ref.listenManual(authControllerProvider, (_, next) {
      final name = next.valueOrNull?.name?.trim() ?? '';
      if (name.isNotEmpty && _nameController.text.isEmpty) {
        _nameController.text = name;
        if (mounted) _change(() {});
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _onBack() {
    if (_step <= widget.initialStep && widget.onBackToWelcome != null) {
      widget.onBackToWelcome!();
      return;
    }
    if (_step > 0 && _step < 12) {
      _change(() {
        _error = null;
        _step--;
      });
    }
  }

  bool get _isContinueEnabled {
    if (_submitting) return false;
    switch (_step) {
      case 0: // Language selection
        return true;
      case 1: // Hello Ilmo
        return true;
      case 2: // Intro questions
        return true;
      case 3: // Subject selection
        return _selectedSubject != null;
      case 4: // Source
        return _selectedSource != null;
      case 5: // Level (Bilim darajasi)
        return _selectedLevel != null;
      case 6: // Oraliq 1 (Ishonch)
        return true;
      case 7: // Reasons (Sabab - multi-select)
        return _selectedReasons.isNotEmpty;
      case 8: // Oraliq 2 (Sur'at)
        return true;
      case 9: // Daily goal (Kunlik maqsad)
        return _selectedDailyGoal != null;
      case 10: // Roadmap (Natija ekrani)
        return true;
      case 11: // Name + Age
        final name = _nameController.text.trim();
        final age = int.tryParse(_ageController.text.trim());
        return name.length >= 2 && age != null && age >= 5 && age <= 100;
      case 12: // Loading
        return false;
      default:
        return false;
    }
  }

  Future<void> _handleContinue() async {
    final lang = ref.read(languageProvider);
    if (_step == 11) {
      await _submitProfile(lang);
      return;
    }

    if (_step < 11) {
      _change(() {
        _error = null;
        _step++;
      });
    }
  }

  Future<void> _submitProfile(String lang) async {
    final name = _nameController.text.trim();
    final age = int.tryParse(_ageController.text.trim());

    if (name.length < 2) {
      _change(() => _error = str3(
            lang,
            'Ismingizni kiriting.',
            'Введите имя.',
            'Please enter your name.',
          ));
      return;
    }
    if (age == null || age < 5 || age > 100) {
      _change(() => _error = str3(
            lang,
            "Yoshingizni to'g'ri kiriting (5–100).",
            'Введите корректный возраст (5–100).',
            'Enter a valid age (5–100).',
          ));
      return;
    }

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      final prefs = ref.read(prefsServiceProvider);
      if (_selectedSubject != null) {
        await prefs.setString('subject_guest', _selectedSubject!);
        ref.read(selectedSubjectProvider.notifier).state = _selectedSubject;
      }
      if (_selectedSource != null) {
        await prefs.setString('source_guest', _selectedSource!);
      }
      if (_selectedClass != null) {
        await prefs.setString('class_guest', _selectedClass!);
      }
      if (_selectedLevel != null) {
        await prefs.setInt('level_guest', _selectedLevel!);
      }
      if (_selectedReasons.isNotEmpty) {
        await prefs.setString('reason_guest', _selectedReasons.join(','));
      }
      if (_selectedDailyGoal != null) {
        await prefs.setInt('daily_goal_guest', _selectedDailyGoal!);
        ref.read(userDailyGoalProvider.notifier).state = _selectedDailyGoal!;
      }

      _change(() {
        _step = 12;
      });
      _finishOnboarding(0);
      return;
    }

    _change(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .completeOnboarding(userId: userId, name: name, age: age);


      // Persist user-keyed preferences
      final prefs = ref.read(prefsServiceProvider);
      if (_selectedSubject != null) {
        await prefs.setString('subject_$userId', _selectedSubject!);
        ref.read(selectedSubjectProvider.notifier).state = _selectedSubject;
      }
      if (_selectedClass != null) {
        await prefs.setString('class_$userId', _selectedClass!);
      }
      if (_selectedDailyGoal != null) {
        await saveDailyGoal(ref, _selectedDailyGoal!);
      }

      if (_selectedSource != null) {
        await prefs.setString('source_$userId', _selectedSource!);
      }
      if (_selectedLevel != null) {
        await prefs.setInt('level_$userId', _selectedLevel!);
      }
      if (_selectedReasons.isNotEmpty) {
        await prefs.setString('reason_$userId', _selectedReasons.join(','));
      }
      await ref.read(learningPreferencesProvider).save(userId, {});
      await prefs.setBool('onboarding_completed_$userId', true);


      if (mounted) {
        _change(() {
          _submitting = false;
          _step = 12;
        });
        _finishOnboarding(userId);
      }
    } catch (e) {
      if (mounted) {
        _change(() {
          _submitting = false;
          _error = extractError(e, language: ref.read(languageProvider));
        });
      }
    }
  }

  void _finishOnboarding(int userId) {
    Future<void>.delayed(const Duration(milliseconds: 650), () async {
      if (!mounted) return;
      if (userId == 0) {
        ref.read(onboardingCompleteProvider.notifier).complete();
        if (mounted) GoRouter.maybeOf(context)?.go('/login');
      } else {
        await _drafts.clear(userId);
        if (!mounted) return;
        await ref.read(authControllerProvider.notifier).markProfileComplete(_nameController.text.trim(), userId: userId);
        if (mounted) GoRouter.maybeOf(context)?.go(subjectsOnly ? '/learn' : '/home');
      }
    });
  }

  double _calculateProgress(int step) {
    switch (step) {
      case 3: // Savol 1: Fan
        return 1.0 / 6.0;
      case 4: // Savol 2: Manba
        return 2.0 / 6.0;
      case 5: // Savol 3: Daraja (Bilim darajasi)
        return 3.0 / 6.0;
      case 6: // Oraliq 1 (Ishonch)
        return 3.3 / 6.0;
      case 7: // Savol 4: Sabab (ko'p tanlov)
        return 4.0 / 6.0;
      case 8: // Oraliq 2 (Sur'at)
        return 4.3 / 6.0;
      case 9: // Savol 5: Kunlik maqsad
        return 5.0 / 6.0;
      case 10: // Oraliq 3 (Natija ekrani)
        return 5.5 / 6.0;
      case 11: // Savol 6: Ism va Yosh
        return 1.0;
      default:
        return 0.0;
    }
  }

  String _getContinueButtonText(String lang) {
    if (_submitting) {
      return str3(lang, 'Yuklanmoqda...', 'Загрузка...', 'Loading...');
    }
    if (_step == 9) {
      return str3(lang, 'MAQSADGA KETDIK', 'ИДТИ К ЦЕЛИ', 'SET GOAL');
    }
    return str3(lang, 'Davom etish', 'Продолжить', 'Continue');
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final colors = Theme.of(context).extension<AppColors>()!.colors;

    final showProgressBar = _step >= 3 && _step < 12;
    final progressValue = showProgressBar ? _calculateProgress(_step) : 0.0;

    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _onBack();
      },
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: _step == 12
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: SafeArea(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded, size: 26),
                          color: _step > 0 ? colors.text : Colors.transparent,
                          onPressed: _step > 0 ? _onBack : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: showProgressBar
                              ? DuoProgressBar(
                                  value: progressValue,
                                  color: BrandPalette.indigo,
                                )
                              : const SizedBox.shrink(),
                        ),
                        if ({4, 5, 7, 9}.contains(_step))
                          TextButton(
                            onPressed: _submitting ? null : () => _change(() { _step++; _error = null; }),
                            child: Text(str3(lang, 'O‘tkazish', 'Пропустить', 'Skip')),
                          )
                        else const SizedBox(width: 48),
                      ],
                    ),
                  ),
                ),
              ),
        body: Column(
          children: [
            Expanded(
              child: AnimatedSwitcher(
                duration: motionDuration(context, 250),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.04, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      )),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<int>(_step),
                  child: !{1, 2, 6, 8}.contains(_step) ? _buildCurrentStep(lang) : LayoutBuilder(builder: (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: _buildCurrentStep(lang)),
                  )),
                ),
              ),
            ),
            if (_step < 12)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Duo3DButton(
                    key: const ValueKey('onboarding_continue_btn'),
                    color: BrandPalette.indigo,
                    onPressed: _isContinueEnabled ? _handleContinue : null,
                    child: Text(_getContinueButtonText(lang)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep(String lang) {
    switch (_step) {
      case 0:
        return _buildStep0Language(lang);
      case 1:
        return _buildStep1Greeting(lang);
      case 2:
        return _buildStep2QuestionsIntro(lang);
      case 3:
        return _buildStep3Subject(lang);
      case 4:
        return _buildStep4Source(lang);
      case 5:
        return _buildStep5Level(lang);
      case 6:
        return _buildStep6Confidence(lang);
      case 7:
        return _buildStep7Reason(lang);
      case 8:
        return _buildStep8Pace(lang);
      case 9:
        return _buildStep9DailyGoal(lang);
      case 10:
        return _buildStep10Roadmap(lang);
      case 11:
        return _buildStep11NameAndAge(lang);
      case 12:
        return _buildStep12Loading(lang);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep0Language(String lang) {
    return _StepContainer(
      mascotPose: MascotPose.hello,
      speechText: str3(
        lang,
        "Qaysi tilda o'rganishni xohlaysiz?",
        'На каком языке вы хотите учиться?',
        'Which language do you want to learn in?',
      ),
      children: [
        _SelectionTile(
          title: "O'zbekcha",
          subtitle: "O'zbek tili",
          isSelected: lang == 'uz',
          leading: const Text('🇺🇿', style: TextStyle(fontSize: 28)),
          onTap: () {
            ref.read(languageProvider.notifier).setLanguage('uz');
            _change(() {});
          },
        ),
        const SizedBox(height: 12),
        _SelectionTile(
          title: 'Русский',
          subtitle: 'Русский язык',
          isSelected: lang == 'ru',
          leading: const Text('🇷🇺', style: TextStyle(fontSize: 28)),
          onTap: () {
            ref.read(languageProvider.notifier).setLanguage('ru');
            _change(() {});
          },
        ),
        const SizedBox(height: 12),
        _SelectionTile(
          title: 'English',
          subtitle: 'English language',
          isSelected: lang == 'en',
          leading: const Text('🇬🇧', style: TextStyle(fontSize: 28)),
          onTap: () {
            ref.read(languageProvider.notifier).setLanguage('en');
            _change(() {});
          },
        ),
      ],
    );
  }

  Widget _buildStep1Greeting(String lang) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DuoSpeechBubble(
              pointerDirection: BubblePointerDirection.down,
              text: str3(
                lang,
                'Salom! Men Ilmoman',
                'Привет! Я Ильмо',
                "Hello! I'm Ilmo",
              ),
              textStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                height: 1.3,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            )
                .motion(context)
                .fadeIn(duration: 350.ms, delay: 100.ms)
                .slideY(begin: 0.12, end: 0, curve: Curves.easeOutQuad),
            const SizedBox(height: 18),
            (MascotImage(
              pose: MascotPose.hello,
              size: 140,
            ) as Widget)
                .motion(context)
                .scale(
                  begin: const Offset(0.35, 0.35),
                  end: const Offset(1.0, 1.0),
                  curve: Curves.easeOutBack,
                  duration: 450.ms,
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2QuestionsIntro(String lang) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;

    InlineSpan buildSpan() {
      if (lang == 'ru') {
        return TextSpan(
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.text,
            height: 1.35,
          ),
          children: const [
            TextSpan(text: 'Ответьте на '),
            TextSpan(
              text: '6 коротких вопросов',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            TextSpan(text: ' — и начнем первый урок!'),
          ],
        );
      } else if (lang == 'en') {
        return TextSpan(
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.text,
            height: 1.35,
          ),
          children: const [
            TextSpan(text: 'Answer '),
            TextSpan(
              text: '6 quick questions',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            TextSpan(text: " — and let's start the first lesson!"),
          ],
        );
      } else {
        return TextSpan(
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.text,
            height: 1.35,
          ),
          children: const [
            TextSpan(
              text: '6 ta qisqa savolga',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            TextSpan(text: ' javob bering — va birinchi darsni boshlaymiz!'),
          ],
        );
      }
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DuoSpeechBubble(
              pointerDirection: BubblePointerDirection.down,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              child: Text.rich(buildSpan()),
            ),
            const SizedBox(height: 18),
            const MascotImage(
              pose: MascotPose.explaining,
              size: 140,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(button: true, selected: isSelected, child: InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? BrandPalette.turquoise.withValues(alpha: 0.2)
                  : BrandPalette.turquoise.withValues(alpha: 0.12))
              : colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? BrandPalette.turquoise : colors.border,
            width: isSelected ? 2.0 : 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? (isDark ? Colors.white : const Color(0xFF0F766E))
                : colors.textSecondary,
          ),
        ),
      ),
    ));
  }

  Widget _buildStep3Subject(String lang) {
    final catalogAsync = ref.watch(subjectCatalogProvider);
    final colors = Theme.of(context).extension<AppColors>()!.colors;

    return _StepContainer(
      mascotPose: MascotPose.thinking,
      speechText: str3(
        lang,
        "Qaysi fanni o'rganmoqchisiz?",
        'Какой предмет вы хотите изучать?',
        'Which subject do you want to learn?',
      ),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildClassChip(
                label: str3(lang, 'Barchasi', 'Все', 'All'),
                isSelected: _selectedClass == 'all',
                onTap: () => _change(() => _selectedClass = 'all'),
              ),
              for (int grade = 1; grade <= 11; grade++) ...[
                const SizedBox(width: 8),
                _buildClassChip(
                  label: str3(lang, '$grade-sinf', '$grade класс', 'Grade $grade'),
                  isSelected: _selectedClass == '$grade',
                  onTap: () => _change(() => _selectedClass = '$grade'),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(str3(lang,
          'Sinfingiz profil uchun saqlanadi. Darslar umumiy fan yo‘lida ko‘rsatiladi.',
          'Класс сохраняется в профиле. Уроки пока идут по общему пути предмета.',
          'Your grade is saved in your profile. Lessons currently follow the shared subject path.'),
          style: TextStyle(fontSize: 12, color: colors.textSecondary)),
        const SizedBox(height: 16),
        catalogAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 3.5,
                valueColor: AlwaysStoppedAnimation(BrandPalette.indigo),
              ),
            ),
          ),
          error: (_, _) => Column(
            children: [
              Text(
                str3(
                  lang,
                  "Fanlarni yuklab bo'lmadi",
                  'Не удалось загрузить предметы',
                  'Could not load subjects',
                ),
                style: TextStyle(color: colors.error),
              ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: () => ref.invalidate(subjectCatalogProvider),
                child: Text(
                  str3(lang, 'Qayta urinish', 'Повторить', 'Retry'),
                ),
              ),
            ],
          ),
          data: (subjects) {
            return Column(
              children: [
                for (final item in subjects) ...[
                  _SelectionTile(
                    title: item.nameFor(lang),
                    isSelected: _selectedSubject == item.slug,
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor:
                          skillColor(item.color).withValues(alpha: 0.15),
                      child: Icon(
                        _getSubjectIcon(item.icon),
                        color: skillColor(item.color),
                        size: 22,
                      ),
                    ),
                    onTap: () {
                      _change(() => _selectedSubject = item.slug);
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStep4Source(String lang) {
    final sources = [
      (
        'friends',
        str3(lang, "Do'stlar yoki yaqinlar", 'Друзья или близкие',
            'Friends or family'),
      ),
      (
        'social',
        'Instagram / Facebook',
      ),
      (
        'tiktok',
        'TikTok',
      ),
      (
        'telegram',
        'Telegram',
      ),
      (
        'youtube',
        'YouTube',
      ),
      (
        'store',
        str3(lang, "Ilovalar do'koni", 'Магазин приложений', 'App store'),
      ),
      (
        'school',
        str3(lang, "Maktab / o'qituvchi", 'Школа / учитель', 'School / teacher'),
      ),
      (
        'other',
        str3(lang, 'Boshqa', 'Другое', 'Other'),
      ),
    ];

    return _StepContainer(
      mascotPose: MascotPose.thinking,
      speechText: str3(
        lang,
        'Ilmo haqida qayerdan bildingiz?',
        'Как вы узнали про Ильмо?',
        'How did you hear about Ilmo?',
      ),
      children: [
        for (final item in sources) ...[
          _SelectionTile(
            title: item.$2,
            isSelected: _selectedSource == item.$1,
            onTap: () {
              _change(() => _selectedSource = item.$1);
            },
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildStep5Level(String lang) {
    final levels = [
      (
        1,
        str3(lang, 'Yangi boshlovchi', 'Новичок', 'Beginner'),
        str3(lang, "Oldin bu fanni o'rganmaganman", 'Раньше не изучал предмет',
            'Never studied this subject before')
      ),
      (
        2,
        str3(lang, 'Asoslarini bilaman', 'Знаю основы', 'Know the basics'),
        str3(lang, 'Oddiy tushunchalarni tushunaman', 'Понимаю простые концепции',
            'Understand basic concepts')
      ),
      (
        3,
        str3(lang, "O'rtacha", 'Средний уровень', 'Intermediate'),
        str3(lang, 'Mustaqil misollar yecha olaman',
            'Могу решать типовые задачи', 'Can solve standard problems')
      ),
      (
        4,
        str3(lang, 'Yaxshi bilaman', 'Хорошо знаю', 'Good understanding'),
        str3(lang, "Murakkab mavzularga tayyorman",
            'Готов к сложным темам', 'Ready for complex topics')
      ),
      (
        5,
        str3(lang, "A'lo", 'Отлично знаю', 'Advanced'),
        str3(lang, 'Eng yuqori natijalar uchun', 'Для максимальных результатов',
            'Aiming for the highest scores')
      ),
    ];

    return _StepContainer(
      mascotPose: MascotPose.explaining,
      speechText: str3(
        lang,
        'Bu fandan qanchalik bilasiz?',
        'Насколько хорошо вы знаете этот предмет?',
        'How well do you know this subject?',
      ),
      children: [
        for (final item in levels) ...[
          _SelectionTile(
            title: item.$2,
            subtitle: item.$3,
            isSelected: _selectedLevel == item.$1,
            leading: _SignalBars(level: item.$1),
            onTap: () {
              _change(() => _selectedLevel = item.$1);
            },
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildStep6Confidence(String lang) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DuoSpeechBubble(
              pointerDirection: BubblePointerDirection.down,
              text: str3(
                lang,
                'Ajoyib! Bilimni mustahkamlaymiz.',
                'Отлично! Закрепим знания.',
                'Awesome! Let\'s reinforce your knowledge.',
              ),
            ),
            const SizedBox(height: 24),
            MascotImage(
              pose: MascotPose.happy,
              size: 140,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep7Reason(String lang) {
    final reasons = [
      (
        'exam',
        str3(lang, 'Imtihonlarga tayyorlanish', 'Подготовка к экзаменам',
            'Exam preparation'),
        Icons.edit_note_rounded,
      ),
      (
        'grades',
        str3(lang, 'Baholarimni yaxshilash', 'Улучшение оценок',
            'Improving my grades'),
        Icons.trending_up_rounded,
      ),
      (
        'self_dev',
        str3(lang, "O'zimni rivojlantirish", 'Саморазвитие',
            'Self-improvement'),
        Icons.psychology_outlined,
      ),
      (
        'olympiad',
        str3(lang, 'Olimpiadaga tayyorlanish', 'Подготовка к олимпиадам',
            'Olympiad preparation'),
        Icons.emoji_events_outlined,
      ),
      (
        'interest',
        str3(lang, 'Qiziqish uchun', 'Ради интереса',
            'Just for curiosity'),
        Icons.lightbulb_outline_rounded,
      ),
      (
        'other',
        str3(lang, 'Boshqa', 'Другое', 'Other'),
        Icons.more_horiz_rounded,
      ),
    ];

    return _StepContainer(
      mascotPose: MascotPose.thinking,
      speechText: str3(
        lang,
        "Nima uchun o'rganasiz?",
        'Зачем вы хотите учиться?',
        'Why are you learning this?',
      ),
      children: [
        Text(
          str3(
            lang,
            'Bir nechta javobni tanlashingiz mumkin:',
            'Можно выбрать несколько вариантов:',
            'You can choose multiple options:',
          ),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).extension<AppColors>()!.colors.textMuted,
          ),
        ),
        const SizedBox(height: 12),
        for (final item in reasons) ...[
          _SelectionTile(
            title: item.$2,
            isMultiSelect: true,
            isSelected: _selectedReasons.contains(item.$1),
            leading: Icon(item.$3, color: BrandPalette.indigo, size: 24),
            onTap: () {
              _change(() {
                if (_selectedReasons.contains(item.$1)) {
                  _selectedReasons.remove(item.$1);
                } else {
                  _selectedReasons.add(item.$1);
                }
              });
            },
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildStep8Pace(String lang) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DuoSpeechBubble(
              pointerDirection: BubblePointerDirection.down,
              text: str3(
                lang,
                'Keling, qanday sur\'atda o\'qishni hal qilaylik!',
                'Давайте решим, в каком темпе будем учиться!',
                'Let\'s decide what pace to learn at!',
              ),
            ),
            const SizedBox(height: 24),
            MascotImage(
              pose: MascotPose.thinking,
              size: 140,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep9DailyGoal(String lang) {
    final goalChoices = [
      (
        10,
        str3(lang, '5 daqiqa / kun', '5 минут в день', '5 min a day'),
        str3(lang, 'Yengil (10 XP)', 'Легкий (10 XP)', 'Casual (10 XP)'),
      ),
      (
        20,
        str3(lang, '10 daqiqa / kun', '10 минут в день', '10 min a day'),
        str3(lang, 'Odatiy (20 XP)', 'Обычный (20 XP)', 'Regular (20 XP)'),
      ),
      (
        30,
        str3(lang, '15 daqiqa / kun', '15 минут в день', '15 min a day'),
        str3(lang, 'Jiddiy (30 XP)', 'Серьезный (30 XP)', 'Serious (30 XP)'),
      ),
      (
        50,
        str3(lang, '20 daqiqa / kun', '20 минут в день', '20 min a day'),
        str3(lang, 'Qattiq (50 XP)', 'Интенсивный (50 XP)', 'Intense (50 XP)'),
      ),
    ];

    return _StepContainer(
      mascotPose: MascotPose.explaining,
      speechText: str3(
        lang,
        'Kunlik maqsadingiz qanday?',
        'Какую цель поставим на день?',
        'What is your daily goal?',
      ),
      children: [
        for (final item in goalChoices) ...[
          _SelectionTile(
            title: item.$2,
            subtitle: item.$3,
            isSelected: _selectedDailyGoal == item.$1,
            leading: Icon(
              Icons.bolt_rounded,
              color: _selectedDailyGoal == item.$1
                  ? BrandPalette.accentOrange
                  : Colors.grey,
              size: 26,
            ),
            onTap: () {
              _change(() => _selectedDailyGoal = item.$1);
            },
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildStep10Roadmap(String lang) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items = [
      (
        Icons.menu_book_rounded,
        BrandPalette.indigo,
        str3(lang, 'Mavzuni chuqur tushunish', 'Глубокое понимание тем',
            'Deep topic understanding'),
        str3(
          lang,
          "Har bir mavzu va tushunchaning mohiyatini anglash",
          'Понимание сути каждого правила и концепта',
          'Mastering the essence of every concept',
        ),
      ),
      (
        Icons.verified_rounded,
        BrandPalette.turquoise,
        str3(lang, 'Imtihonga ishonch bilan tayyorgarlik',
            'Уверенная подготовка к экзаменам', 'Confident exam preparation'),
        str3(
          lang,
          "Murakkab misol va testlarni xatosiz yechish",
          'Решение сложных заданий без лишнего стресса',
          'Tackling tricky questions with confidence',
        ),
      ),
      (
        Icons.alarm_on_rounded,
        BrandPalette.accentOrange,
        str3(lang, "Muntazam o'qish odati", 'Привычка учиться регулярно',
            'Consistent daily study habit'),
        str3(
          lang,
          "Har kuni qulay va qiziqarli darslar",
          'Умные напоминания и увлекательные уроки',
          'Smart reminders and engaging lessons',
        ),
      ),
    ];

    return _StepContainer(
      mascotPose: MascotPose.happy,
      speechText: str3(
        lang,
        'Mana nimaga erishasiz!',
        'Вот чего можно достичь!',
        'Here is what you will achieve!',
      ),
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          decoration: BoxDecoration(
            color: isDark ? BrandPalette.indigoDarkCard : colors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? BrandPalette.indigoDarkSurface : colors.border,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: items[i].$2.withValues(alpha: 0.16),
                      child: Icon(items[i].$1, color: items[i].$2, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            items[i].$3,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: colors.text,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            items[i].$4,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: colors.textSecondary,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (i < items.length - 1) const Divider(height: 28),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep11NameAndAge(String lang) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;

    return _StepContainer(
      mascotPose: MascotPose.hello,
      speechText: str3(
        lang,
        'O\'zingiz haqingizda ayting',
        'Расскажите немного о себе',
        'Tell us a bit about you',
      ),
      children: [
        ErrorBanner(
          message: _error,
          onDismiss: () => _change(() => _error = null),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.border, width: 2),
          ),
          child: Column(
            children: [
              AppTextField(
                controller: _nameController,
                hint: str3(lang, 'Ism yoki taxallus', 'Имя или никнейм',
                    'Name or nickname'),
                prefixIcon: Icon(Icons.person_outline,
                    color: colors.textMuted, size: 22),
                onChanged: (_) => _change(() {}),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _ageController,
                hint: str3(lang, 'Yoshingiz (5–100)', 'Ваш возраст (5–100)',
                    'Your age (5–100)'),
                keyboardType: TextInputType.number,
                prefixIcon: Icon(Icons.cake_outlined,
                    color: colors.textMuted, size: 22),
                onChanged: (_) => _change(() {}),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep12Loading(String lang) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              (MascotImage(pose: MascotPose.happy, size: 128) as Widget)
                  .motion(context, onPlay: (controller) => controller.repeat(reverse: true))
                  .scale(
                    begin: const Offset(0.96, 0.96),
                    end: const Offset(1.04, 1.04),
                    duration: 1200.ms,
                    curve: Curves.easeInOut,
                  ),
              const SizedBox(height: 28),
              Text(
                str3(
                  lang,
                  'TAYYOR!',
                  'ГОТОВО!',
                  'READY!',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 24),
              const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 48),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark
                      ? BrandPalette.indigoDarkCard
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? BrandPalette.indigoDarkSurface
                        : const Color(0xFFE5E7EB),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lightbulb_outline_rounded,
                      color: BrandPalette.accentOrange,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        str3(
                          lang,
                          'Har kuni kichik qadam, katta natija.',
                          'Каждый день — маленький шаг, большой результат.',
                          'Small steps every day lead to big results.',
                        ),
                        textAlign: TextAlign.left,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: colors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }

  IconData _getSubjectIcon(String? iconName) {
    switch (iconName?.toLowerCase()) {
      case 'math':
      case 'calculator':
        return Icons.calculate_outlined;
      case 'physics':
        return Icons.bolt_outlined;
      case 'chemistry':
        return Icons.science_outlined;
      case 'biology':
        return Icons.biotech_outlined;
      case 'history':
        return Icons.menu_book_outlined;
      case 'english':
      case 'language':
        return Icons.translate_rounded;
      default:
        return Icons.school_outlined;
    }
  }
}

class _StepContainer extends StatelessWidget {
  final MascotPose mascotPose;
  final String speechText;
  final List<Widget> children;

  const _StepContainer({
    required this.mascotPose,
    required this.speechText,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        _MascotSpeechHeader(
          pose: mascotPose,
          text: speechText,
        ),
        const SizedBox(height: 24),
        ...children,
      ],
    );
  }
}

class _MascotSpeechHeader extends StatelessWidget {
  final MascotPose pose;
  final String text;

  const _MascotSpeechHeader({
    required this.pose,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        MascotImage(pose: pose, size: 88),
        const SizedBox(width: 8),
        Expanded(
          child: DuoSpeechBubble(
            pointerDirection: BubblePointerDirection.left,
            text: text,
          ),
        ),
      ],
    );
  }
}

class _SelectionTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isSelected;
  final bool isMultiSelect;
  final Widget? leading;
  final VoidCallback onTap;

  const _SelectionTile({
    required this.title,
    this.subtitle,
    required this.isSelected,
    this.isMultiSelect = false,
    this.leading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final borderColor = isSelected
        ? BrandPalette.turquoise
        : colors.border;
    final bgColor = isSelected
        ? (isDark
            ? BrandPalette.turquoise.withValues(alpha: 0.16)
            : BrandPalette.turquoise.withValues(alpha: 0.10))
        : (isDark ? BrandPalette.indigoDarkCard : colors.card);
    final shadowColor = isSelected
        ? const Color(0xFF0D9488)
        : (isDark ? Colors.black26 : const Color(0xFFE5E2F2));

    return Semantics(button: true, selected: isSelected, child: InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2.4 : 1.8,
          ),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              offset: const Offset(0, 3.5),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? (isDark ? Colors.white : const Color(0xFF0F766E))
                          : colors.text,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (isMultiSelect)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? BrandPalette.turquoise : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: isSelected ? BrandPalette.turquoise : colors.textMuted,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: isSelected
                    ? const Icon(
                        Icons.check_rounded,
                        color: BrandPalette.indigo,
                        size: 18,
                      )
                    : null,
              )
            else if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: BrandPalette.turquoise,
                size: 24,
              ),
          ],
        ),
      ),
    ));
  }
}

class _SignalBars extends StatelessWidget {
  final int level;
  const _SignalBars({required this.level});

  @override
  Widget build(BuildContext context) {
    // 4 rising columns (bars)
    final heights = [7.0, 12.0, 17.0, 22.0];
    final activeCount = (level - 1).clamp(0, 4);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor =
        isDark ? const Color(0xFF374151) : const Color(0xFFD1D5DB);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (int i = 0; i < 4; i++) ...[
          Container(
            width: 5.0,
            height: heights[i],
            decoration: BoxDecoration(
              color: i < activeCount
                  ? BrandPalette.turquoise
                  : inactiveColor,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          if (i < 3) const SizedBox(width: 3.0),
        ],
      ],
    );
  }
}
