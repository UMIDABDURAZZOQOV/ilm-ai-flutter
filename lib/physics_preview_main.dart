// Separate local QA entrypoint. Normal main.dart/OAuth/catalog are unchanged.
// flutter run -t lib/physics_preview_main.dart --dart-define-from-file=PRIVATE_JSON
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/physics_preview.dart';
import 'core/network/dio_client.dart' show apiBaseUrl;
import 'core/providers/app_providers.dart';
import 'core/storage/prefs_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/application/auth_controller.dart';
import 'features/physics/data/physics_repository.dart';
import 'features/physics/presentation/physics_preview_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const token = String.fromEnvironment('PHYSICS_TEST_TOKEN');
  const uid = int.fromEnvironment('PHYSICS_TEST_USER_ID');
  if (!kDebugMode ||
      !physicsPreviewAllowed(apiBaseUrl) ||
      token.isEmpty ||
      uid <= 0) {
    throw StateError(
      'Only an explicit debug/local Physics sandbox is permitted.',
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
        physicsRepositoryProvider.overrideWithValue(PhysicsRepository(dio)),
      ],
      child: MaterialApp(
        title: 'ILM AI • Fizika sinovi',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(lightColors),
        home: const PhysicsPreviewScreen(),
      ),
    ),
  );
}
