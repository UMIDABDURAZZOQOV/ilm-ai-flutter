# III qism — lokal QA, 2026-11-04

Joriy yangilanish: III qism10/37matnli mavzu, jami83lokal dars/624topshiriq.
6–10PDF16–25/bosma14–23: butun/qism, barcha mezonlar, ketma-ket strelka,
teskari jadval va nol. 5yangi oqim320px/200%/ReduceMotion;21targetedtest.
To‘liq Flutter512test(2:47), analyze0(3.8s), debugJSwebbuild34.4s o‘tdi.
Oldingi5dars statusi quyida tarix sifatida qoldirilgan. Keyingi manba11,
path11,PDF26–27; manba14keyin path12bo‘ladi. Normalapp/Gradle/auth o‘zgarmagan.


Hozir III qismda 5 lokal dars bor: PDF6–15/bosma4–13, Repyova2024.
37 ta matnli mavzu chegarasi xaritalangan; qolgan32 hali interaktiv emas.
Mundarijadagi nazorat/o‘yin qatorlari tayyor dars hisoblanmaydi.
I qism41/41 va II qism32/33 o‘zgarmagan; II74 bosma68–69 manbasi yo‘q.

Serverning default strict prerequisite qoidasi o‘zgarmagan. Faqat alohida
staging/test QA uchun `MATHEMATICS_QA_SOURCE_GAP_BRIDGE=true` mavjud:
I qism41 va II qism32 darsning barchasi bajarilganda III qismni sinaydi.
Client define yoki request bu ruxsatni bera olmaydi. UI ko‘prik xabarini
ko‘rsatadi, `previous_book_complete=false` qoladi. Yetishmagan74ga progress/XP
yaratilmaydi. Flag o‘chsa unfinished urinish403 bilan to‘xtaydi, draft o‘chmaydi.

Backendning xavfsiz standalone komandasi (faqat o‘zingizning yangi lokal,
barcha Git repositorylardan tashqaridagi katalog):

```powershell
python -m scripts.serve_mathematics_preview --directory C:\ILM-local\mathematics_staging --allow-known-part2-source-gap
```

Qayta ochishda aynan shu katalog va `--resume` ishlatiladi; test flagni yana
berish kerak. Yaratilgan private `flutter-defines.json` qisqa muddatli test
JWT saqlaydi. Uni Gitga yoki build logiga kiritmang. Flutter local/debug:

```powershell
flutter run -d chrome -t lib/mathematics_preview_main.dart --dart-define-from-file=C:\ILM-local\mathematics_staging\flutter-defines.json
```

Cloud muhitida barcha `/workspace` va `/tmp` Git guardlari sabab standalone
positive-run bajarilmagan. Guardni chetlab o‘tish ko‘rsatilmaydi. API TestClient
va alohida loopback PostgreSQL sinovlari bajarilgan. Buyruqlar Windowsda hali
amalda tekshirilmagan. Android/ADB yo‘q; real telefon sinovi bajarilmagan.

Yangi5darsning barcha oqimlari320px/200%matn/ReduceMotionda tekshirildi.
To‘liq Flutter501test/analyze0 va debugJSwebbuild35.1s o‘tdi; dependency Wasm
dry-run ogohlantirishlari bor, Wasm muvaffaqiyati da’vo qilinmaydi. Oddiy app,
Google login, fan katalogi, brend, Gradle va boshqa fanlar o‘zgarmagan.
