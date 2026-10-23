# Samsung A12 — tab o‘tishlarini o‘lchash va yengillashtirish

2026-10-23. Faqat UI feature branchi; app/backend kontraktlari o‘zgarmagan.

## Boshlang‘ich o‘lchov

Galaxy A12, Android 12, display’dan o‘qilgan **60Hz**, **720×1600**, density
**1.875**. Arm64 profile/AOT, lokal QA API. Qurilmadagi APK hash tekshirildi.

Flutter SDK 3.44.6 `SchedulerBinding._profileFramePostEvent` yuboradigan
`Flutter.Frame` VM extension eventlari ishlatildi: `build`, `raster`, `elapsed`,
`vsyncOverhead` qiymatlari mikrosekundlarda. VM service mavjud SDK klienti bilan
ADB tunnel orqali o‘qildi; app source’iga telemetry qo‘shilmadi. Tunnel yakunda
olib tashlanadi. Auth/VM URI va xom loglar private `.dart_tool/`da qoladi.

Scenario: beshta tab oldindan ochiladi; keyin ikkita nav aylanishi va home
ro‘yxatida yuqoriga/pastga scroll. Video frame rate hisoblanmaydi; idle vaqtga
bo‘lingan «o‘rtacha FPS» chiqarilmaydi.

Boshlang‘ich profile SHA256: `dc3d40940d0326dd33e6c45714d9f028f0784a6a408a8a63188f9a7956bf5e7e`.
280 frame: UI p95 **14.543ms**, raster p95 **36.572ms**; UI yoki raster
16.67ms’dan oshgan **59/280** frame. PSS snapshot **172.1 → 190.0MB**.
Bu single-device kuzatuv; warm-up, GPU cache, tarmoq va tashqi faoliyat
natijaga ta’sir qiladi. Memory leak yoki barcha ekranlar benchmarki emas.

## Koddagi o‘zgarish

- `IlmTabView`ning butun Stack/gate wrapperlarini har frame qayta yaratadigan
  `AnimatedBuilder`i chiqarildi. Endi `Offstage`, focus, semantics va input
  tuzilmasi faqat tab yoki input chegarasi o‘zgarganda yangilanadi.
- Alpha `FadeTransition` orqali render qatlamida boshqariladi. Static child
  `RepaintBoundary` ichida qoladi; offset uchun kichik builder ishlaydi.
- 260ms o‘tishning dastlabki 30% qismida eski sahifa o‘chadi; keyingi 70%da
  yangi sahifa paydo bo‘ladi. Bir vaqtda ikkita to‘liq sahifa alpha bilan
  chizilmaydi. 12/8dp yo‘nalishli harakat, rapid retarget, RTL saqlangan.
- Input ko‘rinish yetarli bo‘lganda ochiladi. Outgoing tab focus/semantics/input
  olmaydi. Barcha visited elementlar va scroll/cache saqlanadi.
- Reduce Motion bir zumda o‘tadi; nav ikonlari/selection oldingi dizaynda.

Yangi regression testi static `Offstage` widget identity’lari frame o‘rtasida
o‘zgarmasligini va 28 ta sample’da bir vaqtda ko‘pi bilan bitta sahifa
alpha’si musbat bo‘lishini tekshiradi. Navigation suite **22 passed**.
Yakuniy to‘liq suite **370 passed** (`--concurrency=1`, framework **260s**),
analyze **No issues found**, **184.2s**. Arm64 profile build **337.9s**.
Frozen optimized APK SHA256:
`cd03c2cb9e5fbc5f313ed82a3fae82632cc5260a36971690b82b9ca4434c8f42`.

## Takrorlashdagi nazorat

Keyingi profiling scripti boshlanishi va oxirida telefondagi APK hashini
tekshiradi. Bitta takroriy baseline urinishida fon runner’i boshqa APK
o‘rnatgani sabab input yuborilmadi va yangi o‘lchov olinmadi; eski nusxa
`performance-discarded-baseline-2` deb belgilandi. U yangi benchmark sifatida
ishlatilmaydi. Dastlab VS Code Flutter run jarayoniga tegilmadi. Foydalanuvchi
aniq ruxsat bergach, eski PID allaqachon tugagani va ayni VS Code oynasidagi
runner yangi PID bilan qayta ishlagani tekshirildi. Faqat qurilma, lokal API,
`flutter run` buyrug‘i va VS Code ajdodi mos kelgan shu runner to‘xtatildi.
Biroq terminal runnerni yana ishga tushirdi va APK o‘zgardi; bu urinishda
collector ulanmagan, natija chiqarilmadi. Xuddi shu ruxsat asosida terminalning
yagona child’i aynan Samsung/local-API `flutter run` ekanligi tekshirilib,
faqat shu alohida terminal va uning cmd/Dart runneri yakunlandi. VS Code
ilovasi, boshqa runner, daemon va branchlar saqlandi.

