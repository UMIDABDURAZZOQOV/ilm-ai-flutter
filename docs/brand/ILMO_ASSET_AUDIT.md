# Ilmo — asset va Flutter auditi

2026-10-23 · audit bazasi `7d72b2c` · `feat/flutter-ui-ux-improvements`.

## Tekshirilgan manbalar va ish chegarasi

- `ilm-ai/CLAUDE.md`: lokal backend `c0f84d0`; oldingi to‘liq auditdagi hujjat
  o‘zgarmagan. Hozirgi SHA-256:
  `5542ed45fe9d2fbf820f902956cdeb8ccba5fa89b5a2844eb369cae02eff4a62`.
- Flutter UI worktree `7d72b2c`; asosiy Flutter checkout `79608c2`, Biologiya branchi.
  Remote UI `7d72b2c` va Physics preview `cf01011` boshlanishda tekshirildi.
- `pubspec.yaml`: mavjud mascot papkasi, launcher/splash inputlari, animation va
  image kutubxonalari ko‘rildi. Yangi paket yoki versiya o‘zgarishi talab qilinmadi.
- Barcha `MascotImage` chaqiruvlari, shared widgetlar, Flutter splash va ishlatilmayotgan
  legacy `Mascot` painteri topildi. Yashirin AI Explain chaqiruvlari ham inventarga kirdi.

Boshlanishda linux/macos/windows generated plugin registrant fayllari dirty edi.
Ular boshqa ish sifatida saqlandi: ushbu commitga olinmaydi va qaytarilmaydi.
Backenddagi ko‘plab untracked tarixiy fayllarga tegilmaydi. Fan kontenti, auth,
backend API, Android konfiguratsiya yoki Physics/Biology feature kodi tahrirlanmaydi.

## Grafik tekshiruv natijasi

Barcha 8 PNG 1024×1024; jami **5 382 417 bayt**, taxminan **5,13 MiB**.
Aniq hash, alpha chegaralari, shaffof/semi-shaffof ulushlar va buffer hisobi
[`ilmo_asset_audit.json`](ilmo_asset_audit.json)da. Original fayllar o‘chirilmagan,
qayta eksport yoki siqish qilinmagan. PNGlar alohida yangi grafikaga aylantirilmagan.

| Fayl | Bayt | Alpha chegarasi (x0,y0,x1,y1) | Xulosa |
|---|---:|---|---|
| `ilmo_hello.png` | 799 741 | 239,69,785,955 | Asosiy etalon, yumshoq samimiy salom |
| `ilmo_thinking.png` | 762 314 | 252,69,772,955 | Savol belgisi va sariq antenna chirog‘i mavjud |
| `ilmo_explaining.png` | 1 012 908 | 69,89,955,935 | Doska bilan keng kompozitsiya, bo‘yi biroz kichikroq |
| `ilmo_happy.png` | 912 574 | 187,70,837,954 | Konfetti kompozitsiyaning ichida; yashil chiroq |
| `ilmo_sad.png` | 819 821 | 214,70,810,954 | Ko‘z yoshi va qo‘llab-quvvatlovchi qo‘l; to‘q sariq chiroq |
| `app_icon.png` | 433 026 | 0,0,1024,1024 | Ataylab opaque indigo fon; shaffoflik xatosi emas |
| `app_icon_foreground.png` | 334 422 | 174,198,849,863 | Alohida shaffof bosh; to‘liq tananing o‘rnini bosmaydi |
| `splash_logo.png` | 307 611 | 195,199,829,823 | Alohida shaffof bosh, katta ichki bo‘sh joy saqlangan |

Beshta poza chetida ko‘rinadigan piksel yo‘q; qahramon canvas chegarasida kesilmagan.
Ularda to‘liq shaffof piksel ulushi taxminan **63–72%**. Semi-alpha chetlar borligi
normal antialiasing bo‘lishi mumkin; bu o‘zi halo mavjud yoki yo‘q degan hukm emas.

