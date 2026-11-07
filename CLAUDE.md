# ILM AI Flutter — 2026-10-31 handoff

## 2026-11-06 - AI provider and final-readiness follow-up (NO-GO)

Backend source commit: `98cd97cb77571b2112df889ef352333c3bebe81e`; running loopback service remains `974f542`, not hot-reloaded.

The new 195-line user brief was read fully with credential redaction. The user
confirmed the disclosed keys belong to Google AI Studio. No key was persisted or
sent to any provider. Revoke/replace disclosed credentials in the provider
console; never paste replacements in chat. Gemini Developer API terms currently
exclude clients directed towards or likely accessed by under-18s, so it was NOT
connected to this school app. See `AI_PROVIDER_READINESS.md` in backend docs/beta.

Source changes are isolated on `qa/play-release-audit-20261106` in the Beta
backend: strict private config outside all Git checkouts, optional existing
OpenAI evidence-ID selector with bounded authorized standby, whole-pool
Retry-After/rate/quota handling, no account quota hopping, capped input/output,
per-process call/concurrency limits, no free-form learner messages/answers/IDs
in external selection, and original reviewed-evidence fallback. No provider
was activated; shared/durable production budget and audience/privacy review
remain required. This is not a Gemini integration or provider acceptance.

Added read-only `scripts/mobile_release_preflight.py`: live health200, seven
required mobile auth/catalogue/grade contracts404; NO-GO. Added additive Alembic
0014 PKCE state/grant migration with ownership/schema checks and no user/XP/
progress mutation. Its SQLite tests pass; production migrations were NOT run.
Application rollback preserves these additive tables; destructive downgrade
is deliberately refused. See backend `PRODUCTION_DEPLOYMENT_PLAN.md` for
staging/backup/restore/old-client/publication/rollback requirements.

The signed release candidate remains the prior Biology-only source384f6d6 AAB.
Five-subject production integration and account deletion are still engineering
work, not completed features. HTTPS/OAuth staging, real provider/account tests,
Play-signed upgrade, Data safety and complete device performance acceptance
remain open. No Play upload, backend deploy, production DB write or subject/main
branch change occurred. Source changes are not automatically live in port8930.

Final source validation: combined86 passed/12 deselected/1 warning(51.28s);
separate backend auth/migration57 passed/1 warning(301.01s); standalone65 passed.
Suites overlap; do not sum counts. Fresh Flutter analyze No issues found247.9s;
no Dart/native source changed. New-file Ruff and whitespace checks passed.

Samsung profile: same-account5/5 Learn-ready; Android TotalTime2443-2528ms
(median2450), Dart frame callback470-492ms (median477). UI-polled Learn5902-7186ms
includes tooling overhead, not precise TTI. First profile launch8330ms and restored
debug launch10532ms timeout remain recorded; no startup fix/ANR diagnosis claimed.
Two five-tab rounds had9.59%/27.62% frames over60Hz budget; short post-GC heap
18,190,112 to19,816,160 bytes/PSS156,134 to174,123KiB does not prove no leak.
Original stable debug APK restored with install-r Success; all9 measured user/
progress table digests unchanged. No answers, data clear, uninstall or logout.

Disk-full interrupted initial attempts. Only verified disposable test DB copies
and generated Flutter test/debug-native caches were removed; source PDFs, phone
DB, keys and final APK/AAB preserved. Successful rerun results supersede interrupted
attempts. Detailed evidence and unfinished engineering/external acceptance are in
Flutter docs/PRODUCTION_UPDATE_AUDIT.md and backend docs/beta/AI_PROVIDER_READINESS.md
and PRODUCTION_DEPLOYMENT_PLAN.md. NO-GO remains.


## 2026-11-06 — Yakuniy native tuzatishlar va tekshirilgan artifactlar

**Bu yozuv oldingi hash va USB-pending checkpointlarini almashtiradi.**
App source commit: **384f6d6a2663fd65709df78b08ddfb09de91d138**;
branch: `qa/play-release-audit-20261106`. User tasdiqlagan **1.0.3/code4**, eski
`com.ilmai.app` va upload sertifikati saqlangan. Play upload, remote push yoki
deploy bajarilmagan. Oddiy release hali Biology-only; besh fan Beta ichida.

| Artifact (`ilm-ai-beta-artifacts/`) | Bytes / MiB | SHA256 |
| --- | --- | --- |
| `ILM-AI-1.0.3-code4-release-candidate.aab` | 76 951 648 /73.39 | `a3aa66463f996a772fc1f0d7b3f2fbc653c55f75160c3c34d02a65e4043f003c` |
| `ILM-AI-Beta-1.0.3-code4-20261106.apk` | 209 804 239 /200.08 | `1a54a015468ad5087407ddb18ad88d5a47cb5c4136b759e99922bbdf239d8754` |