## Bir xil scenario’dagi nazorat baseline’i

Qayta o‘rnatilgan B profile APK’si capture boshida va oxirida hash orqali
tekshirildi. **285** haqiqiy frame; bu `performance-baseline-controlled`
capture’i yuqoridagi 280 frame’li dastlabki kuzatuvdan alohida.

| Ko‘rsatkich | p50 | p95 | p99 | max |
|---|---:|---:|---:|---:|
| UI build | 3.219ms | 8.988ms | 19.773ms | 22.959ms |
| Raster | 8.385ms | 29.782ms | 72.427ms | 86.218ms |

16.67ms’dan oshgan: **53/285 (18.6%)**. PSS snapshot **171.2 → 223.0MB**.
Bu run valid; UID, original install time va draft hash teng, app error
logida fatal/unhandled/overflow **0**. Sinf, hisob va dars javoblari
o‘zgartirilmadi. Keyingi C o‘lchovlari shu scenario bilan solishtiriladi.

## Optimallashtirilgan C — ikkita yakuniy capture

Yuqoridagi frozen C APK qayta `install -r` qilindi; AOT `libapp.so`, kernel
yo‘qligi, package va avvalgi signing certificate tekshirildi. Har capture
boshida va oxirida qurilmadagi hash aynan C bilan teng. Bitta 60Hz Samsung,
o‘sha ruscha light UI, 6-sinf va o‘sha oldindan ochilgan besh tab scenario’si.

| Ko‘rsatkich | Nazorat B | C, 1-run | C, 2-run |
|---|---:|---:|---:|
| Haqiqiy frame | 285 | 309 | 302 |
| UI p50 | 3.219ms | 3.484ms | 3.639ms |
| UI p95 | 8.988ms | 8.826ms | 6.651ms |
| UI p99 | 19.773ms | 19.579ms | 21.047ms |
| Raster p50 | 8.385ms | 8.504ms | 8.363ms |
| Raster p95 | 29.782ms | 18.311ms | 17.402ms |
| Raster p99 | 72.427ms | 28.393ms | 24.295ms |
| Raster max | 86.218ms | 49.842ms | 28.457ms |
| UI yoki raster >16.67ms | 53/285 (18.6%) | 30/309 (9.7%) | 29/302 (9.6%) |
| PSS oldin → keyin | 171.2 → 223.0MB | 172.8 → 186.2MB | 185.1 → 187.1MB |

Ushbu kuzatuvda raster p95 **38.5–41.6%** pastroq, budget’dan oshgan frame
ulushi taxminan yarmiga kamaygan. UI p50 biroz yuqori; barcha ko‘rsatkichlar
yaxshilandi deb aytilmaydi. Ikkinchi run warm cache’dan ham foyda olishi mumkin.
Sample’lar umumiy scenario’ga tegishli; alohida tab natijasi sifatida
taqsimlanmagan. Statistically controlled yoki ko‘p qurilmali benchmark emas.

UID, firstInstallTime va mavjud draft mazmunining hash’i har o‘rnatish/capture
ortidan teng. Har ikkala final run va yakuniy logda fatal/unhandled/overflow
**0**. Oxirida Learn ochiq, hisob, til/theme va sinf saqlangan; javob/XP,
dars start/complete yuborilmagan. Yakuniy telefon APK’si **C**.

Raster p95 hali 16.67ms budget’dan yuqori va outlier’lar bor. Shuning uchun
«hamma holatda 60 FPS», «10/10» yoki umumiy release performance signoff
berilmaydi. Cold startup, haqiqiy release, uzun nazariya/quiz oqimlari,
uzoq memory/thermal/battery va boshqa qurilmalar qolgan QA doirasida.
Bu bosqich kodidagi test/analyze toza, telefon tekshiruvi muvaffaqiyatli.
