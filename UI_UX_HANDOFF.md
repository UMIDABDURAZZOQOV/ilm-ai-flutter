# ILM AI — mobil UI/UX, birinchi bosqich

2026-10-22, Asia/Tashkent. Branch: `feat/flutter-ui-ux-improvements`.
Asos: Flutter `feat/physics-first-batch`, `cf010113dcb19fb0a2fb2d7c3142178bcae78395`.
Alohida worktree: `ilm-ai-flutter-ui`. Asl Biologiya/Fizika ishchi branchlari almashtirilmagan.

Markaziy manba `ilm-ai/CLAUDE.md` to‘liq o‘qildi, Fizika branchidagi davom qaydlari ham
solishtirildi. Boshqa akkaunt shu hujjat va fan kontenti bilan ishlayotgani uchun ushbu
UI/UX handoff o‘z Flutter branchida tayyorlandi; markaziy hujjatning fan qaydlari
ustiga yozilmadi. Integratsiyada ushbu bo‘limni markaziy hujjatga alohida UI/UX qaydi
sifatida kiritish mumkin.

## Bajarilgan ishlar

- Dars feedbackidagi `AiExplainButton` va mashqdagi `AiTutorWidget` kirishlari yashirildi.
  Yozilgan nazariya, javob izohi va mavjud backend komponentlari saqlandi; yangi AI
  tushuntirish, kontent yoki API yaratilmagan.
- Mobil Biologiya rejimida backend nashr qilmagan placement tugmasi yashirildi.
- Dars yuklash xatosi lokalizatsiyalangan sabab va joyida retry bilan ko‘rsatiladi.
- `LessonDraftStore` mavjud MCQ darsining public snapshoti, attempt ID, nazariya/savol
  indeksi, tanlov, birinchi javoblar, xatolar navbati va sarflangan vaqtni saqlaydi.
  Bu yangi fan kontenti yoki FRQ javob kaliti emas. Kalit API origin + account + lesson
  bo‘yicha ajratilgan; token yoki credential saqlanmaydi.
- Dars qayta ochilganda saqlangan attempt tiklanadi; yangi start so‘rovi yuborilmaydi.
  Completion oldidan aynan yuboriladigan holat qurilmaga saqlanadi. HTTP javobi
  yo‘qolganda retry o‘sha attempt va birinchi javoblarni yuboradi; server grading,
  idempotency va XP qoidalari o‘zgarishsiz ishlaydi.
- 24 soatlik lokal attempt eskirsa yoki server `study_session_expired/required`
  qaytarsa, tushunarli qayta boshlash oqimi bor. Yangi attempt faqat explicit
  «Yangidan boshlash»dan keyin ochiladi. Oldingi server progressi o‘chirilmaydi.
- Buzilgan lokal draft o‘qilmaydi; saqlash xatosi ko‘rinadigan, scroll qilinadigan
  ogohlantirish va retry bilan beriladi. Muvaffaqiyatli completiondan keyingi cache
  tozalash xatosi server tasdiqlagan natijani muvaffaqiyatsizlikka aylantirmaydi.
- Ism dialogi controller lifecycle, busy, takror bosish, account va mounted
  himoyalariga ega. So‘rov davomida dialogni yopish keyingi callbackni qulatmaydi.
- Kunlik maqsad saqlashida busy/error/retry va account tekshiruvi bor; mavjud offline
  preference navbati saqlandi.
- Tema/til segmentlari semantika, klaviatura fokusi va Reduce Motion’ga moslashtirildi.
- Confetti va dars yakuni tovushi faqat server kamida bitta yulduz qaytarganda ishlaydi.
  Muvaffaqiyatsiz dars uchun rag‘batlantiruvchi matn va Ilmo saqlandi.

## Tekshiruv va chegaralar

Yakuniy tekshiruvlar (Windows, shu branchning yakuniy runtime kodi):

- `flutter test --no-pub`: **151 passed**, 39 soniya. Baseline 143 testga 8 yangi
  UI recovery testi qo‘shildi; mavjud noto‘g‘ri birinchi javob bilan tugagan dars
  tovush testi endi zero-star natijada confetti/tovush yo‘qligini talab qiladi.
  Alohida yangi success testi muvaffaqiyatli natijaning tantanasini ham tekshiradi.
- `flutter analyze --no-pub`: **No issues found**, 7,7 soniya.
- `git diff --check`: toza. Generated platform registrantlarining pub-get hosil
  qilgan keraksiz o‘zgarishlari qaytarildi. Paket/lock fayllariga diff yo‘q.
