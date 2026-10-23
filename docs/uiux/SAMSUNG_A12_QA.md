# Samsung Galaxy A12 — UI tekshiruvi

## Muhit

- Samsung SM-A125F, Android 12, 720×1600 fizik ekran.
- Paket `com.ilmai.app`, versiya `1.0.2+3`, debug build.
- Mavjud lokal backend `/health` HTTP200, `adb reverse tcp:8000 tcp:8000`.
- Production source konfiguratsiyasi o‘zgarmagan. QA build flagi:
  `--dart-define=API_URL=http://127.0.0.1:8000`.
- Yangilash `adb install -r`: uninstall/clear-data ishlatilmaydi.
- Debug sertifikat SHA256:
  `91654ab1a0d72470100401dc4e00f39c9d613dbeec60642c8c7a39bbd71a1776`.

## Takrorlash

```powershell
adb devices -l
adb reverse tcp:8000 tcp:8000
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --debug --no-pub --dart-define=API_URL=http://127.0.0.1:8000
apksigner verify --print-certs build/app/outputs/flutter-apk/app-debug.apk
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell monkey -p com.ilmai.app -c android.intent.category.LAUNCHER 1
```

Lokal hisobotda subprocess return code alohida yoziladi. Mavjud KGP plugin
ogohlantirishi uchun dependency migration keyingi alohida texnik ishdir.

## Qo‘lda tekshirish marshruti

1. Kirilgan hisob saqlanganini tekshirish; loginni qayta so‘rasa, hisobni o‘chirmang.
2. Home’da keyingi darsning asl nomi, Continue va haqiqiy XP; pastga scroll.
3. Outline, grade picker va start sheetni ochish/yopish. Ushbu read-only QA’da
   darsni boshlash/yakunlash shart emas.
4. Practice, quests, league, profile tablari va uzun ro‘yxatda scroll.
5. Kalendar/12 hafta faolligi: serverda yo‘q ma’lumot uydirilmasin.
6. Settings’da light/dark, so‘ng asl rejimni qaytarish. UZ/RU/EN widget testda.
7. Submit/replay fixturelarda tekshiriladi. Real hisobda XP/progressni o‘zgartirish
   uchun dars yuborilmaydi.
8. UID va firstInstallTime yangilashdan oldingi qiymatlar bilan teng bo‘lsin.

Telefon rasmlari `.dart_tool/uiux-review/device/`da faqat lokal saqlanadi.
`before-update.png` — o‘sha paytdagi o‘rnatilgan ilova; uni `aec64b8` Git baseline
bilan tenglashtirmang. Git baseline taqqoslashlari alohida widget fixturelardir.

## Qamrov chegarasi

200% shrift, 320dp/landscape, uch til, reduced motion va semantics widget testlarda.
To‘liq TalkBack foydalanuvchi sinovi, FPS/memory profiling, real Google OAuth,
iOS build va production submit alohida QA talab qiladi; bajarildi deb yozilmaydi.

## Amaldagi telefon natijasi

Build va yangilash muvaffaqiyatli. Hisob/UID/firstInstallTime saqlangan; light/dark,
home, profil, settings, outline va grade picker ko‘rildi. Yakunda avvalgi rejim va
5-sinf qaytarildi. Fatal/unhandled/overflow log belgisi 0.
Aniq hashlar, ikkinchi Flutter run artefakti va qamrov [hisobotda](IMPLEMENTATION_REPORT.md).
