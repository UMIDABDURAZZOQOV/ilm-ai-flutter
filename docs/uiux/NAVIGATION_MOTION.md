# ILM AI — navigatsiya harakati

2026-10-23. Foydalanuvchining pastki ikonlar va tab o‘tishlarini yanada
professional qilish haqidagi alohida so‘rovi asosida.

## Ko‘rinish va xatti-harakat

- `IlmNavigationIcon`: bitta 32 birlikli vector grid, yumaloq 2 birlik stroke.
  Kitob, qalam, checklist, qalqon/yulduz va profil. PNG, tashqi animatsiya fayli
  yoki yangi dependency talab qilmaydi. Original Ilmo/launcher assetlari qolgan.
- Faol tabning ixcham indigo belgisi **280ms** ichida yangi joyga siljiydi;
  turkuaz romb ILM AI brendini eslatadi. Label almashishi **180ms**.
- Ikon bir marta **360ms** harakat qiladi: yengil ko‘tarilish/scale va ikonning
  o‘ziga mos sahifa, qalam, check, yulduz yoki bosh harakati. Loop yo‘q.
  Deaktivatsiya **180ms**. Bosish scale’i **0.94**, **100ms**; selection haptic
  faqat boshqa tab tanlanganda ishlaydi. Bir xil tab qayta so‘rov yubormaydi.
- Butun tugmani yopuvchi katta ripple qo‘shilmagan; doimiy selection belgisi
  va ikonning press effekti ishlaydi. Focus/hover va screen reader targeti qolgan.
- `IlmTabView`: **260ms** yo‘nalishli fade-through; kiruvchi kontent 12dp,
  chiquvchi kontent 8dp siljiydi. RTL yo‘nalishi hisobga olinadi. Bu route push
  emas: beshta tabning mavjud elementlari, scroll va holati saqlanadi.
- Eski sahifa input, focus va semanticsdan chiqariladi. Kiruvchi sahifa yetarli
  ko‘ringuncha pointer inputni olmaydi; pastki navigatsiya doim ishlaydi.
  Tez almashish animatsiyani yangi manzilga yo‘naltiradi.

`DuoBottomNav`/`DuoNavItem` tashqi API nomlari kompatibil adapter sifatida qolgan.
Mavjud lazy tab mounting, route nomlari, provider cache va API kontrakti saqlangan.
Callback animatsiya tugashini kutmaydi. App/page state AnimatedSwitcher bilan
qayta yaratilmaydi. `TickerMode` yashirin ekran animatsiyalarini to‘xtatadi.

## Accessibility

Reduce Motion yoqilsa ikon/selection/sahifa darhol yakuniy holatga o‘tadi.
Qo‘shimcha ripple yo‘q. Safe area, kamida 48dp target, to‘liq localized semantics
va selected holati bor. 320dp, 200% shrift, UZ/RU/EN va RTL tekshirilgan.
Ikondagi check/yulduz dekorativ destination belgisi; foydalanuvchining haqiqiy
yutug‘i, online statusi yoki bajarilgan vazifalar soni sifatida ko‘rsatilmaydi.

## Tekshiruvlar

- Mavjud targeted suite: **40 passed**.
- Yangi navigatsiya suite: **21 passed**, shu jumladan cache/API so‘rovlari,
  scroll/state, rapid switching, haqiqiy semantics actions va Reduce Motion.
- Final to‘liq suite: **259 passed**, **78s**.
- Final `flutter analyze --no-pub`: **No issues found**, **66.5s**.
- Light/dark vector goldenlar: `test/goldens/ilm_navigation_*.png`.
- Motion capture: ikki theme’da 101 tadan kadr; yakuniy golden/capture **2 passed**.
  Preview `.dart_tool/navigation-review/navigation-motion-preview.gif`da; bu
  izolyatsiyalangan widget preview, telefon videosi deb taqdim etilmaydi.
- Final debug build: return code **0**, **79.7s**, lokal API flagi bilan.
  Source production URL, backend, fan kontenti va native launcher o‘zgarmagan.

Qayta tekshirish:

```powershell
flutter test --no-pub test/navigation_motion_test.dart
flutter test --no-pub
flutter analyze --no-pub
flutter test --no-pub test/navigation_motion_test.dart --plain-name "navigation vector golden" --dart-define=NAV_CAPTURE=true
```

## Samsung A12

Paket `com.ilmai.app`, Android UID **10298**, firstInstallTime
**2026-10-21 17:56:08** saqlangan. `adb install -r` muvaffaqiyatli. Frozen APK va
telefondagi paket SHA256 tengligi qayta tasdiqlangan:
`35d4fd743d01680d43e90f974d032903e6c0aeff2389d623e6157d978ece3f6c`.
Sertifikat avvalgi debug sertifikat bilan bir xil.

ADB ulanishi uzilib qayta ulangani sabab birinchi bounded bo‘lmagan UI dump
yakunlanmagan. Keyingi amallar timeout bilan va login shell profilini
ishga tushirmasdan bajarildi. Boshqa Flutter jarayonlari to‘xtatilmadi.
Real telefon videosi, timeline va error loglar `.dart_tool/navigation-review/device/`
ichida private; Git’ga hisob ismi yoki telefon tasviri qo‘shilmaydi.

Telefon QA yakuni: beshta tab, keyin tez Practice → Quests → Learn almashtirish
yozib olindi. Yakunda Learn ochiq, avvalgi ruscha UI va light theme saqlangan.
Video dekodlanib oraliq kadrlar ko‘rildi: yangi vector ikonlar va siljiydigan
selection tasdiqlandi. Joriy app logida fatal/unhandled/overflow belgisi **0**.
Tizim transition/window animation scale **1.0**, animator scale default (`null`);
bu sozlamalar o‘zgartirilmadi. Screenrecord variable-frame-rate yozuvining o‘rtacha
FPS ko‘rsatkichini ilova rendering FPS’i bilan tenglashtirmang.

Profiling orqali FPS/battery o‘lchanmagan; 60fps kafolati yozilmaydi.
Haqiqiy TalkBack foydalanuvchi sinovi va iOS qurilma sinovi alohida QA bo‘lib qoladi.
