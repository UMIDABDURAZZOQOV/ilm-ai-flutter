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
