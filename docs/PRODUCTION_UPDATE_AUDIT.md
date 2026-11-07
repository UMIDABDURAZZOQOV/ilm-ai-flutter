# Existing Play application update audit — 2026-11-06

## Latest hosted checkpoint — 2026-11-08

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

Earlier sections are historical checkpoints, superseded by this record.

## 2026-11-06 - Final-readiness follow-up: NO-GO remains

Backend source commit: `98cd97cb77571b2112df889ef352333c3bebe81e`; running loopback service remains `974f542`, not hot-reloaded.

The user's full195-line final-readiness brief was read with credential redaction.
They confirmed Google AI Studio credentials. No disclosed key was used, saved,
committed or sent to any service. Revoke/replace them through the provider
console. Gemini Developer API's current under-18 client restriction conflicts
with this school app and the user's audience-compatibility requirement; it was
not connected. No replacement provider was activated.

### Changes completed in the isolated backend branch

- Optional existing OpenAI evidence selector: explicit reviewed private config
  outside all Git checkouts, symlink/reparse restrictions,1–8 unique configured
  keys, fixed provider origin, bounded authorized standby for eligible errors.
  Quota/rate errors do not sweep accounts. Retry-After pauses the whole pool;
  credit/spend exhaustion stops inference until operator reconfiguration.
- Reviewed evidence fallback retained. Free-form learner messages, selected
  answers, account/attempt IDs, source metadata and grader feedback/solutions
  are excluded from the optional external payload. Only reviewed teaching
  snippets may be selected; generated prose never becomes scientific content.
- Two-call/6s-per-attempt limits, capped input/completion, two in-flight calls,
 20/min and1000/UTC-day per-process attempt budget. Distributed durable billing
  caps and a real audience/privacy review are still production requirements.
- Read-only public API preflight: health200; mobile auth/catalogue and all five
  grade endpoints404 (seven failed required contracts). No production writes.
- Additive0014 PKCE migration creates/validates state/grant tables, ownership
  and schemas without changing existing user IDs, XP or progress. No live
  migration was run. Backup/restore/rollback and old-client transition plan
  recorded in backend docs/beta/PRODUCTION_DEPLOYMENT_PLAN.md.

### Fresh tests and handset measurements

- Combined reviewed SQLite integration/provider/preflight/migration: **86 passed,
 12 deselected,1 deprecation,51.28s**. Explicit owned bootstrap and copied fixture.
- Separate backend identity/auth/security/migration: **57 passed,1 warning,
 301.01s**. Provider/preflight/migration unit run:65 passed. Suites overlap;
  do not sum these counts or add them to historical Flutter totals.
- New-file Ruff checks and Git whitespace checks passed. The legacy study_help
  file still has pre-existing ambiguous-variable lint findings; they were not
  suppressed and are not claimed fixed. No Dart/native source changed here.
- Fresh Flutter analyze: **No issues found,247.9s**. The earlier1334 Flutter/95
  Beta/other suites refer to the unchanged app source384f6d6, not new test runs.
- Profile builds succeeded (310.1s isolated Perf,454.4s existing Beta identity);
  package/certificate checks passed. Temporary same-certificate profile install
  used install-r and preserved existing authentication/draft. No answer, logout,
  onboarding reset, uninstall or data clear was performed.
- Actual existing-account profile startup, five force-stop launches: **Android
  TotalTime2443–2528ms, median2450ms**; Dart first-frame callback470–492ms,
  median477ms. All five reached Learn. UI-polled Learn visibility5902–7186ms
  includes ADB/uiautomator overhead and is not exact time-to-interactive.
- First launch after profile install was8330ms; debug restore launch again
  timed out at10532ms and later loaded. The original11s debug issue is NOT
  proven fixed or diagnosed as ANR. No “0 lag” or controlled speedup claim.
- Two five-tab navigation rounds:21/219(9.59%) and29/105(27.62%) frames exceeded
  the60Hz build/raster budget. Post-GC heap18,190,112→19,816,160 bytes and
  PSS156,134→174,123KiB. This short, instrumented workload cannot prove no leak;
  Android16/16KB, sustained workloads and crash/ANR acceptance remain open.
- Restored the unchanged stable debug APK with install-r Success. All nine
  measured user/progress table hashes remained unchanged throughout profiling.
  Installed-artifact hash and final UI verification are recorded in local receipts.

### Artifacts and outstanding work

