import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/animated_pressable.dart';
import '../../auth/application/auth_controller.dart';
import '../data/skill_tree_models.dart';
import '../data/skill_tree_repository.dart';
import 'hearts_xp_widgets.dart';
import 'mascot.dart';

const _nodeSpacing = 104.0;
const _amplitude = 64.0;

class _FlatLesson {
  final SkillTreeLesson lesson;
  final String unitTitle;
  final bool unitStart;
  _FlatLesson({required this.lesson, required this.unitTitle, required this.unitStart});
}

final _treeProvider = FutureProvider.autoDispose.family<SkillTreeResponse, String>((ref, subjectSlug) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) throw Exception('not authenticated');
  return ref.read(skillTreeRepositoryProvider).getTree(userId: userId, subjectSlug: subjectSlug);
});

class SkillPathScreen extends ConsumerWidget {
  final SkillSubject subject;
  const SkillPathScreen({super.key, required this.subject});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final treeAsync = ref.watch(_treeProvider(subject.slug));
    final subjectColor = _parseColor(subject.color);

    return Scaffold(
      appBar: AppBar(
        title: Text(subject.nameFor(language)),
        actions: [
          treeAsync.maybeWhen(
            data: (tree) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(child: HeartsXpHeader(summary: tree.user)),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: SafeArea(
        child: treeAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(child: Text(t('skills.error.generic', language))),
          data: (tree) {
            final flat = <_FlatLesson>[];
            for (final unit in tree.units) {
              for (var i = 0; i < unit.lessons.length; i++) {
                flat.add(_FlatLesson(lesson: unit.lessons[i], unitTitle: unit.titleFor(language), unitStart: i == 0));
              }
            }
            final points = List.generate(
              flat.length,
              (i) => Offset(_amplitude * math.sin(i * 0.9), 60 + i * _nodeSpacing),
            );
            final height = 60 + flat.length * _nodeSpacing + 100;
            final firstUnlockedIndex = flat.indexWhere((f) => f.lesson.status == LessonStatus.unlocked);

            return LayoutBuilder(
              builder: (context, constraints) {
                // Spread the winding path across the whole screen width and centre
                // it, so nodes never drift off the left edge (they used to live in
                // a fixed ~208px box).
                final width = constraints.maxWidth;
                final centerX = width / 2;
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      const Mascot(mood: MascotMood.idle, size: 64),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: width,
                        height: height,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(
                              child: CustomPaint(painter: _PathPainter(points: points, color: subjectColor)),
                            ),
                            for (var i = 0; i < flat.length; i++) ...[
                              if (flat[i].unitStart)
                                Positioned(
                                  left: 16,
                                  right: 16,
                                  // Sit clearly above the 64px node (which spans
                                  // dy-32 .. dy+32) instead of overlapping it.
                                  top: points[i].dy - 66,
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                                      decoration: BoxDecoration(color: subjectColor, borderRadius: BorderRadius.circular(20)),
                                      child: Text(
                                        flat[i].unitTitle.toUpperCase(),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.3),
                                      ),
                                    ),
                                  ),
                                ),
                              Positioned(
                                left: centerX + points[i].dx - 32,
                                top: points[i].dy - 32,
                                child: _LessonNodeWidget(
                                  lesson: flat[i].lesson,
                                  title: flat[i].lesson.titleFor(language),
                                  color: subjectColor,
                                  isCurrent: i == firstUnlockedIndex,
                                  onTap: () {
                                    if (flat[i].lesson.status == LessonStatus.locked) return;
                                    context.push('/skills/lesson', extra: flat[i].lesson).then((_) => ref.invalidate(_treeProvider(subject.slug)));
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _PathPainter extends CustomPainter {
  final List<Offset> points;
  final Color color;
  _PathPainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final centerX = size.width / 2;
    final path = Path()..moveTo(centerX + points[0].dx, points[0].dy);
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final midY = (prev.dy + curr.dy) / 2;
      path.quadraticBezierTo(centerX + prev.dx, midY, centerX + (prev.dx + curr.dx) / 2, midY);
      path.quadraticBezierTo(centerX + curr.dx, midY, centerX + curr.dx, curr.dy);
    }

    final paint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    _drawDashedPath(canvas, path, paint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const dashWidth = 3.0;
    const dashGap = 12.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(metric.extractPath(distance, next.clamp(0, metric.length)), paint);
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PathPainter oldDelegate) => oldDelegate.points != points || oldDelegate.color != color;
}

class _LessonNodeWidget extends StatelessWidget {
  final SkillTreeLesson lesson;
  final String title;
  final Color color;
  final bool isCurrent;
  final VoidCallback onTap;

  const _LessonNodeWidget({required this.lesson, required this.title, required this.color, required this.isCurrent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final locked = lesson.status == LessonStatus.locked;
    final completed = lesson.status == LessonStatus.completed;

    Widget node = AnimatedPressable(
      onTap: locked ? () {} : onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: locked ? Colors.grey.shade300 : (completed ? color : Colors.white),
          border: Border.all(color: locked ? Colors.grey.shade400 : color, width: 4),
        ),
        child: Icon(
          locked ? Icons.lock_rounded : (completed ? Icons.check_rounded : Icons.circle),
          color: locked ? Colors.grey.shade500 : (completed ? Colors.white : color),
          size: completed || locked ? 26 : 14,
        ),
      ),
    );

    if (isCurrent && !locked) {
      node = node.animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(begin: 1, end: 1.08, duration: 700.ms, curve: Curves.easeInOut);
    }

    return Column(
      children: [
        node,
        if (completed && lesson.stars > 0)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 1; i <= 3; i++)
                Icon(Icons.star_rounded, size: 12, color: i <= lesson.stars ? Colors.amber : Colors.grey.shade300),
            ],
          ),
      ],
    );
  }
}

Color _parseColor(String? hex) {
  if (hex == null || hex.isEmpty) return const Color(0xFF58CC02);
  final cleaned = hex.replaceFirst('#', '');
  return Color(int.parse('FF$cleaned', radix: 16));
}
