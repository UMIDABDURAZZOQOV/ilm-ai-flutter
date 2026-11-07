# Reviewed mobile staging checkpoint — 2026-11-07

**Not a production signoff.** See backend
`ilm-ai-beta/docs/beta/HTTPS_STAGING.md` and
`docs/beta/FINAL_FIX_PROGRESS_20261107.md` for current blockers and actual evidence.
No staging host, Google OAuth client or certificate has been provisioned.

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

Only after the actual operator-approved HTTPS/OAuth/database deployment is
configured and accepted, build staging with its real public origin, not the
synthetic `.test` origin used by automated fixtures:

```powershell
flutter build apk --debug --target lib/main.dart `
  --build-name=1.0.3 --build-number=4 `
  --dart-define=REVIEWED_MOBILE_RELEASE=true `
  --dart-define=MOBILE_STAGING=true `
  --dart-define=API_URL=https://<approved-staging-api-host>
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
