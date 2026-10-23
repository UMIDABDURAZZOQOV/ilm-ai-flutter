# ILM AI UI/UX — bosqichlar hisoboti

Audit: [UI_UX_AUDIT.md](../../UI_UX_AUDIT.md).
Dizayn qoidalari: [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md).
Asos: `aec64b8`, branch `feat/flutter-ui-ux-improvements`.

## Dalillarni talqin qilish

26 ta reference — foydalanuvchining haqiqiy Samsung A12 rasmlari. Ular maxfiylik
qaydiga muvofiq Git tarkibiga kiritilmaydi. `.dart_tool/uiux-package/`dan o‘qiladi.
`before/` va `phaseN/` widget capturelari bir xil 360×800dp, 2 DPR, RU UI,
light/dark va izolyatsiyalangan fixturelar bilan yaratiladi. Ular jonli backend
natijasi yoki haqiqiy telefon skrinshoti emas. Yakuniy capture: 20 ta holat ikkala
theme’da juftlangan; answer-review yana ikkita AFTER tasvirga ega. Loading, error,
home, outline, start, practice, grades, profile, quests, league, settings, login,
onboarding, theory/theory-next, quiz, exit, wrong/correct feedback va finish mavjud.

Qayta olish:

```powershell
flutter test --no-pub test/uiux_visual_review_test.dart --dart-define=UIUX_CAPTURE=true --dart-define=UIUX_STAGE=phase1
flutter test --no-pub
flutter analyze --no-pub
```

Ko‘rik uchun mahalliy Flutter SDKdagi Roboto yuklanadi; capture bo‘lmagan oddiy
regressiyalar tizim shriftiga bog‘lanmaydi. Komponent goldenlari synthetic matnli,
shaxsiy ism yoki asl telefon ma’lumotlarini o‘z ichiga olmaydi.

## Bosqich 1 — Foundation va P0

- `IlmDesign` ThemeExtension, spacing/radius, type scale va reading width.
- Indigo action va dark mode link rangi ajratildi; semantik matn kontrasti test
  bilan tekshiriladi. Material card/sheet/dialog/listTile/input/button/progress
  standartlari ikkala rejim uchun berildi; app bar scroll tint o‘chirildi.
- Gradient button va qalin bevel o‘rniga tekis indigo action, yengil press.
  Bottom navigation target/label/semantics yaxshilandi; route va callback qolgan.
- Bosh sahifa/catalog/grade/path loading strukturali va uch tilda, Reduced Motion
  bilan ishlaydi. Reloadda mavjud AsyncValue data saqlanadi; path xatosi haqiqiy
  xabar va retry beradi.
- MCQ exit dialogi oldidan eng so‘nggi draft saqlanadi; muvaffaqiyat/xato/default
  practice nusxalari farqlanadi. Dialog ochilishi vaqtida takroriy interaction
  bloklanadi. API completion yoki draft formatiga o‘zgarish yo‘q.
- Qolgan til bannerini bir martalik kontekstga aylantirish va lesson layout
  bosqich 3da; ekranlarga xos qolgan kontrast/balandlik bosqich 2/4da.

**Tekshiruv:** yakuniy to‘liq Flutter suite **198 passed** (72s), 181 mavjud va
17 yangi test. Analyze **No issues found** (65.9s). Komponent goldenlari oddiy run’da tekshirildi. Oxirgi targeted run
**17 passed**; corrected BEFORE **2 passed** / AFTER **2 passed**. 24 ta yuklangan
BEFORE/AFTER juftligi yaratildi. Dark login, home va light theory juftlari ko‘rildi;
home kartasi/yo‘lning balandligi keyingi bosqichda o‘zgartiriladi.

Avvalgi baseline `aec64b8` Git arxividan private
`.dart_tool/uiux-baseline/` snapshotida qayta yaratildi; hech bir boshqa branch
checkout yoki overwrite qilinmadi. Material iconlari va Roboto bilan capture
qilinadi. Home data yuklangani invariant bilan tekshiriladi.

Test topgan regressiyalar: 320dp/200% header overflow, Google actiondagi uzun
matn va field-focus scroll vaqti. Birinchi ikkitasi UI’da o‘raladigan layout bilan
tuzatildi. Physics feature/kontentiga tegilmadi; faqat uning test yordamchisida
keyboard reveal tugashi kutiladi, barcha oldingi assertionlar saqlangan.

Mahalliy backend `/health`: HTTP200. Samsung A12 ADB’da ulangan. Bu bosqichning
server/telefon dars-completion yoki haqiqiy Google login tekshiruvi emas.

## Bosqich 2 — Home va dars yo‘li

- `LearningContinueCard`: keyingi haqiqiy unlocked darsning nomi va bitta asosiy
  indigo CTA. Ilmo shu kontekstda ixcham; kunlik maqsad ikkilamchi, tahrirlash
  va XP progressi avvalgi callback/foydalanuvchi preference bilan qoladi.
