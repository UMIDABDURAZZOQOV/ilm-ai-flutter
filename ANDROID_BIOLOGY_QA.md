# ILM AI — Windows va haqiqiy Android uchun Biologiya QA

Bu qo‘llanma `feat/biology-curriculum`dagi **backend va Flutter birgalikda** sinalishi uchun.
Yangi ilova `/mobile/skills` API talab qiladi. Eski production backendga yangi APKni
ulash Google/katalog ishlashini tasdiqlamaydi. Ushbu cloud muhitida Android SDK va
haqiqiy telefon yo‘q; native APK/Google sinovi o‘tdi degan da’vo yo‘q.

## 1. Windows kompyuterda alohida lokal backend

Python, Flutter stable, Android Studio/SDK 36, JDK 17 va Android platform-tools
o‘rnatilgan bo‘lsin. Ikkala repozitoriyada ham `feat/biology-curriculum`ni oling;
mavjud lokal o‘zgarishlarni yo‘qotmang. Quyidagi buyruqlar yangi, lokal QA bazasi
uchun; production `.env` yoki haqiqiy DB manzilini ishlatmang.

Backend katalogidagi PowerShell:

```powershell
py -3 -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
$env:ENVIRONMENT = 'development'
$env:AUTH_STORAGE = 'database'
$dbFile = (Join-Path $env:TEMP 'ilm-biology-phone-test.db').Replace('\', '/')
$env:DATABASE_URL = "sqlite:///$dbFile"
$env:MOBILE_PUBLISHED_SUBJECTS = 'biologiya'
$env:MOBILE_OAUTH_REDIRECT_URI = 'http://127.0.0.1:8000/auth/google-callback-mobile'
$env:JWT_SECRET = .\.venv\Scripts\python.exe -c "import secrets; print(secrets.token_urlsafe(48))"
$env:SECRET_KEY = .\.venv\Scripts\python.exe -c "import secrets; print(secrets.token_urlsafe(48))"
.\.venv\Scripts\python.exe scripts/import_biology_curriculum.py --all --apply --database-url $env:DATABASE_URL
.\.venv\Scripts\python.exe -m uvicorn main:app --host 127.0.0.1 --port 8000 --no-access-log
```

Import 406 dars/faoliyat bo‘lishi kerak. Bu yangi SQLite QA bazasi; cloud’dagi
PostgreSQL rehearsal haqiqiy foydalanuvchi bazasining backupi yoki importi emas.
JWT/SECRET qiymatlarini konsolga chiqarmang, yubormang yoki repozitoriyaga yozmang.

Google’ni sinash uchun backendning private `.env`ida haqiqiy `GOOGLE_CLIENT_ID`
va `GOOGLE_CLIENT_SECRET` bo‘lishi kerak. Ular APKga kiritilmaydi. Bu oqim
`flutter_web_auth_2` + backenddagi **Web OAuth client** orqali ishlaydi;
Android native Google Sign-In client ishlatilayotgan deb taxmin qilmang.
Google Console’da sinov Web clientiga aynan
`http://127.0.0.1:8000/auth/google-callback-mobile` redirect URI’ni ruxsat qiling.
Consent screen testing holatida bo‘lsa, sinov Google akkaunti test user bo‘lsin.
Console huquqi/credential mavjud bo‘lmasa, Google login tekshiruvini **bloklangan**
deb qayd eting. Backendni qayta boshlagandan keyin tekshiring.

## 2. Telefonga debug APK

Telefonda USB debuggingni yoqing, USB orqali ulang. Flutter katalogidagi ikkinchi
PowerShell oynasi:

```powershell
flutter doctor -v
adb devices
adb reverse tcp:8000 tcp:8000
python ..\ilm-ai\scripts\check_mobile_backend.py --base-url http://127.0.0.1:8000
flutter pub get
flutter analyze
flutter test
flutter build apk --debug --dart-define=API_URL=http://127.0.0.1:8000 --dart-define=SUBJECTS_ONLY=true --dart-define=BIOLOGY_ONLY=true
adb install -r build\app\outputs\flutter-apk\app-debug.apk
adb shell cmd package resolve-activity --brief -a android.intent.action.VIEW -d "ilmai://auth/callback"
```

`adb reverse` telefonning `127.0.0.1:8000` so‘rovlarini kompyuter backendiga
yetkazadi; USB uzilsa ulanish ham uziladi. `10.0.2.2` faqat Android emulatori
uchun, haqiqiy telefon uchun emas. Oddiy HTTP faqat debug manifestda ruxsatli;
release uchun tasdiqlangan HTTPS staging/production origin kerak.

