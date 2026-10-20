import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

Duration motionDuration(BuildContext context, int milliseconds) =>
    MediaQuery.disableAnimationsOf(context)
    ? Duration.zero
    : Duration(milliseconds: milliseconds);

extension AccessibleMotion on Widget {
  Animate motion(
    BuildContext context, {
    void Function(AnimationController)? onPlay,
  }) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Animate(
      autoPlay: !reduced,
      value: reduced ? 1 : null,
      onPlay: reduced ? null : onPlay,
      child: this,
    );
  }
}
