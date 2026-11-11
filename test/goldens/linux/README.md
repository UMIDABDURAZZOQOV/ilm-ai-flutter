# Reviewed Linux host references

These sixteen additional references were visually reviewed against their existing
Windows masters, actual Linux test images and masked diffs on 2026-11-11.
The existing `test/goldens/*.png` Windows references are unchanged.

Source: approved diagnostic commit `628412110e9c23b9f2ffd68bcb3cda65fd5e4296`,
[GitHub run43029048233](https://github.com/UMIDABDURAZZOQOV/ilm-ai-flutter/actions/runs/43029048233),
artifact13858963442, archiveSHA256
`ff5576f783206adb2ed71b2f65a9b2818a61e4408d6d6610cb96f8f712ae1412`.
The artifact had one-day retention; reviewed image provenance is recorded in
`review.json` so future tests do not depend on its continued availability.

The four public Roboto/MaterialIcons files, Flutter3.44.6 framework revision,
engine revision and Dart3.12.2 fingerprints matched Windows exactly. Differences
are confined to rendered glyphs (Roboto, MaterialIcons and default Ahem in the
controls fixture), not card/button layout, vector navigation icons or Ilmo images.
All sixteen image pairs were reviewed; no clipping, missing control, changed
word wrapping or functional UI defect was identified in these differences.
No real learner screenshot, OAuth token or credential is included.

This is a deliberate, finite addition after review, not an automatic refresh of
failing images. No `--update-goldens` command was used. New outputs must not be
copied into these references without a new visual review and provenance record.
Flutter's original `matchesGoldenFile`/`LocalFileComparator` remains pixel-exact;
no masking, tolerance, skip or fallback-to-success is used. Unsupported hosts
fail explicitly. A one-pixel mutation regression verifies strict rejection.

Flutter documents host-specific font rasterization in its
[GoldenFileComparator font guidance](https://api.flutter.dev/flutter/flutter_test/GoldenFileComparator-class.html).
This evidence establishes the cross-host glyph-rendering mismatch, but does not
identify a particular native rasterizer flag or prove every screen production-ready.
Linux CI must actually run successfully after the candidate is separately approved
for push; comparison against captured bytes is not a new Linux application run.
