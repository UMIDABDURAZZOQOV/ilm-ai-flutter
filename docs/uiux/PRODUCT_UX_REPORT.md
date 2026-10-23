# O‘quv oqimining amaliy UI/UX yaxshilanishi

2026-10-23. `10df787` ustida, `feat/flutter-ui-ux-improvements` branchida.
Reja: [PRODUCT_UX_PLAN.md](PRODUCT_UX_PLAN.md).

## 1. Bosh sahifa va qaytish

- Takroriy fan/sinf sarlavhalari birlashtirildi, darslar soni hero kontekstiga
  ko‘chirildi. Birinchi foydalanuvchida nol XP/seriya asosiy darsni siqmaydi;
  mavjud yutuqlar bo‘lsa haqiqiy ko‘rsatkichlar chiqadi.
- `LessonEntry` yangi/resume/expired/review/locked holatlarini ajratadi.
  Hero, qator va start sheet bir xil state/action’dan foydalanadi. Savol yoki
  nazariyaning aniq saqlangan pozitsiyasi ko‘rsatiladi.
- Faqat validated `LessonDraftStore.read()` ishlatiladi; user va API origin
  chegaralari, v1 draft formati saqlangan. Expiry chegarasi mavjud lesson
  oqimidagidek 24 soat; server yakuniy hakam bo‘lib qoladi.
- Resume entry uchun mahalliy expiry timer bor; provider dispose bo‘lsa
  bekor qilinadi. Locked/completed yuzlab darslar uchun timer/provider yoki
  draft JSON o‘qish yaratilmaydi.
- Keyingi amal yo‘ldagi birinchi ochiq dars yoki bo‘lim sinovi. Avvalgi bo‘lim
  sinovi ochiq turganda keyingi bo‘lim darsi uni chetlab o‘tuvchi hero bo‘lmaydi.
- Bo‘lim sarlavhasi yonida backend completed/mavjud darslar progressi bor.
  Coverage to‘liq bo‘lmasa qolgan darslar tayyorlanayotgani aytiladi; butun
  darslik tugadi degan noto‘g‘ri va’da berilmaydi.
- `CustomScrollView`/`SliverList.builder` faqat ko‘rinayotgan va cache yaqinidagi
  qatorlarni mount qiladi. Account/subject/grade bo‘yicha scroll kaliti bor.
  Bu FPS o‘lchovi emas; 406 qatorli test boshlanish/oxirida 20 tadan kam
  `LearningJourneyTile` mount bo‘lishini va oxirgi darsga yetishni tekshiradi.

## 2. Dars/sinov va natija

- `StudyStartSheet` dars va checkpoint uchun bitta responsive tuzilma:
  ixcham ikon/sarlavha, mazmun, holat sababi, indigo action va «Yopish».
  Checkpointdagi eski sariq/oq action va dark grey surface olib tashlandi.
- Qulflangan yoki noma’lum server statusi ochilmaydi. Serverdan olingan
  prerequisite va coverage sabablari saqlangan. Hech bir UI unlock bermaydi.
- Expired draft yangi urinishni avtomatik boshlamaydi; keyingi tiklash
  oynasiga olib borishi matnda tushuntiriladi. Mavjud explicit restart ishlaydi.
- Lesson loading umumiy, lokalizatsiyalangan yuklanish komponentiga keltirildi.
- `LessonCompletionView`: dars nomi, server XP/score/stars, alohida aniqlik va
  vaqt label’lari, mos o‘lchamdagi original Ilmo. Primary — dars yo‘liga qaytish,
  secondary — mavjud read-only javoblarni ko‘rish. Zero-star natijada confetti yo‘q.
- Backend grading, completion/XP/streak, auth, javoblar va dars mazmuni
  o‘zgarmagan. Asl PNG, launcher, splash va onboarding oqimi saqlangan.

## 3. Tekshiruv qamrovi

`lesson_entry_test.dart`: server ustuvorligi, expiry/clock rollback, aniq
theory/question, UZ/RU/EN × light/dark × start/resume/expired 320dp/200%,
origin/user isolation, account switch, haqiqiy hero/qator/sheet mosligi,
resumeda yangi start request yo‘qligi, checkpoint ustuvorligi, lazy 406 qator.

