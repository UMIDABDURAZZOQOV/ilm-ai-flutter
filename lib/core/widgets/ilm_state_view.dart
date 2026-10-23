import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../theme/ilm_design.dart';
import '../i18n/app_localizations.dart';

/// No invented progress, no network calls and no repeating mascot animation.
class IlmLoadingView extends StatelessWidget {
  const IlmLoadingView({super.key, required this.language});
  final String language;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final reduced = MediaQuery.disableAnimationsOf(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: IlmSpace.page,
        child: IlmReadingWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                liveRegion: true,
                child: Text(
                  uiText(
                    language,
                    'Ma’lumotlar yuklanmoqda',
                    'Загружаем данные',
                    'Loading your learning space',
                  ),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: IlmSpace.sm),
              Text(
                uiText(
                  language,
                    'Bir oz kuting. Ma’lumotlar tayyorlanmoqda.',
                    'Подождите немного. Готовим данные.',
                    'One moment. Your data is on its way.',
                ),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: IlmSpace.lg),
              ExcludeSemantics(
                child: Column(
                  children: [
                    if (reduced)
                      Icon(Icons.hourglass_top_rounded, color: colors.primary)
                    else
                      const LinearProgressIndicator(),
                    const SizedBox(height: IlmSpace.lg),
                    for (final width in [1.0, .84, .68])
                      Padding(
                        padding: const EdgeInsets.only(bottom: IlmSpace.md),
                        child: FractionallySizedBox(
                          widthFactor: width,
                          alignment: Alignment.centerLeft,
                          child: Container(
                            height: 72,
                            decoration: BoxDecoration(
                              color: colors.card,
                              borderRadius: BorderRadius.circular(
                                IlmRadius.card,
                              ),
                              border: Border.all(color: colors.border),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class IlmStateView extends StatelessWidget {
  const IlmStateView({
    super.key,
    required this.title,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });
  final String title, message, retryLabel;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: SingleChildScrollView(
        padding: IlmSpace.page,
        child: IlmReadingWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 40,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: IlmSpace.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: IlmSpace.sm),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: IlmSpace.lg),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(retryLabel),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
