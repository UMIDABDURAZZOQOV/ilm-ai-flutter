# Integrated Android Beta

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
remains pending because no Android device is currently visible to Windows/ADB.

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
