// Separate debug/loopback QA entrypoint. Normal main.dart/OAuth stay intact.
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/chemistry_preview.dart';
import 'core/network/dio_client.dart' show apiBaseUrl;
import 'core/providers/app_providers.dart';
import 'core/storage/prefs_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/application/auth_controller.dart';
import 'features/chemistry/data/chemistry_repository.dart';
import 'features/chemistry/presentation/chemistry_preview_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const token = String.fromEnvironment('CHEMISTRY_TEST_TOKEN');
  const uid = int.fromEnvironment('CHEMISTRY_TEST_USER_ID');
  if (!kDebugMode ||
      !chemistryPreviewAllowed(apiBaseUrl) ||
      token.isEmpty ||
      uid <= 0) {
    throw StateError(
      'Only an explicit debug/loopback Chemistry sandbox is permitted.',
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
        chemistryRepositoryProvider.overrideWithValue(ChemistryRepository(dio)),
      ],
      child: const ChemistryPreviewApp(),
    ),
  );
}

class ChemistryPreviewApp extends ConsumerWidget {
  const ChemistryPreviewApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
    title: 'ILM AI · Chemistry QA',
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(ref.watch(resolvedColorsProvider)),
    locale: Locale(ref.watch(languageProvider)),
    supportedLocales: const [Locale('uz'), Locale('ru'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: const ChemistryPreviewScreen(),
  );
}