- O‘qilmaydigan, mutlaq koordinatali to‘lqinsimon maydon o‘rniga nomi va holati
  to‘liq o‘raladigan `LearningJourneyTile`lar. Romb milestone, rangdan tashqari
  lock/check/star, butun qator 48dpdan katta target va semantics bor.
- Bo‘lim sarlavhalari, dars tartibi, lock sababini aniqlash, checkpoint,
  `/skills/lesson` route va server unlock/XP qoidalari o‘zgarmagan. Qulflangan
  kartani bosish mavjud tushuntirish sheetini ochadi, darsni ochib yubormaydi.
- Refresh mavjud read endpointini ishlatadi. Bo‘sh tree o‘zbek/rus/ingliz UI
  xabari bilan chiqadi; sun’iy lesson yoki progress qo‘shilmagan.
- Grade kartalari themed surface/check bilan; reader eni chegaralangan.
  Outline/start sheet safe area va maksimal balandlikka ega. Start CTA endi
  turkuaz ustida oq matn emas, umumiy indigo action.

Targeted regression: **72 passed** (23s), shundan 12 yangi journey testi:
UZ/RU/EN × light/dark × 320×568/640×360, 200% font; goal/continue/locked-row
callback va semantics. To‘liq suite **210 passed** (103s). Keyin qo‘shilgan
offline pull-to-refresh testi bilan yakuniy journey run **13 passed** (9s).
Analyze **No issues found** (64.7s). Capture **2 passed**, 28 ta BEFORE/AFTER juftlik.
Light/dark home, dark grade picker va start sheet juftlari ko‘rildi.

Capture yordamchisida har sahna oldidan route daraxti to‘liq yangilanadi;
“grades” sahnasi haqiqatan sinf pickerini ko‘rsatayotgani assertion bilan
tasdiqlanadi. Home ruscha/inglizcha UI’da dars tili o‘zbekcha ekanini bir marta
ixcham ko‘rsatadi. Callback, API/data qatlamlari va barcha PNGlar o‘zgarmagan.

## Bosqich 3 — Nazariya, savol va javob tahlili

- `LessonStepHeader` nazariya/savol/takrorlash hisobini alohida ko‘rsatadi.
  To‘liq til eslatmasi birinchi qadamda; qolganida ixcham, semantik UZ belgisi.
  Serverning mavjud optional `content_language` metadatasi o‘qiladi va lokal
  snapshotda saqlanadi; eski snapshot ham ishlaydi. Outbound payload o‘zgarmagan.
- Nazariya neytral reader kartasi, 17px/1.6 matn, 640dp maksimal kenglik,
  kontekst ichidagi 72dp Ilmo va har yangi kartada yuqoridan boshlanadigan scroll.
  Asl body/example/source va savol/javob/izoh matnlari o‘zgartirilmagan.
- Variantlarda radio/check/cancel ikonlari va holat semantics bor; tekshirishdan
  oldin to‘g‘ri javobni ko‘rsatmaydi. Feedback muloyimroq, izoh/save error alohida
  scroll, Continue tashqarida qoladi; takrorlash navbati va grading o‘zgarmagan.
- Yakunda original javoblarni read-only ko‘rish va dars yo‘liga aniq qaytish.
  Review serverga qayta start/complete yubormasligi regressiyada tekshiriladi.

To‘liq regression **226 passed** (70s). Yangi 14 ta presentation testi:
legacy/metadata snapshot, javobni erta oshkor qilmaslik, 3 til × 2 theme × 2
o‘lchamda 200% shrift va uzun feedback/save error bilan CTA hit-test.
Qo‘shimcha review testida XP qayta berilmasligi tekshirildi. Goldenlar
yangilandi va to‘liq suite oddiy golden comparison bilan o‘tdi.
BEFORE/AFTER capture testlari **2 + 2 passed**. Theory-next, exit, correct va
finish sahnalari qo‘shildi; yangi answer-review faqat AFTER mavjud. Light theory,
dark wrong feedback va dark finish juftlari ko‘rildi. Testdagi 12/12 va +20
izolyatsiyalangan fixture javobidir, jonli foydalanuvchi natijasi emas.

Analyze: **No issues found** (49.2s). 36 ta private BEFORE/AFTER juftlik.

## Bosqich 4 — Profil va qolgan kundalik ekranlar

- Profil avatar/badge/statlar va kalendar umumiy indigo surface/border bilan.
  UTC faollik/streak hisoblash mantig‘i o‘zgarmagan. 200% shrift uchun kalendar
  o‘z enida scroll qiladi. Har sana va heatmap katagi haqiqiy yakunlangan urinish
  soni bilan semantics oladi; backend `skill_stats.py`dagi ma’no o‘qib tekshirildi.
