import 'dart:async';
import 'package:flutter/material.dart';
import 'features/auth/application/auth_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/providers/app_providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class IlmAiApp extends ConsumerWidget {
  const IlmAiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final colors = learningPalette(ref.watch(resolvedColorsProvider));

    // Keep the system bars blended with the current theme even on screens with
    // no AppBar (splash, login, onboarding, dashboard). Re-applied whenever the
    // theme changes so a light↔dark switch updates the bars immediately.
    SystemChrome.setSystemUIOverlayStyle(systemOverlayStyleFor(colors));

    return _AppLifecycle(child: MaterialApp.router(
      title: 'ILM AI',
      debugShowCheckedModeBanner: false,
      locale: Locale(ref.watch(languageProvider)),
      supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: buildAppTheme(colors),
      routerConfig: router,
    ));
  }
}


class _AppLifecycle extends ConsumerStatefulWidget {
  final Widget child;
  const _AppLifecycle({required this.child});
  @override
  ConsumerState<_AppLifecycle> createState() => _AppLifecycleState();
}

class _AppLifecycleState extends ConsumerState<_AppLifecycle> with WidgetsBindingObserver {
  Timer? _midnight;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleMidnight();
  }
  void _scheduleMidnight() {
    _midnight?.cancel();
    final now = DateTime.now().toUtc();
    final next = DateTime.utc(now.year, now.month, now.day + 1);
    _midnight = Timer(next.difference(now), () {
      if (!mounted) return;
      ref.read(studyRevisionProvider.notifier).state++;
      _scheduleMidnight();
    });
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scheduleMidnight();
      unawaited(ref.read(authControllerProvider.notifier).resume().catchError((Object _) {}));
    }
  }
  @override
  void dispose() {
    _midnight?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => widget.child;
}
