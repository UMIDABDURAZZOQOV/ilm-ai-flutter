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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final current = targetMonth ?? now;
    final year = current.year;
    final month = current.month;
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final firstWeekday = DateTime(year, month, 1).weekday; // 1 = Monday
    final leadingBlanks = firstWeekday - 1;

    final hasData = activity != null && activity!.isNotEmpty;
    final activeDates = <int>{};
    if (activity != null) {
      for (var d = 1; d <= daysInMonth; d++) {
        final key =
            '$year-${month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
        if ((activity![key] ?? 0) > 0) {
          activeDates.add(d);
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.black12,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Month title + Streak badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_monthName(month, language)} $year',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      str3(
                        language,
                        'Streak kalendari',
                        'Календарь серии',
                        'Streak Calendar',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9600).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFF9600).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      color: Color(0xFFFF9600),
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$streakDays ${str3(language, 'kun', 'дн', 'days')}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFFF9600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Weekday header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final wd in _weekdays(language))
                Expanded(
                  child: Center(
                    child: Text(
                      wd,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color:
                            isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Grid of days
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: leadingBlanks + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              if (index < leadingBlanks) {
                return const SizedBox.shrink();
              }
              final day = index - leadingBlanks + 1;
              final isActive = activeDates.contains(day);
              final isToday = now.year == year &&
                  now.month == month &&
                  now.day == day;

              Color? bgColor;
              Color textColor;
              Border? border;

              if (isActive) {
                bgColor = const Color(0xFFFF9600);
                textColor = Colors.white;
              } else if (isToday) {
                bgColor = isDark
                    ? Colors.grey.shade800
                    : const Color(0xFFFF9600).withValues(alpha: 0.12);
                textColor = const Color(0xFFFF9600);
                border = Border.all(
                  color: const Color(0xFFFF9600),
                  width: 1.8,
                );
              } else {
                textColor = isDark ? Colors.grey.shade400 : Colors.grey.shade700;
              }

              return Center(
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                    border: border,
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: const Color(0xFFFF9600).withValues(alpha: 0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isActive || isToday
                              ? FontWeight.w900
                              : FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      if (isActive)
                        const Positioned(
                          top: 2,
                          right: 2,
                          child: Icon(
                            Icons.local_fire_department_rounded,
                            size: 10,
                            color: Colors.yellow,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),

          if (!hasData) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      str3(
                        language,
                        'Faollik ma‘lumotlari hali mavjud emas. Bugun darslarni boshlang!',
                        'Данных об активности пока нет. Начните уроки сегодня!',
                        'No activity data yet. Start lessons today to build your streak!',
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
