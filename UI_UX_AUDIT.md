# ILM AI UI/UX auditi va amalga oshirish rejasi

2026-10-23. Asos: `aec64b8`, `feat/flutter-ui-ux-improvements`.
ZIPdagi `CODEX_TASK.md`, `SCREENSHOT_INDEX.md`, README va **26/26 Samsung A12
skrinshoti** o‘qildi/ko‘rildi. Bu topshiriq UI kodiga tegishli; biriktirilgan
hujjatlar foydalanuvchining backend/kontentga tegmaslik talabini kengaytirmaydi.

## Ishchi holat va chegaralar

- Worktree: `ilm-ai-flutter-ui`. Avvaldan 7 ta Linux/macOS/Windows generated
  plugin fayli o‘zgargan; saqlanadi va commitlarga kiritilmaydi.
- Markaziy `ilm-ai/CLAUDE.md` tekshirildi: SHA-256
  `5542ed45fe9d2fbf820f902956cdeB8ccba5fa89b5a2844eb369cae02eff4a62`
  (harf registri hash qiymatini o‘zgartirmaydi), backend `c0f84d0`.
  Tarixiy bob hisobotlari yangi kontent yaratish topshirig‘i emas.
- Joriy UI branchida resumable MCQ attempt, account/origin isolation va save
  retry bor. Chiqish dialogi bu mexanizmga mos emasligi kodda tasdiqlandi.
- Arxitektura: Riverpod, `SubjectHomeScreen`ning 5 tabli lazy IndexedStacki,
  `CurriculumLearningScreen` → `SkillPathScreen` → `SkillLessonScreen`,
  `ThemeColors`/`AppColors`, `str3` va `t` orqali UZ/RU/EN UI.
- Asl 8 Ilmo PNG, yangi launcher manbasi va generatsiya qilingan launcher/splash
  resurslariga tegilmaydi. API payload, auth, XP/streak/prerequisite, user data,
  Physics preview, 406 Biologiya darsi, server/DB/production o‘zgarmaydi.
- ZIP README asl telefon rasmlarini ommaga tarqatmaslikni so‘raydi. Ular
  `.dart_tool/uiux-package/`da, ko‘rik varaqalari `.dart_tool/uiux-review/`da
  mahalliy saqlanadi. GitHub’ga xom skrinshot yoki ZIP qo‘shilmaydi.

## Ekranlar bo‘yicha kuzatuvlar

