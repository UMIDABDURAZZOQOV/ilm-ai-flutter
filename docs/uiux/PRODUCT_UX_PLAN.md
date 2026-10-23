# ILM AI mahsulot UX dasturi

2026-10-23. Foydalanuvchi UI/UX’ni to‘liq olib borishga ruxsat berdi.
Branch: `feat/flutter-ui-ux-improvements`; boshlang‘ich commit `10df787`.

## Maqsad va baholash

Yangi o‘quvchi fan/sinf tanlay olishi, birinchi darsni tugatishi, saqlangan
urinishga qaytishi va keyingi qadamini yordamsiz tushunishi kerak. «10/10»
o‘lchangan natija emas; haqiqiy o‘quvchilar sinovi o‘tkazilmaguncha bunday
baho yoki retention kafolati berilmaydi.

Mavjud design system, Ilmo, uch til, light/dark, 406 Biologiya darsi,
Fizika/FRQ, backend/auth kontraktlari va server progressi saqlanadi.
Backend/DB/production sozlamalari hamda boshqa worktree’lar o‘zgarmaydi.
Avvaldan dirty bo‘lgan yetti generated plugin fayli commitga kiritilmaydi.

## 1. Keyingi o‘quv qadamini aniq qilish

- Hero, dars qatori va start sheet bir xil real holatni ko‘rsatadi.
- Yangi dars: boshlash. Yaroqli lokal draft: nazariya/savoldagi joyidan davom.
  Muddati tugagan draft: tiklash oynasiga kirish, avtomatik yangi attempt yo‘q.
  Completed/locked holati faqat backenddan olinadi.
- Hisob/API origin bo‘yicha draft izolyatsiyasi saqlanadi; format o‘zgarmaydi.
- Bo‘lim progressi faqat backend completed darslari sonidan hisoblanadi.
  Katalog hali to‘liq bo‘lmasa, bu barcha rejalashtirilgan kontent tugadi
  degan ma’no bermaydi.
- Yagona ustuvor harakat, o‘qiladigan bo‘lim iyerarxiyasi va ixcham kontekst.

## 2. Dars, bo‘lim sinovi va natijalar

- Start/checkpoint sheet: bir xil surface, spacing, indigo action, aniq lock
  sababi, tor/landscape ekran va 200% shriftga scroll.
- Natija: dars nomi, server qaytargan XP/score/stars, javoblarni ko‘rish va
  yo‘lga qaytish. Server tasdiqlamagan keyingi dars yoki yutuq va’dasi yo‘q.
- Loading/error/expiry holatlarida aniq keyingi amal; mavjud retry/save
  mexanizmi saqlanadi. Kontent matni va grading o‘zgarmaydi.

## 3. Sifat dalillari

- Yangi/saqlangan/expired/completed/locked/account-switch holat testlari.
- Uch til × ikki theme, 320dp/200%, landscape va Reduce Motion.
- Muhim ekranlarning oldingi/yangi tasvirlari, real widget fixture capture.
- Har bosqichda targeted/full Flutter tests, analyze va alohida commit/push.
- Samsung A12’da hisobni o‘chirmasdan QA; real hisobda javob/XP yuborilmaydi.
- Release konfiguratsiyasi faqat tekshiriladi. Kalitlar qiymati chiqarilmaydi;
  haqiqiy Google login va publication egasi ishtirokidagi reliz tekshiruvi.

## 4. O‘quvchilar bilan beta sinovi

20–30 o‘quvchilik beta uchun moderator protokoli, vazifalar va natija jadvali
tayyorlanadi. Dastlab yordamsiz fan/sinf tanlash, birinchi darsni topish,
chiqish/qaytish va natijadan keyingi qadam kuzatiladi. Ishtirokchilar va
hisoblarni tashkil qilish, ularga xabar yuborish hamda real natijalarni olish
foydalanuvchi ishtirokini talab qiladi. Uydirma testchilar/retention yo‘q.

## Yakuniy qabul mezonlari

- Hero, qator va sheet’dagi harakatlar bir-biriga zid emas.
- Saqlanmagan/muddati tugagan holatga yolg‘on «davom etish» berilmaydi.
- Qulflangan dars/sinov UI orqali ochilmaydi; mavjud route/API saqlanadi.
- Matn kesilishi/overflow yo‘q; asosiy amallar kamida 48dp.
- Light/dark va tillar funksional jihatdan teng, kontent tili ochiq ko‘rsatilgan.
- Automated QA va real qurilma natijalari alohida, o‘tkazilmagan release/beta
  tekshiruvlari aniq qayd etiladi. Main merge/deploy avtomatik bajarilmaydi.
