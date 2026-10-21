# Fizika §1–7 — alohida lokal/Android QA

2026-10-22. Backend: `feat/physics-curriculum-map`; Flutter:
`feat/physics-first-batch`. Bu **test rejimi**. Oddiy ilovaning Biologiya katalogi,
Google login, production API, package va OAuth sxemasi o‘zgarishsiz qoladi.

## Lokal backend va brauzer

Backendda requirements o‘rnatilgach, Gitdan **tashqaridagi yangi** directory:

```bash
python -m scripts.serve_physics_preview --directory /tmp/ilm-physics-qa
```

Bu yangi SQLite DBda 7 dars va aniq belgilangan bitta sandbox QA akkauntini
ishga tushiradi; eski bazaga/productionga tegmaydi. API: `127.0.0.1:8887`.
Private `flutter-defines.json` faqat shu sandboxning 60 daqiqalik JWT’sini saqlaydi.
Faylni Git/public joyga qo‘ymang, production token bilan almashtirmang.

Flutterda boshqa terminal:

```bash
flutter pub get
flutter run -d chrome --web-port 7357 -t lib/physics_preview_main.dart \
  --dart-define-from-file=/tmp/ilm-physics-qa/flutter-defines.json
```

Sandboxni keyingi safar **`--resume`** bilan ishga tushiring; eski test progressi
saqlanadi, yangi test JWT beriladi. Token eskirganda Flutter’ni yangi defines bilan
qayta ishga tushirish/build kerak. Oddiy Google loginni testdan o‘tdi deb hisoblamang:
bu alohida authenticated QA entrypoint.

## Windows + USB telefon

Android Studio/SDK va `adb` PATH’da bo‘lsin. Backend checkoutda PowerShell:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
$qa = Join-Path $env:LOCALAPPDATA 'IlmPhysicsQA'
$env:ENVIRONMENT = 'test'
python -m scripts.serve_physics_preview --directory "$qa"
# Keyingi safar, yangi terminalda kerakli env va $qa ni qayta o‘rnatib:
# python -m scripts.serve_physics_preview --directory "$qa" --resume
```

Flutter checkoutdagi ikkinchi PowerShell:

```powershell
$qa = Join-Path $env:LOCALAPPDATA 'IlmPhysicsQA'
flutter doctor -v
flutter pub get
adb devices
adb reverse tcp:8887 tcp:8887
flutter run -d YOUR_DEVICE_ID -t lib/physics_preview_main.dart --dart-define-from-file="$qa\flutter-defines.json"
```

Yoki o‘rnatiladigan **debug** APK:

```powershell
flutter build apk --debug -t lib/physics_preview_main.dart --dart-define-from-file="$qa\flutter-defines.json"
adb install -r build\app\outputs\flutter-apk\app-debug.apk
```

`PHYSICS_PREVIEW=true` va `physics_preview_main.dart` targeti bilan Gradle debug uchun avtomatik:
**`com.ilmai.app.physicsqa`**, nomi **ILM AI Fizika QA**, callback sxemasi
`ilmai-physics-qa` olinadi. Asosiy `com.ilmai.app` / `ILM AI` / `ilmai` production
identifikatsiyasi saqlanadi. QA APK asosiy ilovani almashtirmaydi va uning Google
callbackini egallamaydi. Preview release task rad etiladi. Android SDK bu cloud’da
**yo‘q**: native Gradle/build/manifest merge va aynan shu suffix’ni haqiqiy APKdan
tekshirish hali bajarilmadi; Windows builddan so‘ng buni tasdiqlang:

```powershell
adb shell pm list packages | findstr ilmai
# Yangi package com.ilmai.app.physicsqa bo‘lishi kerak.
```

USB `adb reverse` bilan API_URL `http://127.0.0.1:8887`ligicha qoladi; serverni
LAN/productionga ochish kerak emas. Debug manifest lokal HTTP’ga ruxsat beradi;
release HTTPS qoidalari yumshatilmagan. Emulatorda reverse ishlatmasangiz,
private defines’dagi API_URLni `http://10.0.2.2:8887`ga o‘zgartiring.

## Telefon tekshiruv ro‘yxati — hali bajarilmagan

- ILM AI Fizika QA va asosiy ILM AI yonma-yon o‘rnatilsin; asosiy app/account
  sozlamalari va Google callback o‘zgarmasin.
- §1 ochiq, §2–7 qulflangan; 60% dan keyin navbatdagi tugun ochilsin.
- Har mavzuda kartalar, misollar va to‘g‘ri PDF/bosma manba sahifalari ko‘rinsin.
  §1–5 da hisoblash/formula maydoni bo‘lmasin.
- §5 va §7 tartiblash: bosish tartibi ko‘rinsin, «Tartibni tozalash» ishlasin.
- §6 FRQ: `y=x*100`, `170`, `cm`; ekvivalent `100*x`, `1.7`, `m` ham qabul qilinsin.
  `170 kg` o‘lcham feedbackini bersin. §7 shkala, o‘rtacha va yarim-bo‘linma mashqlarini bajaring.
- Xato javobga oldindan yozilgan tushuntirish/yechim chiqsin; AI so‘rovi bo‘lmasin.
- Birinchi muvaffaqiyatli darsga 10 XP; double-tap, timeout/retry, ilovani yopish va
  yangi takroriy urinish XP’ni oshirib yubormasin. Streak bir kunda takror sanalmasin.
- Kiritilgan draft, pending javob va server progressi qayta ochilganda tiklansin.
  Javob saqlanib, HTTP javobi yo‘qolgan holatda keyingi savol noto‘g‘ri feedback olmasin.
- Airplane mode/USB uzilishi: aniq xabar, retry; chiqish tugmasi ishlasin.
  Server davom etsa ham yopilgan widget callback xatosi bermasin.
- Kichik ekran, landscape, Android 200% font, ekrandagi klaviatura va back gesture:
  formula/son/birlik va uzun feedback scroll orqali to‘liq ochilsin.
- TalkBack: maydon labeli, tugun holati, fokus tartibi, feedback live regioni;
  Reduce Motion va past quvvatli qurilmadagi animatsiyalarni tekshiring.
- Asosiy Biology ilovasidagi 406 faoliyat, XP/progress va 47 checkpoint uchun
  mavjud `ANDROID_BIOLOGY_QA.md` ro‘yxati ham saqlanadi.

## Cloud’da haqiqatan tekshirilgan holat

Backend SQLite + PostgreSQL, replay/concurrency/XP va source validatorlar;
Flutter widget/overflow/semantics, standart release JS web build va alohida debug
preview build tekshirilgan. Detallar va aniq sonlar backendning markaziy
`docs/physics/STAGE2_GRADE6_BATCH1.md` / `CLAUDE.md` hujjatida.
Native APK/iOS, Google Console va haqiqiy telefon natijasini bu bilan almashtirmang.
Keyingi §8–17 kontent partiyasi hisobotdan keyingi foydalanuvchi tasdig‘ini kutadi.
