import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/skills/presentation/skill_ui.dart';
import '../providers/app_providers.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final failed =
        ref.watch(sessionRestoreErrorProvider) != null ||
        ref.watch(authControllerProvider).hasError;
    final language = ref.watch(languageProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF2A1F6B),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/mascot/splash_logo.png',
                  width: 160,
                  height: 160,
                  semanticLabel: 'ILM AI',
                ),
                const SizedBox(height: 36),
                if (!failed)
                  const CircularProgressIndicator(color: Color(0xFFF9A825))
                else ...[
                  Text(
                    str3(
                      language,
                      'Sessiyani tekshirib bo‘lmadi. Internetni tekshiring.',
                      'Не удалось проверить сеанс. Проверьте интернет.',
                      'Could not check your session. Check your connection.',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => ref
                        .read(authControllerProvider.notifier)
                        .retryRestore(),
                    child: Text(
                      str3(language, 'Qayta urinish', 'Повторить', 'Retry'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
