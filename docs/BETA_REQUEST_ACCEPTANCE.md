# Submitted Beta requests — requirement audit, 2026-11-06

## 2026-11-06 — Lokal Beta yakuniy Samsung acceptance o‘tdi

User **lokal Beta qolsin** deb tasdiqladi; real Google/HTTPS konfiguratsiyasi
shu bosqichda kechiktirilgan. Yangi APK Samsung SM_A125F / R58NC0JNBXJga
**install -r Success** bilan o‘rnatildi va MainActivity foregroundda ochildi.
O‘rnatilgan base.apk SHA256 lokal artifactga to‘liq mos:
`6af19f86f6b7ace7be077f67c2500f66ec693cf5d65ea6a4501abe15362aefce`.
Uninstall/data clear yo‘q. USB offline holati reconnect/reverse/Retry bilan tiklandi.

Haqiqiy telefonda quyidagilar tasdiqlandi:
- Mavjud session bilan login/onboarding takror chiqmasdan **Biologiya · 7-sinf**
  ochildi.
- Quick switchda **5-sinfda beshala fan ko‘rinadi**: Biologiya ochiq,
  Fizika/Jahon tarixi 6-sinfda, Kimyo/O‘zbekiston tarixi 7-sinfda ochilishi yozilgan.
- Yopiq Kimyoni bosish fan/darsga kiritmadi, tanlash paneli saqlandi.
- **5 → 7** o‘zgarishida restart qilmasdan beshala fan “7-sinfda mavjud” bo‘ldi.
- Modal bekor qilindi; asl **Biologiya · 7-sinf** tanlovi saqlandi. Userning
  amaldagi darsi standart **Saqlab chiqish** orqali **Savol 3/8**da qoldi.
  Agent javob yubormadi, yangi urinish boshlamadi, progress/XPni reset qilmadi.

Dalillar: `ilm-ai-beta-artifacts/beta-request-installed-proof-20261106.json`,
`beta-request-handset-matrix-20261106.json`, `beta-request-grade5-20261106.png/xml`,
`beta-request-grade7-20261106.xml`, `beta-request-final-20261106.png/xml`.
5-sinf screenshot vizual ko‘rildi: barcha besh karta, qulf va sinf statuslari to‘g‘ri.
User ekran boshqaruvini berdi, tekshiruv tugagach qaytarildi. Backend
127.0.0.1:8930 / PID 22220 ishlayotgan holatda qoldirildi.

Biriktirilgan auth + fan/sinf topshiriqlarining **kelishilgan lokal Beta doirasi
bajarildi**. Real Google account chooser/cross-device login hali sozlanmagan,
user qaroriga ko‘ra keyingi bosqich; buni tayyor deb ko‘rsatmang. Oldingi alohida
performance topshirig‘ining to‘liq profile before/after benchmarki ushbu qisqa
UI smoke-test bilan bajarildi deb hisoblanmaydi. App kodi/APK ushbu qayta auditda
o‘zgarmadi; faqat hujjat/dalillar yangilandi.

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

## Final scope and remaining provider work

The user explicitly confirmed retaining local Beta. Real Google account choice,
HTTPS staging and cross-device recovery remain deferred, with
`google_configured=false`; they are not represented as working live features.
The existing provider integration is implemented and tested with mocked provider
responses. The local installation credential reuses this device's account.

Physical Android installation, matching APK hash, restored session and grade
switch/lock acceptance have now passed as recorded above. New-account, different
identity, expiry/logout and network edge cases retain automated coverage;
they were not all repeated by modifying the learner's active handset account.
No fresh answers were submitted on that account. Full quantitative performance
profiling belongs to the separate performance task and is not claimed here.

Implementation, automated validation, APK, agreed local-Beta handset acceptance
and central handoff are complete. This audit changed documentation only; no
new APK rebuild was needed.
