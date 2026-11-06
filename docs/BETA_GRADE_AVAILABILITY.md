# Beta catalogue and unified registration — 2026-11-06

## Catalogue contract

`SkillTreeRepository.getSubjects()` requests the complete `/beta/skills/subjects`
catalogue without a grade query. The existing backend already supplies every
subject and its `grades`, calculated from `ready_lessons > 0`. No new content,
guessed opening grades, database migration or preview bypass is needed.

Verified against the local owned Beta database:

| Subject | Grades with ready content |
| --- | --- |
| Biology | 5–11 |
| Physics | 6–11 |
| Chemistry | 7–11 |
| Uzbekistan history | 7–11 |
| World history | 6–11 |
| Mathematics / Native language | None yet; locked |

These are audit results, not hardcoded UI ranges. `SubjectGradeAvailability`
uses each server DTO. Unknown/empty grade metadata stays locked. A future gap
uses the next actual available grade. Subjects available only in earlier grades
say so instead of promising a future release.

`SubjectGradeCard` is shared by Duo onboarding, SubjectHome's full catalogue
and the in-course subject switch sheet. Every subject stays in the list.
Open cards display the chosen grade; locked cards display a lock and status.
A locked tap only shows a SnackBar. Grade changes use the already loaded
catalogue, without another network request or restart. Subject selection and
restored onboarding continuation also enforce the same availability rule.
Existing account-keyed preferences, draft attempts, XP and prerequisites remain.

## One authentication action

The Beta welcome and signed-out screen each expose one authentication action:
**RO‘YXATDAN O‘TISH** (localized). Repeated callbacks are blocked while pending.
Configured Google uses the existing state/PKCE/code exchange and normal token
storage. The provider URL requests account choice. The backend resolves the
verified Google `sub` before the legacy verified-email linking path; changing
email/display name does not create another profile. Conflicting or ambiguous
identities fail closed. No profile is identified by its display name.

Google is currently unconfigured. The local fallback explicitly says that it
uses this device's internal Beta account. Its runtime random credential stays
in secure storage and reuses the same server identity after logout. It does
not provide Google account selection or cross-device restoration. No credential
is compiled into the APK. Real Google acceptance still requires HTTPS/OAuth
staging configuration.

New authenticated accounts enter the existing onboarding sequence. Completed
accounts go directly to Learn; valid stored sessions keep their existing restore
path. The textbook notice appears in the first Beta welcome under the existing
persisted onboarding completion state. Bibliography/source links, topic totals
and non-result AI entry points remain hidden.

## Validation and artifacts

Beta tests include the availability matrix for grades 5–11, missing/sparse/earlier
grade metadata, locked taps, restored invalid onboarding selections, unchanged
other-account preferences/drafts, large text/light/dark, one registration action,
repeat taps, failed-network retry, verified Google exchange selection and existing
session/refresh/logout/progress regressions. Google provider responses are mocked;
they are not a live OAuth acceptance test.

Run the normal suite without Beta defines, and the Beta tests with
`INTEGRATED_BETA=true` and `API_URL=http://127.0.0.1:8930`. Run analyze and
`scripts/build_integrated_beta.ps1` from the isolated committed Beta worktrees.
The APK's `integrated-beta-build.json` records its exact code commits, bytes,
SHA256 and identity. Final results and device limitations are recorded in CLAUDE.md.

## Performance follow-up

Commit `0afe25a` retains the earlier startup/storage/request/render optimizations.
The new navigation paint boundaries are now Beta-only, preserving normal golden
rendering. Earlier Samsung profile baseline files remain in local artifacts.
No optimized handset comparison is claimed while ADB has no connected device.
Debug APK timing must not be presented as a profile-mode performance result.

## USB test commands

```powershell
$adb = 'C:\Android\platform-tools\adb.exe'
& $adb devices -l
# Continue only after the phone is listed as device and its RSA prompt is accepted.
& $adb reverse tcp:8930 tcp:8930
& $adb install -r 'C:\Users\Page\Desktop\Projects\ilm-ai-flutter-beta\build\app\outputs\flutter-apk\app-debug.apk'
& $adb shell am start -n com.ilmai.app.beta/com.ilmai.ilm_ai_flutter.MainActivity
```

Keep the local backend and USB connection active. Do not uninstall or clear data.