The **existing** signed AAB remains:
`../ilm-ai-beta-artifacts/ILM-AI-1.0.3-code4-release-candidate.aab`
(76,951,648 bytes/73.39MiB, SHA256
`a3aa66463f996a772fc1f0d7b3f2fbc653c55f75160c3c34d02a65e4043f003c`,
source384f6d6). It is still Biology-only, not a newly integrated five-subject
release. Stable debug Beta remains209,804,239 bytes/200.08MiB, SHA256
`1a54a015468ad5087407ddb18ad88d5a47cb5c4136b759e99922bbdf239d8754`.
No release AAB was rebuilt while critical gates remain, and nothing was uploaded.

**Unfinished engineering:** production publication/integration of five subjects
without disabling preview/source gates; owner-verified in-app and public web
account deletion lifecycle; old-client compatibility; startup/jank diagnosis and
optimization. **Unavailable external acceptance:** approved HTTPS/OAuth staging,
new/returning/different real Google accounts and cross-device progress, actual
deployed schemas/config, Play-signed internal-track upgrade and owner-reviewed
Data safety/privacy declarations. Keys do not close any of these gates.

Port8930 remains the original running loopback Beta process with reviewed
fallback and no external AI; new source changes are not claimed deployed there.
Production DB/main/subject branches and existing signing material are preserved.
Full details: backend AI_PROVIDER_READINESS.md and PRODUCTION_DEPLOYMENT_PLAN.md.
Local receipts: final-readiness-production-contract.json, final-readiness-backend-
combined.log, final-readiness-backend-auth-confirm.log, final-readiness-flutter-
analyze.log, performance-final-readiness-existing-account-20261106-startup.json,
final-readiness-profile-nav.json and final-readiness-progress-restored.json.


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

### Native lint follow-up (before final rebuilt artifacts)

The first `:app:lintRelease` exposed **7 errors and18 warnings**. They were fixed
without adding a baseline, suppressing errors, raising minSdk, or changing branding:

- Launch attributes now use inherited API28/API29 day/night style resources;
  API24 base themes contain no newer attributes. Existing API31 splash is retained.
- Capture hardware is declared optional so camera permissions do not silently
  exclude otherwise compatible ChromeOS/tablet devices.
- Ignored Windows `local.properties` drive colons are escaped. Flutter regenerates
  this file; run `python scripts/normalize_android_local_properties.py` after a
  Flutter build and before native lint. Three utility tests cover this behavior.
- The existing no-backup policy now explicitly covers Android12+ cloud backup
  and device transfers, including credential-encrypted/device-encrypted domains.
  This does not delete local data or change server-side progress restoration.

Recheck: **lintRelease BUILD SUCCESSFUL**, **0 errors /17 warnings**, 3m06s.
Remaining warnings concern icon asset/config duplication/shape/monochrome, obsolete
resource qualifiers, a newer desugar library, and legacy storage permission.
They are recorded, not silenced or represented as zero warnings. Relevant
configuration/mobile OAuth/transport tests: **24 passed** after native changes.
The final rebuilt artifacts below include these fixes. Earlier pre-fix receipts
are retained separately and are superseded by the final build receipt.

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

## Built artifacts — update candidate, not release approval

The user explicitly approved 1.0.3/code4 and requested an AAB while retaining
the separate list of failed/unperformed production checks. Nothing was uploaded.

| Artifact | Actual path under `../ilm-ai-beta-artifacts/` | Bytes / MiB | Source commit |
| --- | --- | --- | --- |
| Signed release candidate AAB | `ILM-AI-1.0.3-code4-release-candidate.aab` | 76,951,648 / 73.39 | `384f6d6a2663fd65709df78b08ddfb09de91d138` |
| Local five-subject Beta debug APK | `ILM-AI-Beta-1.0.3-code4-20261106.apk` | 209,804,239 / 200.08 | `384f6d6a2663fd65709df78b08ddfb09de91d138` |

AAB SHA256: `a3aa66463f996a772fc1f0d7b3f2fbc653c55f75160c3c34d02a65e4043f003c`.
Beta APK SHA256: `1a54a015468ad5087407ddb18ad88d5a47cb5c4136b759e99922bbdf239d8754`.

**The AAB uses the existing ordinary Biology-only release configuration, not the
five-subject Beta configuration.** It targets the existing HTTPS API whose new
required endpoints still return404. It is not a functional five-subject production
signoff and must not be uploaded until the blockers above are resolved. Beta
release guards were not removed to manufacture a five-subject signed artifact.

Release build: `flutter --no-version-check build appbundle --release --no-pub
-t lib/main.dart --build-name 1.0.3 --build-number 4
--dart-define=API_URL=https://ilm-ai-backend-256x.onrender.com`, with existing
private key configuration referenced only through `ILM_ANDROID_KEY_PROPERTIES`.
Final build passed in 330.9s. The private key/password were not copied into the repo.
Final debug Beta build passed in 194.4s with the existing loopback Beta flags.