- Flutterning mavjud SDK vositasi Windowsda to‘g‘ridan-to‘g‘ri
  `dart.exe .../flutter_tools.snapshot` orqali ishlatildi. Sandbox lockfile ruxsati
  yo‘q run muvaffaqiyat hisobiga kiritilmadi; yakuniy run ruxsatli muhitda o‘tdi.

Yangi regressionlar:
retry; AI kirishi yashirinligi; process-recreation orqali draft va xatolar navbati;
lost-response completion replay; account/origin isolation; buzilgan va eskirgan draft;
disk xatosi; ism dialogini so‘rov vaqtida yopish; kunlik maqsad xatosi; muvaffaqiyatli
va muvaffaqiyatsiz yakun effektlari. Mavjud Biology, Physics/FRQ, auth, onboarding,
responsive va API contract testlari to‘liq suite tarkibida bajariladi.

Bu widget/mocked API regressionlari. Haqiqiy Android process kill, TalkBack, Google
Console/login, telefon xotira to‘lishi yoki jonli backend bilan end-to-end QA o‘tdi
degan da’vo yo‘q. Ushbu bosqichda APK/AAB yoki yangi production build tayyorlanmadi.

Backend, veb, fan kontenti, FRQ graderi, XP/streak/prerequisite qoidalari, brend va
Ilmo assetlari, OAuth identifikatorlari va nashr flaglariga diff yo‘q. Production DB,
migratsiya, deploy, main merge yoki Play nashri bajarilmadi.

## Keyingi bosqich

Auditning Fizika preview UI matnlarini uz/ru/en tizimiga ulash va Fizika QA hujjatini
joriy katalog/commitlarga moslash bandlari qolgan. Fan kontenti tarjima qilinmaydi.
Keyin vizual izchillik, Ilmo harakatlari va haqiqiy Android QA davom ettiriladi.

## 2026-10-23 — Ilmo brend tizimi

Foydalanuvchining alohida Ilmo/ILM AI topshirig‘i asosida Character Bible,
grafika auditi va hozirgi assetlar bilan bajariladigan shared Flutter yaxshilashlari
tayyorlandi. Tafsilotlar: [Character Bible](docs/brand/ILMO_CHARACTER_BIBLE.md),
[asset auditi](docs/brand/ILMO_ASSET_AUDIT.md),
[o‘lchangan manifest](docs/brand/ilmo_asset_audit.json).

Original 8 PNG saqlandi; yangi 3D grafika yaratilmagan. Shared `MascotImage`,
tokenlar, `IlmoSpeechHeader`, onboarding animatsiyalari va Flutter splashning
dekodlash parametrlari standartlashtirildi. Backend, fan contenti, Physics/Biology
feature kodi, auth/router va native konfiguratsiyada o‘zgarish yo‘q.
Markaziy `CLAUDE.md` SHA/commit qayta tekshirildi; parallel fan ishlariga
aralashmaslik uchun ushbu o‘zgarishning hujjati Flutter UI branchida saqlandi.
Yakuniy tekshiruv: **169 Flutter testi o‘tdi**, analyze **No issues found**.
18 yangi brend testi bor; original PNG hashlarining hammasi saqlandi.
Real telefon/TalkBack/native mask va memory/FPS tekshiruvi hali bajarilmagan.

## 2026-10-23 — Yangi Ilmo launcher ikonkasi

Foydalanuvchi bergan PNG original Flutter papkasida ikki `.png` kengaytma bilan
topildi; faqat shu rasm UI worktree ichiga to‘g‘ri nom bilan nusxalandi. Yangi
1024px indigo master, 66dp xavfsiz doira ichidagi adaptive foreground va 512px
shaffof bo‘lmagan Play Store PNG tayyorlandi. Original `app_icon.png`,
`app_icon_foreground.png`, beshta Ilmo emotsiyasi va splash PNG o‘zgarmagan.

Android/iOS launcher resurslari qayta generatsiya qilindi. Generatorning ayrim
o‘lchamlardagi RGB/alpha yaxlitlashini bartaraf etuvchi takrorlanadigan yakuniy
bosqich skriptga qo‘shildi. Manba rasm retush yoki AI bilan qayta chizilmadi.

