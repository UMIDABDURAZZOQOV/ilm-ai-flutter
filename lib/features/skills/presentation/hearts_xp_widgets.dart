import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/skill_tree_models.dart';

/// Top-bar chips in Duolingo layout: streak · XP · hearts.
/// Hearts are ∞ because the backend has no energy/hearts field — we do not
/// invent a depleting count. Gems/shop are not shown (no inventory API).
class HeartsXpHeader extends StatelessWidget {
  final GamificationSummary summary;
  const HeartsXpHeader({super.key, required this.summary});

  Widget _chip(IconData icon, Color color, String value) {
    return Padding(
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
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeStreak = summary.streakDays > 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _chip(
          Icons.local_fire_department_rounded,
          activeStreak ? BrandPalette.accentOrange : const Color(0xFFB0B0B0),
          '${summary.streakDays}',
        ),
        _chip(
          Icons.bolt_rounded,
          BrandPalette.turquoise,
          '${summary.xpTotal}',
        ),
        _chip(Icons.favorite_rounded, const Color(0xFFFF4B4B), '∞'),
      ],
    );
  }
}