Final AAB build330.9s, debug APK194.4s. AAB bundletool validation, jar signature,
user-approved certificate, manifest va secret/source-file scan passed. Final
manifest min24/target36, non-debuggable, normal ilmai callback, no-backup rules,
optional capture hardware. Barcha8 ta64-bit ELF alignment>=16KB; bu runtime16KB
testi emas. PDF, DB, keystore, known private values yoki JWT literal topilmadi.

Native lint topgan **7 error** tuzatildi: yangi splash atributlari API28/29
day/night resurslariga ko‘chirildi; capture hardware optional; ignored Windows
SDK properties escape qilindi. Android12+ cloud/device-transfer uchun oldingi
no-backup siyosati aniq belgilandi. Lint/source/auth/preview guard o‘chirilmadi.
Flutter local.propertiesni qayta yaratadi; native lintdan oldin:
`python scripts/normalize_android_local_properties.py` (3 tests passed).

**Final lintRelease: BUILD SUCCESSFUL,0 errors/17 warnings,1m33s.** Qolganlari:
legacy storage permission, icon/config duplication/shape/monochrome, obsolete
resource qualifiers, newer desugar dependency. Warnings yashirilmadi. Final
analyze: **No issues found,167.3s**;24 config/mobile OAuth/transport tests passed.
Oldingi1334 full Flutter,95 Beta,55 auth,17 privacy/accessibility,53 backend auth,
14 SQLite Beta/help testlari o‘tgan; suite’lar kesishadi, jamlab total chiqarmang.
35 fresh live Beta API checks passed,9 measured user/progress digests unchanged.
PostgreSQL va haqiqiy Google/Play upgrade acceptance bu bosqichda tekshirilmagan.

Samsungga final APK **install-r Success**. Installed base.apk SHA256 final APKga
aynan mos. Fresh UI shu session/Biologiya7/Savol3/8ni tasdiqladi. Besh tab ochildi,
draft saqlandi; privacy tugmasi haqiqiy telefonda fixed public URL bilan tashqi
Chrome’ni ochdi. Token/credential URLga qo‘shilmadi. Uninstall, data clear,
shaxsiy javob yuborish yoki XP reset yo‘q;9 ta jadval digesti o‘zgarmadi.
`am start-W`11017ms timeout qaytardi, keyin Learn ochilgani fresh UI bilan
tekshirildi. **Cold-start performance hali qabul qilinmagan**; ANR bor deb xulosa
qilinmadi. Profile/release timings, Android16/16KB runtime QA hali ochiq.

**Reliz bloklangan:** production `/auth/mobile/config` va
`/mobile/skills/subjects`404; besh fan/FRQ/help productionga ko‘chirilmagan;
owner-scoped account deletion/public request yo‘q; Data safety deklaratsiyasi
privacy/actual behavior bilan moslashtirilishi kerak. Alohida HTTPS/OAuth staging
userda yo‘q. Real account chooser, cross-device va Play-signed upgrade testlari
qolgan. AAB mavjudligi production-ready degani emas; user ruxsatisiz upload yo‘q.

To‘liq hisobot: `ilm-ai-flutter-beta/docs/PRODUCTION_UPDATE_AUDIT.md`.
Lokal receipts: `release-audit-build-receipt-20261106.json`,
`release-audit-aab-verification-20261106.json`,
`release-audit-installed-final-beta-20261106.json`,
`release-audit-device-status-20261106.json`,
`release-audit-native-lint-result-20261106.json`,
`release-audit-privacy-device-20261106.json`.
Backend127.0.0.1:8930/PID22220 active qoldirildi; service kodi974f542 o‘zgarmagan.
Production commit mustaqil tekshirilmagan. Original key fayllari faqat o‘qildi;
main/fan branchlari va foydalanuvchi/source PDF ma’lumotlari saqlangan. Markaziy
CLAUDE — user so‘ragan handoff. Vaqtinchalik ADB approval usage-limit xatosi resetdan
keyin o‘sha approval yo‘li orqali qayta tekshirilib hal bo‘ldi; bypass qilinmadi.


## 2026-11-06 — 1.0.3/code4 signed update candidate tayyor, upload qilinmadi

User tasdiqlagan eski **com.ilmai.app** va upload kaliti bilan release AAB yaratildi:
`ilm-ai-beta-artifacts/ILM-AI-1.0.3-code4-release-candidate.aab`.
**76 951 484 bytes /73.39MiB**, SHA256
`58e2e3829c71b4256b893e84265876880e7e6ac83d4a9b28e36e7118f70539b3`.
Flutter build commit **36226119a05d2aae2407536aa0e3706ea16dbe97**; build693.0s.
Actual AAB bundletool validate, jar signature, user-approved upload fingerprint,
package/version4/1.0.3, min24/target36, non-debuggable va ilmai callback tekshirildi.
8 ta64-bit ELF alignment>=16KB. PDF/DB/keystore/private config/known secret/JWT
literal topilmadi. **Play Console’ga upload/publish yo‘q.**

