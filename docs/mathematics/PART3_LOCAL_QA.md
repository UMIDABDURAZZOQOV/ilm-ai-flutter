# III qism — lokal QA, 2026-11-04

## Joriy checkpoint: III qism20/37, jami93 lokal dars

Source18–22 (path16–20), PDF36–45/bosma34–43 qo‘shildi.5 yangi darsning
40 topshirig‘i va barcha sahifalar bilan bog‘langan original karta/misollar bor.
Modellar: ikki miqdor farqi,jadvaldagi tanlangan ustunlar,7/9/7 original
belgilar,ikkala katakka bir xil qiymat,bosqichli/shaklli bog‘lanishlar.
Ikkala miqdor0 bo‘lganda bar chizmasining nolga bo‘linishi himoyalangan.

12 yangi test,5 oqim320px/200%matn/ReduceMotion bilan. Full Flutter536test
(3:33), analyze0(2.4s), debugJSwebbuild42.3s o‘tdi. Bu haqiqiy brauzer/API,
Android yoki mustaqil pedagogik tekshiruv degani emas. Backend Math125pass/
1skip va alohida PG1pass34.10s:93dars,seed137XP→1067,replay0.

II74 bosma68–69 hali yo‘q. Explicit local QA siyosati va default strict
prerequisite saqlanadi; boshqa fanlar/normalapp/auth/Gradle o‘zgarmagan.
Keyingi:source23 «Murakkab masalalar yechish»,path21,PDF46–47/bosma44–45.
III qismda17matnli mavzu qolgan, butun1–11kurs hali tugallanmagan.

## Oldingi checkpointlar

## Joriy checkpoint: III qism15/37, jami88 lokal dars

Manba11 va14–17 (path11–15), PDF26–35/bosma24–33 qo‘shildi.
III qismning barcha15 oqimi320px/200%matn/ReduceMotion bilan tekshirildi;
33targetedtest, fullFlutter524test(3:15), analyze0(2.6s), debugJSwebbuild38.7s.
Bular haqiqiy Android, brauzer/API yoki pedagogik pilot tasdig‘i emas.
Original modellar: yo‘lning jami vaqti, nisbiy ko‘p/kam, bir nechta mos
butun/qism taqsimoti,50dan mustaqil tarmoqlar, kichik/katta/farqning4bog‘lanishi.
12–13nazoratning alohida tanasi yo‘q; source14 path12dan ochiladi, soxta
kontrol darsi yaratilmaydi. II74 manbasi hali yo‘q, explicit localQA siyosati
saqlangan. Normalapp/auth/Gradle/frontendga tegilmagan.

Keyingi:source18 «Taqqoslashga doir masalalar»,path16,PDF36–37/bosma34–35.
III qismning22matnli mavzusi qolgan; jami1–11kurs hali tugallanmagan.

## Oldingi checkpointlar va lokal ishga tushirish yo‘riqnomasi

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
