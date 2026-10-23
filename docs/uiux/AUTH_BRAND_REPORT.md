# Login and authentication branding

## Scope and asset choice

The old diamond logo was still referenced by `LoginScreen` and the retained,
unrouted `SignUpScreen`. Both now use `IlmoBrandMark` with the **unchanged**
`assets/mascot/ilmo_app_icon_new.png` master (1254 x 1254, transparent).
This is the source of the current launcher icons, recorded in
`docs/brand/launcher_icon_manifest.json`. Source SHA-256:
`13a5e77618906ab89d8f0c48d68dd6b46214f058b2d535ebc778479f76ea67ea`.

All eleven mascot assets were inventoried. The face master, current launcher,
both foregrounds and splash were inspected visually. The chosen face preserves
the cream robot, purple eyes, patterned indigo doppi, turquoise antenna, yellow
ears and original cheerful expression. The adaptive launcher foreground has
456 x 442 visible pixels on a 1024 square safe-area canvas, so using it directly
would make the login face unnecessarily small. The master displays fully with
`BoxFit.contain`, no clipping or transformation, and a physical-pixel decode
width. No new raster, mascot, launcher regeneration or original asset edit was
needed. Missing-asset fallback is a text wordmark, never the retired logo.

## Presentation

- Face and ILM AI wordmark are centered above the localized heading.
- Content is vertically centered when it fits, with a 440 logical pixel reading
  width and natural scrolling when text or screen constraints require it.
- Heading, explanation and Google action have explicit spacing and hierarchy.
- Existing theme text, surface and action colors support light/dark contrast.
- The old logo shadow and bounce are removed. One 220 ms fade has no delay or
  repeating motion. Reduce Motion shows the final state immediately; its loading
  indicator is static and carries a localized signing-in label.
- The heading is a semantic header, errors a live region, and the decorative
  face does not repeat the adjacent wordmark to screen readers.

## Branding audit

| Surface | Finding and action |
| --- | --- |
| Login / welcome back | Retired icon replaced with official face. |
| Destination after logout | Existing router redirects a signed-out session to the same `/login`; mocked regression covers it. |
| Retained signup source | Same replacement; no new route or auth mechanism added. |
| Native splash | Already uses `assets/mascot/splash_logo.png` in light/dark and Android 12 configuration; retained. |
| Flutter splash / restore error | Same existing Ilmo splash, with progress or retry message; retained. |
| Welcome / onboarding | Existing original Ilmo hello, explaining, happy and thinking poses; retained. |
| Login loading / authentication error | Official face remains visible above the existing Google action and localized error. |
| Generic loading/error views | Neutral progress/cloud symbols, no retired brand mark; retained. |
| Launcher | Current official Ilmo assets and native outputs retained. |
| `assets/icons/icon.png` | No remaining Dart UI references. Original file and pubspec entry retained to preserve assets. |

The lesson milestone diamonds/stars are navigation and progress symbols, not
the retired app logo. They remain unchanged.

## Google OAuth boundary

The app uses the existing backend mobile PKCE exchange and
`FlutterWebAuth2.authenticate`. Its implementation, callback, client IDs,
configuration, token storage and session controller are unchanged. The app name,
logo and verification information displayed by Google's hosted consent/account
screens are managed outside Flutter in the Google Cloud OAuth branding settings.
No Google Cloud or backend configuration was edited or claimed verified.

## Review artifacts

Controlled before/after renders use the Samsung A12 viewport: **720 x 1600
physical pixels, DPR 1.875**, with the same mocked preferences, safe insets,
text scale and reduced-motion setting. They are widget renders, not native phone
screenshots; system bars and Google's hosted UI are not rendered.
The baseline was captured from `6d29d4e` before editing login.

- [Russian, light comparison](../brand/auth-login/ru-light.png)
- [Russian, dark comparison](../brand/auth-login/ru-dark.png)
- All UZ/RU/EN pairs and loading/error renders:
  `.dart_tool/auth-brand-review/{before,after,comparisons}/`.
- Capture hashes/settings: `.dart_tool/auth-brand-review/comparison-manifest.json`.
- Recompose: `python scripts/compare_auth_brand.py` after capturing both stages.

No real account was signed out for this review. No application data was cleared,
and no APK was installed over another running development session.

## Verification

Checks on 2026-10-23:

| Check | Result |
| --- | --- |
| Original login baseline capture | 6 tests passed before implementation. |
| New focused tests and capture/golden generation | 28 passed, exit 0 (12.4 s wrapper). |
| Full suite, without updating goldens | 453 passed, exit 0 (119.8 s wrapper). |
| Original assets | All 20 files byte-for-byte unchanged. |
| Google sign-in handler | Compared with baseline; unchanged. |
| `flutter analyze --no-pub` | No issues found, exit 0 (140.1 s analyzer, 144.5 s wrapper). |

- New widget tests: A12 alignment/assets/CTA, UZ/RU/EN, light/dark,
  320 x 568 and 640 x 360 at 200% text, loading/error, reduced motion,
  retained signup, retired-reference audit and mocked signed-out routing.
- Light/dark login goldens use real review fonts.
- Full Flutter suite includes existing OAuth, storage, launcher, routing,
  accessibility, biology and progress regressions.
- `flutter analyze --no-pub`.
- All original asset hashes compared before and after.

Existing platform plugin registrant changes from other work are excluded from
this commit. Backend, lesson data and progress code are outside this change.

## Changed files

- `lib/core/widgets/ilmo_brand_mark.dart`: shared official face rendering.
- `lib/features/auth/presentation/login_screen.dart`: brand/layout/motion and
  accessible loading presentation; authentication handler unchanged.
- `lib/features/auth/presentation/signup_screen.dart`: remove second stale logo.
- `test/auth_brand_test.dart`: 28 isolated tests and optional A12 captures.
- `test/goldens/auth_login_{light,dark}.png`: login visual regressions.
- `scripts/compare_auth_brand.py`: reproducible comparison composition.
- `docs/brand/auth-login/ru-{light,dark}.png`: controlled before/after review.
- `docs/uiux/AUTH_BRAND_REPORT.md`: audit, scope, verification and limitations.
- `UI_UX_HANDOFF.md`: summary and link to this report.