Rasmlar oq va `#13102C` fonlarga kompozit qilinib, 48/72/96/140 px’da yonma-yon
ko‘rildi: [`ilmo_asset_review.png`](ilmo_asset_review.png). Ko‘rilgan kompozitlarda
katta oq to‘rtburchak, qo‘pol kesilish yoki ko‘zga tashlanadigan keng halo topilmadi.
Bu barcha qurilma/fon uchun piksel darajasidagi sertifikat emas. Transparent
RGB kanallaridagi ma’lumotlar avtomatik “tozalanmadi”; original alpha saqlandi.

Do‘ppi, yumaloq bosh, ko‘z, kiyim va romb detali pozalarda taniladi. Turli qo‘l/doska/
konfetti sabab visible boundsni bitta kenglikka majburan tenglashtirish noto‘g‘ri:
qahramonni cho‘zadi yoki muhim detalni kesadi. Mavjud square canvas saqlanadi.

48 px’da milliy naqsh va yuz ifodasi ishonchli o‘qilmaydi. 72 px’da ham mayda
naqsh/doska detali cheklangan; 96–140 px’da asosiy ifodalar yaxshiroq ajraladi.
Doska rasmi o‘quv ma’lumoti sifatida o‘qilishi talab qilinmaydi. Ilmo matn bilan
birga ishlatiladi; rang va yuz ifodasi yagona signal emas.

## Flutter ekranlarining inventari

| Joy | Oldingi qo‘llanish | Audit qarori |
|---|---|---|
| Welcome `onboarding_screen.dart` | hello 140 | `MascotImage.hero` tokeniga o‘tkazildi |
| Duo onboarding | 88 px nutq headeri; hello 140; ready 128; oraliq holatlar | Umumiy responsive `IlmoSpeechHeader`; salom va ready uchun bitta kirish animatsiyasi |
| Fan tanlash `subject_home_screen.dart` | hello 120 | Tekshirildi; fan feature kodi saqlandi |
| Curriculum tanlash/loading | 110/120/130 | Tekshirildi; kurs/sinf logikasiga tegilmadi |
| Skill Path | hello 112 | Yangi `lesson` tokeniga mos; fayl saqlandi |
| Biologiya darsi | explaining 110, thinking 104, feedback 100, result 180 | Tekshirildi; yangi umumiy dekodlash ishlaydi, feature kodi saqlandi |
| Mashq/checkpoint | thinking 110/104, feedback 88, result 170 | Tekshirildi; feature kodi saqlandi |
| Physics preview | hello 96, explaining 88, feedback/result, yakun 100 | Tekshirildi; pose/grading/layout fayllari o‘zgarmadi |
| Yashirin AI Explain sheet | thinking 72, explaining 56 | Kod inventarga olindi; qayta yoqilmadi |
| Flutter splash | bosh logo 160 | O‘lcham/rang tokeni va fizik piksel dekodlash; auth qarorlari saqlandi |
| Native launcher/splash | mavjud 1024 inputlar va indigo fon | Generator, package, callback yoki resurslar o‘zgartirilmagan |
| Eski `Mascot` painteri | Deklaratsiya mavjud, faol chaqiruv topilmadi | O‘chirilmadi va Ilmo o‘rniga qayta yoqilmadi |

## Auditdan kelib chiqqan reja va bajarilgan xavfsiz ish

1. Rasmni qayta ishlamasdan kanonik o‘lcham, spacing va motion tokenlarini yozish.
2. Shared `MascotImage`ni mavjud API bilan mos saqlab, tor ota konteynerda kvadrat
   sig‘ishini, physical pixel decode va opt-in semantic labelni ta’minlash.
3. Rasm topilmasa tasdiqlanmagan robot o‘rniga oddiy ILM AI yozuvini ko‘rsatish.
4. Onboardingda ortiqcha ikki karra sakrashni olib tashlash; “tayyor” holatida
   takrorlanadigan breathing animatsiyasini bitta kirishga almashtirish.
5. Ilmo–nutq headerini tor ekran/kattalashtirilgan matnda vertikal joylashtirish;
   yetarli joyda 88 dp Ilmo + 16 dp gap + nutq bloki.
6. Original hashlar, barcha pozalar, DPR decode, tor konteyner, Reduce Motion,
   semantic label, fallback, uch tildagi 200% matn va mavjud regressiyalarni tekshirish.