Readiness skripti faqat barcha endpointlar HTTP200, katalogda faqat `biologiya`,
7 sinfda jami 406 dars/faoliyat va Google PKCE konfiguratsiyasi mavjud bo‘lsa
exit0 beradi. Bu haqiqiy Google login yoki telefon testi o‘tdi degani emas.

`INSTALL_FAILED_UPDATE_INCOMPATIBLE` chiqsa, mavjud APK boshqa sertifikat bilan
imzolangan: avtomatik uninstall qilmang. Bir xil signing key yoki lokal ma’lumotni
saqlash rejasi kerak. `adb install -r` mos sertifikatda lokal ma’lumotni saqlaydi.

## 3. Package va sertifikat

Application ID **`com.ilmai.app`**, Kotlin namespace esa
`com.ilmai.ilm_ai_flutter`; ular turlicha bo‘lishi mumkin. Callback
**`ilmai://auth/callback`**, `singleTop`, pluginning alohida `CallbackActivity`si
va `taskAffinity` override qo‘yilmagan konfiguratsiya saqlangan.

Haqiqiy SHA-1/SHA-256ni o‘z signing faylingizdan oling:

```powershell
cd android
.\gradlew.bat :app:signingReport
cd ..
```

Native Google/Firebase Android client ishlatilsa Console’dagi package va shu
build sertifikati mosligini tekshiring. Debug, upload va Play App Signing
sertifikatlari farq qiladi. Cloud’da signing key yo‘q; SHA qiymati taxmin
qilinmagan. Hosted Web OAuth oqimida asosiy tekshiruv Web client credentiali va
aniq backend redirect URI hisoblanadi.

Release APK faqat mavjud upload keystore va ignored `android/key.properties`
tayyor bo‘lgach yig‘iladi. Gradle key yo‘q bo‘lsa ataylab to‘xtaydi; debug keyga
yashirin fallback yo‘q. Tasdiqlangan HTTPS API manzilini qo‘yib:

```powershell
$apiUrl = 'https://YOUR-APPROVED-STAGING-HOST'
flutter build apk --release --dart-define=API_URL=$apiUrl --dart-define=SUBJECTS_ONLY=true --dart-define=BIOLOGY_ONLY=true
```

Bu buyruq deploy, main merge yoki Play Market nashrini bajarmaydi.

## 4. Telefonda qayd qilinadigan QA

Har bandga telefon modeli, Android versiyasi, APK/backend commitlari va
**PASS / FAIL / BLOCKED** natijasini yozing. Ko‘rilmaganini PASS demang.

1. Cold start → onboarding: faqat Biologiya; 5–11-sinf; eski fan saqlangan
   akkaunt/draft yashirilgan fanga olib bormaydi. Guest tanlovlari login xatosidan
   keyin qoladi; appni yopib qayta ochganda davom etadi.
2. Haqiqiy Google account tanlash, cancel, 2FA va Chrome’dan qaytish. Profil
   yarating; qayta ochganda session tiklansin. `ilmai://` URI’da access/refresh
   token bo‘lmasin. Qayta kirish/refresh va A → logout → B akkauntini tekshiring.
3. Har 5–11-sinfdan birinchi darsni oching: karta → savol → xato/to‘g‘ri
   feedback → natija. Ilmo/ranglar saqlansin; dars/lab/checkpoint 20/10/50 XP
   mavjud qoidasi bo‘yicha, retry esa yana XP bermasin.
4. Appni qayta oching: shu akkaunt progressi va XP saqlansin, streak va kunlik
   maqsad bir xil bo‘lsin. Boshqa akkauntga progress aralashmasin.
5. Airplane mode: katalog/lesson loading chegaralangan, tushunarli xato va retry;
   javob yuborish vaqtida tarmoqni uzing, qayta ulang va qayta yuboring. Sessiya
   oddiy tarmoq xatosidan logout bo‘lmasin, XP takror yozilmasin.
6. 320px ekran, landscape, OS font 200%, TalkBack, Reduce Motion; uzun savol,
   nazariya va feedbackda Continue/retryga yetilsin. Background/resume va telefon
   blokirovkasidan keyin holatni tekshiring.
7. Lab/amaliy mashg‘ulot raqamli tahlil ekanligi ko‘rinsin; ilova haqiqiy tajriba
   bajarilganini da’vo qilmasin. Kurs oxirida mavjud bo‘lmagan 12-sinfga o‘tmasin.

## 5. Qolgan release cheklovlari

Live Google Console sozlamalari, real telefon va production loglari cloud’da
tekshirilmagan. Eski veb practice payloadlarining authoritative grading bilan
avvaldan mavjud nomuvofiqligi alohida rollout bloklovchisidir; veb kodi
o‘zgartirilmagan va xavfsizlik uchun `is_correct`ga ishonish qaytarilmagan.
Production import/migratsiya/deploy, main merge va nashr uchun alohida ruxsat kerak.
