# Reviewed mobile staging checkpoint — 2026-11-08

Real HTTPS staging on Samsung SM-A125F now accepts two owner-approved Google
accounts, independent onboarding, restart/session restoration, A→B→A logout/login,
MCQ/FRQ and saved progress. A returned to30 XP/two lessons/20-XP goal; B independently
started atzero and completed Chemistry7 at12/12,+20 XP/one lesson/10-XP goal.
A's Chemistry result was11/12 and Physics5/6; correct/incorrect feedback and
optional reviewed explanations were observed. No identities or tokens are reported.

Three real fixes are accepted: route-extra restoration (`e3571d3`), reviewed
profile404 (`d587f9b`) and native FRQ semantics (`23f696f`, following470313d).
Current Flutter source23f696f: **1375 full tests passed** (serial38:33),105 default
targeted/10 reviewed contracts passed, full analyze **No issues found**.
Backend Live d587f9b: **5334 passed,65 skipped,21 warnings**, import/Docker passed
in CI42395951490. Awake exact-Live public preflight9/9 passed. Counts overlap and
must not be summed; the earlier interrupted Flutter attempt is retained separately.

Current installed artifact: `ILM-AI-Staging-1.0.3-code4-23f696f.apk`,180506516 bytes
(172.14 MiB), SHA2560268df56e4bee55d097dbb885a3b46c0ade13dd04322eda463257419c430abe2.
Separate staging package, install-r Success, no clear/uninstall, bounded credential
scan zero matches. Private OAuth file still has the doubled.json.json extension
and matches active staging. Free hosting/DB, auto-deploy off, deletion/test-auth/
preview flags off; no external AI key. Verified fallback works.

**Production NO-GO**: Live e97c029/main remains unchanged. Production baseline/
verified backup restore/migration/import/deploy approval, actual deletion sender/
policy/storage acceptance, Play-signed1.0.2 update/OAuth compatibility, provider
audience/configuration, exposed operator-key rotation and stable performance/
final production artifact acceptance remain. Free idle wake/timeouts are retained
as failures; no current cold-start SLA or artificial keepalive is claimed.
See backend `docs/beta/GOOGLE_STAGING_ACCEPTANCE_20261107.md` and
`docs/beta/PRODUCTION_READINESS_20261108.md` for current evidence and release gates.

The normal `lib/main.dart` supports an explicit reviewed-learning opt-in:

- `REVIEWED_MOBILE_RELEASE=true`: shared five-subject UI, `/mobile/skills` and
  `/mobile/v2/<subject>`, `/mobile/study-help`; existing Google auth/PKCE remains.
- `MOBILE_STAGING=true`: Android package`com.ilmai.app.staging`, label`ILM AI Staging`,
  callback scheme`ilmai-staging`; requires the reviewed flag and a separate HTTPS
  origin. The known production host, HTTP, credential/query/path URLs are rejected.
- Neither flag enables Beta/test-login auth. They cannot be combined with
  `INTEGRATED_BETA`, `PHONE_QA`, `PHYSICS_PREVIEW` or another entry point. Existing
  Beta/QA release prohibitions remain in force.
- Production keeps `com.ilmai.app`/`ILM AI`/`ilmai`. Default old publication mode is
  retained until hosted acceptance; omitting the reviewed flag does not silently
  publish all subjects. Do not label an old Biology-only AAB as five-subject ready.

To perform real device acceptance against the now operator-approved dedicated
HTTPS/OAuth/database staging, build with its real public origin, not the
synthetic `.test` origin used by automated fixtures. Building an APK does not
itself accept Google/device flows:

```powershell
flutter build apk --debug --target lib/main.dart `
  --build-name=1.0.3 --build-number=4 `
  --dart-define=REVIEWED_MOBILE_RELEASE=true `
  --dart-define=MOBILE_STAGING=true `
  --dart-define=API_URL=https://ilm-ai-103-stage-8b0727.onrender.com
```

No provider key, Google client secret, refresh token or test installation secret
belongs in any define, source file or APK. API origin and feature flags are public
configuration. Actual production AAB, signing/Play upgrade and device acceptance
remain separate release gates; no upload is authorized.

## Session startup and UX

Known cached profile state routes immediately while profile/preferences validate
in background. Requests have10s cancellation deadlines. Session generation and
controller epoch prevent late restore results from changing logout/new-account/
same-account relogin state. Unknown legacy profile state still resolves or shows
the existing retry screen; server authentication is not bypassed. This does not
prove an actual device startup time improvement.

Reviewed welcome has one registration action, a persisted one-time textbook
notice, no local Beta login in release, and the existing Google account chooser
for new/returning accounts. Learning reuses feedback-only MCQ/FRQ explanations,
source/topic-count hiding, grade locks, drafts/retries and per-account progress.

Testing commands use synthetic fixtures and disposable preferences:

```powershell
flutter test test/performance_regression_test.dart test/release_hardening_test.dart
flutter test --dart-define=REVIEWED_MOBILE_RELEASE=true `
  --dart-define=MOBILE_STAGING=true `
  --dart-define=API_URL=https://staging.example.test `
  test/integrated_beta_test.dart test/reviewed_mobile_release_test.dart
flutter analyze
```

38 session/hardening and44 reviewed-staging UI/API tests passed. Login light/dark
goldens were visually inspected and updated only for the requested registration
label. Final full-suite/analyze/native artifact results are recorded in the
central handoff; mock tests are not real hosted OAuth/device acceptance.
