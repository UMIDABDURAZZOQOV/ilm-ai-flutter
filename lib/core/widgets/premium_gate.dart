import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../i18n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'gradient_button.dart';

/// Ported from ilm-ai-mobile's PremiumGate.tsx -- dims locked content and
/// overlays a lock icon + upgrade CTA.
class PremiumGate extends StatelessWidget {
  final bool isLocked;
  final Widget child;
  final ThemeColors colors;
  final String language;

  const PremiumGate({super.key, required this.isLocked, required this.child, required this.colors, required this.language});

  @override
  Widget build(BuildContext context) {
    if (!isLocked) return child;
    return Stack(
      children: [
        Opacity(opacity: 0.2, child: IgnorePointer(child: child)),
        Positioned.fill(
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: colors.border)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_rounded, size: 32, color: colors.primary),
                  const SizedBox(height: 12),
                  Text(t('premium.gate.title', language), style: TextStyle(fontWeight: FontWeight.w700, color: colors.text)),
                  const SizedBox(height: 6),
                  Text(t('premium.gate.desc', language), textAlign: TextAlign.center, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 16),
                  GradientButton(onPressed: () => context.push('/profile/subscription'), child: Text(t('tier.upgrade', language))),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
