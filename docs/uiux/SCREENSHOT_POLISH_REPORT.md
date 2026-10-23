# Samsung tasvirlaridagi beshta UI/UX muammosi

2026-10-23. Ish boshlanishi `676eb37`, branch
`feat/flutter-ui-ux-improvements`. [Audit va reja](SCREENSHOT_POLISH_PLAN.md).

## 1. Kontent tayyorligi va access

`CurriculumTopicSummary.ready` kontent tayyorligini bildiradi, server tree’dagi
`LessonStatus` esa darsning learner uchun ochiqligini belgilaydi. Outline
«Урок доступен» / play belgisi bilan birinchisini ikkinchisidek ko‘rsatgan.

Endi outline’da **«Kontent tayyor / Контент подготовлен / Content prepared»**,
kitob belgisi va darslar o‘quv yo‘lida ketma-ket ochilishi haqidagi izoh bor.
«Dars yo‘liga qaytish» amali haqiqiy locked/unlocked holatlarni ko‘rishga
qaytaradi. Completed va tayyorlanayotgan mavzular o‘z holatini saqlaydi.
Grade/home sonlari «tayyor darslar» deb ataladi. Qo‘shimcha network request,
unlock taxmini, start API yoki DTO/backend o‘zgarishi yo‘q.

## 2. Ixcham home

Birinchi ochiq darsning title/start amali hero’da takrorlanmaydi. Ixcham
`LearningContinueCard.compact` kunlik maqsad, mavjud original Ilmo va course/
content tili izohlarini ko‘rsatadi. Boshlash amali dars qatorida qoladi.
Goal target’i kamida **48dp**; katta shriftda balandlik erkin o‘sadi.

Keyinroq turgan joriy dars/checkpoint uchun tez entry va oldingi checkpoint
priority saqlanadi. Resume savol pozitsiyasi endi dars qatorida ham ko‘rinadi,
semantics label’iga kiradi. Barcha darslar tugallanganda review yo‘riqnomasi,
bo‘sh yoki to‘liq locked yo‘ldagi kontekst yashirilmaydi. Lazy sliver,
account/grade scroll, draft expiry va server hukmi o‘zgarmagan.

## 3. Liga va yangi profil

Umumiy `LearningInvitationCard`: original Ilmo, mazmunli sarlavha/izoh va
«Dars yo‘liga o‘tish». Liga bo‘sh bo‘lsa faqat ma’lumot yo‘qligini bildirish
o‘rniga keyingi qadam bor. Real tier, XP, keyingi liga va ranking saqlangan.
Sun’iy ishtirokchi, rank yoki bonus ko‘rsatilmaydi.

Yangi profilda uchta nol, kalendar va bo‘sh heatmap birinchi vazifa o‘rnini
egallamaydi. Ular **«Statistika va faollik»** yig‘iladigan bo‘limda qoladi.
XP, streak, completed lesson, activity yoki subject/strongest/weakest progress
bor bo‘lsa batafsil mavjud statistika darhol ochiq. Progress yashirilmagan
yoki hisob qayta yozilmagan.

Tab ichidagi CTA callback bilan mavjud Learn’ga qaytadi: class, subject, goal
va tree cache saqlanadi. Alohida profil/liga route’ida mavjud `/learn` ishlaydi.
Bu tugmalar darsni boshlamaydi, XP yoki javob yubormaydi.

## 4. Dark mode va logout

Dark fon/surface/karta **#101420 / #191F30 / #232C42**, chegara **#424F6B**,
selected surface **#30395B**. Binafsha kartalar o‘rniga neytral indigo qatlamlar;
indigo action/link, turkuaz progress va sariq milestone rollari saqlangan.
Asosiy brend **#2A1F6B / #2DD4BF / #F9A825**, original maskot/launcher o‘zgarmagan.

