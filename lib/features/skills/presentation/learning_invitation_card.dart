import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/ilm_design.dart';
import '../../../core/widgets/mascot_image.dart';

/// A useful next step for an empty learning view, without invented progress.
class LearningInvitationCard extends StatelessWidget {
  const LearningInvitationCard({
    super.key,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onOpenLearning,
  });
  final String title, message, actionLabel;
  final VoidCallback onOpenLearning;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!.colors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(IlmRadius.card),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(width: 12),
              MascotImage(
                pose: MascotPose.hello,
                size: MediaQuery.textScalerOf(context).scale(16) > 24 ? 48 : 72,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onOpenLearning,
            icon: const Icon(Icons.menu_book_outlined, size: 20),
            label: Text(actionLabel, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}
