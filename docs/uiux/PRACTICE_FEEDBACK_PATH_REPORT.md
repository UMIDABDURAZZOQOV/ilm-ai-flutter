# Practice, answer feedback and long learning paths

2026-10-23. Branch `feat/flutter-ui-ux-improvements`, implementation baseline
`7506a60`. This change addresses the three issues identified in the phone images.

## Practice hierarchy

`PracticeHubScreen` replaces three equally prominent large cards with one daily
challenge card and a shared group of two compact rows for mistakes and timed
practice. Existing localized descriptions and all three route/mode callbacks
remain. No question count, duration, availability or reward is invented.
The original Ilmo is a small companion in the primary card, omitted at large
text sizes to leave room for the words. Secondary rows have full-width touch
targets and natural text wrapping.

## Answer feedback

`LessonFeedbackPanel` is now a separate, shared presentation widget, still
exported from `lesson_widgets.dart` for its existing callers. Both lessons and
practice use it without changing their grading, attempt, save or retry logic.

The 72 logical pixel mascot column was replaced by a 36 pixel mascot beside
the status heading. Explanation and correct-answer text use the full reading
width. A short correct answer can sit beside its label; longer answers wrap.
The original review hint, save error, and disabled-while-saving action remain.
The panel shrinks to its content, is bounded to 42% of the viewport, and scrolls
its explanation when necessary. Continue stays outside that scroll. Reduce
Motion uses a static saving indicator. At the reviewed normal phone viewport,
all four answer choices remain visible in the wrong-answer capture.

## Long learning paths

`LearningPathSections` holds only local display state. The current server-open
unit starts expanded; other units are collapsed. With no open action, the first
unit is expanded for browsing. Single-unit paths stay open and retain lazy
lesson construction, including the existing 406-lesson scenario.

- Every unit header can expand/collapse and has expanded semantics.
- Completed/total lessons and incomplete-content notices use the existing DTO.
- A pinned section control stays reachable while scrolling a long unit.
- Its sheet lists units and real completion counts, with the current unit marked.
  Empty units show a preparation/empty message instead of a `0/0` completion count.
- Selecting a unit focuses that unit at the top, without starting a lesson.
  The daily goal card stays in the all-sections view.
- All sections and current-section controls provide direct return paths.
- Locked lessons remain inspectable through their original prerequisite sheet.
- The current lesson retains its prominent card; other rows use smaller badges,
  quieter surfaces and less padding. Their complete access state remains in
  semantics, and completed stars remain visible.

State is keyed by account, subject and grade. Visited-tab retention, scroll
storage, pull-to-refresh, lesson entries, checkpoints, draft restore and server
unlock ordering remain. A newly opened current unit expands on a tree update.
Filtering/expansion never writes progress, changes preferences or unlocks content.
Metadata lookup uses lesson/unit maps; only visible lesson widgets are built.

## Verification and review

The existing UZ/RU/EN x light/dark x 320x568/640x360 at 200% journey matrix now
also exercises selecting unit 12 from a lazy picker, current-unit return,
collapse/reopen, all-units return, and all three practice callbacks. The locked
lesson DTO is checked unchanged after navigating to it. Existing lesson-entry,
feedback, account accessibility, OAuth and progress regressions remain.

| Check | Result |
| --- | --- |
| Focused suite with extended interaction coverage | 161 passed (38.3 s wrapper); final full suite also includes the 12-unit picker case. |
| Full suite without updating goldens | 453 passed, exit 0 (409.2 s wrapper). |
| `flutter analyze --no-pub` | No issues found, exit 0 (187.5 s analyzer, 195.4 s wrapper). |
| Final capture review | 2 tests passed, 48 mock renders (58.0 s wrapper). |
| Original assets | All 20 asset hashes unchanged. |
| Lesson/checkpoint entry handlers | Compared with baseline; unchanged. |

Mock review uses a 360x800 logical phone viewport, rendered at 720x1600.
It does not represent native system bars or a new hardware performance run.
The final gallery includes focused, collapsed and picker states in both themes.

Review images:

- Practice: [light](reading-polish/light-practice.png), [dark](reading-polish/dark-practice.png).
- Incorrect feedback: [light](reading-polish/light-feedback.png), [dark](reading-polish/dark-feedback.png).
- Correct feedback: [light](reading-polish/light-correct.png), [dark](reading-polish/dark-correct.png).
- Path overview: [light](reading-polish/light-home.png), [dark](reading-polish/dark-home.png).
- Focused section: [light](reading-polish/light-focused-section.png), [dark](reading-polish/dark-focused-section.png).
- Section picker: [light](reading-polish/light-section-picker.png), [dark](reading-polish/dark-section-picker.png).

The first eight files are before/after comparisons. The last four show the new
navigation states. They contain isolated fixture data, with no real account PII.

Before/after baselines for the affected screens come from the unchanged
`6d29d4e` review renders; the intervening `7506a60` changed authentication only.
The user photographs are not copied into the repository.

Local capture/gallery folders:
`.dart_tool/uiux-review/reading/` and
`.dart_tool/uiux-review/comparisons/reading/`.
Recompose with:
`python scripts/compare_uiux_captures.py --stage reading --baseline polish`.

## Android artifact

The final arm64 profile APK built successfully (Gradle 347.5 s, wrapper 352.8 s).
It is frozen locally at
`.dart_tool/reading-polish/ilm-ai-reading-profile-arm64.apk` (62.0 MB reported by Flutter).
SHA-256: `a74b3e72ad44bd6cad929078b063cae14eda720cbbee39f1dcd18b1de0a8ffd1`.

The source digest snapshot was checked before and after building. App and test
sources match the verified 204-file Dart snapshot. The APK is a development
profile build using the existing local `http://127.0.0.1:8000` API setup; a phone
needs the local backend and ADB reverse for port 8000. It is not a production
release artifact. It was not installed over the connected development session.
The binary and private logs stay out of Git. No new native frame-timing or
real-account usability result is claimed.

## Scope

Changed production files are the three new presentation components plus
`subject_home_screen.dart`, `skill_path_screen.dart`,
`learning_journey_widgets.dart` and the feedback re-export in
`lesson_widgets.dart`. The journey test, capture fixture, relevant home goldens,
comparison utility, report and handoff document are updated.

No backend, API/DTO, curriculum text, grading, XP, auth, token, original asset or
native launcher change is included. The seven pre-existing platform registrant
changes belong to other work and are excluded. The connected phone is not signed
out or cleared, and no running Flutter development session is stopped.
