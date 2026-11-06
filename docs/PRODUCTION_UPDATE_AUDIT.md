# Existing Play application update audit — 2026-11-06

## Decision

**Release approval is withheld. This is an update of an existing Play app.**
The published application is `com.ilmai.app`, not the separate local
`com.ilmai.app.beta`. Do not upload the debug Beta, replace the package ID,
regenerate the upload key, disable source/preview gates, or deploy from this audit.
Work is isolated on `qa/play-release-audit-20261106` in both Beta worktrees.

The user's earlier “first release” answer was corrected: the app is already
published. Public listing and previous signed artifacts independently confirm it.
Absence of signing files in the Beta worktree was not evidence that no release
configuration existed.

## Verified existing release identity

- Play listing: <https://play.google.com/store/apps/details?id=com.ilmai.app>.
- Original local worktree: `../ilm-ai-flutter`, inspected read-only; its existing
  `android/key.properties` and `android/app/upload-keystore.jks` are untracked.
  Their contents/passwords were not printed or committed.
- Upload certificate SHA-256:
  `D0:F0:08:1B:E1:E3:EA:F6:79:8E:4C:95:57:0B:57:36:55:57:DA:23:B5:37:81:F0:DB:B4:19:10:3D:90:04:35`.
- `keytool` successfully opened the existing key/alias. The old release APK
  verifies with `apksigner`; its signer and the old AAB signer match this key.
  The user supplied the same fingerprint from Play Console during this audit.
  This confirms the upload certificate, not the distinct Play app signing key.
- Old APK: `../ilm-ai-flutter/build/app/outputs/apk/release/app-release.apk`,
  75,755,440 bytes, `com.ilmai.app`, 1.0.2/code 3, minSdk 24, targetSdk 36.
- Old AAB: `../ilm-ai-flutter/build/app/outputs/bundle/release/app-release.aab`,
  64,414,113 bytes. Neither old local artifact is assumed to be the latest
  uploaded artifact. The user subsequently confirmed Console production code3
  (1.0.2), Alpha code2 (1.0.1), and approved **1.0.3/code4** for the update.
  `pubspec.yaml` is updated accordingly; package/signing identity is preserved.

## Fixes made in this audit

1. The shared authenticated Dio client previously dispatched requests to an
   arbitrary absolute URL, including explicit `skipAuth` credential bodies,
   and allowed request-level redirects. Five new tests failed before the fix.
   It now rejects any origin/userinfo mismatch before dispatch and enforces
   `followRedirects=false`. Browser OAuth remains separate. Existing Beta/QA
   origin restrictions and refresh compare-and-swap are retained.
2. Settings now offers the existing official public privacy policy linked from
   Play. The fixed HTTPS URL is opened externally, without tokens or account
   identifiers. Repeated taps are coalesced; unavailable/failed browser launch
   gives a localized retry message. This link does not implement account deletion.
3. Gradle accepts an **explicit** `ILM_ANDROID_KEY_PROPERTIES` local path so an
   isolated worktree can reuse the existing private signing configuration.
   Relative keystore paths resolve beside that configuration's original
   `android/app` directory. Default local behavior, permanent application ID,
   debug identity, and all Beta/QA release prohibitions remain intact.

## Live server compatibility (read-only)

On 2026-11-06 the currently configured HTTPS origin
`https://ilm-ai-backend-256x.onrender.com` returned:

| Request | Result | Interpretation |
| --- | --- | --- |
| GET `/health` | 200, status ok, HTTPS | Reachable; health alone is insufficient |
| GET `/openapi.json` | 200 | Existing deployed route inventory inspected |
| GET `/auth/mobile/config` | **404** | New client's required PKCE v2 preflight unavailable |
| GET `/mobile/skills/subjects` | **404** | Normal release catalogue namespace unavailable |
| GET `/skills/subjects` | 200, list | Legacy catalogue exists; it is not a safe substitute |
| GET `/beta/config` | 404 | Local Beta routes are not deployed there |

No production credentials were used and no production login, account, answer,
reward, database migration, source import or configuration was written. A 404
preflight does **not** establish whether the older deployed Google OAuth itself
is configured. The new mobile protocol must be deployed/verified through a
separate approved backend release. Do not downgrade to token-bearing deep links.

The independent local Beta remains loopback-only on port 8930. Its
`google_configured=false`, `test_auth_available=true`, and `production_ready=false`
are local facts, not statements about the existing production deployment.
The user confirms no separate HTTPS/OAuth test environment currently exists.

## Actual handset acceptance

Samsung SM_A125F / Android 12 / serial R58NC0JNBXJ, normal Beta package only.
Before rebuilding, the installed artifact was the earlier `0fd5baa` code build.

- Existing account entered Learn without repeated onboarding.
- Settings → confirm logout reached the one-action local Beta registration screen.
- Android Back exited that screen; reopening still required authentication.
- Registration restored the same account, Biology grade 7, and saved question 3/8.
- All nine measured user/progress table counts and digests remained unchanged
  across logout/login. Refresh-token rows are expected to rotate and are excluded.
