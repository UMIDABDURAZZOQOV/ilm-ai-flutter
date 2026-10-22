/// Ilmo occupies a square canvas. These are layout sizes, not new artwork.
abstract final class IlmoSizes {
  static const double inline = 56;
  static const double compact = 88;
  static const double feedback = 96;
  static const double lesson = 112;
  static const double hero = 140;
  static const double celebration = 176;
  static const double splash = 160;
}

abstract final class IlmoMotion {
  static const entrance = Duration(milliseconds: 250);
  static const double entranceScale = .96;
}

abstract final class IlmoSpacing {
  static const double small = 8;
  static const double standard = 16;
  static const double section = 24;
}
