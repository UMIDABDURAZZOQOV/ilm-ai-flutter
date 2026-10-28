# ILM AI — World history worktree

Work in progress, 2026-10-27. Branch: `feat/world-history-curriculum`, based on
Chemistry Flutter `0312ff3108e96e1e3446bdc8c4dcb27fe7ecd37d`.
Backend companion: `../ilm-ai-world-history/` on the matching feature branch.

## Current status

Separate debug/loopback history screen and API are implemented. Grade6§1–44 plus conclusion and final review are
reviewed local-preview units:361 cards,271 MCQ,175 objective FRQ. **145/219 ready;
74 remain.** Grade7 all44 units add314 cards,298 MCQ and176 objective FRQ. Grade8 all33 units add256 cards,252 MCQ and136 objective FRQ. Grade9§1–22 add154 cards,136 MCQ and94 objective FRQ. Six books and961 original page images are inventoried;216 numbered
blocks plus three conclusion/review units, with original chapters and ancillary links.
Backend `docs/world_history/CHECKPOINT.md` is the continuation record.

The common ILM source/choice/feedback/completion components, Ilmo and themes are
reused. Six grades, original chapter expansion, bibliography, theory, MCQ, typed
FRQ, self/teacher reflection and account/origin-scoped save/resume are present.
No ordinary `main.dart`, release route, OAuth or other subject feature was changed.

Measured QA: **312 history widgets passed in05:32**, **921 full tests passed in07:44**, full analysis **0 issues in104.2s**. Actual API fixtures cover all145 units,
320×568/200% light/dark and UZ/RU/EN interface. Backend QA_REPORT.md records scope.
Widget screenshots were visually inspected;
no real Android/IME/TalkBack run or independent history-teacher approval is claimed.

Batch02–18 add content/fixture coverage; the existing History runtime/UI contract
is unchanged. Large-fixture JSON decoding uses Dio `SyncTransformer` in widget
tests so isolate decoding cannot escape the controlled test async zone; ordinary
application networking remains unchanged. The initial failing§11 FRQ test was
resolved in batch02; all current targeted history tests pass at the batch18 checkpoint.
Widget lesson-opening helpers resolve each original chapter from catalogue data;
the third-chapter§21 and null-chapter conclusion/review flows pass. Grade6
completion can switch to the original grade7 catalogue with44 reviewed lessons
and0 pending units. Grade7 questions/source sheets retain its own book identity;
its FRQ draft survives remount with a distinct lesson-scoped request ID. Ancillary sources
show their real titles, not invented§45/46; review questions retain original
definition pages rather than relabelling184. Production navigation is unchanged.

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