Muhim: bu **oddiy Biology-only release yo‘li**dagi audit candidate. Besh fan,
FRQ/help hali Beta konfiguratsiyasida. Production HTTPS /health200, ammo yangi
/auth/mobile/config va /mobile/skills/subjects404. AAB tayyorligi yangi besh fanli
production muvaffaqiyati emas. Account deletion/public request, Data safety
mosligi, staging real Google/cross-account, Play-signed upgrade va Android16/16KB
runtime QA hali ochiq. Preview/source/auth/release guardlar olib tashlanmadi.

Yangi alohida Beta APK:
`ilm-ai-beta-artifacts/ILM-AI-Beta-1.0.3-code4-20261106.apk`,
**180 483 317 bytes /172.12MiB**, SHA256
`a61e6c5c2241348b73c81e990cb9e3653f9f52c35e527424132bea2e6894b4c0`.
Source **74c3c1ce5d4aae33fc14371fcb415426246a8ce3**, build285.7s,
com.ilmai.app.beta /1.0.3 code4, loopback8930. Signature/manifest/secret scan passed.
Samsungga **install -r Success**. Keyin USB yana offline; shu yangi buildning
post-install launch/installed-hash/progress smoke’i barqaror USB kelguncha pending.
Avvalgi logout/login/offline/recovery acceptance eski installed buildda o‘tgan;
yangisiga avtomatik ko‘chirmang. Userdan ishonchli USB qayta ulash so‘ralgan.
Uninstall/data clear/personal javob yuborish yo‘q, 9 user/progress digest unchanged.

Testlar: **1 334 normal Flutter,95 Beta,55 auth/transport,17 privacy/accessibility,
22 final configuration/OAuth/transport;53 backend auth;14 SQLite Beta/help passed**.
Suite’lar kesishadi — qo‘shib total chiqarmang. Analyze No issues found.
Android lintRelease hozir yakunlanmoqda, final result keyingi qo‘shimchada.
Backend repository **5a65740** docs-only; ishlayotgan lokal service kodi
**974f542** /PID22220, production commit mustaqil tekshirilmagan.

Batafsil: Flutter **docs/PRODUCTION_UPDATE_AUDIT.md**; lokal receipts
`release-audit-build-receipt-20261106.json`, `release-audit-aab-verification-20261106.json`,
`release-audit-api-evidence-20261106.json`, `release-audit-device-status-20261106.json`.
Original Flutter key/config faqat o‘qildi, main/production/fan branchlari saqlangan.


### Play Console tasdig‘i — shu auditning keyingi yangilanishi

User Console’dan production **3 (1.0.2)**, Alpha **2 (1.0.1)** va package
**com.ilmai.app**ni tasdiqladi. **1.0.3/code4** aniq ruxsat bilan belgilandi.
Upload certificate lokal kalit/AAB/APKga mos. Play Console’ga yuborish uchun
ruxsat berilmagan — hech narsa upload/publish qilinmaydi.
Beta regressiya to‘plami **95 passed**. Alohida final config test logi va
imzolangan AAB/debug APK natijasi build tugagach yoziladi. AAB oddiy release
konfiguratsiyasida (Beta flagisiz, Biology-only default saqlangan) audit candidate
sifatida yaratiladi; bu besh fan productionga ko‘chirilgani yoki API/OAuth
acceptance o‘tgani degani emas. Release blockerlar yuqoridagi hisobotda ochiq.


## 2026-11-06 — Mavjud Play ilovasini yangilash auditi (production approval yo‘q)

User oldingi “birinchi release” javobini tuzatdi: **com.ilmai.app Play Store’da
allaqachon mavjud**. Eski Flutter worktreedagi key.properties/upload keystore,
imzolangan AAB/APK topildi. Upload SHA256
`D0:F0:08:1B:E1:E3:EA:F6:79:8E:4C:95:57:0B:57:36:55:57:DA:23:B5:37:81:F0:DB:B4:19:10:3D:90:04:35`
uchalasida mos; user Console’dan aynan shu fingerprintni yubordi. Yangi kalit yoki
applicationId yaratilmaydi. Lokal APK code3; Console highest versionCode hali
so‘ralgan. Upload va Play app signing sertifikatlari bir xil deb hisoblanmaydi.

Ish ikki Beta worktreeda **qa/play-release-audit-20261106** branchida. Original
Flutter/Biology, main va production DB o‘zgarmadi. Batafsil dalil/qolgan ishlar:
`ilm-ai-flutter-beta/docs/PRODUCTION_UPDATE_AUDIT.md` va backend
`docs/beta/PRODUCTION_UPDATE_HANDOFF.md`.

Tuzatishlar: authenticated Dio begona origin/userinfo yoki credential-bearing
redirectga so‘rov yubormaydi (avval 5 test bilan takrorlandi); Settings ichida
mavjud rasmiy public privacy linki, localized failure/retry/tap guard; signing
konfiguratsiyasi alohida worktreeda faqat explicit ILM_ANDROID_KEY_PROPERTIES
orqali eski xususiy kalitdan foydalanishi mumkin. Beta release taqiqi saqlangan.

