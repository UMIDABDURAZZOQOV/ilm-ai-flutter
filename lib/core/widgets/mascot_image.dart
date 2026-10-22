import 'motion.dart';
import '../theme/app_theme.dart';
import '../theme/ilmo_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

enum MascotPose { hello, happy, thinking, explaining, sad }

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

  /// Leave null beside explanatory text to avoid duplicate announcements.
  final String? semanticLabel;

  const MascotImage({
    super.key,
    required this.pose,
    this.size = 72,
    this.animate = true,
    this.fit = BoxFit.contain,
    this.semanticLabel,
  }) : assert(size > 0 && size < double.infinity);

  const MascotImage.hero({
    super.key,
    required this.pose,
    this.animate = true,
    this.semanticLabel,
  }) : size = IlmoSizes.hero,
       fit = BoxFit.contain;

  const MascotImage.compact({
    super.key,
    required this.pose,
    this.animate = true,
    this.semanticLabel,
  }) : size = IlmoSizes.compact,
       fit = BoxFit.contain;

  @override
  Widget build(BuildContext context) {
    // Explicit preferred dimensions also support existing IntrinsicHeight
    // parents (the welcome screen), without asking LayoutBuilder for intrinsics.
    return SizedBox(
      width: size,
      height: size,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final extent = size
              .clamp(
                0.0,
                constraints.maxWidth < constraints.maxHeight
                    ? constraints.maxWidth
                    : constraints.maxHeight,
              )
              .toDouble();
          if (extent == 0) return const SizedBox.shrink();
          // All approved masters are 1024px square. Decode for physical display
          // pixels instead of retaining a 4 MiB RGBA image for every small pose.
          final pixels = (extent * MediaQuery.devicePixelRatioOf(context))
              .ceil()
              .clamp(1, 1024);
          Widget image = Image.asset(
            pose.assetPath,
            width: extent,
            height: extent,
            cacheWidth: pixels,
            cacheHeight: pixels,
            fit: fit,
            filterQuality: FilterQuality.medium,
            semanticLabel: semanticLabel,
            excludeFromSemantics: semanticLabel == null,
            errorBuilder: (context, error, stackTrace) => ExcludeSemantics(
              excluding: semanticLabel == null,
              child: Semantics(
                label: semanticLabel,
                image: true,
                child: SizedBox.square(
                  dimension: extent,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(IlmoSpacing.small),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'ILM AI',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? BrandPalette.creamWhite
                                : BrandPalette.indigo,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );

          if (animate && !MediaQuery.disableAnimationsOf(context)) {
            image = image
                .motion(context)
                .fadeIn(duration: IlmoMotion.entrance)
                .scale(
                  begin: const Offset(
                    IlmoMotion.entranceScale,
                    IlmoMotion.entranceScale,
                  ),
                  end: const Offset(1.0, 1.0),
                  duration: IlmoMotion.entrance,
                  curve: Curves.easeOutCubic,
                );
          }

          return Center(
            widthFactor: 1,
            heightFactor: 1,
            child: SizedBox.square(dimension: extent, child: image),
          );
        },
      ),
    );
  }
}
