# ILM AI dizayn tizimi

## Vizual yo‘nalish

Ilmiy aniqlik, o‘zbekona milliy identifikatsiya va xotirjam o‘rganish. Indigo
asosiy harakatlar va brendga, turkuaz o‘quv progressiga, sariq kichik yutuq va
e’tibor nuqtalariga xizmat qiladi. Do‘ppi naqshli Ilmo mavjud original holatlarda
ishlatiladi. Romb korporativ belgi; Ilmo tushuntiruvchi hamroh. Ular sahifada
bir-biri bilan raqobatlashadigan ikki katta logotipga aylantirilmaydi.

Yuqori kontrastli matn, yumshoq surface qatlamlari, 1px chegara va ozgina press
feedback. Asosiy CTA gradient va qalin 3D platformasiz. Eski `Duo*` class nomlari
call-site mosligi uchun qoladi; ushbu mahsulotning vizual qoidalari ILM AI’ga xos.

## Tokenlar

| Vazifa | Light | Dark |
|---|---|---|
| Brend indigo | `#2A1F6B` | Brend identifikatori o‘sha rang |
| Harakat foni / yozuv | `#2A1F6B` / oq | `#6754D4` / oq |
| Link, faol tab | `#2A1F6B` | `#B8ACFF` |
| Fon / surface / karta | `#F7F7FC` / oq / oq | `#13102C` / `#1C173E` / `#251F50` |
| Asosiy / ikkilamchi / muted matn | `#1E1A34` / `#59516E` / `#68617C` | `#F1F0FA` / `#C3BDDB` / `#B2AACD` |
| Progress aksenti | `#2DD4BF` | `#2DD4BF` |
| Yutuq aksenti | `#F9A825` | `#F9A825` |
| Success matni | `#087F6B` | `#34D399` |
| Xato matni | `#B91C1C` | `#F87171` |
| Warning matni | `#9A5B04` | `#FBBF24` |

`IlmDesign` ThemeExtension action/onAction/focus rollarini ajratadi.
`AppColors` mavjud API sifatida qoladi. Normal matn ranglari fon, surface va
karta bilan, semantik status matnlari o‘z status foni bilan **kamida 4.5:1**
kontrastga test qilinadi. Bu [Flutter accessibility tavsiyalari](https://docs.flutter.dev/ui/accessibility)
va [WCAG contrast minimum](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html)
asosidagi muhandislik mezoni; butun ilova sertifikatlandi degan da’vo emas.

- Spacing: **4, 8, 16, 24, 32**; page gutter 24, tor zich joylarda 16.
- Radius: 12 kichik element, 16 control, 20 karta/dialog, 28 sheet.
- Type: 30/26/23 headline; 20/17 title; 17/15 body; 13 yordamchi matn.
  Body line-height 1.5–1.55; kontent matni tarjima/rewritesiz render qilinadi.
- Reader eni: **640dp**; keng sahifa chegarasi 960dp. Balandlik qat’iy emas;
  katta matnni siqish yoki `textScaler`ni cheklash ishlatilmaydi.
- Interaktiv elementlar: kamida **48dp**; tab label to‘liq semanticsda;
  tanlov/xato faqat rang orqali ifodalanmaydi.
- Harakat: 180–250ms, kuchsiz scale/translate. Reduce Motion tizim parametri
  ustun. Loading soxta foiz yoki XP bermaydi; skeleton ekran o‘quvchini kutish
  holatidan xabardor qiladi.

Pastki navigatsiyada destination almashishini aniq ko‘rsatish uchun selection
280ms, ikonning bir martalik gesture’i 360ms, sahifa fade-through’i 260ms.
Tab state/cache saqlanadi; motion loop ishlatilmaydi. Reduce Motion hammasini
darhol yakunlaydi. Tafsilot: [navigatsiya motion standarti](NAVIGATION_MOTION.md).

## Til va ishonch

### O‘quv harakatlari va qaytish

`LessonEntry` hero, dars qatori va start sheet uchun bitta holat manbai:
start/resume/expired/review/locked. Lokal resume faqat user/origin bo‘yicha
validated draft va amaldagi muddatga asoslanadi; completed/locked backenddan.
`StudyStartSheet` dars/checkpoint uchun umumiy frame va action tartibidir.
Bo‘lim progressi faqat mavjud backend darslari denominatoridan olinadi;
coverage tugallanmagan bo‘lsa bu tushuntiriladi.

`LessonCompletionView` tasdiqlangan XP/score/starsni ko‘rsatadi. Aniqlik va vaqt
alohida nomlanadi, asosiy amal yo‘lga qaytaradi. Natija/sheet o‘lchami kontentga
mos; katta shriftda kartalar vertikal joylashadi. Yangi holat uchun rasm
generatsiya qilinmagan, mavjud Ilmo pozalari ishlatilgan.

Uzun yo‘l sliver ro‘yxati bilan render qilinadi. Bu frame-time kafolati emas;
haqiqiy FPS va memory profile/release qurilmada alohida o‘lchanadi.

UZ/RU/EN interface qo‘llanadi. `t` va `str3`ning mavjud fallbacklari saqlanadi.
Biologiyaning manbali o‘zbekcha mazmuni o‘zgarmaydi. Dars tili izohi UI tilida;
ruscha interfeysda o‘zbekcha dars matnining mavjudligi tarjima xatosi deb
ko‘rsatilmaydi. UI, dars mazmuni va bibliografik nomlar auditda alohida baholanadi.

Chiqish dialogi aynan yakuniy lokal saqlash natijasidan keyin ko‘rsatiladi.
MCQ draft yo‘q/yaroqsiz bo‘lsa “saqlandi” deyilmaydi. Practice oqimiga resumable
va’da qo‘shilmagan. XP, yulduz va unlock hisoblari backend natijasidan olinadi.

## Tekshiruv manbalari

`test/ilm_design_system_test.dart`: ranglar, theme parity, 320dp/200% yuklanish,
UZ/RU/EN save outcome, ikki komponent golden. `test/uiux_visual_review_test.dart`:
actual Flutter ekranlari, mavjud Biologiya API fixturelari va alohida soxta UI
hisobi; hech bir jonli backendga ulanmaydi. Xom telefon reference va mahalliy
capturelar `.dart_tool/uiux-review/`dan tashqariga tarqatilmaydi.
