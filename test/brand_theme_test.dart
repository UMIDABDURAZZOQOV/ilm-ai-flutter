import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ilm_ai_flutter/core/theme/app_theme.dart';
import 'package:ilm_ai_flutter/core/widgets/romb_badge.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/skill_ui.dart';

void main() {
  group('1-BOSQICH: Brand Palette and Theme Tests', () {
    test('BrandPalette constants match exact specification', () {
      expect(BrandPalette.indigo, const Color(0xFF2A1F6B));
      expect(BrandPalette.accentOrange, const Color(0xFFF9A825));
      expect(BrandPalette.turquoise, const Color(0xFF2DD4BF));
      expect(BrandPalette.creamWhite, const Color(0xFFFAF7F2));
    });

    test('learningPalette in light mode provides brand colors and semantic safety', () {
      final palette = learningPalette(lightColors);

      // Brand colors
      expect(palette.primary, BrandPalette.indigo);
      expect(palette.secondary, BrandPalette.accentOrange);
      expect(palette.accent, BrandPalette.turquoise);
      expect(palette.creamWhite, BrandPalette.creamWhite);

      // Semantic safety (green success, red error)
      expect(palette.success, const Color(0xFF059669));
      expect(palette.error, const Color(0xFFDC2626));
      expect(palette.warning, const Color(0xFFD97706));

      // Background and card contrast
      expect(palette.background, Colors.white);
      expect(palette.card, Colors.white);
    });

    test('learningPalette in dark mode provides deep indigo background with high contrast', () {
      final palette = learningPalette(darkColors);

      // Dark background is deep indigo, not grey/green
      expect(palette.background, BrandPalette.indigoDarkBg);
      expect(palette.surface, BrandPalette.indigoDarkSurface);
      expect(palette.card, BrandPalette.indigoDarkCard);
      expect(palette.border, BrandPalette.indigoDarkBorder);

      // Primary is high-contrast indigo, secondary is accent orange, accent is turquoise
      expect(palette.primary, BrandPalette.indigoDarkPrimary);
      expect(palette.secondary, BrandPalette.accentOrange);
      expect(palette.accent, BrandPalette.turquoise);
      expect(palette.creamWhite, BrandPalette.creamWhite);

      // Semantic colors intact in dark mode
      expect(palette.success, const Color(0xFF34D399));
      expect(palette.error, const Color(0xFFF87171));
    });

    test('skillColor fallback defaults to brand indigo #2A1F6B', () {
      expect(skillColor(null), BrandPalette.indigo);
      expect(skillColor(''), BrandPalette.indigo);
      expect(skillColor('invalid'), BrandPalette.indigo);
      expect(skillColor('#2DD4BF'), const Color(0xFF2DD4BF));
    });

    test('gradeColor reflects new brand accents', () {
      expect(gradeColor('A+'), const Color(0xFF059669)); // Success emerald
      expect(gradeColor('B+'), const Color(0xFF2DD4BF)); // Brand turquoise
      expect(gradeColor('C'), const Color(0xFFF9A825)); // Brand orange
      expect(gradeColor('Sertifikatsiz'), const Color(0xFFFF4B4B)); // Error red
    });

    testWidgets('RombBadge renders child in signature diamond brand shape', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: RombBadge(
                size: 60,
                color: BrandPalette.indigo,
                child: const Icon(Icons.star, color: Colors.white, size: 24),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(RombBadge), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });
  });
}
