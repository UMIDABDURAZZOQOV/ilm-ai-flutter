# ILM AI Chemistry: local QA preview

## Current checkpoint — batch50, 2026-10-26

260/268 source entries implemented; grade11 §1–25. Five scenarios at
320×568 and200% text scale passed in17s;20 captures visually inspected.
Normality/percent, named-species rate, stipulated rate factors, inverse rate
and equilibrium quotient use existing inputs, feedback and source controls.
Full Flutter601 tests passed in360s; analysis0 issues/627.5s. Fifteen sanitized
actualHTTP fixtures;51 correct answers,255/5100XP preserved→260/5200XP,
+100once,identical completion replay. Comma and exponent variants agree.
The first HTTP precondition found the prior catalog still cached by the old
preview process; no answers had been sent. Restarting only the owned loopback
preview with --resume imported the new index and preserved all prior progress.
All source readiness flags remain false; independent teacher and copy spacing
reviews remain pending. Native Android/IME/TalkBack not certified.

## Historical checkpoint — batch49, 2026-10-26

255/268 source entries implemented; grade11 §1–20. Five scenarios at
320×568 and 200% text scale passed in19s;20 captures visually inspected.
Precipitate balance, density, final solution volume, reaction-specific normality
and percent/molar conversion use existing inputs, feedback and source controls.
Full Flutter596 tests passed in481s; analysis0 issues/72.9s. Fifteen sanitized
actualHTTP fixtures;50 correct answers,250/5000XP preserved→255/5100XP,
+100once,identical completion replay. Comma and exponent variants agree.
The first widget command selected no tests because a private preparation script
was invoked from the wrong directory; corrected preparation preceded the five
passing scenarios. All source readiness flags remain false; independent teacher
and copy spacing reviews remain pending. Native Android/IME/TalkBack not certified.

## Historical checkpoint — batch48, 2026-10-26

250/268 source entries implemented; grade11 §1–15. Five scenarios at
320×568 and 200% text scale passed in18s;20 captures visually inspected.
Hydrolysis, solution roles, phase masses, crystallization balance and total
solution percentage use existing MCQ/FRQ, feedback and source controls.
Full Flutter591 tests passed in467s; analysis0 issues/101.1s. Fifteen sanitized
actualHTTP fixtures;52 correct answers,245/4900XP preserved→250/5000XP,
+100once,identical completion replay. Comma and exponent variants agree.
All source readiness flags remain false; independent teacher and copy spacing
reviews remain pending. Native Android/IME/TalkBack are not certified.
Earlier sections are historical.

## Historical checkpoint — batch47, 2026-10-26

245/268 source entries implemented;grade11§1–10. Five new320×568/200%
scenarios passed in19s;20 captures inspected for gas-particle count,
equivalent volume, CH4 atom count, anion word and carbonate equation feedback.
Current/prior grade11 source locators remain distinct and reachable.
Full Flutter586 tests passed in438s; analysis0 issues/91.7s. Fifteen sanitized
actualHTTP fixtures;64 correct answers,240/4800XP preserved→245/4900XP,
+100once,identical completion replay. Whole-course readiness remains false;
nativeAndroid/IME/TalkBack notcertified. Earlier sections are historical.

## Current checkpoint — batch46, 2026-10-26

240/268 source entries implemented:grades7–10 all mapped entries and grade11
§1–5. Five new320×568/200% scenarios passed in11s;20 captures inspected,
including negative spin, isotope mean, scientific notation and current11/prior10
source locators. Full Flutter581 tests passed in284s; analysis0 issues/247.2s.
The test HTTP adapter now routes grade11 independently. Production navigation
and shared graders retain their contracts. Fifteen sanitized actualHTTP fixtures;
76 answers,235/4700XP preserved→240/4800XP,+100once,identical complete replay.
Whole-course readiness remains false;nativeAndroid/IME/TalkBack notcertified.
All sections below are historical checkpoints;backend CHECKPOINT has full QA.

## Current checkpoint — batch45, 2026-10-26

235/268 source teaching entries implemented in the paired Chemistry backend:
all74 grade7, all59 grade8, all61 grade9, and all41 grade10 entries.
The six grade10 laboratories are guided digital analysis, with no physical
experiment procedures. All whole-course readiness flags remain false.

