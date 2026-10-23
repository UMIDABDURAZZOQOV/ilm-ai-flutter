import 'package:flutter/material.dart';

/// The approved face master used to create the current launcher icons.
/// Unlike the adaptive foreground, it has no launcher safe-circle padding.
class IlmoBrandMark extends StatelessWidget {
  const IlmoBrandMark({super.key, this.size = 160});

  static const asset = 'assets/mascot/ilmo_app_icon_new.png';
  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
    asset,
    width: size,
    height: size,
    fit: BoxFit.contain,
    cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).ceil().clamp(
      1,
      1254,
    ),
    filterQuality: FilterQuality.medium,
    // The adjacent ILM AI wordmark names the brand once for screen readers.
    excludeFromSemantics: true,
    errorBuilder: (context, error, stackTrace) => SizedBox.square(
      dimension: size,
      child: Center(
        child: Text('ILM AI', style: Theme.of(context).textTheme.titleLarge),
      ),
    ),
  );
}
