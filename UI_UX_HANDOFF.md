# ILM AI — mobil UI/UX, birinchi bosqich

2026-10-22, Asia/Tashkent. Branch: `feat/flutter-ui-ux-improvements`.
Asos: Flutter `feat/physics-first-batch`, `cf010113dcb19fb0a2fb2d7c3142178bcae78395`.
Alohida worktree: `ilm-ai-flutter-ui`. Asl Biologiya/Fizika ishchi branchlari almashtirilmagan.

Markaziy manba `ilm-ai/CLAUDE.md` to‘liq o‘qildi, Fizika branchidagi davom qaydlari ham
solishtirildi. Boshqa akkaunt shu hujjat va fan kontenti bilan ishlayotgani uchun ushbu
UI/UX handoff o‘z Flutter branchida tayyorlandi; markaziy hujjatning fan qaydlari
ustiga yozilmadi. Integratsiyada ushbu bo‘limni markaziy hujjatga alohida UI/UX qaydi
sifatida kiritish mumkin.

## Bajarilgan ishlar

- Dars feedbackidagi `AiExplainButton` va mashqdagi `AiTutorWidget` kirishlari yashirildi.
  Yozilgan nazariya, javob izohi va mavjud backend komponentlari saqlandi; yangi AI
  tushuntirish, kontent yoki API yaratilmagan.
- Mobil Biologiya rejimida backend nashr qilmagan placement tugmasi yashirildi.
- Dars yuklash xatosi lokalizatsiyalangan sabab va joyida retry bilan ko‘rsatiladi.
- `LessonDraftStore` mavjud MCQ darsining public snapshoti, attempt ID, nazariya/savol
  indeksi, tanlov, birinchi javoblar, xatolar navbati va sarflangan vaqtni saqlaydi.
  Bu yangi fan kontenti yoki FRQ javob kaliti emas. Kalit API origin + account + lesson
  bo‘yicha ajratilgan; token yoki credential saqlanmaydi.
- Dars qayta ochilganda saqlangan attempt tiklanadi; yangi start so‘rovi yuborilmaydi.
  Completion oldidan aynan yuboriladigan holat qurilmaga saqlanadi. HTTP javobi
  yo‘qolganda retry o‘sha attempt va birinchi javoblarni yuboradi; server grading,
  idempotency va XP qoidalari o‘zgarishsiz ishlaydi.
- 24 soatlik lokal attempt eskirsa yoki server `study_session_expired/required`
  qaytarsa, tushunarli qayta boshlash oqimi bor. Yangi attempt faqat explicit
  «Yangidan boshlash»dan keyin ochiladi. Oldingi server progressi o‘chirilmaydi.
- Buzilgan lokal draft o‘qilmaydi; saqlash xatosi ko‘rinadigan, scroll qilinadigan
  ogohlantirish va retry bilan beriladi. Muvaffaqiyatli completiondan keyingi cache
  tozalash xatosi server tasdiqlagan natijani muvaffaqiyatsizlikka aylantirmaydi.
- Ism dialogi controller lifecycle, busy, takror bosish, account va mounted
  himoyalariga ega. So‘rov davomida dialogni yopish keyingi callbackni qulatmaydi.
- Kunlik maqsad saqlashida busy/error/retry va account tekshiruvi bor; mavjud offline
  preference navbati saqlandi.
- Tema/til segmentlari semantika, klaviatura fokusi va Reduce Motion’ga moslashtirildi.
- Confetti va dars yakuni tovushi faqat server kamida bitta yulduz qaytarganda ishlaydi.
  Muvaffaqiyatsiz dars uchun rag‘batlantiruvchi matn va Ilmo saqlandi.

## Tekshiruv va chegaralar

Yakuniy tekshiruvlar (Windows, shu branchning yakuniy runtime kodi):

- `flutter test --no-pub`: **151 passed**, 39 soniya. Baseline 143 testga 8 yangi
  UI recovery testi qo‘shildi; mavjud noto‘g‘ri birinchi javob bilan tugagan dars
  tovush testi endi zero-star natijada confetti/tovush yo‘qligini talab qiladi.
  Alohida yangi success testi muvaffaqiyatli natijaning tantanasini ham tekshiradi.
- `flutter analyze --no-pub`: **No issues found**, 7,7 soniya.
- `git diff --check`: toza. Generated platform registrantlarining pub-get hosil
  qilgan keraksiz o‘zgarishlari qaytarildi. Paket/lock fayllariga diff yo‘q.
- Flutterning mavjud SDK vositasi Windowsda to‘g‘ridan-to‘g‘ri
  `dart.exe .../flutter_tools.snapshot` orqali ishlatildi. Sandbox lockfile ruxsati
  yo‘q run muvaffaqiyat hisobiga kiritilmadi; yakuniy run ruxsatli muhitda o‘tdi.

Yangi regressionlar:
retry; AI kirishi yashirinligi; process-recreation orqali draft va xatolar navbati;
lost-response completion replay; account/origin isolation; buzilgan va eskirgan draft;
disk xatosi; ism dialogini so‘rov vaqtida yopish; kunlik maqsad xatosi; muvaffaqiyatli
va muvaffaqiyatsiz yakun effektlari. Mavjud Biology, Physics/FRQ, auth, onboarding,
responsive va API contract testlari to‘liq suite tarkibida bajariladi.

Bu widget/mocked API regressionlari. Haqiqiy Android process kill, TalkBack, Google
Console/login, telefon xotira to‘lishi yoki jonli backend bilan end-to-end QA o‘tdi
degan da’vo yo‘q. Ushbu bosqichda APK/AAB yoki yangi production build tayyorlanmadi.

Backend, veb, fan kontenti, FRQ graderi, XP/streak/prerequisite qoidalari, brend va
Ilmo assetlari, OAuth identifikatorlari va nashr flaglariga diff yo‘q. Production DB,
migratsiya, deploy, main merge yoki Play nashri bajarilmadi.

## Keyingi bosqich

Auditning Fizika preview UI matnlarini uz/ru/en tizimiga ulash va Fizika QA hujjatini
joriy katalog/commitlarga moslash bandlari qolgan. Fan kontenti tarjima qilinmaydi.
Keyin vizual izchillik, Ilmo harakatlari va haqiqiy Android QA davom ettiriladi.
