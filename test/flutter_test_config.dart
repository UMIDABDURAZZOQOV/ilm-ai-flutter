import 'dart:async';

import 'package:ilm_ai_flutter/core/widgets/animated_ilmo.dart';

/// Runs before every test file. The endless idle loop would keep
/// pumpAndSettle waiting forever and make golden frames time-dependent.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  AnimatedIlmo.ambientIdle = false;
  await testMain();
}