Hozirgi testlar: **1 334 normal Flutter**, **55 auth/transport**, **17 privacy +
account accessibility**, **53 backend auth**, **14 SQLite Beta/help** passed;
12 PostgreSQL variant deselected. Suite’lar kesishadi, sonlarini qo‘shmang.
Analyze: **No issues found**. Full Flutter log 114m55s, analyze 6274.7s ko‘rsatdi;
xotira bosimi bor edi, buni tezlik benchmarki deb ko‘rsatmang. Yakuniy Beta
regression/build/installation holati keyingi qo‘shimchada yoziladi.

Haqiqiy Samsungda logout → Back/reopen → shu qurilma credentiali bilan qayta
kirish shu account/Biologiya7/Savol3/8ni tikladi. 9 user/progress jadvali digestlari
o‘zgarmadi. Faqat ADB reverse olib tashlanib offline cold start qilindi: session
saqlandi va Retry/Settings bilan tushunarli connection error; reverse + Retrydan
keyin shu Learn/draft tiklandi. Shaxsiy javob/XP reset, uninstall/data clear yo‘q.
Bu Google account chooser/cross-device yoki Play-signed upgrade sinovi emas.

**Reliz to‘siqlari:** joriy HTTPS production health200, ammo yangi client uchun
/auth/mobile/config va /mobile/skills/subjects404 (faqat read-only tekshiruv).
Bu eski production OAuth sozlanmagan degani emas. Alohida HTTPS/OAuth staging
userda hali yo‘q. Oddiy release hali Biology-only, besh fan/FRQ/help Beta gates
ichida. Account-deletion flow yo‘q; public Play “No data collected” deklaratsiyasi
privacy policy va saqlanayotgan account/progress bilan moslashtirilishi kerak.
Console highest versionCode, backward-compatible backend rollout, owner-scoped
deletion/public path, Play internal-track upgrade va Android16/16KB runtime QA
bajarilmasdan production-ready deb aytmang. Eski release 8 ta64-bit ELF alignment
va zipalign16KB tekshiruvidan o‘tdi; Samsung page size4096, runtime16KB emas.

Avtomatik review live DB yo‘li bilan test buyrug‘ini rad etdi; xavfsiz alohida
SQLite backup faqat read-only source orqali yaratilib, testlar disposable DBlarda
bajarildi. Secret log/Git/APKga chiqarilmadi. Lokal8930/PID22220 saqlangan.


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


### 2026-11-06 15:10+05 — Samsungga haqiqiy o‘rnatish tasdiqlandi

Foydalanuvchi telefonni uladi va **lokal Beta qolsin** deb tasdiqladi; real
HTTPS/Google OAuth bu bosqich uchun kechiktirildi. Samsung SM_A125F / R58NC0JNBXJ
authorized device bo‘ldi. `adb reverse tcp:8930 tcp:8930`, **install -r Success**,
MainActivity launch va foreground tasdiqlandi. Telefonda o‘rnatilgan base.apk
SHA256 `6af19f86f6b7ace7be077f67c2500f66ec693cf5d65ea6a4501abe15362aefce`
lokal yangi APKga mos. Uninstall yoki data clear yo‘q.

USB bir marta offline bo‘ldi, reconnectdan keyin reverse qayta o‘rnatildi.
Katalogda avvalgi network error Retry orqali tiklandi; saqlangan session bilan
**Biologiya · 7-sinf** Learn ochildi, login/onboarding takror so‘ralmadi.
Backend 8930da ishlamoqda. Dalil:
`ilm-ai-beta-artifacts/beta-request-installed-proof-20261106.json` va
`beta-request-retry-20261106.xml/png`.

Foydalanuvchi shu paytda telefonning dars/AI oynalarini ham boshqarmoqda.
Agent hech qanday savolga javob yubormadi yoki urinishni yangilamadi. Qo‘lda
fan/sinf panelini tekshirish uchun qisqa exclusive screen control so‘raldi;
automatik 5–11 matrix testlari o‘tgan. Quyidagi oldingi “ADB bo‘sh/o‘rnatilmagan”
holatlari avvalgi tekshiruv vaqtiga tegishli; ushbu follow-up ularni yangilaydi.


## 2026-11-06 — Biriktirilgan yakuniy topshiriq bandlari qayta audit qilindi

`e83a7436-6610-4995-960c-d93840c60b99/Pasted text.txt` boshidan oxirigacha
qayta o‘qildi. Ichida unified auth va ikki marta takrorlangan fan/sinf topshirig‘i
bor. Har bir mazmunli talab `ilm-ai-flutter-beta/docs/BETA_REQUEST_ACCEPTANCE.md`
jadvalida kod/test dalili va qolgan haqiqiy acceptance holatiga bog‘landi.
Mavjud test loglari va APK bytes/SHA256 qayta tekshirildi; app kodi o‘zgarmadi,
APK qayta yig‘ilmadi. Backend LOCAL_BETA.mddagi eski ikki tugmali kirish yo‘riqnomasi
va eski branch nomi tuzatildi. Bu bosqich faqat hujjat/audit o‘zgarishlari.

