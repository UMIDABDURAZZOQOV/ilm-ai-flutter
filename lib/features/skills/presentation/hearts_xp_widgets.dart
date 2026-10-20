import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/skill_tree_models.dart';

/// Real study statistics. The old unlimited-hearts decoration remains opt-in
/// for legacy callers; the active product has no hearts/energy system.
class HeartsXpHeader extends StatelessWidget {
  final GamificationSummary summary;
  final bool showHearts;
  const HeartsXpHeader({super.key, required this.summary, this.showHearts = false});

  Widget _chip(BuildContext context, IconData icon, Color color, String value, String label) {
    return Semantics(label: label, excludeSemantics: true, child: Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 3),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              color: Theme.of(context).extension<AppColors>()!.colors.text,
            ),
          ),
        ],
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    final streakLabel = language == 'uz' ? '${summary.streakDays} kunlik seriya' : language == 'ru' ? 'Серия: ${summary.streakDays} дней' : '${summary.streakDays} day streak';
    final activeStreak = summary.streakDays > 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _chip(context,
          Icons.local_fire_department_rounded,
          activeStreak ? BrandPalette.accentOrange : const Color(0xFFB0B0B0),
          '${summary.streakDays}', streakLabel,
        ),
        _chip(context,
          Icons.bolt_rounded,
          BrandPalette.turquoise,
          '${summary.xpTotal}', '${summary.xpTotal} XP',
        ),
        if (showHearts) _chip(context, Icons.favorite_rounded, const Color(0xFFFF4B4B), '∞', 'Unlimited hearts'),
      ],
    );
  }
}
