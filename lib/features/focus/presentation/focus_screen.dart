import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart' show languageProvider;
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/animated_pressable.dart';

String _tr(String lang, String uz, String ru, String en) =>
    lang == 'ru' ? ru : lang == 'en' ? en : uz;

const _focusOptions = [25, 50];
const _shortBreak = 5;
const _longBreak = 10;

/// Pomodoro focus timer with a radial countdown. During a break the learner can
/// jump into a quick quiz from their materials. A longer break every 4th round.
class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key});

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen>
    with SingleTickerProviderStateMixin {
  int _focusMin = 25;
  bool _isFocus = true;
  bool _longBreakNow = false;
  int _left = 25 * 60;
  bool _running = false;
  int _rounds = 0;
  Timer? _timer;
  late final AnimationController _pulse;

  int get _breakMin => _longBreakNow ? _longBreak : _shortBreak;
  int get _total => (_isFocus ? _focusMin : _breakMin) * 60;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  void _start() {
    if (_running) return;
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_left <= 1) {
        _onPhaseEnd();
      } else {
        setState(() => _left--);
      }
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _running = false);
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _isFocus = true;
      _left = _focusMin * 60;
    });
  }

  void _onPhaseEnd() {
    _timer?.cancel();
    if (_isFocus) {
      final nr = _rounds + 1;
      final long = nr % 4 == 0;
      setState(() {
        _rounds = nr;
        _isFocus = false;
        _longBreakNow = long;
        _left = (long ? _longBreak : _shortBreak) * 60;
        _running = false;
      });
    } else {
      setState(() {
        _isFocus = true;
        _left = _focusMin * 60;
        _running = false;
      });
    }
  }

  void _setFocus(int m) => setState(() {
        _focusMin = m;
        if (_isFocus && !_running) _left = m * 60;
      });

  void _setBreakKind(bool long) => setState(() {
        _longBreakNow = long;
        if (!_isFocus && !_running) _left = (long ? _longBreak : _shortBreak) * 60;
      });

  String _fmt(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final lang = ref.watch(languageProvider);
    final accent = _isFocus ? colors.primary : colors.warning;
    final pct = _total == 0 ? 0.0 : (_total - _left) / _total;

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
          _tr(lang, 'Fokus rejimi', 'Фокус-режим', 'Focus mode'),
          style: TextStyle(color: colors.text, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.5),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Phase badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_isFocus ? Icons.psychology_rounded : Icons.coffee_rounded,
                          size: 18, color: accent),
                      const SizedBox(width: 8),
                      Text(
                        _isFocus
                            ? _tr(lang, 'Fokus', 'Фокус', 'Focus')
                            : (_longBreakNow
                                ? _tr(lang, 'Uzoq tanaffus', 'Длинный перерыв', 'Long break')
                                : _tr(lang, 'Qisqa tanaffus', 'Короткий перерыв', 'Short break')),
                        style: TextStyle(color: accent, fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms),
                const SizedBox(height: 24),

                // Duration presets (only when paused)
                if (!_running)
                  Wrap(
                    spacing: 10,
                    children: _isFocus
                        ? _focusOptions
                            .map((m) => _Chip(
                                  label: '$m ${_tr(lang, 'daq', 'мин', 'min')}',
                                  selected: _focusMin == m,
                                  color: colors.primary,
                                  colors: colors,
                                  onTap: () => _setFocus(m),
                                ))
                            .toList()
                        : [
                            _Chip(
                                label: _tr(lang, 'Qisqa · 5', 'Короткий · 5', 'Short · 5'),
                                selected: !_longBreakNow,
                                color: colors.warning,
                                colors: colors,
                                onTap: () => _setBreakKind(false)),
                            _Chip(
                                label: _tr(lang, 'Uzoq · 10', 'Длинный · 10', 'Long · 10'),
                                selected: _longBreakNow,
                                color: colors.warning,
                                colors: colors,
                                onTap: () => _setBreakKind(true)),
                          ],
                  ).animate().fadeIn(delay: 100.ms, duration: 300.ms),
                const SizedBox(height: 28),

                // Radial timer
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, _) {
                    final scale = _running ? 1 + _pulse.value * 0.015 : 1.0;
                    return Transform.scale(
                      scale: scale,
                      child: SizedBox(
                        width: 280,
                        height: 280,
                        child: CustomPaint(
                          painter: _RingPainter(
                            pct: pct,
                            accent: accent,
                            track: colors.border.withValues(alpha: 0.4),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _fmt(_left),
                                  style: TextStyle(
                                    fontSize: 64,
                                    fontWeight: FontWeight.w900,
                                    color: colors.text,
                                    fontFeatures: const [FontFeature.tabularFigures()],
                                    letterSpacing: -2,
                                  ),
                                ),
                                if (_rounds > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text('🍅 $_rounds',
                                        style: TextStyle(color: colors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                const SizedBox(height: 32),

                // Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PremiumButton(
                      onPressed: () => _running ? _pause() : _start(),
                      borderRadius: 22,
                      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_running ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 24),
                          const SizedBox(width: 10),
                          Text(
                            _running
                                ? _tr(lang, 'Pauza', 'Пауза', 'Pause')
                                : _tr(lang, 'Boshlash', 'Старт', 'Start'),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    AnimatedPressable(
                      onTap: _reset,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.border.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.refresh_rounded, color: colors.textSecondary, size: 22),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 300.ms, duration: 350.ms),

                // Break: quick quiz from materials
                if (!_isFocus) ...[
                  const SizedBox(height: 24),
                  PremiumButton(
                    onPressed: () => context.push('/quiz'),
                    variant: PremiumButtonVariant.outline,
                    borderColor: colors.warning,
                    textColor: colors.warning,
                    borderRadius: 18,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.quiz_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _tr(lang, 'Materialdan tez viktorina', 'Быстрый тест по материалу',
                              'Quick quiz from materials'),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms, duration: 300.ms),
                ],
                const SizedBox(height: 28),
                Text(
                  _tr(
                    lang,
                    '25/50 daqiqa fokus, 5/10 daqiqa tanaffus. Har 4 fokusdan keyin uzoq tanaffus.',
                    '25/50 мин фокуса, 5/10 мин перерыва. Длинный перерыв каждые 4 раунда.',
                    '25/50 min focus, 5/10 min break. A long break every 4 rounds.',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.textMuted, fontSize: 13, height: 1.5, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double pct;
  final Color accent;
  final Color track;
  _RingPainter({required this.pct, required this.accent, required this.track});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 8;
    final trackPaint = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    final arcPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: [accent.withValues(alpha: 0.7), accent],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * pct.clamp(0.0, 1.0),
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.pct != pct || old.accent != accent || old.track != track;
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final ThemeColors colors;
  final VoidCallback onTap;
  const _Chip({
    required this.label,
    required this.selected,
    required this.color,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : colors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? color : colors.border, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : colors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
