# Android QA integration handoff — 2026-10-27

Bu patch avtomatik qo‘llanmagan. Shared Gradle fayli va parallel fanlar branchlari o‘zgarmadi. Hozirgi Gradle faqat Physics QA uchun alohida package beradi: History target bilan oddiy `com.ilmai.app` ID chiqishi mumkin. History APK’ni shu holatda o‘rnatmang.

`ANDROID_QA_IDENTITY.patch` ayni tekshirilgan Gradle fayliga `git apply --check`dan o‘tdi. Bu Kotlin/Gradle compile yoki Android qurilma testi o‘tdi degani emas; Android SDK/adb yo‘q. Integration egasi boshqa agentlarning o‘zgarishlari bilan solishtirgach, izolyatsiyalangan branchda qo‘llasin.

Patch History debug target+flag uchun `.uzhistoryqa` package suffix, alohida nom va `ilmai-uzhistory-qa` callback scheme beradi. Oddiy ilova va Physics konfiguratsiyasi saqlanadi. Ikkita fan preview flagi birgalikda rad etiladi; barcha preview release buildlari rad etiladi. Bu Google login qo‘shmaydi: History faqat alohida lokal test identity bilan ishlaydi.

PowerShell’da integration reviewdan keyin:

```powershell
git apply --check docs/uzbekistan-history/ANDROID_QA_IDENTITY.patch
git apply docs/uzbekistan-history/ANDROID_QA_IDENTITY.patch
flutter doctor -v
flutter analyze
flutter test
flutter build apk --debug -t lib/uzbekistan_history_preview_main.dart --dart-define-from-file=C:\ILM-QA-PRIVATE\history-qa\flutter-defines.json
```

Defines fayli Gitdan tashqaridagi yangi lokal sandboxdan olinadi; unda bir soatlik faqat test JWT bor. Uni Git, issue, chat yoki umumiy logga qo‘shmang. Sandboxni backenddagi `scripts.serve_uzbekistan_history_preview` bilan ishga tushiring; `--resume` progressni saqlaydi. Backend localhost8891 bo‘lsa, USB/adb orqali `adb reverse tcp:8891 tcp:8891`dan foydalanish mumkin. Bu buyruq bu muhitda bajarilmagan.

APK’ni o‘rnatishdan oldin `apkanalyzer manifest application-id build\app\outputs\flutter-apk\app-debug.apk` natijasi aynan `com.ilmai.app.uzhistoryqa` ekanini tekshiring. Paket ID oddiy ilova bilan teng bo‘lsa o‘rnatmang. Signing, target va callbackni real SDK’da tekshirish qolgan.

Real QA: 7-sinf barcha42 dars; avvalgi prerequisite; xato/to‘g‘ri javob; ism/atama/asr yozuvi; xronologiya; javobni ikki marta yuborish; internet uzilishida retry; ilovani yopib qoralama va progressni tiklash; qayta yakunda XP takrorlanmasligi; oltita bob tugallanish belgisi;8-sinf halol manba-kutilmoqda holati;9–11 hali dars yo‘q holati. Kichik ekran,200% matn,TalkBack,fokus,Reduce Motion va Android lifecycle alohida tekshiriladi. Bob belgisi alohida checkpoint quiz emas.

Bu yakuniy mahsulot release’i, barcha sinflar tayyorligi yoki haqiqiy telefondagi muvaffaqiyat haqida da’vo emas.
