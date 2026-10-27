# ILM AI — World history worktree

Work in progress, 2026-10-27. Branch: `feat/world-history-curriculum`, based on
Chemistry Flutter `0312ff3108e96e1e3446bdc8c4dcb27fe7ecd37d`.
Backend companion: `../ilm-ai-world-history/` on the matching feature branch.

## Current status

Separate debug/loopback history screen and API are implemented. Grade6§1–41 are
reviewed local-preview lessons:329 cards,241 MCQ,157 objective FRQ. **41/219 ready;
178 remain.** Six books and961 original page images are inventoried;216 numbered
blocks plus three conclusion/review units, with original chapters and ancillary links.
Backend `docs/world_history/CHECKPOINT.md` is the continuation record.

The common ILM source/choice/feedback/completion components, Ilmo and themes are
reused. Six grades, original chapter expansion, bibliography, theory, MCQ, typed
FRQ, self/teacher reflection and account/origin-scoped save/resume are present.
No ordinary `main.dart`, release route, OAuth or other subject feature was changed.

Measured QA:93 history tests, including actual API fixtures for all41 lessons,
320×568/200% light/dark and UZ/RU/EN interface. Current full suite **702 passed**
in03:23; full Flutter analysis **0 issues in101.8s**. Backend QA_REPORT.md records scope.
Widget screenshots were visually inspected;
no real Android/IME/TalkBack run or independent history-teacher approval is claimed.

Batch02–08 add content/fixture coverage; the existing History runtime/UI contract
is unchanged. Large-fixture JSON decoding uses Dio `SyncTransformer` in widget
tests so isolate decoding cannot escape the controlled test async zone; ordinary
application networking remains unchanged. The initial failing§11 FRQ test was
resolved in batch02; all93 targeted/702 full tests pass at the batch08 checkpoint.
Widget lesson-opening helpers resolve each original chapter from catalogue data;
the new third-chapter§21 flow passes without changing production navigation.

## Local QA entrypoint

Backend `scripts/serve_world_history_preview.py` creates a disposable synthetic
loopback sandbox outside Git. Run the Flutter debug entrypoint with its private
defines file, never a literal token in a command or tracked configuration:

```powershell
flutter run -t lib/world_history_preview_main.dart --dart-define-from-file="../ilm-ai-world-history-local-qa/flutter-defines.json" -d chrome --web-port 7366
```

This command is a run instruction, not a claim that a browser/native run occurred.
Debug/explicit loopback guards reject release/remote use. Knowledge remains
reviewed Uzbek; Russian/English UI does not auto-translate historical content.

## Integration requirements

- Reuse Ilmo, theme, source sheets, feedback, completion and the existing common
  ILM learning contract. Preserve Biology 406 and Chemistry 268 lessons and data.
- Provide six grades 6–11, original chapter/topic order and bibliography.
- Keep `jahon_tarixi` separate from the future `ozbekiston_tarixi` course.
  Central Asian content within the supplied grade-6 book must remain included.
- Use server-only deterministic MCQ and explicit-alias objective FRQ. Do not
  automatically grade complex historical opinions or rely on private keys in
  the client. Retain identity/snapshot/expiry/replay and once-only XP rules.
- Keep UZ/RU/EN interfaces. Authored historical content is reviewed Uzbek only;
  no AI translation, Tutor, Explain or live generated feedback.
- Preserve save/resume, source locations and readable feedback. Test 320×568,
  landscape, 200% text, keyboard insets and account changes. No native Android,
  IME or TalkBack success may be claimed without the actual native run.
- Run Flutter analysis and relevant/full regressions for implementation batches.
  Commit and push only this feature branch. No main merge or production deploy.

Original books, full OCR/text, scanned maps/page images, private QA data and
credentials must never be committed. Backend source validators are mandatory;
an unfinished Physics FRQ prototype is not a production capability.
