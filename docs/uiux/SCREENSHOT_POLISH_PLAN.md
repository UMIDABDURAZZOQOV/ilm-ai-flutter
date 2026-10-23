# Ekranlardan topilgan UX muammolari — 2026-10-23

Boshlanish: `676eb37`, `feat/flutter-ui-ux-improvements`, UI worktree.
Foydalanuvchining 17 ta yangi Samsung tasviri asosida. Avvaldan o‘zgargan
7 ta desktop generated plugin fayli ushbu ishga qo‘shilmaydi.

## Audit va amalga oshirish tartibi

1. **P0 — readiness/access chalkashligi.** Curriculum summary faqat
   `ready/completed` beradi; `ready` foydalanuvchiga ochiq degani emas.
   Mavzular oynasida «kontent tayyor» va o‘quv yo‘lida ketma-ket ochilish
   izohi, play o‘rniga kitob belgisi. Server tree lock/unlock o‘zgarmaydi.
   Grade va home tayyor darslar sonini access sifatida atamaydi.
2. **P1 — home hajmi.** Birinchi dars uchun takroriy title/start hero’si
   o‘rniga ixcham kunlik maqsad paneli. Asosiy boshlash amali dars qatorida.
   Yo‘lda keyinroq turgan joriy dars/checkpoint uchun tez qaytish saqlanadi.
   Goal, resume/expiry, lazy ro‘yxat va account/grade scroll saqlanadi.
3. **P1 — liga.** Bo‘sh reytingga original Ilmo, aniq izoh va mavjud Learn
   tabiga qaytish amali. Rank yoki XP to‘qilmaydi; real tier/progress saqlanadi.
4. **P1 — profil.** Haqiqiy faoliyati yo‘q hisobda boshlash taklifi birinchi.
   Nol statistikalar, kalendar va heatmap yig‘iladigan bo‘limda saqlanadi.
   Har qanday real progress bo‘lsa mavjud batafsil ko‘rinish to‘g‘ridan-to‘g‘ri.
5. **P1 — vizual hierarchy.** Dark surface’lar neytral indigo tusida;
   asosiy indigo/turkuaz/sariq va Ilmo assetlari saqlanadi. Logout pastroq
   urg‘udagi aniq nomlangan amal; tasdiqlash va auth mexanizmi o‘zgarmaydi.

## Tekshiruv

- UZ/RU/EN, light/dark, 320dp/200%, landscape, semantics va callback testlari.
- Birinchi dars bir marta ko‘rinishi, oldingi mavjud checkpoint priority,
  resume/expired, tayyor/yozilmagan/completed mavzu va read-only outline.
- Yangi/real progressli profil, bo‘sh/to‘liq liga, mavjud tab/cache’ga qaytish.
- Theme contrast, yangilangan dark golden’larni ko‘rish va BEFORE/AFTER capture.
- To‘liq `flutter test`, `flutter analyze`; Samsung’da hisob/draft saqlangan
  holda APK/hash va asosiy ekranlar. Real akkauntdan logout/lesson complete yo‘q.
- UI commit/push alohida; backend, DB, fan kontenti, assets va production
  sozlamalari hamda markaziy `CLAUDE.md` o‘zgartirilmaydi.