Google's bundletool1.18.3 (official release asset; upstream SHA256 verified)
validated the **actual final AAB**. `jarsigner` verified archive integrity;
`keytool` confirmed the exact user-approved upload certificate. Bundle manifest:
`com.ilmai.app`, 1.0.3/code4, non-debuggable, min24/target36, normal `ilmai` callback.
All eight final 64-bit native libraries have >=16KB ELF load alignment. ZIP scan
found no PDF/database/keystore/private config, known local-secret values or JWT
literals. This does not verify runtime behavior or production provider settings.
Beta APK signature/package/version and corresponding secret/source-file scan pass.

Final Beta `adb install -r` returned **Success**. The installed base.apk was read
and hashed without reading any account credentials/data: exact SHA256 matches the
final APK above, and package/version4/1.0.3 match. A fresh package-checked UI capture
shows the same account session, Biology7 and saved question3/8. All9 measured
user/progress table digests remain unchanged across the audit. No uninstall,
data clear, personal answer or XP reset. Five tabs were traversed on the earlier
1.0.3 build with the same Dart app code; all loaded and returned to the saved draft.

`am start -W` timed out at11017ms on the final install before the app subsequently
loaded Learn (verified by fresh screenshot/XML). This is a debug/device timing
observation, **not accepted cold-start performance** or an ANR diagnosis. Complete
profile/release startup and responsiveness acceptance remains open.

Additional final validation: **95 Beta Flutter tests** and **24 config/mobile
OAuth/transport tests** and3 SDK normalization tests passed. Final Android native
lint passed after all builds (1m33s), with0 errors/17 warnings. Final analyze:
No issues found (167.3s). Plugin KGP migration and Java deprecation warnings appeared in
successful builds; dependencies were not upgraded opportunistically.

Receipts: `release-audit-build-receipt-20261106.json`,
`release-audit-aab-verification-20261106.json`, `release-audit-api-evidence-20261106.json`.
The backend worktree at build was docs-only commit `5a65740`; the running local
service code remains the earlier `974f542`. Deployed production commit is unknown.

### Safe local phone commands

These commands install only the separate Beta, never the production AAB:

```powershell
$adb = 'C:\Android\platform-tools\adb.exe'
& $adb devices -l
# Continue only when the Samsung appears as device, not offline/unauthorized.
& $adb -s R58NC0JNBXJ reverse tcp:8930 tcp:8930
& $adb -s R58NC0JNBXJ install -r 'C:\Users\Page\Desktop\Projects\ilm-ai-beta-artifacts\ILM-AI-Beta-1.0.3-code4-20261106.apk'
& $adb -s R58NC0JNBXJ shell am start -n com.ilmai.app.beta/com.ilmai.ilm_ai_flutter.MainActivity
```

Keep the localhost backend running; USB reverse must be reapplied after reconnect.
Do not uninstall or clear app data to work around connectivity/signing issues.

### Final operating state

Local backend still returns200/ok/integrated_beta on127.0.0.1:8930; left running.
A fresh read-only35-call Beta API acceptance passed and all9 measured table digests
were unchanged. Production was not mutated; required public endpoint404 blockers
remain. Nothing was uploaded to Play or pushed/deployed remotely.

Phone evidence: `release-audit-installed-final-beta-20261106.json`,
`release-audit-final-installed-learn-20261106.png/xml`,
`release-audit-five-tabs-20261106.json`, `release-audit-device-status-20261106.json`.
Native errors before/after and final source validation:
`release-audit-android-lint.log`, `release-audit-android-lint-fixed.log`,
`release-audit-android-lint-final.log`, `release-audit-native-lint-final-report.xml`.
The automatic review usage-limit error temporarily prevented one ADB action; it
was retried through the same approval mechanism after the stated reset time,
not bypassed. Final on-device acceptance above supersedes the earlier USB-pending
checkpoint; it does not close real Google/Play upgrade/performance requirements.

Final handset privacy action was also tested: the fixed public privacy URI opened
external Chrome, without credentials in the URL. The Beta was restored to Learn
with saved question3/8. Evidence: `release-audit-privacy-device-20261106.json`.

## 2026-11-07 — final blockers implementation and new Beta artifact

**Production remains NO-GO.** This section supersedes earlier artifact/process
and pending account-deletion/publication engineering status. It does not replace
the still-required live Google, Play-signed upgrade, policy and device acceptance.

