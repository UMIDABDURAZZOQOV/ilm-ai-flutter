import 'package:ilm_ai_flutter/core/widgets/animated_ilmo.dart';
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
          LayoutBuilder(
            builder: (context, constraints) {
              const mascotSize = 100.0;
              const inlineGap = 12.0;
              final scaler = MediaQuery.textScalerOf(context);
              final style = Theme.of(context).textTheme.titleLarge;
              // Reserve readable space for the heading beside the artwork.
              // This budget scales with text across phone widths.
              final headingWidth = scaler.scale(128);
              final stackHeader =
                  constraints.maxWidth < mascotSize + inlineGap + headingWidth;
              final heading = Text(title, style: style);
              const ilmo = AnimatedIlmo(
                pose: MascotPose.hello,
                size: mascotSize,
              );
              return Flex(
                direction: stackHeader ? Axis.vertical : Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (stackHeader) ...[
                    heading,
                    const SizedBox(height: 8),
                    const Center(child: ilmo),
                  ] else ...[
                    Expanded(child: heading),
                    const SizedBox(width: inlineGap),
                    ilmo,
                  ],
                ],
              );
            },
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
