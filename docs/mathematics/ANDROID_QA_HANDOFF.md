# Matematika Android QA — integratsiya handoff

## 2026-11-04 — Matematika katalogi va telefon sinovi holati

Feature branch `feat/mathematics-curriculum`: I qism41 va II qism32,
jami73 lokal dars,422 karta/544topshiriq. II qism32/33:74ning
bosma68–69sahifalari yo‘q; app katalogi bu kamchilikni ko‘rsatadi.
Kitob tanlash va IIqism oldidan Iqism41mavzusi prerequisite ishlaydi.

Yakuniy avtomatik tekshiruv: Flutter491passed, analyze0issue;
MathpreviewJSdebugweb33.7s.32yangi oqim320px/200%matn/ReduceMotion bilan
widgettestda o‘tdi. Haqiqiy brauzer/API va Android sinovi deyilmaydi.
AndroidSDK/adb yo‘q; APK yig‘ilmadi, fizik telefon/TalkBack/signing tekshirilmadi.
Umumiy Gradle yoki productionappidentity o‘zgarmadi; quyidagi alohida
`.mathqa` identity patch hali qo‘llanmagan. Telefoniga mavjud app/progressni
bosib o‘rnatish mumkin deb hisoblamang; alohidaQAidentity avval tayyorlansin.

Real telefon ro‘yxatiga qo‘shilsin: I/IIkitob tanlash, yopiqIIqism sababi,
I tugagach42dan boshlash,20dagi ikki o‘nlik/0birlik,100jadvali horizontal
scroll, cho‘tning xonalari, ikki xonali amallar, qavsdagi feedback, timeoutdan
so‘ng ayniUUIDretry, accountalmashish, oldprogress/replay0XP, katta matnda
32/33manba qaydi. Markaziy qarorlar va keyingiIIIqism manba handoffi
backenddagi `docs/mathematics/PART3_SOURCE_HANDOFF.md`da. IIIqism hali0dars.


2026-10-27. Patch shared Gradle fayliga **qo‘llanmagan**. History/Kimyo/Jahon tarixi agentlarining parallel Android o‘zgarishlari bilan integratsiya review talab qilinadi. Patch alohida Physics bazasiga mo‘ljallangan; boshqa fan patchi bilan birini ustiga ko‘r-ko‘rona qo‘llamang.

Math debug target va MATHEMATICS_PREVIEW=true uchun `.mathqa` applicationId suffix, alohida label/callback hamda preview release radini taklif qiladi. Bu Kotlin compile, signing, real Google login yoki Android test dalili emas. Normal app va OAuth o‘zgartirilmadi.

SDK/adb mavjudligi doctor hisobotida alohida ko‘rsatiladi. Review va SDK build bo‘lmaguncha hozirgi target bilan APKni oddiy ILM AI ustiga o‘rnatmang: shared Gradle faqat Physics uchun alohida paketni ta’minlaydi.

Reviewdan keyin Windows PowerShell:

```powershell
git apply --check docs/mathematics/ANDROID_QA_IDENTITY.patch
# Integratsiya egasi patchni boshqa fanlar o‘zgarishlari bilan birlashtiradi.
flutter doctor -v
flutter analyze
flutter test
flutter build apk --debug -t lib/mathematics_preview_main.dart --dart-define-from-file=C:\ILM-QA-PRIVATE\math\flutter-defines.json
apkanalyzer manifest application-id build\app\outputs\flutter-apk\app-debug.apk
# Application ID com.ilmai.app.mathqa bo‘lmasa, o‘rnatmang.
```

Backend CLI `python -m scripts.serve_mathematics_preview --directory C:\ILM-QA-PRIVATE\math` yangi, Gitdan tashqaridagi xususiy papkada ishlaydi. `--resume` oldingi progressni saqlaydi, faqat test JWTni yangilaydi. Defines fayli maxfiy va Gitga qo‘shilmaydi. USB orqali 8892-portni adb reverse qilish yoki tasdiqlangan private LAN IP ishlatish mumkin; bu amallar ushbu muhitda bajarilmagan.

Real QA: faqat birinchi5dars, xato javob va pog‘onali ishora, sanashda har shaklga bir marta tegish, ekran/tasma masshtabi, 320px/200%matn, klaviatura/landscape, TalkBack/fokus/kontrast, ReduceMotion, offline retry/pendingUUID, qayta ochish, akkauntlar orasida qoralama ajralishi, ikki parallel completionda10XPbir marta,24soat urinishdan keyin yangi urinish. Matematika hali 1–11 to‘liq kurs emas. O‘qituvchi va real bola pilot sinovi yo‘q.
