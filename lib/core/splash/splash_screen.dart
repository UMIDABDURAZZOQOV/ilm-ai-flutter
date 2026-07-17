import 'package:flutter/material.dart';

/// Shown only while AuthController restores tokens from secure storage on
/// cold start; the router redirects away as soon as that resolves.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
