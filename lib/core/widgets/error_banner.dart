import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme.dart';

/// Ported from ilm-ai-mobile's ErrorMessage.tsx.
class ErrorBanner extends StatelessWidget {
  final String? message;
  final VoidCallback? onDismiss;

  const ErrorBanner({super.key, required this.message, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) return const SizedBox.shrink();
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.errorLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.error.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colors.error.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.error_outline_rounded, color: colors.error, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(message!, style: TextStyle(color: colors.error, fontSize: 14, fontWeight: FontWeight.w600))),
          if (onDismiss != null)
            InkWell(
              onTap: onDismiss,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(6),
                child: Icon(Icons.close_rounded, color: colors.error, size: 18),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 300), curve: Curves.easeOut).slideX(begin: -0.1, end: 0, curve: Curves.easeOut);
  }
}
