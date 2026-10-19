import 'package:flutter/material.dart';

import '../../onboarding/presentation/duo_onboarding_screen.dart';

/// Unified Duolingo-style onboarding screen hosting the full 14-step onboarding flow.
/// Integrated seamlessly into the existing `/setup` router destination.
class SetupProfileScreen extends StatelessWidget {
  const SetupProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DuoOnboardingScreen();
  }
}
