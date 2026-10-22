# ILM AI — yangi Ilmo launcher ikonkasi

2026-10-23. Ishchi papka: `ilm-ai-flutter-ui`, branch:
`feat/flutter-ui-ux-improvements`.

## Manba va taqqoslash

Yangi rasm avval UI worktree ichida qidirildi; u yerda yo‘q edi. Asl Flutter
papkasidagi `assets/mascot/ilmo_app_icon_new.png.png` faylining **faqat o‘zi**
`assets/mascot/ilmo_app_icon_new.png` nomi bilan nusxalandi. SHA-256:
`13a5e77618906ab89d8f0c48d68dd6b46214f058b2d535ebc778479f76ea67ea`.
Nusxa original bilan baytma-bayt teng; manba qayta saqlanmagan.

| Asset | O‘lcham / holat | Natija |
|---|---|---|
| Oldingi `app_icon.png` | 1024×1024, fonli, yuz maydaroq detalli | O‘z nomida zaxira sifatida saqlandi |
| Oldingi `app_icon_foreground.png` | 1024×1024, shaffof qatlam | O‘z nomida zaxira sifatida saqlandi |
| Yangi `ilmo_app_icon_new.png` | 1254×1254, shaffof, do‘ppi va yuz detallari aniqroq | Tasdiqlangan yangi manba |
| `launcher_icon.png` | 1024×1024, to‘liq indigo fon | Legacy Android / iOS master |
| `launcher_icon_foreground.png` | 1024×1024, shaffof, xavfsiz doira uchun joy qoldirilgan | Android adaptive foreground |
| `artwork/icons/ilm_ai_play_store_512.png` | 512×512, 32-bit sRGB PNG, barcha alpha=255, 183 882 bayt | Play Store uchun tayyor fayl |

Yangi grafika yoki yangi maskot yaratilmagan. Berilgan yuz, do‘ppi, antenna,
quloqlar va ranglarga chizish/retush/rang almashtirish qo‘llanmagan. Faqat to‘liq
shaffof tashqi qator/ustunlar chiqarildi, tomonlar nisbati saqlanib kichraytirildi,
markazga qo‘yildi va fon bilan kompozitsiya qilindi. Juda xira chet piksellari ham
o‘chirilmadi. Shu sabab adaptive ko‘rinishda konservativ bo‘sh joy qoldirilgan.

## Android chegaralari