Functional source commits on `qa/final-production-fixes-20261106`:
Flutter `ac168c3acbd045f80a275d3297832057590cdae4`, backend
`b4e138a31d605cee0e1d2ae4a45068b5ce0da88c`. Later docs-only commits do not change
the code used for the new APK. Main/subject branches and production were not edited.

### App changes

Settings now contains the localized signed-in account-deletion action. The dialog
requires explicit permanent-deletion consent, emailed6-digit proof and server
acknowledgment. Pending file cleanup and financial retention review have distinct,
honest states. Server errors do not falsely clear/log out the account. Successful
revocation clears only the exact UID's local lesson drafts/preferences and matching
secure-session generation. Other accounts/global theme-language/ordinary logout
are preserved. A late deletion acknowledgment cannot clear a new same-UID login.
Final small-screen Uzbek200% text/keyboard widget tests reproduced an overflow;
moving actions into scrollable content fixed both failures. Existing learning,
subject switching, graders and checked-feedback-only help were not rewritten.

Changed app files: `lib/features/settings/{data/account_deletion_repository.dart,
presentation/account_deletion_button.dart,presentation/settings_screen.dart}`,
`lib/features/auth/application/auth_controller.dart`,
`lib/core/storage/{prefs_service.dart,secure_token_storage.dart}` and
`test/account_deletion_test.dart`.

### Evidence

- Full Flutter suite1359 passed/20m35s before the final responsive dialog fix;
  final targeted deletion/auth/storage/widget20 passed after that fix.
  Do not describe this as a single full1367-test run.
- Reviewed-staging UI/API44 and local-Beta UI/API44 passed as separate mocked
  transport commands. Final analyze: No issues found,234s.
- Backend deletion32 passed on disposable SQLite/real PostgreSQL schemas, plus2
  cached-file-auth runtime rejection cases. Actual Alembic whole-chain migration,
 1381-lesson source import/idempotent reimport and synthetic137 XP preservation
  passed in a fresh real PostgreSQL schema. Final config/startup/email42 passed.
- Publication/provider5 passed/5 PG variants skipped; separate PostgreSQL evidence
  above. Earlier broad207 passed/5 skipped/5 fixture errors were followed by a
  corrected allowlisted disposable test URL and a passing5-case rerun. No preview
  guard was weakened and no clean full-backend run is claimed.
- Android debug build succeeded,166.3s. Existing future KGP plugin warnings remain.

Receipts/logs live in sibling `ilm-ai-beta-artifacts`, prefixed `blockers-`.
Detailed13-point report: `BLOCKERS_FIX_HANDOFF_20261107.md`.

### New artifact / server / device

APK: `ILM-AI-Beta-1.0.3-code4-ac168c3.apk`,209821062bytes/200.10MiB, SHA256
`4854ff1c23282c0f159d55f563b6eb467d4184b481c882854440a12c17ccf2c5`.
Verified `com.ilmai.app.beta`,1.0.3/code4,min24/target36,debug and v2 signature.
Launch activity: `com.ilmai.ilm_ai_flutter.MainActivity`. Static archive scan found
no checked PDF/DB/keystore/private files or NVIDIA/AQ/JWT literals, not a universal
proof against every secret format. Receipt: `blockers-beta-debug-build-20261107.json`.

Backend resumed from `b4e138a`, PID3892,127.0.0.1:8930. Health200 and17 public API
checks passed; all five subjects visible for grades5–11 with actual content locks.
All46 account/progress table hashes/counts match before/after and the earlier
checkpoint. No login/answer/reward/account was created by these probes. Google
is unconfigured; no provider key was activated. Verified explanation fallback
continues without one. Deletion deliberately remains disabled on8930 until real
policy/mailbox/storage/worker acceptance. SQLite server is left running; separate
owned PostgreSQL test cluster was stopped after tests.

Latest ADB list is empty. No new phone installation, Android15 edge-to-edge,
profile/release cold-start/frame/memory benchmark or signed upgrade was performed.
Do not clear/uninstall phone data. Prior phone observations above are historical,
not acceptance of this APK.

Latest public production preflight at2026-11-07T10:07:32Z: health200, mobile auth,
catalogue and five grade routes404. No hosted HTTPS/Google staging or real mailbox
acceptance. Public deletion page is implemented but not hosted/enabled; privacy,
Data safety, financial retention/support and backups require owner/operator review.
Existing production upload-key evidence does not replace a Play-signed upgrade.
No final five-subject production AAB was rebuilt while these critical gates remain;
the older Biology-only AAB is not this commit. No push, production migration/deploy
or Play upload was performed. See backend `docs/beta/PRODUCTION_DEPLOYMENT_PLAN.md`
for the exact operator sequence after separate permission.