**Tugallangan:** lokal Beta UI/flow, stable verified identity integratsiyasi,
5–11 katalog/qulf qoidalari, avtomatik testlar/analyze, debug APK va handoff.
Dalillar: 1 327 normal Flutter, 107 Beta, 53 identity/auth, 14 Beta/help test;
APK 209 766 255 byte / 200,05 MiB, build Flutter `0fd5baa`, backend `974f542`.

**Hali tugallanmagan:** real Google providerda akkaunt tanlash/qayta kirish va
haqiqiy Androidga o‘rnatib interaktiv acceptance/responsivenessni tekshirish.
Yangi jonli tekshiruv: `/beta/config` `google_configured=false`, local test auth
mavjud; `/health` `ok / integrated_beta`; `adb devices -l` bo‘sh.
Oldingi user qarori lokal Beta edi. Qolgan real sinovlar uchun telefon ulanishi
hamda staging/OAuth mavjudligi haqida aniq so‘rov yuborildi. Secret chat/Git/APKga
so‘ralmadi. Bularni “100% bajarildi” deb ko‘rsatmaslik kerak.


### 2026-11-06 — Android debug ArtProfile build guard correction

The first new debug build stopped safely before producing an APK: the earlier
performance guard matched AGP's debug `ArtProfile` metadata tasks. The guard now
matches only actual app Profile artifact tasks (assemble/bundle/package/Flutter
compile/install), still requiring `BETA_PERFORMANCE=true`. The separate Beta
release prohibition remains. No opt-in flag was added to debug to evade the guard.
Android configuration plus normal registration opt-in tests: **4 passed** in
`grade-lock-android-config.log`. Native Profile/Release dry-run guard results and
the successful rebuilt APK receipt are recorded in central CLAUDE.md/local
artifacts. No release artifact is generated by the dry-run checks.


## 2026-11-06 — Barcha fanlar ko‘rinadi, sinfga qarab qulflanadi; yagona kirish

Alohida `feat/beta-subject-switch-ai-help` Beta worktree. Onboardingning fan
bosqichi, asosiy katalog va Learn ichidagi quick switch endi bitta
`SubjectGradeCard` / `SubjectGradeAvailability`dan foydalanadi. Sinfga mos
kelmagan fanlar yashirilmaydi. `getSubjects()` mavjud to‘liq katalogni grade
filtrisiz oladi; backend `grades`ni ready lessonlardan hisoblaydi. Live katalog:
Biologiya 5–11; Fizika/Jahon tarixi 6–11; Kimyo/O‘zbekiston tarixi 7–11.
Matematika/Ona tili ham ko‘rinadi, ammo tayyor sinf yo‘q va yopiq.
Bu chegaralar UIga hardcode qilinmagan; bo‘sh metadata yopiq qoladi.

Har kartada sinf holati bor: mavjud / keyingi haqiqiy sinfda ochiladi / avvalgi
sinflarda mavjud / hozircha yo‘q. Yopiq tap faqat SnackBar, tanlov yoki progress
yozuvi yo‘q. 5–11 sinf almashsa katalog qayta so‘ralmaydi, qulf darhol yangilanadi.
Asosiy tanlash va qayta tiklangan onboarding draftining Continue tugmasida ham
availability guard bor. Boshqa sinfga yashirin fallback bilan o‘tish olib tashlandi.

Beta welcome va login ekranida bitta **RO‘YXATDAN O‘TISH** auth tugmasi.
Google configured bo‘lsa mavjud state/PKCE/code-exchange/provider tekshiruvi;
hozir sozlanmaganligi va qurilmadagi ichki Beta akkaunti ishlatilishi aniq yoziladi.
Runtime secure credential logoutdan keyin ham shu identityni qaytaradi; Google
akkaunt tanlash/cross-device login hozir ishlayapti deb ko‘rsatilmaydi. Bir vaqtning
o‘zida takroriy callback bloklangan. Yangi user mavjud onboardingga kiradi,
completed user Learn; haqiqiy saqlangan sessiya eski restore yo‘lidan o‘tadi.
Darslik haqidagi bir martalik notice birinchi welcome ichida mavjud persisted
onboarding holati bilan; natija tashqarisidagi AI/manba/topic-count UI yashirilganicha.
Backend verified Google sub orqali avvalgi profilni topadi; email/name almashishi
progressni ajratib yubormaydi. Backend code commit `974f542`.

