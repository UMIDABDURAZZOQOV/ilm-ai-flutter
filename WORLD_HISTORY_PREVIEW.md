# ILM AI — World history worktree

Work in progress, 2026-10-26. Branch: `feat/world-history-curriculum`, based on
Chemistry Flutter `0312ff3108e96e1e3446bdc8c4dcb27fe7ecd37d`.
Backend companion: `../ilm-ai-world-history/` on the matching feature branch.

## Current status

No history screen, route, endpoint, imported lesson or release is exposed yet.
The source audit covers six supplied grade 6–11 books and 961 decoded pages;
216 numbered source blocks were identified, including three combined grade-10
topics. Final teaching-entry count awaits ancillary/activity inventory.
Backend `docs/world_history/CHECKPOINT.md` is the continuation record.

Initial worktree check: offline dependency resolution succeeded and Flutter
analysis reported 0 issues in 252.3 s. No history widget/native test is claimed;
the history implementation has not been added yet.

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
