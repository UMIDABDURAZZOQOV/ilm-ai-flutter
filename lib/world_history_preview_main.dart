// Separate debug/loopback QA entrypoint. Normal main.dart/OAuth stay intact.
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/world_history_preview.dart';
import 'core/network/dio_client.dart' show apiBaseUrl;
import 'core/providers/app_providers.dart';
import 'core/storage/prefs_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/application/auth_controller.dart';
import 'features/world_history/data/world_history_repository.dart';
import 'features/world_history/presentation/world_history_preview_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const token = String.fromEnvironment('WORLD_HISTORY_TEST_TOKEN');
  const uid = int.fromEnvironment('WORLD_HISTORY_TEST_USER_ID');
  if (!kDebugMode ||
      !worldHistoryPreviewAllowed(apiBaseUrl) ||
      token.isEmpty ||
      uid <= 0) {
    throw StateError(
      'Only an explicit debug/loopback WorldHistory sandbox is permitted.',
    );
  }
  final prefs = await PrefsService.create();
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      headers: {'Authorization': 'Bearer $token'},
    ),
  );
  runApp(
    ProviderScope(
      overrides: [
        prefsServiceProvider.overrideWithValue(prefs),
        currentUserIdProvider.overrideWithValue(uid),
        worldHistoryRepositoryProvider.overrideWithValue(
          WorldHistoryRepository(dio),
        ),
      ],
      child: const WorldHistoryPreviewApp(),
    ),
  );
}

class WorldHistoryPreviewApp extends ConsumerWidget {
  const WorldHistoryPreviewApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
    title: 'ILM AI · WorldHistory QA',
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(ref.watch(resolvedColorsProvider)),
    locale: Locale(ref.watch(languageProvider)),
    supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: const WorldHistoryPreviewScreen(),
  );
}
