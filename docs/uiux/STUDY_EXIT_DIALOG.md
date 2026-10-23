# Darsdan chiqish oynasi

2026-10-23. Foydalanuvchi yuborgan Samsung A12 tasviridagi dialog bo‘yicha
alohida UI yaxshilashi. `feat/flutter-ui-ux-improvements` branchi.

## Dizayn

- Katta markaziy graduation-cap o‘rnida sarlavha yonida 40dp tonal belgi.
  Saqlangan urinish, saqlash xatosi va saqlanmaydigan mashq alohida ko‘rsatiladi.
- Chapga tekislangan sarlavha va qisqartirilgan UZ/RU/EN matnlar. Lokal saqlash,
  darsning amal qilish muddati va oldingi yutuqlarning saqlanishi aniq aytiladi.
- Bir xil kenglikdagi ikkita amal: indigo «Davom etish» va chegarali
  «Saqlab chiqish». Saqlash muvaffaqiyatsiz bo‘lsa yoki mashq saqlanmasa,
  ikkinchi tugma oddiy «Chiqish» bo‘ladi.
- Maksimal kenglik 400dp, tashqi yon bo‘shliq 20dp, ichki bo‘shliq 24dp,
  radius 28dp. Primary target kamida 52dp, secondary kamida 48dp.
- Light/dark ranglari mavjud `AppColors`/`IlmDesign` tizimidan olinadi.
  Cheklangan balandlik va katta shriftda kontent scroll qilinadi; shrift
  o‘lchami majburan pasaytirilmaydi.
- Dialogning qisqa 180ms kirish / 140ms chiqish o‘tishi bor. Reduce Motion
  yoqilganda dialog animatsiyasiz ochiladi.

## Xulq va chegaralar

`StudyExitDialog` faqat tasdiqlash UI komponentidir. Mavjud `StudyExitGuard`
yakuniy lokal saqlashni kutadi, takroriy back’ni to‘sadi va keyin haqiqiy natijani
dialogga beradi. Continue, Android back va barrier orqali yopish darsni saqlab
turadi; chiqish tasdig‘i avvalgi route’ga qaytaradi. Yangi API yoki dependency yo‘q.

Draft formati, urinish muddati, baholash, savol javoblari, XP, autentifikatsiya,
backend, 406 ta Biologiya darsi va Fizika/FRQ kontentida o‘zgarish yo‘q.
Ilmo, launcher, splash va onboarding assetlari o‘zgarmagan.

## Tekshiruvlar

Yangi suite: `test/study_exit_dialog_test.dart` — **29 test**:

- UZ/RU/EN × light/dark × saved/failed/unsaved, 320dp va 200% shrift;
- 568×320 landscape va 200% shriftda ikkala amalga yetib borish;
- save tugashini kutish va takroriy back’da faqat bitta saqlash;
- save exception’da yolg‘on muvaffaqiyat matnini ko‘rsatmaslik;
- Android back’da darsning qolishi, tasdiqlanganda chiqish, Reduce Motion;
- real Roboto/Material Icons bilan light/dark golden tasvirlar.

Mavjud design-system va subject testlari bilan dastlabki targeted tekshiruv
**74 passed**. Ikon fonti yuklangach yangi suite qayta tekshirildi: **29 passed**.

- Final to‘liq suite: **288 passed**, **57s**.
- `flutter analyze --no-pub`: **No issues found**, **76.6s**.
- `git diff --check`: xato yo‘q.

### Samsung A12

- Android debug build: return code **0**, frozen APK tayyorlash bilan **43.8s**.
  Faqat lokal QA API flagi ishlatildi; production sozlamasi o‘zgarmadi.
- Mavjud debug sertifikati tekshirildi. `adb install -r` muvaffaqiyatli;
  UID, original install time va lokal draft mazmuni o‘zgarmagan.
- APK SHA256: `4edba12a09763920925c6496053052903be6217255adb22c34a70008cb700534`.
  O‘rnatilgach telefondagi APK hashiga tengligi tekshirildi.
- Mavjud **5/12** savoldagi urinish ochildi. Close orqali yangi dialog,
  «Продолжить» orqali ayni savolga qaytish, Android back va
  «Сохранить и выйти» orqali home’ga qaytish tekshirildi. Savollarga javob
  yuborilmadi, yangi dars boshlanmadi va yakunlash so‘rovi berilmadi.
- Draftning elapsed time’dan boshqa barcha maydonlari oldingi holati bilan
  hash orqali solishtirildi: mazmuni bir xil. Darsdagi vaqt tabiiy ravishda
  o‘tadi; natija va progressni sun’iy yangilash yo‘q.
- Real telefon light mode’da tekshirildi; dark mode izolyatsiyalangan haqiqiy
  widget capture va golden orqali tekshirildi. Bu TalkBack foydalanuvchi
  sinovi yoki animatsiya FPS o‘lchovi deb taqdim etilmaydi.

Telefon bir capture vaqtida boshqa ilovaga almashgan. O‘sha tasvir dialog
dalili sifatida ishlatilmadi; keyingi amallarda exact UI target va joriy ILM AI
window focus qayta tekshirildi. Tasdiqlangan tasvirlar private
`.dart_tool/exit-dialog-review/device/exit-dialog.png`, `after-continue.png`,
`after-leave.png` fayllarida.

Fon rejimidagi faol `flutter run` QA davomida paketni boshqa APK hashiga
almashtirgani ham kuzatildi. O‘sha jarayon majburan to‘xtatilmadi. Frozen APK
qayta `install -r` qilindi va yakuniy telefondagi hash yuqoridagi **4edba12…**
hashiga tengligi qayta tasdiqlandi (`device/final-apk-check.json`).
Yakuniy tekshiruvda UID/original install time/draft mazmuni bir xil;
app PID logida fatal, unhandled exception va RenderFlex overflow belgilari **0**.
Main merge, production deploy va Play nashri bajarilmadi.

### Tasvirlar

`test/goldens/study_exit_light.png` va `study_exit_dark.png` sintetik test
tasvirlaridir. Haqiqiy lesson widgetlari va izolyatsiyalangan fixture’lar bilan
light/dark capture ham qayta bajarildi: **2 passed**.

Private taqqoslashlar `.dart_tool/exit-dialog-review/light-before-after.png`
va `dark-before-after.png`da. Oldingi UI — phase4 capture; yangi UI —
`UIUX_STAGE=exit-dialog`. Haqiqiy telefon tasvirlari va foydalanuvchi yuborgan
surat Git’ga qo‘shilmaydi.

### Qayta bajarish

```powershell
flutter test --no-pub test/study_exit_dialog_test.dart
flutter test --no-pub
flutter analyze --no-pub
flutter test --no-pub test/uiux_visual_review_test.dart --dart-define=UIUX_CAPTURE=true --dart-define=UIUX_STAGE=exit-dialog
```
