import 'package:flutter/material.dart';

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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.errorLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(message!, style: TextStyle(color: colors.error, fontSize: 13))),
          if (onDismiss != null)
            InkWell(onTap: onDismiss, child: Icon(Icons.close, color: colors.error, size: 16)),
        ],
      ),
    );
  }
}
