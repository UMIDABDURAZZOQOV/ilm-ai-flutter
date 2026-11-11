import 'dart:io';

/// Selects a reviewed host baseline without changing Flutter's exact comparator.
/// Windows references stay at their original paths. Linux references were
/// visually reviewed with identical Flutter/font fingerprints; see their README.
/// Unsupported hosts fail explicitly instead of skipping or accepting a diff.
String platformGolden(String fileName, {String? operatingSystem}) {
  if (!RegExp(r'^[a-z][a-z0-9_]*\.png$').hasMatch(fileName)) {
    throw ArgumentError.value(
      fileName,
      'fileName',
      'Expected a golden filename',
    );
  }
  return switch (operatingSystem ?? Platform.operatingSystem) {
    'windows' => 'goldens/$fileName',
    'linux' => 'goldens/linux/$fileName',
    final host => throw UnsupportedError('No reviewed golden host: $host'),
  };
}