- Profilning tashqarisidagi qo‘shimcha settings qatori yagona AppBar actioniga
  ko‘chirildi. Tab switch state va barcha route’lar saqlangan.
- Liga neytral karta, rang faqat tier belgisida; bo‘sh reyting halol izoh beradi.
  Vazifalar ixcham streak/stat, real goal va daily challenge bilan. Pull-refresh
  xatosi AsyncValue retry state’iga o‘tadi, unhandled future chiqarmaydi.
- Practice mode kartalariga maqsadni tushuntiruvchi qisqa UI matni. Savollar
  umumiy reader/header/feedback komponentlaridan foydalanadi; timer, attempt,
  submit/retry, placement va checkpoint qoidalari o‘zgarmagan.
- Settings selected check/semantics, 48dpdan katta target va katta shrift/tor
  ekran uchun ustunli tanlov. Onboarding field yorlig‘i yozish vaqtida qoladi;
  disabled CTA sababi tushunarli. OAuth, validation va draft/account qoidalari
  o‘zgarmagan. Login’da korporativ belgi bilan ILM AI nomi tartiblangan.

**Tekshiruv:** to‘liq suite **238 passed** (69s), final analyze **No issues found**
(122.2s). Oxirgi onboarding helper holati tuzatilgach targeted **22 passed** (20s).
12 yangi accessibility matritsasi 3 til × 2 theme × 2 o‘lchamda profil, liga,
vazifalar, settings, login, keyboardli onboarding va kalendarni 200%da tekshiradi.
Final BEFORE/AFTER capture **2 + 2 passed**, **40 juftlik + 2 yangi review tasviri**.
Dark profil/onboarding, light vazifalar juftlari ko‘rildi; boshqa ekranlar ham
bir xil harnessdan qayta olindi. Native stderr warning bilan PowerShell exit’ini
adashtirmaslik uchun final buyruqlarda subprocess return code alohida yozildi.

Avvalgi test urinishlarida noto‘g‘ri fayl nomi va yangi testdagi semantics handle
lifecycle xatosi topildi. Test yordamchisi tuzatildi; yuqoridagi natijalar faqat
yakuniy muvaffaqiyatli runlarga tegishli.

Backend CLAUDE.md hash/HEAD qayta tekshirildi va saqlangan. `aec64b8` bilan
assets/native launcher, network, Physics, fixture/content, pubspec diffi yo‘q.
Markaziy hujjat egasi uchun [handoff](CLAUDE_MD_OWNER_HANDOFF.md) tayyorlandi.
Telefon tartibi: [Samsung A12 QA](SAMSUNG_A12_QA.md).

## Samsung A12 — yakuniy kuzatuv

Android debug build return code **0** (yakuniy incremental build 53.7s). Paket va
avvalgi debug sertifikat tekshirilib, `adb install -r` **Success** bo‘ldi. UID
**10298**, firstInstallTime **2026-10-21 17:56:08** saqlandi; uninstall/clear-data
bajarilmadi. Hisob qayta login talab qilmasdan ochildi.

Real telefon: home, practice, quests, league, profile light ekranlari; keyin
settings/profile/home/outline/grade picker dark holatlari ko‘rildi. Ilovada ochiq
turgan 3/12 savoldan chiqishda mahalliy draft saqlangani haqidagi dialog ko‘rildi.
Serverga dars completion yuborish QA tarkibiga kiritilmadi; XP/streak ko‘rsatkichlari
sun’iy to‘ldirilmadi. Yakunda 5-sinf, ruscha UI, light mode va home qaytarildi.
Joriy app PID error logida fatal/unhandled/RenderFlex overflow belgilari **0**.

QA davomida yana `flutter run` jarayoni paketni yangilagani kuzatildi. Foydalanuvchi
shu ishni davom ettirishni aytdi; jarayon majburan to‘xtatilmadi. Standalone APKning
o‘rnatish oldidagi SHA256 `dfb0327b2912390832b86e570eba25a3cc426c4d55dbec8c48919fed8598d3ea`;
oxirgi telefondagi APK SHA256
`75d3964b19ff72c088daa230bf9c425977a99b52c44fe4c12c1df0f156b8ffb4`.
Oxirgi APK telefondan private nusxa sifatida olindi, sertifikati tekshirildi va
telefon `sha256sum` natijasi bilan tengligi tasdiqlandi. Final lastUpdateTime
**2026-10-23 09:02:08**. Bular ikkita artefakt: hashlar bir xil deb yozilmaydi.

