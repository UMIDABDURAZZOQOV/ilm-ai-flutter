# Submitted Beta requests — requirement audit, 2026-11-06

The complete attachment `e83a7436-6610-4995-960c-d93840c60b99/Pasted text.txt`
was read. It contains unified authentication and subject/grade availability
requests; the latter is repeated. The exported usage-limit notices are not
application requirements.

## Unified authentication

| Requirement | Evidence and status |
| --- | --- |
| One registration action, no separate existing-account/login choice | Implemented in Beta welcome and LoginScreen using BetaLogin. `beta_registration_test.dart` checks one action and removal of old choices. |
| New identity creates a profile; existing identity reuses it | Implemented. Verified Google `sub` lookup precedes legacy verified-email linking; changed email/name preserves the user ID and saved XP. Backend identity tests passed. Live Google is pending configuration. |
| Different accounts stay separate | Automated provider/ownership tests passed; same display name never selects another identity. The configured Google URL requests account choice. Actual Google chooser on a phone is pending. |
| Valid session skips authentication; existing completed account skips onboarding | Existing secure-token restore/router flow retained. Restart, logout/relogin and incomplete/completed profile tests passed. |
| Duplicate taps, loading, understandable errors | Busy guard includes stale callbacks. Single provider exchange/local login and failed-network retry tests passed. |
| Preserve Ilmo/design | Existing branding/navigation retained. Normal golden images pass unchanged; large-text/light/dark tests pass. Actual handset responsiveness is still pending. |
| Keep token/provider checks and ownership | State, PKCE, verified identity, refresh rotation, logout races and ownership tests passed. No name-only access or compiled credential was added. |
| All eight requested test scenarios | Automated coverage: first account, reuse, other identity, restart, expiry/refresh, logout, progress/isolation and network/auth errors. Google responses/browser callbacks are mocked, not live provider acceptance. |

## All subjects and grade locks

| Requirement | Evidence and status |
| --- | --- |
| Show every catalogue subject in grades 5–11 | Implemented in onboarding, SubjectHome catalogue and quick switch; grade filters removed. Automated matrix tests passed. |
| Open only grades with actual ready content | Existing complete backend catalogue supplies `grades` from `ready_lessons > 0`; no guessed UI opening ranges or fabricated courses. Unknown metadata stays locked. |
| Lock icon and status on every card | Shared SubjectGradeCard: current grade, next real grade, earlier-only availability or unavailable status. Sparse/unknown/earlier metadata tests passed. |
| Locked tap explains without entering | SnackBar only; no subject selection or progress/preference write. Tests passed. |
| Update immediately on grade change | Same loaded catalogue reused. Grade changes 5–11 tested without restart or catalogue refetch. |
| Onboarding and main selector use identical rules | Shared SubjectGradeAvailability/card plus selection and restored-draft continuation guards. Tests passed. |
| Preserve progress and existing features | Other-account preferences and lesson drafts preserved; existing MCQ/FRQ/session regressions pass. Nine live user/progress table fingerprints unchanged across backend restart and API checks. |
| Preserve branding and readable cards | Existing colors/Ilmo retained; common card dimensions and accessible wrapping, light/dark/200% text tests. Handset scrolling/perceived lag not yet verified. |

## Build and verification evidence

- Normal Flutter suite: **1,327 passed**.
- Beta acceptance: **107 passed**; final selection follow-up **10 passed**.
- Android configuration/normal registration opt-in follow-up: **4 passed**.
- Flutter analyze: **No issues found**, 97.6 seconds, committed application code.
- Backend identity/auth: **53 passed**; Beta/help SQLite: **14 passed**,
  **12 deselected** (PostgreSQL not run).
- Native dry runs reject unauthorized Profile and Beta Release. Debug APK built
  successfully after correcting the DebugArtProfile task-name false positive.
- APK: **209,766,255 bytes / 200.05 MiB**, package `com.ilmai.app.beta`, debug.
- Flutter build commit: `0fd5baa072900659a0be8788ac5916b680dd1a0d`.
- Backend build commit: `974f542e657767e50816f980080321e7b6361b58`.
- SHA256: `6af19f86f6b7ace7be077f67c2500f66ec693cf5d65ea6a4501abe15362aefce`.
- Stable APK: `../ilm-ai-beta-artifacts/ILM-AI-Beta-20261106.apk`.
- Full operational report: `../ilm-ai-beta-artifacts/GRADE_LOCK_ACCEPTANCE.md`.
- Central handoff: `../ilm-ai/CLAUDE.md`.

## Open external acceptance items — not marked complete

1. **Real Google sign-in/account choice:** current `/beta/config` explicitly
   reports `google_configured=false`. The user previously chose local Beta while
   HTTPS staging/OAuth were unavailable. Runtime installation identity reuses
   this device's local account; it cannot provide Google account selection or
   cross-device recovery. Complete live acceptance only after an isolated HTTPS
   staging origin and private Google OAuth server configuration are available.
   Secrets belong in the private server configuration, not chat/Git/APK.
2. **Physical Android installation and acceptance:** fresh `adb devices -l`
   reports no connected device. No install/launch or perceived responsiveness
   result is claimed. Connect USB debugging, accept RSA, then use the documented
   reverse/install-r/launch commands. Do not clear data or uninstall.

The application implementation, automated validation, APK and central handoff
are complete for the agreed local Beta. End-to-end provider/device acceptance
remains open for the two reasons above. This audit changes documentation only;
the existing APK does not require rebuilding.
