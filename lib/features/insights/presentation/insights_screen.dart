import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart' show languageProvider;
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/premium_loading.dart';
import '../../auth/application/auth_controller.dart' show currentUserIdProvider;
import '../data/insights_repository.dart';

String _tr(String lang, String uz, String ru, String en) =>
    lang == 'ru' ? ru : lang == 'en' ? en : uz;

final _insightsProvider = FutureProvider.autoDispose<Insights?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  return ref.read(insightsRepositoryProvider).getInsights(userId);
});

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final lang = ref.watch(languageProvider);
    final async = ref.watch(_insightsProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.text, size: 24),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _tr(lang, 'O\'rganish tahlili', 'Аналитика обучения', 'Learning insights'),
          style: TextStyle(color: colors.text, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.5),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: PremiumLoading()),
        error: (e, _) => Center(
          child: Text(_tr(lang, 'Xato', 'Ошибка', 'Error'),
              style: TextStyle(color: colors.textSecondary, fontSize: 15, fontWeight: FontWeight.w500)),
        ),
        data: (data) {
          if (data == null || !data.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(Icons.insights_rounded, size: 40, color: colors.primary),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _tr(lang, 'Hali ma\'lumot yo\'q — material yuklab, viktorina yeching.',
                          'Пока нет данных — загрузите материал и пройдите тест.',
                          'No data yet — upload material and take a quiz.'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.textSecondary, fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: _StatTile(value: '${data.overallPct}%', label: _tr(lang, 'O\'rtacha', 'Средний', 'Average'), color: colors.primary, colors: colors)),
                    const SizedBox(width: 12),
                    Expanded(child: _StatTile(value: '${data.sessions}', label: _tr(lang, 'Sessiya', 'Сессии', 'Sessions'), color: colors.secondary, colors: colors)),
                    const SizedBox(width: 12),
                    Expanded(child: _StatTile(
                      value: '${data.trend >= 0 ? '+' : ''}${data.trend}',
                      label: _tr(lang, 'O\'zgarish', 'Тренд', 'Trend'),
                      color: data.trend >= 0 ? colors.success : colors.error,
                      colors: colors,
                    )),
                  ],
                ).animate().fadeIn(duration: 300.ms),
                const SizedBox(height: 18),

                if (data.recentScores.length >= 2) ...[
                  _Card(colors: colors, child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_tr(lang, 'So\'nggi natijalar', 'Недавние результаты', 'Recent scores'),
                          style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      SizedBox(height: 56, child: CustomPaint(
                        size: const Size(double.infinity, 56),
                        painter: _SparkPainter(data.recentScores, colors.primary),
                      )),
                    ],
                  )).animate().fadeIn(delay: 100.ms, duration: 300.ms),
                  const SizedBox(height: 18),
                ],

                if (data.files.isNotEmpty) ...[
                  _Card(colors: colors, child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_tr(lang, 'Materiallar', 'Материалы', 'Materials')} (${data.materialsCount})',
                          style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      Wrap(spacing: 8, runSpacing: 8, children: data.files.map((f) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: colors.background, borderRadius: BorderRadius.circular(999)),
                        child: Text(f, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                      )).toList()),
                    ],
                  )).animate().fadeIn(delay: 200.ms, duration: 300.ms),
                  const SizedBox(height: 18),
                ],

                if (data.strong.isNotEmpty)
                  _TopicCard(title: _tr(lang, 'Kuchli mavzular', 'Сильные темы', 'Strong topics'),
                      topics: data.strong, color: colors.success, colors: colors).animate().fadeIn(delay: 300.ms, duration: 300.ms),
                if (data.weak.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _TopicCard(title: _tr(lang, 'Zaif mavzular', 'Слабые темы', 'Weak topics'),
                      topics: data.weak, color: colors.warning, colors: colors).animate().fadeIn(delay: 400.ms, duration: 300.ms),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final ThemeColors colors;
  const _StatTile({required this.value, required this.label, required this.color, required this.colors});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final ThemeColors colors;
  const _Card({required this.child, required this.colors});
  @override
  Widget build(BuildContext context) => PremiumCard(
        borderRadius: 20,
        padding: const EdgeInsets.all(18),
        child: child,
      );
}

class _TopicCard extends StatelessWidget {
  final String title;
  final List<TopicStat> topics;
  final Color color;
  final ThemeColors colors;
  const _TopicCard({required this.title, required this.topics, required this.color, required this.colors});

  @override
  Widget build(BuildContext context) {
    return _Card(
      colors: colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          ...topics.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(t.topic, style: TextStyle(color: colors.text, fontSize: 13))),
                        Text('${t.accuracy}%', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: t.accuracy / 100,
                        minHeight: 6,
                        backgroundColor: color.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  final List<int> data;
  final Color color;
  _SparkPainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final path = ui.Path();
    for (var i = 0; i < data.length; i++) {
      final x = i / (data.length - 1) * size.width;
      final y = size.height - (data[i].clamp(0, 100) / 100) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_SparkPainter old) => old.data != data || old.color != color;
}