- Removed only ADB reverse (no Wi-Fi/mobile-data setting changes), force-stopped
  and reopened: session was retained, catalogue showed a localized connection
  error with Retry/Settings. Restored reverse and Retry recovered the same Learn
  screen and saved question 3/8 without reauthentication.
- No uninstall/data clear, personal answer submission or XP reset. No production
  account deletion or destructive data migration was performed.
- Another app became foreground during a later capture. That capture is excluded
  from app acceptance. Local capture helper now fails closed outside the Beta
  package and rejects stale/failed UI dumps.

These are real **local Beta** tests, not a production Google account chooser,
cross-device identity test, or a Play-signed upgrade test.

## Outstanding release blockers

1. **Backend/client contract**: missing live PKCE v2 and mobile catalogue routes.
   Set up an isolated HTTPS test deployment before testing real OAuth or writes;
   rollout must preserve existing IDs, users, progress and old-client compatibility.
2. **Five-subject publication**: ordinary release still defaults to reviewed
   Biology only. Five-subject/FRQ/help integration is Beta-only and protected by
   preview/source gates. It must receive a separate reviewed production integration;
   setting `BIOLOGY_ONLY=false` or removing Beta guards is not an acceptable fix.
   Some Beta-only UI changes likewise are not ordinary-release features yet.
3. **Account deletion**: inspected mobile Settings/auth and backend routes have
   no account-deletion workflow. The public policy says deletion is available
   in-app/by contact. A verified, owner-scoped request/deletion workflow and a
   discoverable public deletion resource must be implemented and tested without
   deleting anyone else's records or shared textbook content. The privacy button
   alone does not close this issue.
4. **Store declarations**: public listing currently says “No data collected,”
   while the published privacy policy and account/progress models describe account
   and usage data collection. The owner must reconcile Data safety with actual
   deployed behavior and SDKs. The policy's AI sharing/training statements also
   require verification against actual production provider settings; no assumption
   is made from the local Beta's absent AI key.
5. **Signed upgrade**: versionCode4/1.0.3 is now approved from Console highest3;
   Play App Signing's app certificate is distinct from the verified upload key.
   Validate a Play internal-track upgrade over an existing Play installation,
   retaining account/drafts/progress. Do not sideload an upload-key APK over a
   Play-signed installation or uninstall to bypass a signature mismatch.
6. **Device/performance**: Samsung is a 4096-byte page-size Android 12 device.
   Old release APK's eight 64-bit ELF libraries pass >=16KB segment alignment;
   `zipalign -c -P 16 4` passes. This is structural evidence only. New signed AAB
   and Android 16/16KB runtime, accessibility, and optimized profile comparisons
   are still required; debug frame timings are not production performance proof.

No “100% bug-free” or production signoff is made from passing automated tests.

## Validation records

Local ignored artifacts in `../ilm-ai-beta-artifacts`:

- `release-audit-boundary-before.log`: 5 failures reproducing the transport issue.
- `release-audit-auth-tests.log`: **55 passed** after fix (auth/refresh/PKCE,
  session restore, concurrency and performance regressions).
- `release-audit-privacy-tests.log`: **17 passed**, including public policy launch
  success/failure/repeated taps and account layouts in three languages, two themes,
  small/landscape screens and 200% text.
- `release-audit-backend-auth.log`: **53 passed**, one Starlette/httpx deprecation.
- `release-audit-backend-beta.log`: **14 passed, 12 deselected**, one deprecation;
  SQLite copied fixture only, PostgreSQL not exercised in this run.
- `release-audit-flutter-full.log`: **1,334 passed**; reported elapsed 114m55s
  under host memory pressure. Separate privacy/accessibility run covers the files
  added after full-suite enumeration; the suites overlap and must not be summed.
- `release-audit-analyze.log`: **No issues found**, reported 6274.7s.
- `progress-release-audit-before-20261106.json` and
  `progress-release-audit-after-login-20261106.json`: all 9 table digests equal.
- `release-audit-elf-alignment-20261106.json`: old release/current Beta ELF checks.
- `release-audit-logged-out-20261106.xml`,
  `release-audit-reopen-auth-fresh-20261106.xml`,
  `release-audit-relogin-fresh-20261106.xml`,
  `release-audit-current-safe-20261106.xml`: package-checked handset evidence.

Auto-review rejected an integration-test command referencing the live local Beta
DB path. It was replaced with an explicit consistent SQLite backup via a read-only
source connection, sanitized ownership marker and disposable test DBs. The live
database was never a writable test target. No credentials were copied into logs.

## Official requirements checked

- [Android versioning](https://developer.android.com/studio/publish/versioning):
  update versionCode must exceed previously used values.
- [Current target API requirement](https://developer.android.com/google/play/requirements/target-sdk):
  app updates require API 36 as of this audit date; inspected APK already targets 36.
- [16KB guidance](https://developer.android.com/guide/practices/page-sizes):
  native alignment and runtime testing are separate checks.
- [Account deletion](https://support.google.com/googleplay/android-developer/answer/13327111?hl=en):
  in-app and public-web request pathways and associated data handling are required.
- [Data safety](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en-EN):
  declarations must reflect actual collection and processing.
- [Existing public policy](https://ilm-ai-edu.vercel.app/privacy).
