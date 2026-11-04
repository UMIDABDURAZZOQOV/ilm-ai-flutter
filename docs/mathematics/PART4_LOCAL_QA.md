# Matematika IV qism — lokal sinov

2026-11-04. 1-sinf IVqism112–116/PDF5–14/bosma4–13 uchun5dars va5original
geometrik model qo‘shildi. Jami115lokal dars; IV5/33,28mavzu hali yaratilmagan.
1–11kurs tugallanmagan. Normalmain,auth,Gradle,frontend va boshqa fanlar o‘zgarmagan.

Modellar: siljigan chizg‘ich oraliqlari, berilgan uzunlikda ikkinchi uchni
joylash, oradagi nuqtada12cmni bo‘lish, uzunliklari saqlanadigan siniq yo‘l,
ochiq/yopiq3–6uchli oddiy shakl. Raqamli cm fizik piksel o‘lchovi emas;
model fizik chizish mahorati, umumiy topologiya yoki o‘quvchi o‘zlashtirishini
avtomatik tasdiqlamaydi. Barcha baholash va XP serverda.

12yangi test13sda o‘tdi:5fullflow320px/200%matn/ReduceMotion,APIkontrakt,
strictmode,interval/endpoint,chegara qiymatlari,lifecycle reset,bo‘g‘inlar jami,
ochish/yopish va burishda tomon sanog‘i. To‘liqFlutter587test5:06da o‘tdi.
Analyze0issue2.9s;debugJSwebbuild67.5s. Buildda faqat yaroqsiz compile-onlytoken
va lokalURL ishlatilgan; bu brauzer/API yoki Android sinovi degani emas.
Backendmaqsadli7test29.90s va haqiqiyloopbackPG1test57.87s o‘tdi.

Server IVuchun defaultblocked. Faqat `MATHEMATICS_QA_PART3_SCHEDULE_BRIDGE=true`
va oldingi `MATHEMATICS_QA_SOURCE_GAP_BRIDGE=true` flaglari, shu UIDdagi oldingi
110mavjud dars va aniqmanbalar tekshirilgach lokalIV ochiladi. UIgapmetadataxabarini
ko‘rsatadi. II74vaIII5schedule-onlyqatori tugallangan deb sanalmaydi;
`previous_book_complete=false`, `course_ready=false`. Client permission bermaydi.

Backendni barchaGitrepositorylardan tashqaridagi yangi privatepapkada ishga tushirish:

```powershell
python -m scripts.serve_mathematics_preview --directory C:\ILM-local\mathematics_staging --allow-known-part2-source-gap --allow-known-part3-schedule-gap
flutter run -d chrome -t lib/mathematics_preview_main.dart --dart-define-from-file=C:\ILM-local\mathematics_staging\flutter-defines.json
```

Resumeuchunbackendbuyruqqa `--resume` vaikkalaflagyana beriladi. PrivateJWT/defines
Git/logga kiritilmaydi. Windowsbuyruqlari hali Windowsda tekshirilmagan.
CloudGitancestor guardi chetlab o‘tilmagan; standalonepositiveCLI hali tekshirilmagan.
AndroidSDK/ADB yo‘q; realAndroid/TalkBack/pedagog/pilot holati tasdiqsiz.

Keyingi: IV117 «Ko‘pburchakning perimetri»,PDF15–16/bosma14–15.
Asosiy manba va testcheckpointlari backend `docs/mathematics/`da saqlanadi.
