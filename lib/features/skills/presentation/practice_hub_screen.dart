import 'package:flutter/material.dart';

import '../../../core/config/mobile_release.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/ilm_design.dart';
import '../../../core/widgets/mascot_image.dart';
import 'skill_ui.dart';

/// Practice entry points share the existing callbacks and question sources.
class PracticeHubScreen extends StatelessWidget {
  const PracticeHubScreen({
    super.key,
    required this.language,
    required this.onDaily,
    required this.onMistakes,
    required this.onLightning,
  });

  final String language;
  final VoidCallback onDaily, onMistakes, onLightning;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!.colors;
    String tr(String uz, String ru, String en) => str3(language, uz, ru, en);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(tr('Mashq', 'Практика', 'Practice')),
      ),
      body: IlmReadingWidth(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Text(
              tr(
                'Bilimingizni mustahkamlang',
                'Закрепите знания',
                'Make your knowledge stick',
              ),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              biologyOnly
                  ? tr(
                      'Biologiya bo‘yicha bilimingizni takrorlang va mustahkamlang.',
                      'Повторяйте и закрепляйте знания по биологии.',
                      'Review and strengthen your biology knowledge.',
                    )
                  : tr(
                      'Takrorlash barcha o‘rgangan fanlaringizni qamrab oladi.',
                      'Повторение охватывает все изученные предметы.',
                      'Review covers all the subjects you have studied.',
                    ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Material(
              color: c.primaryLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(IlmRadius.card),
                side: BorderSide(color: c.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                key: const ValueKey('practice_daily'),
                onTap: onDaily,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr(
                                    'Kunlik sinov',
                                    'Вызов дня',
                                    'Daily challenge',
                                  ),
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  tr(
                                    'Bugungi savollar to‘plami',
                                    'Подборка вопросов на сегодня',
                                    'Today’s question set',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (MediaQuery.textScalerOf(context).scale(16) <=
                              20) ...[
                            const SizedBox(width: 12),
                            const MascotImage(
                              pose: MascotPose.thinking,
                              size: 56,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              tr('Boshlash', 'Начать', 'Start'),
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(color: c.primary),
                            ),
                          ),
                          Icon(Icons.arrow_forward_rounded, color: c.primary),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              tr(
                'Boshqa mashqlar',
                'Другие упражнения',
                'More ways to practise',
              ),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            Material(
              color: c.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(IlmRadius.card),
                side: BorderSide(color: c.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _PracticeRow(
                    icon: Icons.auto_fix_high_rounded,
                    title: tr(
                      'Xatolar ustida ishlash',
                      'Работа над ошибками',
                      'Review mistakes',
                    ),
                    subtitle: tr(
                      'Oldingi xatolarni tushunib oling',
                      'Разберитесь с прошлыми ошибками',
                      'Understand your previous mistakes',
                    ),
                    onTap: onMistakes,
                  ),
                  Divider(height: 1, indent: 68, color: c.border),
                  _PracticeRow(
                    icon: Icons.bolt_rounded,
                    title: tr(
                      'Tezlik mashqi',
                      'На скорость',
                      'Lightning practice',
                    ),
                    subtitle: tr(
                      'Qisqa va tezkor takrorlash',
                      'Короткое повторение на время',
                      'A short, timed review',
                    ),
                    onTap: onLightning,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PracticeRow extends StatelessWidget {
  const _PracticeRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: c.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: c.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
