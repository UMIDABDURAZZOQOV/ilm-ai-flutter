import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shown only while AuthController restores tokens from secure storage on
/// cold start; the router redirects away as soon as that resolves. Branded
/// with a large centred logo so the app entry feels finished, not blank.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()?.colors;
    final primary = colors?.primary ?? const Color(0xFF4F46E5);
    final bg = colors?.background ?? Colors.white;

    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 132,
              height: 132,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(34),
                boxShadow: [
                  BoxShadow(color: primary.withValues(alpha: 0.28), blurRadius: 32, offset: const Offset(0, 16)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(34),
                child: Image.asset('assets/icons/icon.png', width: 132, height: 132, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2.6, valueColor: AlwaysStoppedAnimation(primary)),
            ),
          ],
        ),
      ),
    );
  }
}
