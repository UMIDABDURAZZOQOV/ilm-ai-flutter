# Integrated Android Beta

## Google-only correction — 2026-11-09

Owner explicitly requested Google as the only registration/login entry. Source
68d0697 removes the password-choice experiment and unused email/signup/reset
screens. One registration CTA opens Google directly; verified subject, PKCE,
existing sessions and account-scoped progress remain. No email sender is required
for this Google flow. Legacy backend contracts/data remain for old clients.

New Google-only staging APK installed-r Success; owner third-account login,
no repeated onboarding and session restoration after restart were observed.
1428 full Flutter tests passed in17:20;54 focused tests overlap, analyze clean.
Signed1.0.3/code4 Google-only AAB verified, not uploaded and still NO-GO.
Staging backendcc239d0 is Live; exact-source9/9 public contracts passed. Backend
full CI is pending;83/83 real PostgreSQL/PDF/Windows coverage gaps passed locally.
Current artifacts/evidence/limits: [FINAL_READINESS_20261109.md](FINAL_READINESS_20261109.md).
Earlier checkpoints below are historical; they do not supersede this decision.

## Current HTTPS staging acceptance — 2026-11-08

Current app source7a2e37e supports reviewed five-subject publication and exact
Google auth/deletion callback routes. Separate Samsung staging package uses real
HTTPS backend597b5ac;9/9 public contracts passed. Owner-approved third-account
Google reauth/deletion/relogin and protected A/B progress passed, including
read-only DB purge confirmation. Flutter1393 full tests/37 targeted/analyze clean.
Signed production AAB1.0.3/code4 is a locally validated NO-GO candidate only;
current backend full CI and actual production/DB/privacy/upgrade/performance gates
remain. See PRODUCTION_UPDATE_AUDIT.md for current artifacts and limits. Earlier
local-only/Biology-only/pending-device statements below describe older checkpoints.

## 2026-11-06 — Existing Play update audit and final Beta installation

Current audit branch: `qa/play-release-audit-20261106`. The existing Play identity
is `com.ilmai.app`; its upload certificate and Console version3 were verified.
User-approved1.0.3/code4 signed AAB and a separate Beta APK were built and audited.
The final Beta APK is installed on Samsung, its installed hash matches, and the
same account/grade7/saved question3/8 remain. Native lint passes with0 errors and
17 recorded warnings. The local backend remains active on127.0.0.1:8930.

**This does not approve production release.** Ordinary signed release remains
Biology-only; five-subject/FRQ/help integration is still Beta-only. The live
production mobile auth/catalogue endpoints return404. Account deletion, Data
safety reconciliation, real OAuth, Play-signed upgrade and performance/runtime
acceptance remain open. Nothing was uploaded to Play. See
[the complete update audit](PRODUCTION_UPDATE_AUDIT.md) for final hashes, commits,
tests, actual handset evidence and limitations. Older checkpoints below are
historical; their ADB-empty or previous APK values do not describe this final state.

## 2026-11-06 — Catalogue availability and registration

All subjects remain visible in onboarding, the main catalogue and quick switch.
The shared card derives grade locks and labels from the existing complete backend
catalogue; unsupported/unknown grades cannot be selected. Locked taps only show
an explanation. Beta registration has one action, preserving provider verification,
existing accounts, sessions and progress. Local Google remains unconfigured and
is honestly labeled. See [the contract](BETA_GRADE_AVAILABILITY.md) and CLAUDE.md
for tests, files, limitations and the APK receipt. No optimized handset performance
or installation is claimed while ADB has no connected device.


## Latest UI policy — 2026-10-31

The Beta now exposes study help only below checked MCQ/FRQ feedback (both
correct and incorrect), opened explicitly by the student. Subject chat and
pre-answer help entry points were removed; switching subjects/grades remains.
Changing questions closes the old help modal and cancels its request. No
grading/reward/prerequisite contracts changed; no real AI key is configured.

Textbook bibliography, page locators and source-opening links are hidden from
the Beta student UI. Provenance remains in API/models/database and source
validation is unchanged. Grade/path/topic totals are hidden; progress still
works and paginated lesson ranges still navigate. The first Ilmo greeting in
onboarding states that topics are based on school textbooks, controlled by the
existing persisted onboarding completion state. Returning accounts are not reset.

The older sections below describe earlier checkpoints; their subject chat and
pre-answer help claims are superseded by this policy. See CLAUDE.md for files,
test coverage and the current APK receipt for the actual build identity.

2026-10-31 update: active isolated branch `feat/beta-subject-switch-ai-help`.
Adds direct subject/grade switching and question/subject study help with an
honest reviewed-evidence fallback. No actual AI token is configured. See
`../CLAUDE.md` and backend `docs/beta/STUDY_HELP.md` for audit, files and tests.
The older beta branch below remains a preserved checkpoint. The build receipt
beside the APK records the actual new branch and exact commits.

