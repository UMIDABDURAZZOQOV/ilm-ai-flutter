import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/skills/presentation/skill_ui.dart';
import '../providers/app_providers.dart';
import '../theme/ilmo_tokens.dart';
import '../theme/app_theme.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final failed =
        ref.watch(sessionRestoreErrorProvider) != null ||
        ref.watch(authControllerProvider).hasError;
    final language = ref.watch(languageProvider);
    return Scaffold(
      backgroundColor: BrandPalette.indigo,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/mascot/splash_logo.png',
                  width: IlmoSizes.splash,
                  height: IlmoSizes.splash,
                  cacheWidth:
                      (IlmoSizes.splash *
                              MediaQuery.devicePixelRatioOf(context))
                          .ceil()
                          .clamp(1, 1024),
                  cacheHeight:
                      (IlmoSizes.splash *
                              MediaQuery.devicePixelRatioOf(context))
                          .ceil()
                          .clamp(1, 1024),
                  semanticLabel: 'ILM AI',
                ),
                const SizedBox(height: 36),
                if (!failed)
                  const CircularProgressIndicator(
                    color: BrandPalette.accentOrange,
                  )
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