[Android rasmiy qo‘llanmasi](https://developer.android.com/develop/ui/compose/system/icon_design_adaptive)
asosida 108dp qatlam, 72dp ko‘rinadigan markaziy maydon va 66dp xavfsiz doira
ishlatildi. Yangi foregrounddagi **barcha alpha>0 piksellari** markazdan 31.5185dp
radius ichida; chegara 33dp. Generatsiya qilingan besh Android zichligi ham
alohida testda tekshiriladi. Tayyor qatlamning o‘zida padding borligi uchun
`adaptive_icon_foreground_inset: 0`; ikkinchi marta kichraytirilmaydi.

Indigo fon: **`#2A1F6B`**. Dumaloq burchak, tashqi soya va oldindan kesilgan
maskalar asosiy fayllarga qo‘shilmagan. Doira, squircle, yumaloq kvadrat va
teardrop ko‘rinishlarining 128/64/48px taqqoslashlari
[vizual ko‘rik varag‘ida](launcher_icon_review.png) bor. Bu diagnostik ko‘rinishlar;
OEM qurilmalarining barcha animatsiyalarini tasdiqlaydigan telefon testi emas.

Play Store fayli [Google Play rasmiy talablariga](https://developer.android.com/distribute/google-play/resources/icon-design-specifications)
mos kvadrat, 512×512, 1MBdan kichik va shaffof bo‘lmagan PNG. Play tomonidan
beriladigan burchaklar va soya rasmga pishirilmagan.

## Qayta tayyorlash

Repo ildizida, Pillow o‘rnatilgan Python va loyihadagi Dart bilan:

```powershell
python scripts/prepare_launcher_icon.py
dart run flutter_launcher_icons
python scripts/prepare_launcher_icon.py --finalize-native
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --debug --no-pub
```

`flutter_launcher_icons 0.14.4` / `image 4.3.0`ning average resize operatsiyasi
ayrim o‘lchamlarda bir xil fonni `(42,30,106,254)`gacha yaxlitlashi kuzatildi.
Oxirgi tayyorlash bosqichi shu generator yaratgan **26 ta kvadrat native PNG**ni
bir xil masterdan Pillow/Lanczos orqali yozadi: barcha alpha=255, fon burchaklari
aniq indigo. Adaptive qatlamlar/XML generatorniki bo‘lib qoladi. Kichik 20/29px
rasmlarda yuz yonidagi filtr o‘tishlari normal; test fon burchaklarini va butun
rasmning shaffof emasligini tekshiradi.

[Manifest](launcher_icon_manifest.json) manba, ikki eski zaxira va barcha yakuniy
kvadrat PNGlarning SHA-256 qiymatlarini saqlaydi. Manba hash o‘zgarsa skript
avtomatik davom etmaydi. Qayta generatsiyadan keyin uchala tayyorlash buyrug‘ini
shu tartibda bajarish kerak.

## Qamrov

`pubspec.yaml`dagi faqat launcher konfiguratsiyasi, Android/iOS launcher
resurslari, yangi ikonka fayllari, tayyorlash skripti va tekshiruv/hujjatlar
yangilandi. Asl sakkizta Ilmo PNG hashlarining regression testi saqlangan.
Splash, onboarding, Ilmo emotsiyalari, backend API, darslar, auth va foydalanuvchi
ma’lumotlari kodi o‘zgarmagan. Avvaldan mavjud desktop plugin registrant
o‘zgarishlari ushbu commitga qo‘shilmaydi. Markaziy `ilm-ai/CLAUDE.md`ga yozilmadi.

## Yakuniy tekshiruv

| Tekshiruv | Natija |
|---|---|
| `flutter analyze --no-pub` | **No issues found**, yakuniy run 60.2s |
| `flutter test --no-pub` | **181 passed**, 50s; 169 mavjud + 12 yangi ikonka regressiyasi |
| Asset yaxlitligi | Original 8 PNG va yangi manba hashlarining barchasi saqlangan; 29 hosila PNG manifest bilan teng |
| Vizual ko‘rik | Oldingi/yangi va 4 ta Android maskasi, 128/64/48px ko‘rildi; yuz, do‘ppi, antenna kesilmagan |
| Takroriy generatsiya | Uchala tayyorlash buyrug‘i qayta bajarildi; manifest va barcha 29 hosila PNG hash qiymatlari aynan bir xil |
| Generatsiyadan keyingi targeted test | Ikonka va original Ilmo testlari: **30 passed**, 3s |
| Android debug build | **Built `build/app/outputs/flutter-apk/app-debug.apk`**, Gradle 253.8s |
| APK resurslari | Paket ichidagi 10 launcher PNG piksellari tekshirilgan native manbalar bilan teng |
| Telefon | **Samsung Galaxy A12 / SM-A125F, Android 12, arm64**; `adb install -r`: **Success** |
| Telefon ko‘rinishi | Launcherda yangi Ilmo yuzi, do‘ppi va antenna to‘liq ko‘rildi; [asl o‘lchamdagi kesma](launcher_icon_device.png) |

### Telefon va build dalillari

- Paket o‘zgarmagan: `com.ilmai.app`, `1.0.2` / versionCode `3`, debug.
- Oldingi va yangi APK sertifikat SHA-256 teng:
  `91654ab1a0d72470100401dc4e00f39c9d613dbeec60642c8c7a39bbd71a1776`.
- Tekshirilgan build va **telefonga o‘rnatilgan** APK SHA-256 ham teng:
  `f870df6081e161a5abfa2b211b6916365e975cd7bfc38a457f50aecf60c3383a`.
- Paket UID `10298` va `firstInstallTime=2026-10-21 17:56:08` saqlangan;
  faqat `lastUpdateTime` yangilangan. Uninstall yoki app data clear bajarilmagan.
- To‘liq telefon skrinshotlari, test/build loglari va APK `.dart_tool/` / `build/`
  ichida mahalliy qoladi. Hisobotga faqat ILM AI ikonkasining kesmasi kiritildi.
- Bu launcher QA. Google login, backend, XP yoki haqiqiy darsni qayta sinash
  amalga oshirilmagan. iOS ikonkalari generatsiya/test qilindi; iOS native build
  yoki iPhone sinovi bajarilmadi.

Build muvaffaqiyatli; mavjud `device_info_plus`, `flutter_tts`,
`flutter_web_auth_2` pluginlarining kelgusi Flutter versiyalarida KGP migratsiyasi
haqida ogohlantirishi bor. Bog‘liqliklar ushbu ikonka vazifasida yangilanmadi.
Production deploy, Play Store nashri va `main` merge bajarilmadi.
