import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/providers/app_providers.dart';
import 'core/storage/prefs_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await PrefsService.create();

  runApp(
    ProviderScope(
      overrides: [prefsServiceProvider.overrideWithValue(prefs)],
      child: const IlmAiApp(),
    ),
  );
}
