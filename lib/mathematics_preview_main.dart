// Separate local/test entrypoint; normal main.dart/catalog/OAuth stay unchanged.
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'core/config/mathematics_preview.dart';
import 'core/network/dio_client.dart' show apiBaseUrl;
import 'core/storage/prefs_service.dart';
import 'core/theme/app_theme.dart';
import 'features/mathematics/data/math_repository.dart';
import 'features/mathematics/presentation/math_preview_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const token = String.fromEnvironment('MATHEMATICS_TEST_TOKEN');
  const uid = int.fromEnvironment('MATHEMATICS_TEST_USER_ID');
  if (!kDebugMode ||
      !mathematicsPreviewAllowed(apiBaseUrl) ||
      token.isEmpty ||
      uid <= 0) {
    throw StateError(
      'Only an explicit debug/local Mathematics sandbox is permitted.',
    );
  }
  final preferences = await PrefsService.create();
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      headers: {'Authorization': 'Bearer $token'},
    ),
  );
  runApp(
    MaterialApp(
      title: 'ILM AI · Matematika',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(lightColors),
      home: MathPreviewScreen(
        repository: MathRepository(dio),
        preferences: preferences,
        userId: uid,
      ),
    ),
  );
}
