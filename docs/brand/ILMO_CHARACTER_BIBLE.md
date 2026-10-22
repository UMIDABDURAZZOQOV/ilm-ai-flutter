# ILM AI — Ilmo Character Bible

Versiya 1.0 · 2026-10-23 · amaldagi PNGlar va Flutter komponentlari asosida.

## 1. Brend va xarakter

Rasmiy mahsulot nomi **ILM AI**, maskot nomi **Ilmo**. Nom, bosh harflar va
milliy identifikatsiya barcha mahsulot yuzalarida saqlanadi. Ilmo — o‘quvchi
yonidagi sabrli, ziyrak va samimiy robot hamroh. U o‘quvchini baholovchi hakam
yoki inson o‘qituvchining o‘rnini egallagan mutlaq ekspert qilib ko‘rsatilmaydi.

Qadriyatlar: bilimga qiziqish; rostgo‘ylik; muntazam kichik qadamlar; hurmat;
xatodan o‘rganish; O‘zbekiston madaniyatiga tabiiy yaqinlik. Ilmo natijani
bo‘rttirmaydi, uyaltirmaydi va bilim olishni bolaning shaxsiy qadriga bog‘lamaydi.

ILM AI o‘zining do‘ppi, romb bezagi, indigo palitrasi va xotirjam harakati bilan
taniladi. Qisqa dars yoki hajmli tugma kabi umumiy UX tamoyillari boshqa ta’lim
ilovasining maskoti, kompozitsiyasi yoki brend ohangini aynan ko‘chirishga sabab emas.

Mavjud `ilmo_hello.png` asosiy vizual etalon. Qolgan holatlar shu qahramonning
ifodalaridir. Bu hujjat yangi 3D model yoki to‘liq model sheet mavjudligini
bildirmaydi. Kelajakdagi grafikani brend egasi ushbu etalon bilan solishtiradi.

## 2. O‘zgarmas identifikatsiya

- Indigo do‘ppi va uning oq milliy geometrik naqshi. Uni oddiy beysbol kepkasi,
  toj yoki begona brend bosh kiyimiga almashtirmang.
- Katta, yumaloq burchakli robot boshi; yumshoq oq-krem korpus; boshga nisbatan
  kichik tana. Qirrali, metallik yoki jangovar robotga aylantirmang.
- Binafsha ko‘zlar, samimiy yuz, kichik og‘iz va muloyim qosh ifodalari.
- Sariq quloq qismlari, kiyim chetlari va romb bezagi; indigo kiyim.
- Antenna va uning taniladigan shakli. Mavjud pozalarda chiroq ranglari farq
  qiladi: bu saqlangan grafik xususiyat; UI ularni avtomatik qayta bo‘yamaydi.
- Oyoq, qo‘l, bosh va kiyim nisbatlari original fayldan olinadi. PNGni cho‘zish,
  qiyshaytirish, ko‘zgudek aylantirish yoki do‘ppining bir qismini kesish mumkin emas.

3D yoritishdagi rang o‘tishlari tabiiy; har pikselni quyidagi HEX qiymatiga
majburan tekislash talab qilinmaydi. HEXlar interfeys va yangi grafik uchun
asosiy yo‘nalish, original rasmlarni qayta bo‘yash bu bosqichga kirmaydi.

| Rang | Token | Vazifa |
|---|---|---|
| Indigo `#2A1F6B` | `BrandPalette.indigo` | Asosiy brend, do‘ppi/kiyim, muhim amallar |
| Sariq `#F9A825` | `BrandPalette.accentOrange` | Bezak, iliqlik, XP/streak aksenti |
| Turkuaz `#2DD4BF` | `BrandPalette.turquoise` | Tanlov, yordamchi urg‘u, texnologik detal |
| Oq-krem `#FAF7F2` | `BrandPalette.creamWhite` | Tana va yumshoq yuzalar |

To‘q rejimning mavjud indigo yuzalari va o‘qilishi qulay primary varianti saqlanadi.
To‘g‘ri/xato feedback rangi semantik vazifasini bajaradi; maskot rangini almashtirmaydi.

## 3. Ifodalar va qo‘llanish

| Holat / fayl | Qachon ishlatiladi | Chegara |
|---|---|---|
| Salomlashish · `ilmo_hello.png` | Welcome, tanishtirish, neytral qaytish | Har bir ekranda qayta salomlashmasin |
| O‘ylanish · `ilmo_thinking.png` | Savol, tanlov, kutish yoki mulohaza | Tarmoq xatosini o‘quvchining xatosi sifatida ko‘rsatmasin |
| Tushuntirish · `ilmo_explaining.png` | Mavjud nazariya, yo‘riq, tushuntirish | Doskadagi mayda chiziqlar o‘quv kontenti o‘rnini bosmaydi |
| Xursandlik · `ilmo_happy.png` | Haqiqiy yakun va muvaffaqiyat | Soxta natija, kafolat yoki ma’lumot saqlanmasidan oldingi mukofot yo‘q |
| Qo‘llab-quvvatlash · mavjud `ilmo_sad.png` | Xatodan so‘ng qisqa hamdardlik | Ko‘z yoshi ayblash vositasi emas; qayta-qayta va jazo sifatida ishlatilmaydi |