`study_flow_quality_test.dart`: noma’lum status lock, uch tildagi light/dark
checkpoint, landscape lesson sheet, 320dp/landscape/200% natija amallari va
real fontli natija goldenlari. Mavjud Biologiya, Physics/FRQ, recovery va
navigation regressiyalari to‘liq suite’da tekshiriladi.

Mavjud scroll testlari lazy render’dan keyingi frame’ni kutadi va aniq dars
qatori orqali checkpointni topadi. Content/API/assertion ma’nolari saqlangan;
katta fontda haqiqatan bosiladigan target qo‘shimcha tekshiriladi.

Dastlabki tekshiruv: **159 targeted passed**, **365 full-suite passed**.
Keyingi tekshiruv: **367 passed**, analyze **No issues found**, **69.6s**.
Inglizcha singular/plural tekshiruvidan keyin **368 passed**, analyze
**No issues found**, **51.9s**. Accessibility container yakuniy tuzatishi uchun
qo‘shimcha regression testi bor; oxirgi natija quyida qayd etiladi.

Ikki theme’da 21 tadan real widget capture: **42 BEFORE/AFTER juftlik**,
baseline `10df787`, `.dart_tool/uiux-review/comparisons/product/`da.
Real font/asset yuklangan natija goldenlari Git’da; xom telefon suratlari private.

### Samsung’dagi dastlabki QA

Debug APK muvaffaqiyatli yig‘ildi (Gradle **130.8s**); frozen hash:
`23ca62017bafa93f7ac9ed76af4aa1d7519ce6fb08f928b80c3b27acf8bcf4e7`.
Mavjud debug sertifikati bilan `install -r` qilindi, telefondagi hash tengligi
tekshirildi. UID, original install time va lokal urinishning elapsed time’dan
boshqa mazmuni bir xil. Telefonda saqlangan joriy **6-sinf** saqlanib qoldi.
Bosh sahifa va darsning ma’lumot oynasi ochilib/yopildi; start/complete yoki
javob yuborish bajarilmadi. Fatal/unhandled/overflow log belgilari **0**.

Accessibility XML’da bo‘lim sarlavhasi va dars tavsifi bitta tugma node’iga
qo‘shilib ketgani ko‘rildi. `Semantics(container: true)` bilan bo‘lim, progress
va dars ajratildi; regression test node label’i va bounds’ini tekshiradi.
Bu haqiqiy TalkBack foydalanuvchi sinovining o‘rnini bosmaydi.

