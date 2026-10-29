# ILM AI Android phone QA

This is an isolated local debug integration, not a production release.
Branch in both repos: `qa/android-five-subjects`. No changes were pushed to main,
the original feature branches, or any remote backend/database.

## What the APK contains

Package `com.ilmai.app.phoneqa`, display name **ILM AI QA**, unique callback
scheme `ilmai-phone-qa`. It can coexist with `com.ilmai.app`; storage and login
are separate. Never uninstall or clear the ordinary ILM AI app.

The normal onboarding, Ilmo assets, themes, Google login implementation and
Biology navigation remain present. A QA-only `/learn` hub opens these adapters:

| Subject | Reviewed lessons | Runtime |
| --- | ---: | --- |
| Biology | 406 | Existing mobile v1 theory/MCQ and five-tab UI |
| Physics | 316 | Existing v2 theory/MCQ/FRQ preview |
| Chemistry | 268 | Existing v2 theory/MCQ/FRQ preview |
| Uzbekistan History | 172 | Existing v2 theory/MCQ/FRQ preview |
| World History | 219 | Existing v2 theory/MCQ/FRQ preview |

Total: 1,381 lessons. All five are connected to the **QA hub**. This does not
publish the other four into the ordinary Biology-only mobile catalogue.
Their preview screens retain their own grade/catalogue, prerequisites,
server grading and progress. The hub shows shared account XP. Biology's
profile/quests/league are not a verified unified five-subject progress UI.
Biology FRQ is not implemented by this work. Physics FRQ remains preview.
Google OAuth is deliberately **not configured or end-to-end tested** in this
local sandbox; QA pairing tests login/session/onboarding with a synthetic user.
Do not interpret an available Google button as a completed OAuth test.
Push registration and AI tutor are disabled only for this phone sandbox.

## Start or resume the backend

Use an ordinary PowerShell terminal. Initial setup has already created this
private sandbox. `--resume` preserves its XP, answers, preferences and progress;
it also creates a fresh single-use pairing code (10 minutes, at most 5 tries).
Stop an existing server with Ctrl+C before restarting it on the same port.

```powershell
Set-Location C:\Users\Page\Desktop\Projects\ilm-ai-phone-qa
$env:PYTHONUTF8 = '1'
python -X utf8 scripts/serve_phone_qa.py --directory C:/Users/Page/Desktop/Projects/ilm-ai-phone-qa-local --resume --port 8925
```

In another terminal, read the code locally; do not share `server.json`,
`pairing.json`, databases, session tokens or screenshots containing the code.

```powershell
(Get-Content -Raw C:\Users\Page\Desktop\Projects\ilm-ai-phone-qa-local\pairing.json | ConvertFrom-Json).code
```

The APK contains no pairing code, access token or refresh token. After pairing,
the existing authenticated session stores its tokens in Android secure storage.
The sandbox imports only reviewed source content; it never imports production
`main` startup. Its new SQLite database is outside Git, with separate tables for
the existing adapters and all original preview ownership gates intact. The long
database filename intentionally satisfies all three existing staging checks.

## Connect and install

Enable Android Developer options and USB debugging, connect USB and accept the
computer's RSA prompt on the phone. `devices -l` must show `device`, not
`unauthorized`. Use the serial actually shown if it has changed.

```powershell
$adb = 'C:\Android\platform-tools\adb.exe'
& $adb devices -l
$qaDevice = 'R58NC0JNBXJ'
& $adb -s $qaDevice reverse tcp:8925 tcp:8925
& $adb -s $qaDevice install -r 'C:\Users\Page\Desktop\Projects\ilm-ai-flutter-phone-qa\build\app\outputs\flutter-apk\app-debug.apk'
& $adb -s $qaDevice shell am start -n 'com.ilmai.app.phoneqa/com.ilmai.ilm_ai_flutter.MainActivity'
```

Complete the existing onboarding. On login, use **Lokal QA akkauntiga kirish**
with the code. Use fictional name/age; this is user ID 990005 in a local database.
Open each subject, theory/source, MCQ, an applicable FRQ, feedback and results.
Reopen the lesson/app and verify saved progress and once-only XP. Test light/dark,
Russian/Uzbek/English UI, large text, keyboard, system Back and app resume.
Subject content remains in its reviewed language. Handset visual, TalkBack, IME,
Google OAuth and user acceptance checks are not claimed by automated tests.

The PC server and USB tunnel must remain available. After unplugging or rebooting,
repeat `adb reverse`; this build has no LAN or production fallback.

```powershell
& $adb -s $qaDevice reverse --list
Invoke-RestMethod http://127.0.0.1:8925/health
# When finished, remove only the QA tunnel:
& $adb -s $qaDevice reverse --remove tcp:8925
```

Server binds 127.0.0.1 only, rejects non-loopback/forwarded peers, exposes no
signup/email/password-reset/tutor endpoints, and has Google credentials empty.
Debug Android cleartext is limited to loopback. QA Dio refuses other origins
and does not follow redirects. Release builds and mismatched QA targets fail.

## Rebuild

Flutter 3.44.6, Dart 3.12.2, Android SDK C:\Android (compile API36), JDK17.
Dependencies use the existing lockfile; no dependency upgrades were requested.

```powershell
Set-Location C:\Users\Page\Desktop\Projects\ilm-ai-flutter-phone-qa
C:\flutter\bin\flutter.bat pub get
C:\flutter\bin\flutter.bat analyze
C:\flutter\bin\flutter.bat test
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\build_phone_qa.ps1
```

The build script runs `flutter build apk --debug` with the dedicated target and
all four preview opt-ins; it writes `phone-qa-build.json` beside the APK containing
both Git commits, exact size and SHA256. No secret dart-defines are used.

Android references: [ADB](https://developer.android.com/tools/adb),
[build variants](https://developer.android.com/build/build-variants),
[network security config](https://developer.android.com/privacy-and-security/security-config).
