import 'package:flutter/material.dart';

import '../data/skill_tree_models.dart';

class HeartsXpHeader extends StatelessWidget {
  final GamificationSummary summary;
  const HeartsXpHeader({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, color: Color(0xFFFFC800), size: 20),
          const SizedBox(width: 4),
          Text('${summary.xpTotal}', style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(width: 14),
          Icon(Icons.local_fire_department_rounded, color: summary.streakDays > 0 ? const Color(0xFFFF9600) : Colors.grey, size: 20),
          const SizedBox(width: 4),
          Text('${summary.streakDays}', style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
