import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'animated_ilmo.dart';
import 'mascot_image.dart';

/// Duolingo-style character callout used by every lesson screen: Ilmo asks
/// the question from a speech bubble and reacts in place once it is checked.
///
/// [verdict] is null before checking, then true or false.
class IlmoQuestionCallout extends StatelessWidget {
  const IlmoQuestionCallout({
    super.key,
    required this.prompt,
    required this.reactionKey,
    this.verdict,
  });

  final Widget prompt;
  final Object reactionKey;
  final bool? verdict;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact =
          constraints.maxWidth < 300 ||
          MediaQuery.textScalerOf(context).scale(16) > 24;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ExcludeSemantics(
            child: AnimatedIlmo(
              pose: verdict == null
                  ? MascotPose.thinking
                  : verdict!
                  ? MascotPose.happy
                  : MascotPose.sad,
              activity: verdict == null
                  ? IlmoActivity.listening
                  : verdict!
                  ? IlmoActivity.success
                  : IlmoActivity.encouraging,
              size: compact ? 84 : 132,
              reactionKey: '$reactionKey:$verdict',
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: SpeechBubble(
              child: Semantics(container: true, header: true, child: prompt),
            ),
          ),
        ],
      );
    },
  );
}

/// Rounded bubble with a tail pointing at Ilmo on the left.
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!.colors;
    return CustomPaint(
      painter: _BubblePainter(fill: c.surface, stroke: c.border),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(26, 14, 16, 14),
        child: child,
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  _BubblePainter({required this.fill, required this.stroke});
  final Color fill, stroke;
  @override
  void paint(Canvas canvas, Size size) {
    const tail = 10.0, radius = 16.0;
    final body = RRect.fromLTRBR(
      tail,
      0,
      size.width,
      size.height,
      const Radius.circular(radius),
    );
    final tailY = math.min(
      size.height - radius,
      math.max(radius, size.height * .72),
    );
    final path = Path()
      ..addRRect(body)
      ..moveTo(tail, tailY - 9)
      ..lineTo(0, tailY + 4)
      ..lineTo(tail, tailY + 7)
      ..close();
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_BubblePainter old) =>
      old.fill != fill || old.stroke != stroke;
}
