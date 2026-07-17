import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/network/error_message.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/application/auth_controller.dart';
import '../data/subscription_repository.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _loading = false;

  Future<void> _checkout(String gateway) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    setState(() => _loading = true);
    try {
      final res = await ref.read(subscriptionRepositoryProvider).checkout(userId: userId, gateway: gateway);
      if (res.ok == false || res.checkoutUrl.isEmpty) {
        await _showTestModeDialog(userId);
        return;
      }
      await FlutterWebAuth2.authenticate(url: res.checkoutUrl, callbackUrlScheme: 'ilmai');
      await ref.read(subscriptionRepositoryProvider).confirmPayment(sessionId: res.sessionId, userId: userId);
      ref.invalidate(subscriptionStatusProvider);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(extractError(e))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showTestModeDialog(int userId) async {
    final language = ref.read(languageProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('payment.test.title', language)),
        content: Text(t('payment.test.message', language)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t('common.cancel', language))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(t('payment.test.confirm', language))),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ref.read(subscriptionRepositoryProvider).confirmPayment(sessionId: 'test', userId: userId);
        ref.invalidate(subscriptionStatusProvider);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final language = ref.watch(languageProvider);
    final status = ref.watch(subscriptionStatusProvider).valueOrNull;
    final isPremium = status?.isPremium ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(t('payment.title', language))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (isPremium)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: colors.primaryLight, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    Icon(Icons.star, color: colors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t('payment.current.plan', language), style: TextStyle(fontSize: 12, color: colors.textMuted)),
                          Text(t('tier.premium', language), style: TextStyle(fontWeight: FontWeight.w700, color: colors.text)),
                          if (status?.expiresAt != null) Text(t('payment.expires', language).replaceAll('{date}', status!.expiresAt!), style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: _PlanCard(
                    title: t('tier.free', language),
                    features: ['payment.free.f1', 'payment.free.f2', 'payment.free.f3', 'payment.free.f4'],
                    language: language,
                    colors: colors,
                    highlighted: !isPremium,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PlanCard(
                    title: t('tier.premium', language),
                    features: ['payment.premium.f1', 'payment.premium.f2', 'payment.premium.f3', 'payment.premium.f4', 'payment.premium.f5', 'payment.premium.f6'],
                    language: language,
                    colors: colors,
                    highlighted: isPremium,
                    isPremiumCard: true,
                  ),
                ),
              ],
            ),
            if (!isPremium) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : () => _checkout('payme'),
                style: ElevatedButton.styleFrom(backgroundColor: colors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                child: Text(t('payment.payme', language)),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _loading ? null : () => _checkout('click'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: BorderSide(color: colors.border)),
                child: Text(t('payment.click', language)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final List<String> features;
  final String language;
  final ThemeColors colors;
  final bool highlighted;
  final bool isPremiumCard;

  const _PlanCard({
    required this.title,
    required this.features,
    required this.language,
    required this.colors,
    required this.highlighted,
    this.isPremiumCard = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPremiumCard ? colors.primaryLight : colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: highlighted ? colors.primary : colors.border, width: highlighted ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: colors.text)),
          const SizedBox(height: 12),
          for (final key in features)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check, size: 14, color: colors.success),
                  const SizedBox(width: 6),
                  Expanded(child: Text(t(key, language), style: TextStyle(fontSize: 12, color: colors.textSecondary))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