Six new320×568/200% scenarios passed in34s;24 captures inspected for feedback
scrolling, pinned Continue, and current/prior source page locators. Full Flutter:
576 tests passed in557s; analysis:0 issues in85.9s. Eighteen sanitized public
HTTP fixtures contain catalogs, lessons and post-answer feedback. Backend HTTP
preserved229/4580XP and added62 correct answers/120XP once→235/4700XP.
No nativeAndroid/IME/TalkBack certification or fresh production build is claimed.
Earlier sections below are historical checkpoints. See backend
`docs/chemistry/CHECKPOINT.md` for the current source and regression evidence.

Separate `feat/chemistry-curriculum` branch, based on polished UI444743b.
Normal main.dart, auth, navigation, Biology and Physics files remain intact.
Only the common source sheet gained optional paired printed/PDF/spread labels;
existing references without spread regions retain their presentation.

Grade7 §1 has eight original theory cards, nine MCQ and three short-text FRQ.
All claims/questions/feedback refer to reviewed pages3–8 of the supplied2017
textbook. The five-grade source map is in the backend Chemistry branch under
`docs/chemistry`. Only1/268 source teaching entries is implemented. The other
grades/topics are not advertised as completed courses.

## Run

Start the backend's disposable loopback sandbox using
`scripts/serve_chemistry_preview.py`; see its `docs/chemistry/LOCAL_PREVIEW.md`.
It creates a private, expiring synthetic-account defines file outside Git.

```powershell
flutter run -d chrome --web-hostname=127.0.0.1 --web-port=7358 --target=lib/chemistry_preview_main.dart --dart-define-from-file=C:/Users/Page/Desktop/Projects/ilm-ai-chemistry-local-qa/flutter-defines.json
```

The entrypoint requires debug mode, an explicit preview flag, loopback API and
synthetic token. No release/public/LAN bypass or normal-login change is provided.
Do not commit the defines file or debug web build. Normal Chemistry publication
and shared-engine consolidation require later review; Physics FRQ is unfinished.

## Learning contract

Same source -> theory -> MCQ/FRQ -> feedback -> result conventions. Existing
Ilmo, DuoChoiceCard, ContentSourceButton, LessonFeedbackPanel,
LessonCompletionView and StudyExitDialog are reused. One theory card at a time;
feedback remains scrollable and bounded. Server responses alone determine
correctness, XP/stars, elapsed time and progress. The client has no private keys
or accepted aliases before submission.

Drafts are scoped to account/API/lesson. Request IDs persist before /start;
ambiguous submissions freeze the same payload until retry/reconciliation. Account
changes cancel pending work. Expired attempts require an explicit new attempt.
No AI feature, chemistry formula parser or equation/numeric evaluator is claimed
for this first conceptual topic.

## Evidence

- Final full Flutter suite:473 passed;20 new Chemistry checks included.
- Static analysis:No issues found.
- Separate JavaScript debug web build succeeded (548.5s); existing secure-storage/
  TTS WASM dry-run warnings remain. No WASM or release build is claimed.
- Final label/token rebuild succeeded in120.2s with `--debug --no-wasm-dry-run`.
- The local7358 web server returns HTTP200 for index/main.dart.js. Browser-use
  webview attachment timed out twice; actual browser interaction is unverified.
- Small320px, landscape640x360,200% text,UZ/RU/EN,light/dark and reduced-motion
  widget checks passed. Native phone/TalkBack/IME QA has not been performed.
- Public fixtures came from the real isolated backend API. The private rubric,
  JWT, PDF, OCR and original source-page images are not bundled.
- Ten real widget captures were visually reviewed, then stored as app UI review
  evidence below. These are original app explanations, not textbook page images.

| Screen | Light | Dark |
| --- | --- | --- |
| Theory | [view](docs/chemistry-preview/theory-light.png) | [view](docs/chemistry-preview/theory-dark.png) |
| MCQ | [view](docs/chemistry-preview/mcq-light.png) | [view](docs/chemistry-preview/mcq-dark.png) |
| FRQ | [view](docs/chemistry-preview/frq-light.png) | [view](docs/chemistry-preview/frq-dark.png) |
| Feedback | [view](docs/chemistry-preview/feedback-light.png) | [view](docs/chemistry-preview/feedback-dark.png) |
| Result | [view](docs/chemistry-preview/result-light.png) | [view](docs/chemistry-preview/result-dark.png) |

