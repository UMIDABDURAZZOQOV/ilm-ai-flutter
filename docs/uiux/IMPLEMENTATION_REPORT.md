# ILM AI UI/UX — bosqichlar hisoboti

Audit: [UI_UX_AUDIT.md](../../UI_UX_AUDIT.md).
Dizayn qoidalari: [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md).
Asos: `aec64b8`, branch `feat/flutter-ui-ux-improvements`.

## Dalillarni talqin qilish

26 ta reference — foydalanuvchining haqiqiy Samsung A12 rasmlari. Ular maxfiylik
qaydiga muvofiq Git tarkibiga kiritilmaydi. `.dart_tool/uiux-package/`dan o‘qiladi.
`before/` va `phaseN/` widget capturelari bir xil 360×800dp, 2 DPR, RU UI,
light/dark va izolyatsiyalangan fixturelar bilan yaratiladi. Ular jonli backend
natijasi yoki haqiqiy telefon skrinshoti emas. 12 holat: home, practice, grades,
profile, quests, league, settings, login, onboarding, theory, quiz, feedback.

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
