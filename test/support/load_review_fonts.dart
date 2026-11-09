import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';

Future<void> loadReviewFonts() async {
  final config = File('.dart_tool/package_config.json');
  final packages =
      (jsonDecode(config.readAsStringSync()) as Map)['packages'] as List;
  final flutter = packages.cast<Map>().singleWhere(
    (p) => p['name'] == 'flutter',
  );
  final sdk = Directory.fromUri(
    config.uri.resolve(flutter['rootUri'] as String),
  ).parent.parent;
  final text = FontLoader('Roboto');
  for (final weight in ['Regular', 'Medium', 'Bold']) {
    text.addFont(
      Future.value(
        ByteData.sublistView(
          File(
            '${sdk.path}/bin/cache/artifacts/material_fonts/Roboto-$weight.ttf',
          ).readAsBytesSync(),
        ),
      ),
    );
  }
  await text.load();
  final icons = FontLoader('MaterialIcons')
    ..addFont(
      Future.value(
        ByteData.sublistView(
          File(
            '${sdk.path}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
          ).readAsBytesSync(),
        ),
      ),
    );
  await icons.load();
}