Tekshiruv: **1 327 normal Flutter test passed** (`grade-lock-normal-final.log`),
**107 Beta test passed** (`grade-lock-beta-verified.log`), oxirgi selection fallback
aniqlashtirilgandan keyin yana **10 passed** (`grade-lock-selection-final.log`).
Yangi registration + grade tests **10 passed**. Normal golden rasmlar yangilanmadi;
oldingi 16/17-pixel nav farqi paint boundaryni faqat Beta uchun qoldirish bilan
bartaraf etildi. `flutter analyze --no-pub`: **No issues found** (102,9s).
Backend: **53 identity/auth tests** va **14 Beta/help tests**, PG 12 deselected.
UI Google provider javoblari mock; live OAuth hali tekshirilmagan.

Oldingi performance commit `0afe25a` optimizatsiyalari saqlangan. Samsungdagi
baseline lokal artifactlarda bor; ADB hozir bo‘sh, shuning uchun yangi APKni
telefonga o‘rnatildi yoki optimized profile tezligi o‘lchandi deb hisoblamang.
Debug natija profile performance dalili emas. APK hajmi/hash/aniq commitlari uning
`integrated-beta-build.json` receiptida, yakuniy backend/PID/APK/device holati
markaziy `../ilm-ai/CLAUDE.md`da qayd etiladi. Gitga PDF/DB/secret/APK kirmaydi.
To‘liq kontrakt: `docs/BETA_GRADE_AVAILABILITY.md`.


## 2026-10-31 — Beta UI/UX: faqat natijada AI, yashirilgan manbalar

Yangi foydalanuvchi talabi oldingi subject chat/pre-answer help UI topshirig‘ini
almashtirdi. Ish `feat/beta-subject-switch-ai-help` Beta worktree ichida.
Backend grader/provenance/preview gate/XP/draft/onboarding saqlash kalitlari
o‘zgarmadi. Source ma’lumotlari model/API/DBda saqlanadi.

- Learn headeridan **AI savol** olib tashlandi; **Fanlar**, sinf va Mavzular
  navigatsiyasi saqlangan. Fan/sinf/mavzu ekranida AI tushuntirish yo‘q.
- AssessmentLessonScreen (Fizika/Kimyo/ikki tarixning mavjud MCQ/FRQlari),
  SkillLessonScreen va SkillPracticeScreen (Biologiya MCQ): help faqat mavjud
  tekshiruvdan keyingi correct/wrong `LessonFeedbackPanel` ichida, izohdan
  keyin va Continue oldida turadi. Modal faqat bosilganda so‘rov yuboradi.
  Tekshirilmagan yoki attempt/question konteksti yo‘q button ko‘rinmaydi.
  Savol/attempt/fan/sinf/dars almashsa eski modal yopiladi, request cancel bo‘ladi.
  Legacy umumiy AI tugmasi Beta ichida yashirilgan.
- ContentSourceButton Beta ichida nol o‘lchamli: nazariya, savol, review,
  natija, preview va help ichida bibliografiya/havola/book-open kirishi yo‘q.
  Help source refs render qilinmaydi; outline kitob/PDF betlarini ko‘rsatmaydi.
  Kontentning o‘zi va backenddagi manba tekshiruvi o‘zgarmagan.
- Grade kartalari/daily-goal course note/topic outline/section picker va
  bob sarlavhalaridagi jami dars soni yashirilgan. Paginationda diapazon bor,
  jami denominator yo‘q. Bajarilgan darslar va progress chizig‘i saqlanadi.
  Oddiy non-Beta buildning manba/count ko‘rinishi mosligicha qoladi.
- Ilmo bilan birinchi salomlashish onboarding bosqichiga qisqa darslik xabari
  qo‘shildi (uz/ru/en). Mavjud onboardingCompleteProvider bilan boshqariladi;
  tugallangan onboarding/login/restartda chiqmaydi, eski user flaglari reset yo‘q.
- Haqiqiy AI key yo‘q; reviewed-evidence fallback ishlashda davom etadi.

Tekshiruv: yakuniy Beta acceptance **63 passed** (MCQ/FRQ correct/wrong,
Biologiya, quick switch, modal lifecycle, source/count UI, onboarding bir marta).
Normal katalog/Biologiya/golden UI regressiyasi **85 passed**; yakuniy
`flutter analyze --no-pub`: **No issues found** (95,1s). To‘liq normal suite va
APK/device natijalari lokal `../ilm-ai-beta-artifacts/UI_RESULTS_ACCEPTANCE.md`
hamda markaziy `../ilm-ai/CLAUDE.md` handoffda qayd etiladi.
Loglar `ui-results-*.log` (Gitga kirmaydi); source PDF/DB/secret/APK commit qilinmaydi.
Yangi receipt APK yonida; avvalgi 2065823 buildni yangi deb ko‘rsatmang.

## 2026-10-31 22:16 +05 — Samsungga o‘rnatildi, backend faol

Oldingi “ADB bo‘sh” holati yangilandi: **R58NC0JNBXJ / Samsung SM_A125F**
authorized `device`. USB reverse **tcp:8930 → tcp:8930** o‘rnatildi.
Mavjud 200,03 MiB APK `adb install -r` bilan **Success**; ilova ochildi,
foreground MainActivity va PID 12037 tasdiqlandi. Uninstall/data clear yoki
APK rebuild qilinmadi. Device `base.apk` va lokal APK SHA256 mos:
`518d0ae8e2d4c9bf1ebf42102bd491a245ca38c6bc9212d57ca5c04f29136d04`.
Build commitlari: Flutter `2065823`, backend `8f2ed67`.

