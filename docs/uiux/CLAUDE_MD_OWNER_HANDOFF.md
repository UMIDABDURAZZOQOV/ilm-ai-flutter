# Markaziy CLAUDE.md egasiga handoff

Backend repozitoriysiga patch avtomatik qo‘llanmagan. Hujjat egasi joriy
branchida quyidagi qaydni mos joyga qo‘shishi mumkin; butun faylni almashtirmang.

Tekshirilgan manba: `ilm-ai`, `feat/biology-curriculum`, `c0f84d0`.
CLAUDE.md SHA256:
`5542ed45fe9d2fbf820f902956cdeb8ccba5fa89b5a2844eb369cae02eff4a62`.
Hash o‘zgarsa, avval yangi fan/backend qaydlarini o‘qing.

## Qo‘shish uchun qayd

```markdown
### 2026-10-23 — Flutter professional UI/UX

Flutter UI worktree: ilm-ai-flutter-ui.
Branch: feat/flutter-ui-ux-improvements. Main bilan avtomatik merge qilinmagan.
26 ta Samsung A12 reference asosida UI_UX_AUDIT.md va to‘rt bosqich bajarildi:
1. Design tokens, kontrast, localized loading/retry va draftga mos exit.
2. Home Continue kartasi, o‘qiladigan dars yo‘li va safe-area sheetlar.
3. Nazariya/savol progressi, variant holatlari, scrollable feedback va read-only
   javob tahlili. Asl dars matni tarjima qilinmadi.
4. Profil/kalendar, liga/vazifalar/amaliyot, settings va onboarding parity.

Backend/DB, outbound API payload, auth kontrakti, Biology 406 darsi, Physics/FRQ
va production konfiguratsiyasi o‘zgarmagan. Original Ilmo PNG va launcher/splash
resurslari saqlangan. Mavjud optional content_language metadatasi o‘qiladi;
lokal draft eski payloadni ham qabul qiladi.

Test va telefon QA dalillari Flutter branchidagi docs/uiux/IMPLEMENTATION_REPORT.md
hamda docs/uiux/SAMSUNG_A12_QA.md da. Telefon/reference tasvirlari maxfiy:
.dart_tool/uiux-review, Git’ga qo‘shilmaydi. Main merge qarori loyiha egasida.
```

Frontend/backend deploy, migratsiya, production flag va Google Console o‘zgarishi
bajarilmagan. Parallel fan commitlarini ushbu UI commitlari bilan aralashtirmang.