Analyze **No issues found**, to‘liq suite **181 passed** (12 yangi ikonka testi).
Android debug APK muvaffaqiyatli yig‘ildi va imzasi tekshirilib Samsung Galaxy
A12 / Android 12 telefoniga `adb install -r` bilan yangilandi. UID va dastlabki
o‘rnatilgan vaqt saqlangan; ilova o‘chirilmagan. Launcherda yangi ikonka ko‘rildi,
o‘rnatilgan APK hashi buildga teng. Bu dars/backend/Google login end-to-end QA
emas. iOS native build bajarilmadi.

Tafsilotlar, qayta generatsiya buyruqlari, hashlar va telefon kesmasi:
[launcher hisoboti](docs/brand/LAUNCHER_ICON_UPDATE.md).
Splash/onboarding, auth, fan kontenti va backend kodi o‘zgarmagan; production
deploy, Play Store nashri va `main` merge bajarilmagan.

## 2026-10-23 — Professional UI/UX: to‘rt bosqich

26 ta haqiqiy Samsung A12 reference va CODEX_TASK.md asosida audit/implementatsiya
bajarildi. Branch `feat/flutter-ui-ux-improvements`; `main`ga merge qilinmagan.

- Foundation/P0: `900c442` — tokenlar, kontrast, loading/retry, haqiqiy draft exit.
- Home/path: `33c010c` — asosiy Continue, o‘qiladigan darslar va safe sheetlar.
- Lesson: `f0e7a76` — reader, real qadamlar, feedback va read-only javob tahlili.
- Profil va qolgan ekranlar: ushbu handoff bilan birga alohida Phase 4 commit.

Yakuniy to‘liq suite **238 passed**, analyze **No issues found**; oxirgi onboarding
targeted **22 passed**. 40 ta light/dark BEFORE/AFTER juftlik va 2 yangi answer-review
tasviri private `.dart_tool/uiux-review/`da. Original screenshotlar Git’ga kiritilmadi.
Asl Ilmo PNG/launcher, backend/network kontrakti, Biologiya 406 darsi va Physics/FRQ
kontentiga diff yo‘q. Android debug build va Samsung A12 yangilash tekshiruvi bor.

Tafsilotlar: [audit](UI_UX_AUDIT.md), [bosqichlar hisoboti](docs/uiux/IMPLEMENTATION_REPORT.md),
[telefon QA](docs/uiux/SAMSUNG_A12_QA.md),
[markaziy CLAUDE.md egasiga handoff](docs/uiux/CLAUDE_MD_OWNER_HANDOFF.md).
TalkBack foydalanuvchi sinovi, Google OAuth va iOS build alohida qolgan QA ishlaridir.

## 2026-10-23 — Pastki navigatsiya animatsiyalari

Foydalanuvchi so‘roviga ko‘ra beshta original vector destination ikoni,
siljiydigan indigo/turkuaz selection, qisqa gesture/press va yo‘nalishli tab
fade-through qo‘shildi. Lazy mounting, tab scroll/cache, callback va route’lar
saqlangan. Reduce Motion, 320dp/200%, uch til va RTL uchun 21 yangi test bor.
To‘liq suite **259 passed**, analyze **No issues found**. Debug APK hisobni
saqlagan holda Samsung A12’ga yangilandi va frozen hash bilan tekshirildi.
Tafsilot: [navigatsiya hisoboti](docs/uiux/NAVIGATION_MOTION.md).

## 2026-10-23 — Darsdan chiqish dialogi

Ixcham status belgisi, qisqartirilgan UZ/RU/EN matni, bir xil kenglikdagi
«Davom etish» / «Saqlab chiqish» amallari. Saqlash xatosi va saqlanmaydigan
mashqda «Chiqish» ko‘rsatiladi. Mavjud lokal draft/back logikasi saqlangan.
29 yangi test bilan to‘liq suite **288 passed**, analyze **No issues found**.
Samsung’da 5/12 urinishda dialog va ikkala amal tekshirildi; lokal draft
mazmuni o‘zgarmagan. Frozen APK qayta o‘rnatilib yakuniy hash tasdiqlandi.
Tafsilot: [dialog hisoboti](docs/uiux/STUDY_EXIT_DIALOG.md).

## 2026-10-23 — Mahsulot UX dasturi