Replay/once-only XP, strict source validation, SQLite and real PostgreSQL results
are recorded in the backend's `docs/chemistry/QA_REPORT.md`.


## Batch02 ? numerical FRQ

The isolated v2 preview now accepts numeric_value questions with an explicit
fixed unit. It sends the exact bounded value to the server; it never evaluates,
grades or converts units locally. Decimal comma/dot and e notation are supported
server-side; a full text keyboard keeps e/minus available on mobile IMEs.
All475 Flutter tests passed (2m02s); analysis reported no issues (101.3s).
This includes320x568/200% numeric submission using real public backend fixtures.
No native IME/device verification or new browser-build claim is made.


## Batch04 — formulas and equations

The same local v2 flow supports bounded chemical_formula and chemical_equation
input. The server preserves case/subscripts, checks reviewed species and atom
balance, and accepts reordered terms/proportional integer coefficients. No
client grading, reaction prediction or general structural/ionic engine is added.
The UI refuses an attempt for a different requested lesson. Source keys remain
private before submission; feedback and results use shared ILM AI components.

Final full Flutter suite479 passed (2m12s); analysis clean (20.7s). The separate
debug web build against the corrected synthetic sandbox passed183.9s. Fixtures
come from real local API runs and contain no tokens or grading specs. Real HTTP
QA completed16 lessons/172 assessments/320 once-onlyXP. Native phone/IME/TalkBack
and browser interaction are not claimed. Normal app publication remains gated.

Current private QA defines are under
`C:/Users/Page/Desktop/Projects/ilm-ai-chemistry-batch04-final-qa/` (port8898).
Never commit this expiring synthetic token or the compiled private debug build.


## Batch05 — exact source identities

Prior paragraphs, chapter reviews and practical activities retain separate source
buttons with their actual identities/pages. Source dialogs accept optional labels
and topic titles while preserving existing default behavior. Real API fixtures
cover all three source kinds; no keys or tokens are included before answering.

Full Flutter482 tests passed (1m44s), analysis clean (130.9s); final fixture
source tests7 passed (4s), including320x568/200% widget captures inspected by eye.
Fresh backend synthetic HTTP QA:21 lessons/236 questions/420 once-onlyXP, replay
identical. No native/browser/IME/TalkBack QA or fresh web build claimed.

Final private sandbox: `C:/Users/Page/Desktop/Projects/ilm-ai-chemistry-batch05-final-qa/`,
loopback8899. Old immutable sandboxes remain unchanged; never commit QA tokens.
Current course21/268; readiness remains false and source issues stay visible.


## Batch07 — water recognition and feedback provenance

Chemistry supplies the exact source widget to an optional slot in the existing
scrollable common feedback panel. Other users of that component retain their
prior behavior. Water fixtures are real sanitized local API responses; hydrate
notation is a recognition MCQ, not a new parser feature. Source dialogs remain
reachable at320px/200% text for theory80/PDF41:left and feedback82/PDF42:left.
Widget captures were inspected; no native/browser/IME/TalkBack claim.

Final full Flutter484 passed/104s; analyze clean/118.7s. Fresh final backend HTTP:
31 lessons/343 questions/620 once-onlyXP, completion replay identical, private
grading hidden. Earlier immutable attempts remain untouched. Current private
defines: `C:/Users/Page/Desktop/Projects/ilm-ai-chemistry-batch07-final-qa/`,
loopback8900. Never commit tokens/compiled private builds. Course31/268 and all
whole-course ready flags false; see backend source review and checkpoint.


## Batch08 — solution units and prior mass source

Two actual API-payload tests cover source§10/34 alongside§32/91 and fixed mol/l
input at320px/200% text. Exact0,4 is forwarded; the visible unit helper and common
feedback/source dialog are scrollable. No client-side grading/unit conversion
or production widget change. Captures inspected; no native/browser/IME claim.

Full Flutter486 passed/74s; analyze clean/117.8s; final focused recapture2 passed.
Backend208 passed/1 skipped (opt-in PG); HTTP preserved31/620XP then addedfive
lessons/42 questions/100XP,total36/720XP,replay identical. Current private8900
sandbox remains append-compatible with unchanged earlier manifests. Course36/268;
all complete-course flags false. No tokens or compiled private builds are public.
