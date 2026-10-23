# ILM AI — o‘quvchilar bilan foydalanish sinovi

Bu protokol tayyor; haqiqiy ishtirokchilar bilan sinov hali o‘tkazilmagan.
20–30 o‘quvchini foydalanuvchi jalb qiladi. Agent hech kimga xabar yubormaydi.

## Boshlash

UZ asosiy guruh, RU/EN interfeysini ishlatuvchilar ham qamrab olinadi.
Samsung A12 kabi oddiy Android va kamida yana ikki ekran o‘lchami tanlanadi.
Haqiqiy hisobda tajriba deb progressni sun’iy o‘zgartirmang; ajratilgan beta
hisoblari bilan odatiy o‘qish jarayoni kuzatiladi.

Moderator: «Ilovani sinayapmiz. Sizni baholamaymiz. Nima kutayotganingizni
ovoz chiqarib aytishingiz mumkin». Harakat nomlarini oldindan o‘rgatmang.
To‘xtab qolsa yordamni qayd eting, so‘ng davom etishga yordam bering.

## Vazifalar

| Vazifa | O‘quvchiga aytiladigan topshiriq | Kuzatiladigan natija |
|---|---|---|
| 1 | O‘zingizga mos sinfni tanlab, birinchi darsni toping | Tanlov va asosiy harakatni yordamsiz topishi |
| 2 | Nazariyani o‘qib, savollarga o‘ting | Nazariya/savol bosqichini tushunishi, matn o‘qilishi |
| 3 | Darsdan chiqing va qolgan joyingizdan qayting | Saqlash matnini tushunishi, ayni savol qaytishi |
| 4 | Darsni odatiy ravishda tugating, natijani tushuntiring | Score/XP/vaqt ma’nosini ajrata olishi |
| 5 | Endi qaysi darsni o‘qishingizni ko‘rsating | Keyingi qadam, qulflangan dars sababi ravshanligi |
| 6 | Javoblaringizni ko‘ring, so‘ng til/theme’ni toping | Ikkilamchi amallarni topishi, matnlar kesilmasligi |

## Qayd jadvali

`beta_observations_template.csv`ga ishtirokchi kodini yozing (`P01`, `P02`).
Ism, telefon, token yoki parol yozilmaydi. Har vazifa uchun bajarildi/bajarilmadi,
yordam soni, vaqt, xato bosish va o‘quvchining qisqa izohi qayd qilinadi.
Saqlash/internet uzilishi alohida takrorlanganda qaysi build/API ishlatilgani
yoziladi. Taqdimotdagi fixture tasviri real ishtirokchi dalili o‘rnida ishlatilmaydi.

## Ichki qabul maqsadlari — hali erishilgani tasdiqlanmagan

- Asosiy 1/3/5-vazifalarni qatnashchilarning kamida 80% yordamsiz bajarishi.
- Javob/progress yo‘qolishi va hisob aralashishi bo‘yicha ochiq kritik muammo 0.
- Qaysi tugma bosilishi kerakligini noto‘g‘ri talqin qilishlar tuzatiladi va
  yangi qatnashchida qayta kuzatiladi.
- Kuniga qaytish: birinchi darsni boshlagan real kohortdan keyingi kuni nechasi
  qaytgani hisoblanadi. Testchilar soni, sanalar va denominator ko‘rsatiladi.
  Retention uchun hozircha o‘lchov yoki kafolat yo‘q.

Avval 5 kishidagi kuzatuvlar asosida xatolar tuzatiladi, keyin qolgan guruhda
qayta tekshiriladi. Dizaynning yakuniy bahosi ana shu dalillar bilan yangilanadi.
