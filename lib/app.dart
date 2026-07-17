import 'package:flutter/material.dart';
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

    return MaterialApp.router(
      title: 'Ilm AI',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(colors),
      routerConfig: router,
    );
  }
}
