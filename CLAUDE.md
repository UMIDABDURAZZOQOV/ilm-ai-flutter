# ILM AI Flutter — 2026-10-31 handoff

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
