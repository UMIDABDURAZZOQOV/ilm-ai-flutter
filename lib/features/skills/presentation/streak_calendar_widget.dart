import '../../../core/theme/app_theme.dart';
import 'package:flutter/material.dart';

import 'skill_ui.dart';

class StreakCalendarWidget extends StatelessWidget {
  final Map<String, int>? activity;
  final int streakDays;
  final String language;
  final DateTime? targetMonth;

  const StreakCalendarWidget({
    super.key,
    required this.activity,
    required this.streakDays,
    required this.language,
    this.targetMonth,
  });

  String _monthName(int month, String lang) {
    const uz = [
      'Yanvar',
      'Fevral',
      'Mart',
      'Aprel',
      'May',
      'Iyun',
      'Iyul',
      'Avgust',
      'Sentabr',
      'Oktyabr',
      'Noyabr',
      'Dekabr',
    ];
    const ru = [
      'Январь',
      'Февраль',
      'Март',
      'Апрель',
      'Май',
      'Июнь',
      'Июль',
      'Август',
      'Сентябрь',
      'Октябрь',
      'Ноябрь',
      'Декабрь',
    ];
    const en = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final idx = (month - 1).clamp(0, 11);
    switch (lang) {
      case 'ru':
        return ru[idx];
      case 'en':
        return en[idx];
      default:
        return uz[idx];
    }
  }

  List<String> _weekdays(String lang) {
    switch (lang) {
      case 'ru':
        return ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
      case 'en':
        return ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
      default:
        return ['Du', 'Se', 'Cho', 'Pa', 'Ju', 'Sha', 'Ya'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!.colors;
    final now = DateTime.now().toUtc();
    final current = targetMonth ?? now;
    final year = current.year, month = current.month;
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final leadingBlanks = DateTime(year, month, 1).weekday - 1;
    final activeDates = <int>{};
    for (var day = 1; day <= daysInMonth; day++) {
      final key =
          '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      if ((activity?[key] ?? 0) > 0) activeDates.add(day);
    }
    final dayExtent = MediaQuery.textScalerOf(context).scale(13) * 1.6 + 12;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${_monthName(month, language)} $year',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  str3(
                    language,
                    'Faollik kalendari',
                    'Календарь активности',
                    'Activity calendar',
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      color: c.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$streakDays ${str3(language, 'kun', 'дн', 'days')}',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: (dayExtent * 7 + 24).clamp(
                    constraints.maxWidth,
                    double.infinity,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          for (final wd in _weekdays(language))
                            Expanded(
                              child: Center(
                                child: Text(
                                  wd,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: leadingBlanks + daysInMonth,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisExtent: dayExtent,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                        ),
                        itemBuilder: (context, index) {
                          if (index < leadingBlanks) {
                            return const SizedBox.shrink();
                          }
                          final day = index - leadingBlanks + 1;
                          final active = activeDates.contains(day);
                          final today =
                              now.year == year &&
                              now.month == month &&
                              now.day == day;
                          final key =
                              '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
                          return Semantics(
                            label:
                                '$key. ${str3(language, 'Yakunlangan urinishlar', 'Завершено попыток', 'Completed attempts')}: ${activity?[key] ?? 0}',
                            excludeSemantics: true,
                            child: Center(
                              child: Container(
                                width: dayExtent,
                                height: dayExtent,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: active ? c.primary : null,
                                  border: today
                                      ? Border.all(color: c.primary, width: 2)
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '$day',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: today || active
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    color: active
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.onPrimary
                                        : c.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (activity == null || activity!.isEmpty) ...[
              const SizedBox(height: 12),
              Text(
                str3(
                  language,
                  'Bajarilgan darslar shu yerda ko‘rinadi.',
                  'Завершённые уроки появятся здесь.',
                  'Completed lessons will appear here.',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