Qo‘llab-quvvatlash uchun yangi nomdagi poza APIga qo‘shilmagan. Mavjud `sad`
etalonida ko‘z yoshi va bosh barmoq ishorasi bor. Neytral, ko‘z yoshisiz support
pozasi keyingi grafik topshiriq: tasdiqlangan original kelmaguncha fayl
o‘zgartirilmaydi. Zarur neytral vaziyatda `hello` yoki `thinking` tanlanishi mumkin.

Muvaffaqiyatni matn va server natijasi tushuntiradi. Ilmo hissiy yordam beradi;
rang yoki yuz ifodasi yagona ma’lumot manbai bo‘la olmaydi.

## 4. Flutter o‘lchami va joylashuvi

Barcha hozirgi PNGlar 1024×1024 shaffof kvadrat canvasda. O‘lcham **canvas**ga
tegishli, qahramonning ko‘rinadigan bo‘yiga emas. `explaining` doskasi bilan
kengroq; uni boshqalarga teng kenglik qilish uchun kesmang yoki alohida cho‘zmang.

| Token | dp | Tavsiya |
|---|---:|---|
| `IlmoSizes.inline` | 56 | Mavjud tor legacy joylar; yangi full-body qo‘llanish uchun afzal emas |
| `IlmoSizes.compact` | 88 | Nutq blokida, yordamchi sarlavhada |
| `IlmoSizes.feedback` | 96 | Qisqa javob reaksiyasi uchun yangi joylashuvlar |
| `IlmoSizes.lesson` | 112 | Dars kirishi yoki yo‘l yordamchisi |
| `IlmoSizes.hero` | 140 | Welcome va onboardingning asosiy Ilmosi |
| `IlmoSizes.celebration` | 176 | Yakun ekranidagi katta urg‘u |
| `IlmoSizes.splash` | 160 | Flutter splashdagi alohida bosh logotipi |

Bu tokenlar yangi UI uchun standart; mavjud darsdagi 100/110/170/180 kabi
tasdiqlangan o‘lchamlar ushbu bosqichda majburan almashtirilmaydi. Biologiya va
Fizika feature fayllari o‘zgartirilmagan. Keyingi alohida vizual QAda yaqin token
tanlanadi, joylashuvning yaxshilanishi real ekran orqali tekshiriladi.

`MascotImage.hero` va `.compact` qayta foydalaniladigan kirishlardir. Asosiy
`MascotImage` mavjud parametrlar bilan ishlaydi, kichik ota konteynerga sig‘adi va
rasmni proporsional ko‘rsatadi. Yangi UI `BoxFit.contain`dan foydalanadi.

Standart bo‘shliq: mayda 8 dp, maskot–nutq orasida 16 dp, blokdan keyin 24 dp.
`IlmoSpeechHeader` tor kenglikda yoki katta matnda vertikal joylashadi; odatiy
kenglikda Ilmo chapda, matn o‘ngda. Uzun nutq scroll qilinadigan ekran ichida turadi.
Ilmo hech qachon davom etish tugmasini yoki kiritish maydonini yopmaydi.

## 5. Animatsiya

- Standart kirish: **250 ms**, opacity 0→1, scale **0,96→1**, `easeOutCubic`.
- Ilmo uchun bitta kirish animatsiyasi. Uni yana tashqi 0,35→1 sakrash bilan
  qo‘shmang. Kutilmagan aylanish, kuchli bounce va ekran bo‘ylab uchish qo‘llanmaydi.
- “Tayyor” ekrani holatni bir marta bildiradi; tinimsiz nafas olish yoki sakrash yo‘q.
- Pozani almashtirish uchun tasdiqlangan PNGlar ishlatiladi. Bu skelet/rig,
  lip-sync, ko‘zning alohida animatsiyasi yoki yangi 3D animatsiya emas.
- OS Reduce Motion yoqilganda Ilmo statik. Yashirin tab tickerlari mavjud
  arxitektura orqali o‘chadi; ushbu ish ularni qayta yoqmaydi.
- Maqsad — tez va xotirjam muloqot. Qurilmada FPS o‘lchanmaguncha 60 FPS yoki
  batareya yaxshilanishining sonli da’vosi berilmaydi.

## 6. Kichik ekran, ikonka va splash

Full-body PNGni 48 px’da muhim belgi sifatida ishlatmang: do‘ppi naqshi va
yuz ifodasi o‘qilmaydi. 72 px ham nozik detallar uchun cheklangan. Bu joylar uchun
kelajakda tasdiqlangan alohida bosh/compact eksport kerak; mavjud rasmdan
avtomatik kesma yasalmaydi. Ikonka grafikasini dars maskoti o‘rnida qo‘ymang.

