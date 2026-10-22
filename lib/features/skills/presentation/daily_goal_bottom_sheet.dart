import '../../../core/widgets/duo_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../application/learning_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/application/auth_controller.dart';
import 'skill_ui.dart';

/// User-specific daily XP goal persisted in SharedPreferences via `daily_goal_<userId>`.
/// Default is 20 XP to match the platform default.
final userDailyGoalProvider = StateProvider<int>((ref) {
  ref.watch(studyRevisionProvider);
  final user = ref.watch(currentUserIdProvider);
  if (user == null) return 20;
  return ref.read(prefsServiceProvider).getInt('daily_goal_$user') ?? 20;
});

Future<void> saveDailyGoal(WidgetRef ref, int goal) async {
  final user = ref.read(currentUserIdProvider);
  if (user != null) {
    await ref.read(learningPreferencesProvider).save(user, {
      'daily_goal_xp': goal,
    });
  }
  if (!ref.context.mounted || ref.read(currentUserIdProvider) != user) return;
  ref.read(userDailyGoalProvider.notifier).state = goal;
}

class DailyGoalOption {
  final int xp;
  final String titleUz;
  final String titleRu;
  final String titleEn;
  final bool recommended;

  const DailyGoalOption({
    required this.xp,
    required this.titleUz,
    required this.titleRu,
    required this.titleEn,
    this.recommended = false,
  });

  String title(String lang) => str3(lang, titleUz, titleRu, titleEn);
}

const dailyGoalOptions = <DailyGoalOption>[
  DailyGoalOption(
    xp: 10,
    titleUz: 'Yengil',
    titleRu: 'Легкий',
    titleEn: 'Casual',
  ),
  DailyGoalOption(
    xp: 20,
    titleUz: 'Oddiy (Tavsiya etiladi)',
    titleRu: 'Обычный (Рекомендуется)',
    titleEn: 'Regular (Recommended)',
    recommended: true,
  ),
  DailyGoalOption(
    xp: 30,
    titleUz: 'Jiddiy',
    titleRu: 'Серьезный',
    titleEn: 'Serious',
  ),
  DailyGoalOption(
    xp: 50,
    titleUz: 'Intensiv',
    titleRu: 'Интенсивный',
    titleEn: 'Intense',
  ),
];

Future<int?> showDailyGoalBottomSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String language,
  Color? accentColor,
}) {
  return showModalBottomSheet<int>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => DailyGoalBottomSheet(
      language: language,
      accentColor:
          accentColor ??
          Theme.of(ctx).extension<AppColors>()?.colors.secondary ??
          const Color(0xFFF9A825),
    ),
  );
}

class DailyGoalBottomSheet extends ConsumerStatefulWidget {
  final String language;
  final Color accentColor;

  const DailyGoalBottomSheet({
    super.key,
    required this.language,
    required this.accentColor,
  });

  @override
  ConsumerState<DailyGoalBottomSheet> createState() =>
      _DailyGoalBottomSheetState();
}

class _DailyGoalBottomSheetState extends ConsumerState<DailyGoalBottomSheet> {
  late int _selectedGoal;
  bool _saving = false;
  bool _saveError = false;

  @override
  void initState() {
    super.initState();
    _selectedGoal = ref.read(userDailyGoalProvider);
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.language;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                str3(lang, 'Kunlik maqsad', 'Цель на день', 'Daily Goal'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                str3(
                  lang,
                  'Har kuni o‘rganish uchun o‘zingizga mos XP maqsadini tanlang.',
                  'Выберите цель по XP для ежедневного обучения.',
                  'Choose a daily XP goal that works best for you.',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              for (final opt in dailyGoalOptions) ...[
                _GoalOptionTile(
                  option: opt,
                  isSelected: _selectedGoal == opt.xp,
                  language: lang,
                  accentColor: widget.accentColor,
                  isDark: isDark,
                  onTap: _saving
                      ? null
                      : () {
                          setState(() => _selectedGoal = opt.xp);
                        },
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 12),
              if (_saveError)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      str3(
                        lang,
                        'Maqsad saqlanmadi. Qayta urinib ko‘ring.',
                        'Не удалось сохранить цель. Повторите попытку.',
                        'Could not save the goal. Please retry.',
                      ),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: widget.accentColor,
                  foregroundColor: foregroundOn(widget.accentColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _saving
                    ? null
                    : () async {
                        final owner = ref.read(currentUserIdProvider);
                        setState(() {
                          _saving = true;
                          _saveError = false;
                        });
                        try {
                          await saveDailyGoal(ref, _selectedGoal);
                          if (context.mounted) {
                            Navigator.of(context).pop(
                              ref.read(currentUserIdProvider) == owner
                                  ? _selectedGoal
                                  : null,
                            );
                          }
                        } catch (_) {
                          if (mounted) setState(() => _saveError = true);
                        } finally {
                          if (mounted) setState(() => _saving = false);
                        }
                      },
                child: Text(
                  str3(lang, 'Saqlash', 'Сохранить', 'Save'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalOptionTile extends StatelessWidget {
  final DailyGoalOption option;
  final bool isSelected;
  final String language;
  final Color accentColor;
  final bool isDark;
  final VoidCallback? onTap;

  const _GoalOptionTile({
    required this.option,
    required this.isSelected,
    required this.language,
    required this.accentColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? accentColor
        : (isDark ? Colors.grey.shade800 : Colors.grey.shade300);
    final bgColor = isSelected
        ? accentColor.withValues(alpha: isDark ? 0.20 : 0.10)
        : (isDark ? Colors.grey.shade900 : Colors.grey.shade50);

    return Semantics(
      button: true,
      selected: isSelected,
      enabled: onTap != null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 2.2 : 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? accentColor.withValues(alpha: 0.2)
                      : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.bolt_rounded,
                  size: 20,
                  color: isSelected ? accentColor : Colors.grey,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${option.xp} XP',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: isSelected ? accentColor : null,
                      ),
                    ),
                    Text(
                      option.title(language),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle_rounded, color: accentColor, size: 22)
              else
                Icon(
                  Icons.radio_button_unchecked,
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