Bu tartib hujjat/asset auditidan keyin amalga oshirildi. O‘lchamga mos dekodlash
bandwidth yoki APK hajmini kamaytirmaydi: original fayllar o‘sha-o‘sha. U kichik
UI rasmiga kerakli piksel bufferini tanlaydi; haqiqiy runtime xotira/FPS benchmarki yo‘q.

## Yangi original grafika talab qiladigan alohida ishlar

- Ko‘z yoshisiz, neytral qo‘llab-quvvatlash holati.
- 48–72 px uchun barcha kerakli ifodalarning tasdiqlangan bosh/compact eksportlari.
- Old/yon/orqa ko‘rinish va yagona yoritish/nisbatlar bilan rasmiy model sheet.
- Zarur bo‘lsa original 3D rig va harakat namunalari; hozirgi PNG transformlarini
  skelet animatsiyasi deb atamaslik.
- Launcher maskalari, native splash ketma-ketligi va past quvvatli Androidda
  designer + qurilma review. Masterlar kelmaguncha avtomatik crop/redraw yo‘q.

## Qayta bajarish

Python + Pillow kerak. Script PNGni faqat o‘qiydi; `assets/` ichiga hisobot yozishni
rad etadi. Texnik audit sonlari vizual review o‘rnini bosmaydi.

```powershell
python scripts/audit_ilmo_assets.py --report docs/brand/ilmo_asset_audit.json --preview docs/brand/ilmo_asset_review.png
flutter analyze --no-pub
flutter test --no-pub
```

Flutter orqali actual shared widget galereyasini olish uchun qo‘shimcha:

```powershell
flutter test --no-pub --dart-define=ILMO_QA_CAPTURE=true test/ilmo_brand_test.dart
```

QA tasviri `.dart_tool/ilmo-audit/flutter-gallery.png`ga yoziladi; product asseti emas.
Test natijalari va Git handoff yakuniy ish hisobotida qayd etiladi. Haqiqiy telefon,
TalkBack yoki native mask testi bajarilmasa PASS deb belgilanmaydi.

## Yakuniy tekshiruv — 2026-10-23

- Ilmo uchun **18 yangi test**: barcha original hashlar/PNG headerlari,
  physical-pixel decode, square contain, cheklangan joy, Reduce Motion, semantic
  label/fallback, uz/ru/en 200% matn, portrait/landscape va Flutter galereyasi.
- To‘liq Flutter: **169 passed**, 63 soniya; `ILMO_QA_CAPTURE=true` bilan.
  Mavjud Biology, Physics/FRQ, auth, onboarding va darsni tiklash testlari ham o‘tdi.
- `flutter analyze --no-pub`: **No issues found**, 69,2 soniya.
- Dastlabki umumiy regression welcome ekranidagi `IntrinsicHeight` bilan
  `LayoutBuilder` mos emasligini ko‘rsatdi. Explicit preferred-size wrapper bilan
  tuzatildi; mavjud 320×568/640×360 welcome testlari yakuniy suite’da o‘tdi.
  Original asset testi endi `ResizeImage.imageProvider` ichidagi aynan o‘sha
  AssetImage pathini tekshiradi; asset tekshiruvi olib tashlanmagan.
- Native icon, splash va 5 poza oq/to‘q fonda Pillow audit kompozitida ko‘rildi;
  actual Flutter shared-widget galereyasi ham render qilinib ko‘rildi. Test galereyasi
  renderer dalili; telefonning native launcher/splash ketma-ketligi testi emas.
- `git diff --check` toza. `assets/`, pubspec/lock, Biology/Physics/auth/router va
  Android fayllarida diff yo‘q. Original 8 PNG SHA’lari testda tasdiqlandi.
- Flutter vositalari mavjud SDK `dart.exe .../flutter_tools.snapshot` orqali
  ishlatildi. Oldingi tugallanmagan yoki failing runlar muvaffaqiyat deb sanalmadi.

Real Android, TalkBack, native launcher maskalari va physical memory/FPS hali
tekshirilmagan. Yangi grafika kutadigan tavsiyalar alohida qoladi. Backend va
production amallari, main merge yoki deploy bajarilmadi. Boshlanishdan mavjud
generated platform o‘zgarishlari ushbu commitga qo‘shilmaydi.