`app_icon.png` ataylab fonli va opaque. `app_icon_foreground.png` shaffof,
`splash_logo.png` alohida bosh kompozitsiyasidir. Shaffoflik hamma faylga bir xil
talab emas. Antenna, do‘ppi, ko‘zlar va quloqlar turli launcher maskalarida
kesilmasligi haqiqiy Androidda tekshiriladi. Native icon/splash generatorlari
ushbu ishda qayta ishga tushirilmaydi; package va callback o‘zgarmaydi.

Flutter rasmlarni chizish hajmi × DPR bo‘yicha, original 1024 px’dan oshirmay
dekodlaydi. PNG fayllari qayta siqilmaydi yoki almashtirilmaydi. Masalan,
88 dp × DPR3 = 264 px; bitta RGBA buffer taxminan 272 KiB, master 4 MiB.
Bu faqat buffer hisobi, real ilova xotirasi/FPS o‘lchovi emas; engine keshi va
bir nechta o‘lchamdagi nusxalar qo‘shimcha xotira ishlatishi mumkin.

## 7. Accessibility va texnik nosozlik

Ilmo yonidagi nutq mazmuni screen reader uchun o‘qiladi, dekorativ rasm yana
takror e’lon qilinmaydi. Rasmning o‘zi ma’no tashisa, `semanticLabel`ga tanlangan
UI tilida qisqa ta’rif beriladi. Standalone image labelida yangi dars javobi bo‘lmaydi.

Rasm yuklanmasa umumiy komponent ixcham **ILM AI** yozuvini ko‘rsatadi.
Yangi robot belgisi yoki begona maskot bilan almashtirmaydi. Bunday fallback
asset xatosini tuzatildi deb hisoblash emas; sabab QAda tekshiriladi.

## 8. Uch tildagi muloqot ohangi

O‘zbekcha: sodda, muloyim “siz”, tabiiy imlo, bir gapda bitta fikr. Ruscha:
hurmatli “вы”, qisqa va ravon. Inglizcha: xotirjam, aniq va do‘stona.
Ismlar **ILM AI** va **Ilmo**; ruscha mavjud lokal matndagi “Ильмо” talaffuz
yozuvi yangi brend nomi emas. Bu hujjat UI tone misollaridir, fan kontenti emas.

| Vaziyat | O‘zbekcha | Русский | English |
|---|---|---|---|
| Salom | Salom! Men Ilmoman. Birga boshlaymiz. | Привет! Я Ильмо. Давайте начнём вместе. | Hello! I’m Ilmo. Let’s get started together. |
| O‘ylanish | Shoshilmang, birga o‘ylab ko‘ramiz. | Не спешите, давайте подумаем вместе. | Take your time. Let’s think it through together. |
| Tushuntirish | Keling, bosqichma-bosqich ko‘rib chiqamiz. | Давайте разберём по шагам. | Let’s go through it step by step. |
| Haqiqiy yakun | Yaxshi mehnat qildingiz! | Вы хорошо поработали! | Nice work! |
| Qo‘llab-quvvatlash | Xato qilish tabiiy. Yana urinib ko‘ramiz. | Ошибаться нормально. Попробуем ещё раз. | Mistakes are part of learning. Let’s try again. |
| Tarmoq xatosi | Ulanishni tekshirib, qayta urinib ko‘ring. | Проверьте соединение и повторите попытку. | Check your connection and try again. |

“Nega bilmaysiz?”, “Siz sustsiz”, aybdorlik tug‘diruvchi yig‘i, soxta raqamlar,
kafolatli baho/natija va haddan tashqari undovlardan foydalanmang. Ilmo
serverda saqlanmagan natijani “saqlandi” deb aytmaydi.

## 9. Noto‘g‘ri ishlatish va yangi grafika uchun mezon

Taqiqlanadi: nomni almashtirish; milliy naqshni olib tashlash; ko‘z/kiyimni
begona rangga bo‘yash; watermark yoki boshqa brend qahramonini qo‘shish;
rasmni stretch, crop yoki mirror qilish; ko‘z yoshi bilan bosim o‘tkazish;
Ilmo tasviri ichiga o‘quv matnini tiqish; soxta “thinking” orqali mavjud bo‘lmagan
AI yoki tayyorlanmayotgan shaxsiy rejani va’da qilish.

Yangi grafik kelganda: original reference bilan yonma-yon review; shaffof
canvas va bir xil bazaviy yoritish; do‘ppi/antenna to‘liqligi; yuz/tana nisbatlari;
oq/to‘q fon va kichik hajm; kerakli huquqlar hamda source master topshirilishi.
Eskilar alohida saqlanadi. Ko‘z yoshisiz support, compact bosh ifodalari va
rasmiy turn-around/model sheet alohida grafik topshiriqlari bo‘lib qoladi.
