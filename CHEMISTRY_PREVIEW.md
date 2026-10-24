# ILM AI Chemistry: local QA preview

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
