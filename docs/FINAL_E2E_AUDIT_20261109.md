# Final end-to-end audit checkpoint — not release approval

Isolated branch `qa/final-e2e-audit-20261109`, based on ce1541f. Existing package
com.ilmai.app/1.0.3/code4, Google-only entry, Ilmo, source validation, graders,
account boundaries, progress and subject/grade switching remain.

Reproduced UI-001: catalogue error Column overflowed71px at640×240/200%.
Error body now scrolls within a bounded reading width; retry/settings preserved.
Failing-before regression and screenshot harness live outside release artifacts.
New visual test covers splash/login/welcome/path/loading/error/profile/settings,
subject sheet and deletion/scrolled actions in light/dark and200% text.

Phone exposed UI-002: feedback followed by an identical solution paragraph.
Four pure regressions failed before the fix. Shared presentation helper removes
only an already displayed whole passage after whitespace comparison, retaining
original text/order/objects. Distinct calculations/case/partial passages remain.
Assessment and reviewed explanation UI use it; graders/source evidence/storage
are unchanged. Seven helper tests and a reviewed-sheet widget regression cover it.
Assessment screenshot tests explicitly use synthetic correctness states, not live
graders or NVIDIA; synthetic feedback labels identify the fixture.

First full run after UI-001:1433passed/21m09s. After UI-002,58targeted tests passed;
new final full run is separate and pending. CI now also runs reviewed five-subject
release regressions without real service requests. Final suite/analyze/build and
device results must be recorded before declaring this source accepted.

Backend ffeb4b0 exact CI passed5488cases/11Windows-only skips, no failures, Docker
and isolated PostgreSQL faults.1,381reviewed lessons/12,027questions validated
read-only. Production still Livee97c029/mobile404; staging actualcc239d0 initially
timed out, then exact9/9warm contracts passed. Any follow-up Free staging deploy
has its own receipt and does not update production or mutate its database.

**NO-GO:** real NVIDIA/authenticated rendering/production entitlement, actual
production API/schema/deletion acceptance, mixed-audience mandatory-Google policy,
current privacy/Console declarations, exposed-credential rotation, Play-signed
old-version upgrade and final-device matrix remain open. No paid resources or
production/Play changes authorized. Full evidence reports are in sibling
`ilm-ai-beta-artifacts/FINAL_PRODUCTION_AUDIT.md` and `FINAL_GO_NO_GO.md`.