Validation on 2026-10-31: 1,314 normal Flutter tests and 56 beta/feedback tests
passed; analyze found no issues. Backend SQLite integration/help regression:
14 passed; provider/config verification: 2 passed. The local server retained
all 9 user/progress table digests after --resume. New feature device acceptance
was pending at build time because no Android device was then visible to ADB.

2026-10-31 22:16 +05 device follow-up: authorized Samsung SM_A125F was connected;
USB reverse for 8930 configured, existing APK installed with `install -r` (Success)
and launched in the foreground. Installed base.apk SHA256 matches the build
receipt (518d0ae8…9136d04). Existing localhost backend PID 12940 was preserved;
health returned 200 / integrated_beta and 35 live API checks passed expected
statuses. All five catalogues and source-linked no-token help were verified.
No APK rebuild, data clear or production change. Full handset MCQ/FRQ/reward/
restart acceptance still requires manual testing; install/launch alone does not
claim those flows passed. See CLAUDE.md and the local artifacts readiness report.

Branch: `beta/android-integrated-five-subjects` in this repository and sibling
`ilm-ai-beta`. Based on preserved QA checkpoints 4cd3a0a / 0c7a80e. Those QA
commits exist locally; GitHub commit lookups returned 422 and no QA branch was
advertised. No main/subject branch merged or rewritten; no remote deployment.

## Build

Uses normal `lib/main.dart`, IlmAiApp/router/onboarding, Ilmo assets and five tabs.
No separate QA home or subject preview screens in the beta student journey.

```powershell
Set-Location 'C:\Users\Page\Desktop\Projects\ilm-ai-flutter-beta'
$env:JAVA_HOME='C:\Program Files\Eclipse Adoptium\jdk-17.0.19.10-hotspot'
.\scripts\build_integrated_beta.ps1
```

This invokes `flutter build apk --debug --no-pub -t lib/main.dart` with
`INTEGRATED_BETA=true` and `API_URL=http://127.0.0.1:8930`. Debug-only guards,
separate application ID `com.ilmai.app.beta`, name **ILM AI Beta**, callback
`ilmai-beta`. Release builds with this flag are rejected. Compiling without
the flag preserves the existing Biology-only publication policy and identity.

APK: `build/app/outputs/flutter-apk/app-debug.apk`.
Build receipt alongside it: `integrated-beta-build.json`, with SHA256, actual
bytes and both exact commits. The script requires clean committed beta worktrees.
There are no compiled test credentials; local login creates a device credential
in secure storage and obtains normal account tokens from the local server.

## Tests

```powershell
flutter analyze --no-pub
flutter test --no-pub --concurrency=2
flutter test test/integrated_beta_test.dart test/beta_shell_test.dart --no-pub `
  --dart-define=INTEGRATED_BETA=true --dart-define=API_URL=http://127.0.0.1:8930
```

The normal suite checks existing behavior without beta flags. Separate beta tests
exercise normal app login/router/session restoration, grade filtering, disabled
subjects, four existing FRQ editors, all teaching sections, shared feedback,
restart/request identity and 360px/200% text layouts. Backend tests exercise real
graders and database ownership/reward/prerequisite rules on SQLite/PostgreSQL;
widget HTTP mocks do not claim scientific grading or device acceptance.

## Course/UI integration

| Subject | Grades | Units | Engine |
| --- | --- | ---: | --- |
| Biology | 5–11 | 406 | Existing v1 theory/MCQ |
| Physics | 6–11 | 316 | Existing v2 MCQ/applicable FRQ |
| Chemistry | 7–11 | 268 | Existing v2 MCQ/applicable FRQ |
| Uzbekistan history | 7–11 | 172 | Existing v2 MCQ/objective short answers |
| World history | 6–11 | 219 | Existing v2 MCQ/objective short answers |

Same normal catalogue/grade/chapter/path presentation; original source order,
source links, prerequisites, scientific data, response editors and server grading
are retained. Long chapters use ten-item ranges; future chapters remain collapsed
and the section chooser remains available. No invented chapters or quizzes.
One common v2 teaching/exercise controller presents all existing cards, formula
expressions, worked steps and non-scored reflections. Biology retains its v1
lesson controller. Its FRQ is not implemented or claimed.

The normal profile shows all five subjects, shared XP/streak/activity. Drafts
are isolated by API origin/account/subject/lesson; session request IDs and frozen
pending answers survive restart. Rewards come only from acknowledged server
results. Non-Biology practice lists completed lessons for review; the existing
Biology daily/mistake/lightning modes stay Biology modes.

## Phone setup and limits

See sibling backend **`docs/beta/LOCAL_BETA.md`** for complete Uzbek PowerShell
commands, current owned data directory, Google/HTTPS setup requirements and
Google/Android primary documentation links. Local server port 8930 uses ADB
reverse; this APK has no independent internet backend. Google OAuth and HTTPS
staging are not configured, as confirmed by the user. Local beta login is
explicitly labeled. It is not suitable for public sharing or production.

Real handset acceptance is pending when no ADB device is attached. Automated
tests and a successful debug build must never be presented as a phone smoke test.