Ko‘p ABI’li birinchi profile build paytida 8GB kompyuter RAM’i **97%** band
bo‘ldi; 610s’dan keyin faqat shu taskning tekshirilgan `assembleProfile` clienti
bekor qilindi. Boshqa build/daemon jarayonlari to‘xtatilmadi. Samsung ABI
`arm64-v8a` ekanligi o‘qildi. Qayta build faqat shu ABI, bitta worker va
1536MB Gradle heap bilan, faqat subprocess environment orqali bajariladi.
Global/production Gradle sozlamalari o‘zgartirilmaydi. Usul
[Gradle build environment hujjati](https://docs.gradle.org/current/userguide/build_environment.html)
asosida. Profile/AOT build FPS o‘lchovi yoki Play release imzosi degani emas.

### Yakuniy UI bosqichi dalillari

- Yangi entry suite **28**, flow suite **53**: jami **81 yangi test**.
- To‘liq suite **369 passed** (`--concurrency=1`, framework **218s**).
- Analyze **No issues found**, **131.8s**. Eng oxirgi `0/0` guard va semantics
  uchun flow/journey/navigation qayta tekshiruvi **87 passed**, **48s**.
- Final light/dark widget capture **2 passed**; 42 ta juftlik qayta yaratildi.
- Arm64 profile/AOT build muvaffaqiyatli: Gradle **1124.2s**, wrapper **1131.5s**.
  Dastlabki profile/Gradle keshini yaratish, xotira bosimi va single worker
  sababli bu build sekin bo‘ldi; bu ilovaning ishga tushish vaqti emas.
- Frozen profile APK SHA256:
  `dc3d40940d0326dd33e6c45714d9f028f0784a6a408a8a63188f9a7956bf5e7e`.
  APK’da arm64 `libapp.so` bor, debug kernel yo‘q, paket va debug sertifikat
  mos. Telefonga `install -r` qilindi va qurilmadagi hash tengligi tasdiqlandi.
- Profile update’dan so‘ng ham UID, firstInstallTime va draft hash teng.
  Accessibility XML’da bo‘lim/progress va darsning alohida bounds/label’i
  ko‘rildi. App logida fatal/unhandled/overflow **0**.

### Keyingi performance bosqichining boshlang‘ich o‘lchovi

Samsung A12, 60Hz, profile AOT. Flutter SDK `SchedulerBinding` yuborgan
haqiqiy `Flutter.Frame` extension eventlari, video FPS emas. Oldindan ochilgan
5 tab bo‘ylab ikki aylanish va home scroll, **280 kadr**:

| Ko‘rsatkich | p50 | p95 | p99 |
|---|---:|---:|---:|
| UI build | 3.220ms | 14.543ms | 20.479ms |
| Raster | 8.669ms | 36.572ms | 59.399ms |

UI yoki raster 16.67ms’dan oshgan kadrlar **59/280**. PSS oldin **172.1MB**,
keyin **190.0MB**; bu ikkita snapshot memory leak sinovi emas. Bu o‘lchov
chizish bosqichini yana yengillashtirish zarurligini ko‘rsatdi. Ommaviy
reliz performance signoff’i berilmadi. Keyingi optimallashtirish alohida
commit va xuddi shu scenario’da qayta o‘lchov bilan bajariladi.

### Navigatsiya performance bosqichi — yakun

Keyingi bosqich bajarildi: `IlmTabView` har frame butun Stack/gate tuzilmasini
qayta qurmaydi. Static child, render alpha va bir vaqtning o‘zida bitta sahifa
chiziladigan 260ms fade-through; fokus/input, RTL, Reduce Motion va scroll/cache
saqlangan. Yakuniy suite **370 passed**, analyze **No issues found (184.2s)**.

Samsung’da bir xil scenario’ning qayta o‘lchangan B nazorati **285 frame**,
so‘ng C optimallashtirilgan versiyada **309** va **302 frame**:
raster p95 **29.782 → 18.311 / 17.402ms**, budget’dan oshgan frame ulushi
**18.6% → 9.7% / 9.6%**. Hash/cert/AOT tekshirilgan C APK telefonda qoldi;
UID, firstInstallTime, draft hash teng va app xato belgisi **0**.

Fon runner qayta APK o‘rnatgani sabab bitta C urinishida collector ulanmadi;
u natija sifatida ishlatilmadi. Foydalanuvchining aniq ruxsatidan so‘ng faqat
o‘sha avtomatik qayta boshlayotgan runnerning tekshirilgan alohida terminali
yakunlandi. Boshqa branch, VS Code yoki daemonlarga tegilmadi.

Natija sezilarli, lekin raster p95 barcha run’da 16.67ms’dan past emas.
Single-device/warm-cache cheklovlari, to‘liq jadval va qolgan release QA:
[TAB_PERFORMANCE.md](TAB_PERFORMANCE.md). 60 FPS yoki «10/10» kafolati yo‘q.

## 4. Ommaviy reliz va beta

[Release UX gate](RELEASE_UX_GATE.md) va [beta protokoli](BETA_USABILITY_PROTOCOL.md)
tayyor. Upload signing kaliti bu worktree’da yo‘q; signing himoyasi o‘zgarmadi.
Haqiqiy Google OAuth, production foydalanuvchi oqimi, TalkBack foydalanish
sinovi, boshqa real qurilmalar va o‘quvchilar kuzatuvi bajarildi deb yozilmaydi.
Beta CSV shablonida foydalanuvchi PII yoki tokenlar uchun ustun yo‘q.

Haqiqiy o‘quvchilar natijasigacha «10/10» yoki retention kafolati berilmaydi.
Main merge, production deploy va Play publication ushbu ishga kirmaydi.