Settings’dagi katta qizil logout o‘rniga sokin outline amal. UZ/RU/EN:
«Akkauntdan chiqish / Выйти из аккаунта / Log out of account». Tasdiqlash
dialogi, cancel va haqiqiy `authController.logout()` mexanizmi saqlangan;
real telefondagi hisobdan chiqish QA uchun bajarilmaydi.

## 5. Avtomatik tekshiruvlar

- Yangi `screenshot_polish_test.dart`: **55 test**. Readiness/access,
  first home’da yagona title/action, 48dp compact goal, 200%/landscape,
  UZ/RU/EN light/dark, profil expand/collapse, progressning 7 manbasi,
  ranked/empty liga, tab cache va standalone route, logout cancel/session,
  completed-path review guidance, 6 yangi real-font golden.
- Mavjud entry, curriculum, lazy 406-row, server grading, expiry, account
  isolation va recovery testlari qoldirilgan. Faqat o‘zgargan UI matni va
  takroriy hero action olib tashlanganiga oid assertions yangilangan.
- Dark palitra sabab controls/navigation/completion/exit’ning 4 ta dark
  golden’i yangilangan; light golden’lar o‘zgarmagan.
- Yakuniy to‘liq suite: **425 passed**, framework **285s**,
  subprocess **305.6s**, `--concurrency=1`; golden update’siz qayta tekshirildi.
- Analyze **No issues found**, **2873.6s**; subprocess **2879.1s**. Yakunda
  xotira tekshiruvida 8GB host RAM’i **97.3%** band, available **211MB** edi.
  Bu hostdagi tekshiruv davomiyligi, ilovaning startup yoki frame vaqti emas.
- O‘zgarishdan oldingi capture suite **2 passed**, **42** light/dark tasvir,
  baseline `676eb37`. Yakuniy capture suite **2 passed (13s)**, wrapper **51.5s**;
  **42 ta BEFORE/AFTER juftlik** yaratilib asosiy ekranlar ko‘rib chiqildi.
  Widget fixturelari telefon benchmarki yoki production foydalanuvchi ma’lumoti
  emas. Yangi 6 golden’dagi liga fixture’i keyingi tier’ning haqiqiy XP
  chegarasi bilan 0/100 progressni tekshiradi; eski umumiy review fixture’ining
  min-XP oralig‘i noma’lum holati real telefon progressi sifatida olinmaydi.
- Umumiy review fixture’iga Silver uchun `min_xp: 100` va UZ/EN nomlari
  qo‘shildi. Unga bog‘liq UI/accessibility/navigation **36 test qayta o‘tdi**,
  framework **69s**, wrapper **91.6s**; capturelar yangilandi. 42 ta taqqoslashning
  2 ta liga tasvirida fixture oralig‘i ham tuzatilgani caption/manifest’da
  alohida yozilgan; qolgan 40 juftlikda ma’lumot fixture’i bir xil.

## 7. Android build va qurilma nazorati

Arm64 profile/AOT build muvaffaqiyatli: Gradle **389.1s**, wrapper **394.5s**.
Frozen APK SHA256:
`7f14dc73c907943e51dc53c9e0b59e691e10f67780c1205d9a083a49655618fa`.
`libapp.so` bor, debug kernel yo‘q, package `com.ilmai.app`, avvalgi signing
certificate mos. `install -r` ma’lumotlarni o‘chirmaydi. Build paytidagi `lib/`
fayl digestlari tekshirildi; keyingi o‘zgarish faqat review test fixture’ida.

VS Code’dagi aynan UI worktree/Samsung runneri qayta APK o‘rnatib turgani
aniqlandi. Foydalanuvchining avvalgi aniq ruxsati asosida faqat shu runner
to‘xtatildi. Windows SDK’dagi `dart.exe` wrapper’idan tashqari qolgan
`dartvm.exe` va uning frontend/DDS/per-device ADB child’lari ham tekshirilib
yakunlandi; shared Gradle daemon, global ADB server va VS Code saqlandi.
Hash noto‘g‘ri bo‘lgan QA urinishlari input yubormay to‘xtadi, valid natija
sifatida olinmadi. Startup’da fokus kechikishi uchun bounded kutish qo‘shildi.

