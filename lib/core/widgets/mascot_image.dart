import 'motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

enum MascotPose {
  hello,
  happy,
  thinking,
  explaining,
  sad,
}

extension MascotPoseAsset on MascotPose {
  String get assetPath {
    switch (this) {
      case MascotPose.hello:
        return 'assets/mascot/ilmo_hello.png';
      case MascotPose.happy:
        return 'assets/mascot/ilmo_happy.png';
      case MascotPose.thinking:
        return 'assets/mascot/ilmo_thinking.png';
      case MascotPose.explaining:
        return 'assets/mascot/ilmo_explaining.png';
      case MascotPose.sad:
        return 'assets/mascot/ilmo_sad.png';
    }
  }
}

/// Small Ilmo mascot image widget with pose enum and light entrance animation.
class MascotImage extends StatelessWidget {
  final MascotPose pose;
  final double size;
  final bool animate;
  final BoxFit fit;

  const MascotImage({
    super.key,
    required this.pose,
    this.size = 72,
    this.animate = true,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(
      pose.assetPath,
      width: size,
      height: size,
      fit: fit,
      excludeFromSemantics: true,
      errorBuilder: (context, error, stackTrace) => SizedBox(
        width: size,
        height: size,
      ),
    );

    if (animate && !MediaQuery.disableAnimationsOf(context)) {
      image = image
          .motion(context)
          .fadeIn(duration: 250.ms)
          .scale(
            begin: const Offset(0.92, 0.92),
            end: const Offset(1.0, 1.0),
            duration: 250.ms,
            curve: Curves.easeOutCubic,
          );
    }

    return image;
  }
}
