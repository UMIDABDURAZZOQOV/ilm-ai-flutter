import 'package:flutter/material.dart';
import '../theme/ilmo_tokens.dart';
import 'duo_chrome.dart';
import 'mascot_image.dart';

/// The bubble carries the accessible message; the adjacent Ilmo is decorative.
/// Large text and narrow screens place the message beneath the character.
class IlmoSpeechHeader extends StatelessWidget {
  final MascotPose pose;
  final String text;
  const IlmoSpeechHeader({super.key, required this.pose, required this.text});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final stacked =
          constraints.maxWidth < 320 ||
          MediaQuery.textScalerOf(context).scale(16) > 20.8;
      final mascot = MascotImage.compact(pose: pose);
      final bubble = DuoSpeechBubble(
        text: text,
        pointerDirection: stacked
            ? BubblePointerDirection.none
            : BubblePointerDirection.left,
      );
      if (stacked) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: mascot),
            const SizedBox(height: IlmoSpacing.standard),
            bubble,
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          mascot,
          const SizedBox(width: IlmoSpacing.standard),
          Expanded(child: bubble),
        ],
      );
    },
  );
}
