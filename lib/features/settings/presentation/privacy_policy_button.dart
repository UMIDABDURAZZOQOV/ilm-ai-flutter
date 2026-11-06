import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/providers/app_providers.dart';
import '../../skills/presentation/skill_ui.dart';

// The policy linked by the existing com.ilmai.app Play listing. No credentials
// or account identifiers are included in this public browser request.
final privacyPolicyUri = Uri.parse('https://ilm-ai-edu.vercel.app/privacy');
final privacyPolicyLauncherProvider = Provider<Future<bool> Function()>(
  (ref) =>
      () => launchUrl(privacyPolicyUri, mode: LaunchMode.externalApplication),
);

class PrivacyPolicyButton extends ConsumerStatefulWidget {
  const PrivacyPolicyButton({super.key});

  @override
  ConsumerState<PrivacyPolicyButton> createState() =>
      _PrivacyPolicyButtonState();
}

class _PrivacyPolicyButtonState extends ConsumerState<PrivacyPolicyButton> {
  bool _opening = false;

  Future<void> _open() async {
    if (_opening) return;
    setState(() => _opening = true);
    var opened = false;
    try {
      opened = await ref.read(privacyPolicyLauncherProvider)();
    } catch (_) {
      // A missing browser/platform handler must not crash account settings.
    }
    if (!mounted) return;
    setState(() => _opening = false);
    if (!opened) {
      final language = ref.read(languageProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            str3(
              language,
              'Sahifani ochib bo‘lmadi. Qayta urining.',
              'Не удалось открыть страницу. Повторите попытку.',
              'Could not open the page. Please try again.',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    return TextButton.icon(
      key: const ValueKey('privacy_policy'),
      onPressed: _opening ? null : _open,
      icon: const Icon(Icons.privacy_tip_outlined, size: 20),
      label: Text(
        str3(
          language,
          'Maxfiylik siyosati',
          'Политика конфиденциальности',
          'Privacy policy',
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