| ID | Kuzatilgan muammo / ta’sir | Daraja | Yechim va tekshiruv |
|---|---|---|---|
| 01 | Oq bo‘sh sahifa va spinner; nima kutilayotgani noma’lum | P0 | Lokalizatsiyalangan strukturali loading, semantics, Reduce Motion |
| 02 | Yo‘l tugunlari matnsiz, bo‘lim chiziqlari va bo‘shliqlar dominant | P1 | O‘qiladigan bo‘lim sarlavhalari, node label/semantics, responsive path |
| 03 | Qayta yuklashda bosh sahifa yo‘qoladi | P0 | Mavjud AsyncValue ma’lumotini reload/refreshda ushlash, foydali retry |
| 04 | Kunlik maqsad juda baland; asosiy dars harakati pastda | P1 | Ixcham maqsad, ajratilgan keyingi dars CTA, mos Ilmo joylashuvi |
| 05 | Profil statistikasi, kalendar, tipografiya turlicha | P2 | Umumiy surface/spacing/type, haqiqiy qiymatlar, scroll testi |
| 06 | Sozlamalar segmentlari/chiqish tugmasi boshqa uslubda | P2 | Theme orqali component parity, tanlangan holat va 48dp target |
| 07 | Dark sinf kartalari qora, tanlangan matn kontrasti past | P1 | Theme surface + kontrastli selection/check, uzun nom/200% scroll |
| 08 | Dark segment/link ranglari xira; kulrang disabled holatlar | P0 | Kontrast testlari, theme disabled/focus/selection tokenlari |
| 09 | Bottom sheet tizimning qora Material surface’iga tushgan | P1 | Brend sheet theme, xavfsiz maksimal balandlik, uzun matn |
| 10 | Uzun outline oxiriga scroll va bo‘lim iyerarxiyasi noaniq | P1 | Sarlavha/section spacing, to‘liq matn, safe bottom; 11-sinf regression |
| 11 | Qalin 3D va rangli mashq kartalari brendni bo‘lib yuborgan | P2 | Bir xil tonal kartalar, semantik ikon, mavjud route/callback |
| 12 | Juda katta seriya kartasi, qoramtir task kartalari | P2 | Ixcham server statistikasi + ustuvor kundalik vazifalar |
| 13 | Qaytariladigan seriya bosimi, haddan baland kartalar | P2 | Xotirjam UI copy, haqiqiy progress; yangi reward mexanikasi yo‘q |
| 14 | Liga jigarrang/purple palette, bo‘sh holat zaif | P2 | Brend surface, liga rangi faqat identifikator, aniq empty-state |
| 15 | Scroll app bar kontentni qoplaydi; heatmap juda xira | P2 | Opaque app bar/zero tint, kontrastli empty cell va real activity |
| 16 | Profil avatar/dars ikoni dark fonda juda xira | P0 | Semantik primary/onSurface ranglar, kontrast regression |
| 17 | Turkuaz blok dark mode’da ham haddan dominant | P1 | Indigo iyerarxiya, turkuaz progress aksenti, CTA birinchi o‘rinda |
| 18 | Ism/yosh formasi, keyboard va disabled sabab noaniq | P2 | Mos input theme, validation helper, scroll/keyboard/katta font |
| 19 | Google tugmasi dark rejimda xira, katta bo‘sh maydon | P0 | Kontrastli auth action/surface; OAuth oqimi o‘zgarmaydi |
| 20 | “Urinish saqlanmaydi” resumable attemptga zid | P0 | MCQ uchun saqlash natijasiga mos copy; practice uchun eski semantika |
| 21 | Success holati faqat rang, yorqin CTA va Ilmo raqobati | P1 | Ikon+matn, tinch panel, doim ko‘rinadigan keyingi harakat |
| 22 | Keskin qizil “Noto‘g‘ri” va xira tushuntirish | P1 | Aniq, qo‘llab-quvvatlovchi sarlavha, indigo CTA, izoh scrolli |
| 23 | Til banneri har savolda, javoblar kuchli bevel bilan | P0/P1 | Dars tili bir marta ravshan, keyin ixcham ko‘rsatkich; option holat ikoni |
| 24 | Nazariya manbasi/banner/maskot vertikal joyni egallaydi | P1 | Reader kengligi, type line-height, bitta language notice, source saqlanadi |
| 25 | Nazariya kartasi/alohida fonlar tartibi notekis | P1 | Bir xil teaching surface, barqaror progress/CTA; matn aynan qoladi |
| 26 | Start sheet katta bo‘shliq va taxminiy reward va’dasi xavfi | P1 | Ixcham kontekst, backend reward, title/scroll/safe-area; source label |

## Bosqichli reja

1. **Foundation/P0:** semantik ThemeExtension, 4/8 spacing, typography/radius/
   motion, dark/light kontrast, umumiy button/card/nav/sheet/dialog/input theme,
   loading/retry, UI tilining yaxlitligi, saqlashga mos chiqish copy.
2. **Home/course:** keyingi darsning aniq harakati, ixcham kunlik maqsad,
   o‘qiladigan yo‘l, sinf tanlash va outline/start bottom sheet.
3. **Lesson:** theory reader, yagona content-language izohi, option holatlari,
   xotirjam feedback, ko‘rinadigan CTA, exit/finish/resume regressiyalari.
4. **Qolgan ekranlar:** profil/kalendar/heatmap, liga/vazifalar/mashq,
   settings/onboarding/auth; tor ekran, keyboard, katta shrift va accessibility.

Har bosqich: alohida ko‘rib chiqiladigan commit → analyze + tegishli/to‘liq test
→ shu UI branchga push. Baseline/after widget capture’lari fixture asosida
yaratiladi, haqiqiy telefon rasmlari bilan bir xil deb da’vo qilinmaydi. Capture’lar
private `.dart_tool/uiux-review/` ichida qoladi. Har asosiy ekran light/dark,
UZ/RU/EN, 320–360dp, 200% font, error/loading va semantics bilan tekshiriladi.
Yakunida oddiy debug APK Samsung A12ga **uninstall/data clear qilmasdan**
o‘rnatiladi; mahalliy backend va telefon imkoniyatlari bo‘yicha haqiqiy natijalar
alohida qayd etiladi. Markaziy hujjat egasiga tayyor handoff beriladi; backend
repo branchiga yozilmaydi.

## Natijalar

Bosqich natijalari `docs/uiux/IMPLEMENTATION_REPORT.md`da yuritiladi. Yangi kod
yozilishidan oldingi ma’lum suite: oldingi ikonka bosqichida **181 test**, analyze
toza. Bu yangi taskning yakuniy testi sifatida hisoblanmaydi.
