import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/premium_button.dart';

/// IELTS practice lives on the web (long reading passages + scroll-through
/// listening are a poor fit for a phone). Rather than hide IELTS entirely and
/// leave learners wondering, the app keeps an IELTS entry that hands off to the
/// website's IELTS section in the browser.
class IeltsWebScreen extends ConsumerWidget {
  const IeltsWebScreen({super.key});

  static const _ieltsUrl = 'https://ilm-ai-edu.vercel.app/ielts';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final language = ref.watch(languageProvider);
    String tr(String uz, String ru, String en) => language == 'ru' ? ru : language == 'en' ? en : uz;

    Future<void> openIelts() async {
      final uri = Uri.parse(_ieltsUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('IELTS')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 96,
                height: 96,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(Icons.headphones_rounded, size: 48, color: colors.primary),
              ),
              const SizedBox(height: 28),
              Text(
                tr('IELTS tayyorgarlik', 'Подготовка к IELTS', 'IELTS Preparation'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: colors.text, letterSpacing: -0.5),
              ),
              const SizedBox(height: 12),
              Text(
                tr(
                  "To'liq IELTS practice — Listening, Reading, Writing, Speaking — web saytimizda qulayroq ishlaydi. Bir bosishda o'ting.",
                  'Полная практика IELTS — Listening, Reading, Writing, Speaking — удобнее на нашем сайте. Перейдите в один клик.',
                  'Full IELTS practice — Listening, Reading, Writing, Speaking — works better on our website. Jump over in one tap.',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: colors.textSecondary, fontWeight: FontWeight.w500, height: 1.5),
              ),
              const SizedBox(height: 36),
              PremiumButton(
                onPressed: openIelts,
                borderRadius: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(tr("IELTS'ga o'tish", 'Перейти к IELTS', 'Go to IELTS')),
                    const SizedBox(width: 8),
                    const Icon(Icons.open_in_new_rounded, size: 18),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                tr('Brauzerda ochiladi', 'Откроется в браузере', 'Opens in your browser'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: colors.textMuted, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
