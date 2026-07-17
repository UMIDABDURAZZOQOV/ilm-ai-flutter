import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/network/error_message.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/premium_gate.dart';
import '../../auth/application/auth_controller.dart';
import '../../subscription/data/subscription_repository.dart';
import '../data/gaps_repository.dart';

final _gapsProvider = FutureProvider.autoDispose<GapsReportResponse?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  return ref.read(gapsRepositoryProvider).getReport(userId);
});

class GapsReportScreen extends ConsumerWidget {
  const GapsReportScreen({super.key});

  Color _weaknessColor(double score, ThemeColors colors) {
    if (score < 0.34) return colors.success;
    if (score < 0.67) return colors.warning;
    return colors.error;
  }

  String _weaknessLabel(double score, String language) {
    if (score < 0.34) return t('gaps.weakness.low', language);
    if (score < 0.67) return t('gaps.weakness.medium', language);
    return t('gaps.weakness.high', language);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final language = ref.watch(languageProvider);
    final gapsAsync = ref.watch(_gapsProvider);
    final isPremium = ref.watch(subscriptionStatusProvider).valueOrNull?.isPremium ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(t('gaps.title', language))),
      body: SafeArea(
        child: gapsAsync.when(
          data: (report) {
            if (report == null || !report.ready) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(t('gaps.not.ready', language), textAlign: TextAlign.center, style: TextStyle(color: colors.textMuted)),
                ),
              );
            }
            final visibleGaps = isPremium ? report.gaps : report.gaps.take(2).toList();
            final hiddenCount = report.gaps.length - visibleGaps.length;

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                for (final gap in visibleGaps)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(gap.topic, style: TextStyle(fontWeight: FontWeight.w700, color: colors.text)),
                              if (isPremium && gap.recommendedAction != null) ...[
                                const SizedBox(height: 4),
                                Text(gap.recommendedAction!, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: _weaknessColor(gap.weaknessScore, colors).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                          child: Text(_weaknessLabel(gap.weaknessScore, language), style: TextStyle(color: _weaknessColor(gap.weaknessScore, colors), fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                  ),
                if (hiddenCount > 0)
                  PremiumGate(
                    isLocked: true,
                    colors: colors,
                    language: language,
                    child: Container(
                      height: 140,
                      decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(extractError(e), style: TextStyle(color: colors.error))),
        ),
      ),
    );
  }
}
