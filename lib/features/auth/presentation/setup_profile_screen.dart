import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/error_message.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/premium_button.dart';
import '../application/auth_controller.dart';
import '../data/auth_repository.dart';

/// Shown once, right after Google sign-in, for a user who hasn't set a name+age.
/// Both are required before entering the app. Google gives us a name; the learner
/// can change it (nickname) and adds their age.
class SetupProfileScreen extends ConsumerStatefulWidget {
  const SetupProfileScreen({super.key});

  @override
  ConsumerState<SetupProfileScreen> createState() => _SetupProfileScreenState();
}

class _SetupProfileScreenState extends ConsumerState<SetupProfileScreen> {
  final _name = TextEditingController();
  final _age = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Prefill with the name Google gave us; the user can change it.
    _name.text = ref.read(authControllerProvider).valueOrNull?.name ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    super.dispose();
  }

  Future<void> _submit(String Function(String, String, String) tr) async {
    final name = _name.text.trim();
    final age = int.tryParse(_age.text.trim());
    if (name.length < 2) {
      setState(() => _error = tr('Ismingizni kiriting.', 'Введите имя.', 'Please enter your name.'));
      return;
    }
    if (age == null || age < 5 || age > 100) {
      setState(() => _error = tr("Yoshingizni to'g'ri kiriting (5–100).", 'Введите корректный возраст (5–100).', 'Enter a valid age (5–100).'));
      return;
    }
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).completeOnboarding(userId: userId, name: name, age: age);
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) setState(() => _error = extractError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final language = ref.watch(languageProvider);
    String tr(String uz, String ru, String en) => language == 'ru' ? ru : language == 'en' ? en : uz;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Text('👋', textAlign: TextAlign.center, style: const TextStyle(fontSize: 56))
                  .animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.7, 0.7), end: const Offset(1, 1), curve: Curves.easeOutBack),
              const SizedBox(height: 20),
              Text(
                tr('Xush kelibsiz!', 'Добро пожаловать!', 'Welcome!'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: colors.text, letterSpacing: -0.5),
              ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
              const SizedBox(height: 10),
              Text(
                tr("Boshlashdan oldin o'zingiz haqingizda ozgina ayting.",
                    'Прежде чем начать, расскажите немного о себе.',
                    'Before we start, tell us a bit about you.'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: colors.textSecondary, fontWeight: FontWeight.w500, height: 1.4),
              ).animate().fadeIn(delay: 150.ms, duration: 350.ms),
              const SizedBox(height: 36),
              ErrorBanner(message: _error, onDismiss: () => setState(() => _error = null)),
              PremiumCard(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                borderRadius: 20,
                child: AppTextField(
                  controller: _name,
                  hint: tr('Ism yoki taxallus', 'Имя или никнейм', 'Name or nickname'),
                  prefixIcon: Icon(Icons.person_outline, color: colors.textMuted, size: 22),
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 350.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
              const SizedBox(height: 16),
              PremiumCard(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                borderRadius: 20,
                child: AppTextField(
                  controller: _age,
                  hint: tr('Yoshingiz', 'Ваш возраст', 'Your age'),
                  keyboardType: TextInputType.number,
                  prefixIcon: Icon(Icons.cake_outlined, color: colors.textMuted, size: 22),
                ),
              ).animate().fadeIn(delay: 250.ms, duration: 350.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
              const SizedBox(height: 28),
              PremiumButton(
                onPressed: _loading ? null : () => _submit(tr),
                loading: _loading,
                borderRadius: 20,
                child: Text(tr('Davom etish', 'Продолжить', 'Continue')),
              ).animate().fadeIn(delay: 300.ms, duration: 350.ms),
            ],
          ),
        ),
      ),
    );
  }
}
