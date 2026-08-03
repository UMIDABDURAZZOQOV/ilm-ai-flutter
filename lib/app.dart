import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/app_providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class IlmAiApp extends ConsumerWidget {
  const IlmAiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final colors = ref.watch(resolvedColorsProvider);

    // Keep the system bars blended with the current theme even on screens with
    // no AppBar (splash, login, onboarding, dashboard). Re-applied whenever the
    // theme changes so a light↔dark switch updates the bars immediately.
    SystemChrome.setSystemUIOverlayStyle(systemOverlayStyleFor(colors));

    return MaterialApp.router(
      title: 'Ilm AI',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(colors),
      routerConfig: router,
    );
  }
}