Pre-install telefon tasvirlarida oldingi runner allaqachon yangi dev UI’ni
ko‘rsatgan. Ular `676eb37`ning nazorat baseline’i deb olinmaydi; asosiy
BEFORE/AFTER dalil — eski commitdan olingan widget capture va foydalanuvchi
bergan original 17 tasvir. Telefonning yakuniy tekshiruvi frozen profile APK’da.

Samsung’da `blue_light_filter=1` o‘qildi. Shu sabab real screencap’da ranglar
iliq/jigarrangroq ko‘rinishi mumkin; tizim filtri o‘zgartirilmadi. App palette
hex qiymatlari va golden/capture kontrasti alohida tekshirilgan.

### Haqiqiy Samsung A12 — yakuniy natija

- Frozen hash capture boshida/oxirida teng; profile/AOT APK telefonda qoldi.
- **Light va dark**: home, topics, yangi profil, bo‘sh liga, settings va logout
  dialogi tekshirildi. Profilning statistikasi har ikkala temada haqiqatan
  ochildi va yopildi; kalendar ko‘rinishi bilan tasdiqlandi. Android node label’i
  subtitle bilan birlashgani uchun QA selektori fresh prefix orqali tekshirildi.
- Profil/liga CTA’lari mavjud Learn’ga qaytdi. Logout dialogi faqat ochilib
  bekor qilindi; akkauntdan chiqish, dars start/complete yoki javob yuborish yo‘q.
- Android UID **10298** va firstInstallTime **2026-10-21 17:56:08** teng.
  Draftlar to‘liq user/origin key’i bo‘yicha hashed; elapsed time’dan boshqa
  barcha mazmun digestlari teng. Theme/language/class/subject/daily goal
  qiymatlari ham avvalgi bilan teng; asl **dark / ru** holati tiklandi.
- Fatal/unhandled/RenderFlex overflow belgisi **0**. Yakunda Learn ochiq,
  ro‘yxat tepada. Private snapshot, XML, screenshot va VM URI’lar Git’da yo‘q.

### Joriy APK’da frame timing

Original dark/ru holatida, 60Hz A12, oldindan ochilgan besh tab va home scroll.
Haqiqiy `Flutter.Frame` VM eventlari; APK hash o‘lchov boshida/oxirida teng.

| Ko‘rsatkich | p50 | p95 | p99 | max |
|---|---:|---:|---:|---:|
| UI build | 3.487ms | 9.136ms | 27.073ms | 30.253ms |
| Raster | 8.212ms | 15.375ms | 23.534ms | 30.161ms |

**300** frame, UI yoki raster 16.67ms’dan oshgan **23/300 (7.7%)**.
PSS snapshot **201.1 → 208.8MB**; uzoq memory leak testi emas.
Bu bitta warm scenario; oldingi light-theme benchmark bilan controlled A/B
sifatida solishtirilmaydi. Outlier’lar bor; barcha oqimlarda 60 FPS kafolati
yoki release signoff berilmaydi. Tizim rang filtri va shaxsiy sozlamalar saqlandi.

## 6. Chegaralar

Backend/DB, auth/network kontraktlari, fan kontenti va 406 Biologiya darsi,
Physics/FRQ, assets, splash, launcher va production konfiguratsiyasida diff
yo‘q. Markaziy `ilm-ai/CLAUDE.md` hash’i avvalgi bilan teng. Oldindan dirty
7 ta generated desktop plugin fayli ushbu commitga qo‘shilmaydi.

Haqiqiy o‘quvchilar bilan usability/beta, TalkBack va signed release/OAuth
tekshiruvlari [release gate](RELEASE_UX_GATE.md)da qoladi. Bu vizual bosqich
«10/10», retention yoki barcha sharoitda 60 FPS sertifikati emas.
