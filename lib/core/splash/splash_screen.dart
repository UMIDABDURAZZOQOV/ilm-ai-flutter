import 'package:flutter/material.dart';

/// Shown only while AuthController restores tokens from secure storage on
/// cold start; the router redirects away as soon as that resolves. Branded
/// indigo + Ilmo splash logo so native and Flutter splash match.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const _indigo = Color(0xFF2A1F6B);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: _indigo,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image(
              image: AssetImage('assets/mascot/splash_logo.png'),
              width: 160,
              height: 160,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 36),
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.6,
                valueColor: AlwaysStoppedAnimation(Color(0xFFF9A825)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
