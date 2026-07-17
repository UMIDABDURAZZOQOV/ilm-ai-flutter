import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/network/error_message.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../auth/application/auth_controller.dart';
import '../data/plan_models.dart';
import '../data/plan_repository.dart';

final _planProvider = FutureProvider.autoDispose<LearningPlan?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  try {
    return await ref.read(planRepositoryProvider).getPlan(userId);
  } catch (_) {
    return null;
  }
});

class LearningPlanScreen extends ConsumerStatefulWidget {
  const LearningPlanScreen({super.key});

  @override
  ConsumerState<LearningPlanScreen> createState() => _LearningPlanScreenState();
}

class _LearningPlanScreenState extends ConsumerState<LearningPlanScreen> {
  final _goal = TextEditingController();
  final _targetDate = TextEditingController();
  final _dailyHours = TextEditingController(text: '2');
  bool _generating = false;
  String? _error;
  bool _showForm = false;

  Future<void> _generate() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final language = ref.read(languageProvider);
    if (_goal.text.trim().isEmpty || _targetDate.text.trim().isEmpty) {
      setState(() => _error = t('plan.error.fill', language));
      return;
    }
    final hours = double.tryParse(_dailyHours.text.trim()) ?? 0;
    if (hours < 0.5 || hours > 8) {
      setState(() => _error = t('plan.error.hours', language));
      return;
    }
    setState(() {
      _generating = true;
      _error = null;
    });
    try {
      await ref.read(planRepositoryProvider).generatePlan(
            userId: userId,
            dailyHours: hours,
            goal: _goal.text.trim(),
            targetDate: _targetDate.text.trim(),
          );
      ref.invalidate(_planProvider);
      setState(() => _showForm = false);
    } catch (e) {
      setState(() => _error = extractError(e));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Widget _buildForm(ThemeColors colors, String language) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ErrorBanner(message: _error, onDismiss: () => setState(() => _error = null)),
        TextField(
          controller: _goal,
          decoration: InputDecoration(
            hintText: t('plan.goal.placeholder', language),
            filled: true,
            fillColor: colors.inputBackground,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.border)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _targetDate,
          decoration: InputDecoration(
            hintText: t('plan.date.placeholder', language),
            filled: true,
            fillColor: colors.inputBackground,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.border)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _dailyHours,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: t('plan.hours.placeholder', language),
            filled: true,
            fillColor: colors.inputBackground,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.border)),
          ),
        ),
        const SizedBox(height: 20),
        GradientButton(onPressed: _generating ? null : _generate, loading: _generating, child: Text(t('plan.generate', language))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final language = ref.watch(languageProvider);
    final planAsync = ref.watch(_planProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t('plan.title', language)),
        actions: [
          if (!_showForm)
            IconButton(icon: const Icon(Icons.refresh), onPressed: () => setState(() => _showForm = true)),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _generating
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const CircularProgressIndicator(), const SizedBox(height: 16), Text(t('plan.generating', language))]))
              : planAsync.when(
                  data: (plan) {
                    if (_showForm || plan == null || plan.error != null) {
                      return SingleChildScrollView(child: _buildForm(colors, language));
                    }
                    return ListView(
                      children: [
                        Text(plan.summary, style: TextStyle(color: colors.textSecondary, fontSize: 14, height: 1.4)),
                        const SizedBox(height: 16),
                        for (final week in plan.weeklyBreakdown)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t('plan.week.label', language).replaceAll('{n}', '${week.week}').replaceAll('{focus}', week.focus), style: TextStyle(fontWeight: FontWeight.w700, color: colors.primary)),
                                const SizedBox(height: 8),
                                for (final day in week.days)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(t('plan.day.label', language).replaceAll('{n}', '${day.day}').replaceAll('{topic}', day.topic), style: TextStyle(fontWeight: FontWeight.w600, color: colors.text, fontSize: 13)),
                                        Text(t('plan.day.duration', language).replaceAll('{minutes}', '${day.durationMinutes}'), style: TextStyle(fontSize: 11, color: colors.textMuted)),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        if (plan.tips.isNotEmpty) ...[
                          Text(t('plan.tips.title', language), style: TextStyle(fontWeight: FontWeight.w700, color: colors.text)),
                          const SizedBox(height: 8),
                          for (final tip in plan.tips)
                            Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('• $tip', style: TextStyle(color: colors.textSecondary, fontSize: 13))),
                        ],
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => SingleChildScrollView(child: _buildForm(colors, language)),
                ),
        ),
      ),
    );
  }
}