Backend oldindan ishlayotgan PID 12940 bilan **127.0.0.1:8930**da qoldirildi;
health **200 / ok / integrated_beta**. 35 jonli API tekshiruvi kutilgan statuslar,
5 fan / 1 381 birlik, 5 manbali tokensiz help, profile/progress APIlarini tasdiqladi.
Authsiz help 401, eski tutor 404; 9 user/progress jadvali probe davomida o‘zgarmadi.
AI key/OAuth/HTTPS yo‘q; lokal beta login va reviewed-evidence fallback ishlatiladi.

Telefonda MCQ + AI tushuntirish kirishi va manba paneli ko‘rildi; agent hech
qanday javob tanlamadi/yubormadi. To‘liq MCQ/FRQ/XP/progress handset acceptance
foydalanuvchining qo‘lda sinovi uchun ochiq. USB/kompyuter faol tursin.
Dalillar `../ilm-ai-beta-artifacts/phone-readiness-20261031.json` va
`phone-backend-checks-20261031.json`; to‘liq operatsion qayd backend `CLAUDE.md`da.
Bu bosqich faqat hujjatlashtirish; kod/main/production/fan branchlari o‘zgarmadi.

Branch `feat/beta-subject-switch-ai-help`, backend sibling `ilm-ai-beta` ham shu
branchda. Asos `0e508ef` / backend `eb04a8d`. Main/production/fan branchlariga tegilmagan.
Rasmdagi brief to‘liq o‘qildi: Learn ichida tez fan/sinf almashtirish,
MCQ/FRQ izohi correct/wrong holatlarida, subject chat va keyin private token ulash.

## Yechim

- `subject_switch_sheet.dart`: backend katalogidagi besh fan va sinflar,
  unavailable/unsupported grade disabled, joriy tanlov belgisi, sinf o‘zgarganda
  scroll boshiga qaytish. SubjectHome learning preferences orqali per-user
  tanlovni saqlaydi; modal bekor qilinsa yozuv yo‘q. Mavjud draft/XP/progress kalitlari saqlanadi.
- CurriculumLearning headerida **Fanlar**, subject/grade va **AI savol**.
- `features/study_help/study_help.dart`: identifier-only context, Dio repository,
  Riverpod provider, modal/chat/follow-up/retry, source buttons, keyboard-safe
  scroll, light/dark/system theme, logoutda cancel/close. Serverdan boshqa
  subject/grade javobi rad etiladi. Provider kaliti yoki test login tokeni kodda yo‘q.
- AssessmentLessonScreen barcha MCQ va mavjud FRQ editorlari uchun oldin/keyin
  izoh kirishi; SkillLessonScreen va SkillPracticeScreen Biologiya v1 uchun.
  `LessonFeedbackPanel.help` nullable, oldingi flow defaulti o‘zgarmaydi.
  Timed practice vaqti help ochilganda ham davom etadi; XP/grader o‘zgarmaydi.
- Faqat debug integratedBeta ichida UI ochiladi; oddiy release/Biology policy saqlangan.
  AI tokensiz holati aniq yoziladi. Tayyor manbali izoh mavjud, erkin generativ
  yoki internet chat tayyor deb ko‘rsatilmaydi. Biologiyada FRQ qo‘shilmagan.
- Build script faqat oldingi beta va ushbu aniq feature branch, clean committed
  worktrees, alohida `com.ilmai.app.beta` / **ILM AI Beta**, normal `lib/main.dart`.

## Qat’iy manba qoidasi

Barcha bilim faqat userning tekshirilgan darslik materialidan. Backend
`/beta/study-help` asli preview/source/session/ownership/prerequisite tekshiruvlarini
saqlaydi. V2 javobdan oldin private javob kaliti/yechim chiqmaydi. Keyin original
grader feedback/solution qaytariladi. MCQ variantlari manbali yechimga solishtiriladi;
manbasiz distractor sabablari o‘ylab topilmaydi. Model keyin ulanganda ham faqat
tasdiqlangan evidence IDlarini tanlaydi. Eski manbasiz tutor bu flowga ulanmagan.

Backendning `docs/beta/STUDY_HELP.md` hujjatida to‘liq audit, API kontrakti,
private tokenni keyin ulash, o‘zgargan fayllar va cheklovlar yozilgan.
HTTPS/OAuth hozir yo‘q, LOCAL_BETA.md talablari amal qiladi. PDF/OCR/DB/credential
Git yoki APKga qo‘shilmaydi. Haqiqiy AI chaqiruvi qilinmagan.

## Tekshiruv va keyingi qadam

