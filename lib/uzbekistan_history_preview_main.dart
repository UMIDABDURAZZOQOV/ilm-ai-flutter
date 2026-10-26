// Separate local QA entrypoint. Normal main.dart/OAuth/catalog are unchanged.
// flutter run -t lib/uzbekistan_history_preview_main.dart --dart-define-from-file=PRIVATE_JSON
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/uzbekistan_history_preview.dart';
import 'core/network/dio_client.dart' show apiBaseUrl;
import 'core/providers/app_providers.dart';
import 'core/storage/prefs_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/application/auth_controller.dart';
import 'features/uzbekistan_history/data/history_repository.dart';
import 'features/uzbekistan_history/presentation/history_preview_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const token = String.fromEnvironment('UZBEKISTAN_HISTORY_TEST_TOKEN');
  const uid = int.fromEnvironment('UZBEKISTAN_HISTORY_TEST_USER_ID');
  if (!kDebugMode ||
      !uzbekistanHistoryPreviewAllowed(apiBaseUrl) ||
      token.isEmpty ||
      uid <= 0) {
    throw StateError(
      'Only an explicit debug/local Uzbekistan history sandbox is permitted.',
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
        historyRepositoryProvider.overrideWithValue(HistoryRepository(dio)),
      ],
      child: MaterialApp(
        title: 'ILM AI • O‘zbekiston tarixi',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(lightColors),
        home: const UzbekistanHistoryPreviewScreen(),
      ),
    ),
  );
}
