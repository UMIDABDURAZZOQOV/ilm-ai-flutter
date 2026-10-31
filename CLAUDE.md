# ILM AI Flutter — 2026-10-31 handoff

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
