# ILM AI — ommaviy relizdan oldingi UX tekshiruvi

2026-10-23. Bu hujjat reliz berildi degan tasdiq emas.

## Mavjud dalillar

- Flutter UI alohida feature branchda, production/backend/DB o‘zgarmagan.
- Asl Ilmo/launcher va 406 Biologiya darsi saqlangan.
- Light/dark, uch til, 200% shrift, tor/landscape ekran, save/retry/resume
  izolyatsiyalangan widget/API fixture testlari bilan qamrab olingan.
- Samsung A12 debug/lokal API tekshiruvi haqiqiy release/OAuth sinovi bilan
  tenglashtirilmaydi.

## Egasi ishtirokida bajariladigan tekshiruvlar

| Tekshiruv | Hozirgi holat | Kerakli dalil |
|---|---|---|
| Release imzosi | Bu UI worktree’da `android/key.properties` yo‘q | Egasining upload keystori bilan muvaffaqiyatli release/AAB |
| Production API oqimi | Source default URL saqlangan | Release’da login → dars → exit/resume → completion → profil |
| Google OAuth | Haqiqiy interaktiv login bu bosqichda bajarilmagan | Console/SHA/redirect bilan egasi kirib-chiqib tekshirishi |
| Sekin/uzilgan internet | Avtomatik error/retry testlari bor | Release telefonda offline/reconnect, sekin tarmoq va qaytish |
| TalkBack | Semantics testlari bor | Haqiqiy screen reader bilan asosiy vazifalarni bajarish |
| Qurilmalar | Samsung A12 real, boshqa o‘lchamlar widget test | Kamida yana ikki real Android ekranida asosiy oqim |
| Tezlik va resurs | Lazy ro‘yxat va A12 profile/AOT frame timing bor; [dalillar](TAB_PERFORMANCE.md) | Release/startup, barcha muhim ekranlar va uzoq memory sinovi |
| O‘quvchi sinovi | Protokol va CSV tayyor | Haqiqiy qatnashchilar kuzatuvi va tuzatishdan keyingi qayta sinov |

Imzolash cheklovi kodda mavjud: release kalitisiz build to‘xtaydi; debug kalit
bilan production chiqarish uchun bu himoya o‘chirilmaydi. Kalit qiymatlari
hujjatga, logga yoki Git’ga kiritilmaydi. Play Console, production deploy va main
merge alohida qaror sifatida qoladi.