Tasvirlar/xulosa `.dart_tool/uiux-review/device/`da: `final-*`,
`verified-home-dark.png`, `verified-outline-dark.png`, `exit-on-device.png`,
`QA_SUMMARY.json`. Birinchi koordinata asosidagi capturelar ekran almashtirilgani
sababli to‘g‘ri nomlanmagan; ular dark mode dalili sifatida ishlatilmadi. Yakuniy
targetlar har amal oldidan UI XML orqali qayta topildi, theme settle kutilib
tasvirlar qayta olindi. Telefonning asl tasvirlari yoki hisob ismi commit qilinmaydi.

## Qolgan mustaqil QA

Haqiqiy Google OAuth, TalkBack bilan foydalanuvchi sinovi, FPS/memory profiling va
iOS native build bajarilmadi. Mavjud KGP dependency ogohlantirishi keyingi SDK/plugin
migratsiyasida hal qilinadi; bu UI ishida dependency yoki production flag o‘zgarmadi.
Yangi 3D asset kerak bo‘lmadi. Backend egasi uchun hujjat tavsiyasi tayyor; boshqa
repo CLAUDE.md fayliga yozilmadi. Main merge, deploy va Play nashri bajarilmadi.

## Qo‘shimcha so‘rov — navigatsiya animatsiyalari

Beshta original vector ikon, 280ms selection, 360ms bir martalik ikon gesture’i
va 260ms yo‘nalishli tab fade-through qo‘shildi. State/scroll/cache va route’lar
saqlangan, Reduce Motion’da harakat darhol yakunlanadi. 21 ta yangi test bilan
yakuniy suite **259 passed**, analyze **No issues found**. Frozen APK hash bilan
tekshirilib Samsung A12’ga yangilandi; real video va dekodlangan kadrlar ko‘rildi,
error logda fatal/unhandled/overflow belgisi 0. Main merge/deploy bajarilmadi.
[To‘liq motion hisoboti](NAVIGATION_MOTION.md).

## Qo‘shimcha so‘rov — darsdan chiqish dialogi

Samsung tasviridagi katta ikon va uzun paragraf o‘rniga ixcham sarlavha,
holat belgisi, qisqa matn va to‘liq kenglikdagi ikkita amal joriy qilindi.
Saqlashning haqiqiy natijasi, dars muddati va oldingi yutuqlar haqidagi ma’no
saqlangan. Light/dark, uch til, 320dp/200%, landscape, saqlash xatosi va
Reduce Motion uchun **29 yangi test**; to‘liq suite **288 passed**, analyze
**No issues found**. [Batafsil dialog hisoboti](STUDY_EXIT_DIALOG.md).

## Mahsulot UX dasturi — o‘quv oqimi

Yangi/resume/expired/review/locked holatlari hero/qator/sheet’da izchil,
bo‘lim progressi real server darslariga asoslangan. Ixcham bosh sahifa,
lazy ro‘yxat, umumiy dars/checkpoint sheet va qayta tuzilgan natija ekrani.
81 yangi test bilan **369 full-suite passed**, analyze **No issues found**;
yakuniy komponent/nav **87 passed**, 42 ta BEFORE/AFTER juftlik.
Samsung’da debug va arm64 profile/AOT APK, cert/hash/user-data tekshirildi.
Haqiqiy 280 Flutter.Frame boshlang‘ich o‘lchovi raster p95 36.572ms chiqdi;
keyingi bosqich shu ko‘rsatkichni yaxshilaydi. [Batafsil hisobot](PRODUCT_UX_REPORT.md).
Beta protokoli va release UX gate tayyor; haqiqiy tester/OAuth/Play release
sinovlari bajarildi deb yozilmaydi.

## Mahsulot UX dasturi — navigatsiya performance

Profile o‘lchovidan so‘ng tab animatsiyasida static wrapperlar va render alpha
joriy qilindi, bir vaqtda ikkita sahifa shaffof chizilishi olib tashlandi.
Yangi regression bilan navigation **22**, full suite **370 passed**, analyze
**No issues found**. Arm64 profile build tayyor. Qurilma o‘lchovlari va aniq
cheklovlar [TAB_PERFORMANCE.md](TAB_PERFORMANCE.md)da; release/beta signoff
faqat o‘quvchi sinovi va release QA’dan keyin beriladi.

## Yangi Samsung tasvirlari — beshta UX tuzatishi

Readiness/access copy va ikonlar ajratildi; first-home takroriy hero o‘rniga
compact goal, keyingi dars/checkpoint va completed-path guidance saqlangan.
Reusable `LearningInvitationCard` bo‘sh liga/profilga keyingi qadam beradi.
Real progressli profil avvalgidek, yangi hisob statistikasi expand/collapse’da.
Dark neutral qatlamlari va aniq nomlangan secondary logout joriy qilindi.
**55 yangi test, 425 full-suite passed, analyze toza**, 6 yangi golden,
4 ta palette dark golden yangilandi. UI/QA dalillari va chegaralar:
[SCREENSHOT_POLISH_REPORT.md](SCREENSHOT_POLISH_REPORT.md).