Dars holatlari va keyingi harakatlar izchil, home header ixcham, 406 qatorli
yo‘l lazy render, bo‘lim progressi serverga mos. Dars/checkpoint sheet bir xil,
natija ekrani dars nomi/score/XP/vaqtni aniq ko‘rsatadi. Accessibility header va
tugma node’lari ajratilgan. 81 yangi test, **369 full-suite passed**, analyze
toza; final targeted **87 passed**, 42 BEFORE/AFTER tasvir. Profile/AOT Samsung
testida ma’lumotlar saqlangan. Raster boshlang‘ich o‘lchovi yaxshilash talab
qilganligi sabab performance signoff hali berilmagan.

[Reja](docs/uiux/PRODUCT_UX_PLAN.md), [hisobot](docs/uiux/PRODUCT_UX_REPORT.md),
[beta protokoli](docs/uiux/BETA_USABILITY_PROTOCOL.md),
[release UX gate](docs/uiux/RELEASE_UX_GATE.md).

## 2026-10-23 — navigatsiya tezligi

Tab gate’lari har frame qayta qurilmaydi; static child, render alpha va
ustma-ust sahifasiz fade-through. Input/focus, RTL, Reduce Motion, scroll/cache
saqlangan. Navigation **22**, full suite **370 passed**, analyze **No issues found**.
Arm64 profile build tayyor. Samsung’dagi haqiqiy frame timing, APK va data
tekshiruvlari: [performance hisoboti](docs/uiux/TAB_PERFORMANCE.md).

## 2026-10-23 — yangi 17 ta tasvirdagi muammolar

Outline kontent tayyorligini access’dan ajratadi. Home birinchi darsni
takrorlamaydigan ixcham goal paneli, keyingi entry/checkpoint va review saqlangan.
Bo‘sh liga/yangi profil uchun umumiy Ilmo card va mavjud Learn tabiga CTA;
nol statistika yig‘iladigan bo‘limda, real progress esa darhol ochiq.
Dark qatlamlar neytral indigo; logout aniq nomlangan outline amal.
55 yangi test bilan **425 full-suite passed**, analyze **No issues found**,
42 ta widget BEFORE/AFTER juftlik. Original assetlar va darslar o‘zgarmagan.

[Audit/reja](docs/uiux/SCREENSHOT_POLISH_PLAN.md),
[batafsil tekshiruv va Samsung natijalari](docs/uiux/SCREENSHOT_POLISH_REPORT.md).

## 2026-10-23 — Login va autentifikatsiya brendingi

Login va saqlangan signup kodidagi eski romb logo joriy launcher manbasi
bo‘lgan rasmiy Ilmo yuzchasiga almashtirildi. Rasm kesilmaydi; markazlashuv,
kichik ekran/katta matn scrolli va 220 ms Reduce Motion’ga mos fade bor.
Google Sign-In, tokenlar, darslar va progress o‘zgarmagan; 20 original asset
baytma-bayt saqlangan. 28 yangi test bilan **453 full-suite passed**, analyze
**No issues found**. UZ/RU/EN va light/dark uchun A12 o‘lchamida 6 ta mock
BEFORE/AFTER juftlik tayyorlandi. Haqiqiy akkauntdan chiqish yoki yangi APK
o‘rnatish bajarilmadi.

[Brend auditi, taqqoslashlar va test natijalari](docs/uiux/AUTH_BRAND_REPORT.md).

## 2026-10-23 — Practice, feedback va uzun dars yo‘li

Practice’da kunlik sinov asosiy karta, xatolar va tezlik mashqi ixcham satrlar.
Feedback’da kichik Ilmo sarlavhaga ko‘chirildi, izoh to‘liq kenglikda o‘qiladi;
Continue alohida qoladi. Dars yo‘lida joriy bob ochiq, qolganlari yig‘iladi.
Doim ko‘rinadigan bob tanlash, joriy bobga qaytish va barcha boblarni ko‘rish bor.
UI tanlovi server lock/progress yoki mavjud dars/checkpoint amallarini o‘zgartirmaydi.

Kengaytirilgan mavjud testlar 12-bobga o‘tish, katta shrift, uch til/ikki rejim
va Practice callbacklarini qamraydi. To‘liq suite **453 passed**, analyze
**No issues found**; 48 ta mock render, 12 ta ommaviy review tasviri tayyor.

[O‘zgarishlar, taqqoslashlar va tekshiruv natijalari](docs/uiux/PRACTICE_FEEDBACK_PATH_REPORT.md).

Arm64 profile APK ham muvaffaqiyatli yig‘ildi; source digestlari tekshirilgan.
Bu mavjud lokal API uchun development build. Telefonga o‘rnatilmadi; frozen
APK yo‘li va SHA-256 yuqoridagi hisobotda berilgan.