Yangi backend: 6 passed, 4 deselected (PG yangi testlari ishlatilmagan), 1
Starlette/httpx deprecation warning. Barcha fanlar, source/owner/lock gate,
MCQ/numeric FRQ correct/wrong, no-XP writes, no-token va noto‘g‘ri provider ID.
Flutter beta va feedback regressiyasi: **56 passed (27s)**. `flutter analyze --no-pub`:
**No issues found**. Oddiy konfiguratsiyadagi butun test to‘plami:
**1 314 passed (9m26s)**. Loglar: `study-help-beta-tests-final.log`,
`study-help-normal-tests-final.log`, `study-help-analyze-final.log` (Gitga kirmaydi).
Oxirgi modal status key tuzatishidan keyin study_help_test alohida qayta tekshirildi:
**9 passed (6s)**; follow-up, retry, account cancel/close va kontekst mosligi.
Backend yakuniy code commit: `8f2ed670c1eebd6c413f1bb79f5765f8387ea869`.
Live localhost health/config ishladi, eski tutor 404, authsiz study-help 401.
Server --resume startidan oldin/keyin 9 user/progress jadvalining count/hashlari bir xil.
Yangi Android acceptance hozir ochiq: 31-oktabrda ADB qurilma ro‘yxati bo‘sh.
Haqiqiy APK bytes/hash/ikkala commit uning yonidagi `integrated-beta-build.json`da.

## 2026-11-07 - Final fixes and isolated HTTPS staging checkpoint (NO-GO)

Latest owner steering: highest Play versionCode is still3;1.0.3/code4 preparation
is authorized, upload/deploy is not. No HTTPS/OAuth staging resource exists.
Both Beta worktrees remain on qa/final-production-fixes-20261106; main/subject
branches and production database/deployment/Play release were not modified.

Code commits: Flutter d00ce86ffd359a640b0553bb49dd6508f99386fd;
backend ac668bfdeb1f31b107fb5e286893629895476485. Subsequent receipt commits only
update documentation. Five-subject /mobile publication reuses reviewed graders
behind explicit source/coverage/private-rubric checks, while preview and test-auth
guards stay closed. Prepared isolated staging env/validator/launcher, pinned
additive migration0015 and separate Android staging identity. No hosted resources
were provisioned or migration applied to production. NVIDIA quota hopping was
removed per latest final brief:402/403 stop pool,429 pauses; reviewed fallback.
Email verification codes/recipients/raw provider exceptions no longer enter logs.
Production reminders preserved through lifecycle; staging sends no scheduled push.
Known cached Flutter sessions route immediately with guarded background profile/
preferences validation; unknown profile state still resolves or shows retry.

Final evidence (commands overlap; do not sum as unique tests): full Flutter1347
passed/6m40s, reviewed-staging44, local-Beta44, session/hardening38; final analyze
No issues found/90s. Backend publication/Beta/provider182 passed19 PostgreSQL
deselected; auth/session/config94; startup/email/schema/config43; final scheme/
config34. New/changed policy/publication Ruff passed. First full Flutter3 stale
label/golden failures were inspected/corrected and full rerun passed; two braces
lint findings were corrected. Real PostgreSQL/Google/device acceptance remains.

Local8930 backend was stopped when checked; restored with --resume, PID22368,
source ac668bf, loopback only. Health200/ok/integrated_beta; five subjects visible,
grade5 only Biology available. Unauthenticated help401, old tutor404. Before/after
46 account/progress table count/hash receipts identical; no account/answer/XP
created by probes. Google unconfigured; no AI key activated. Server left running.

New Beta APK:
C:\Users\Page\Desktop\Projects\ilm-ai-beta-artifacts\ILM-AI-Beta-1.0.3-code4-d00ce86.apk
209809731bytes /200.09MiB; source d00ce86; com.ilmai.app.beta/1.0.3/code4/target36.
SHA256 4dc61f94bf81410c1f96ab5da27bbacc598a7a58aa53200b710d37ceeed57a6e.
Build205.9s; v2 debug signature verifies. APK scan found no checked private files/
credential/JWT literals. Existing future KGP plugin warnings remain. ADB empty:
no new install or phone smoke/upgrade/performance test was claimed. Do not clear
phone data. Final signed five-subject production AAB has NOT been produced.

Live read-only production preflight: health200, mobile auth/catalogue and five
grade routes404. NO-GO blockers: publication import/fresh PostgreSQL whole-chain
acceptance; verified in-app AND public-web account deletion/revocation/data
lifecycle; actual HTTPS/Google new/returning/account-switch/offline acceptance;
real signed upgrade/performance; accurate privacy/Data safety/deletion URLs.
No paid hosting/provider activation, secret persistence, push/deploy/Play upload.

Resume from backend docs/beta/FINAL_FIX_PROGRESS_20261107.md and HTTPS_STAGING.md,
Flutter docs/REVIEWED_MOBILE_STAGING.md, and sibling artifacts/
FINAL_FIX_CHECKPOINT_20261107.md (install/start commands and receipt paths).
