# ILM AI1.0.3 readiness checkpoint — not release approval

## Owner correction: Google-only authentication

The owner's latest instruction supersedes the optional-password experiment.
The single registration CTA opens Google directly for new and returning learners.
Password choice/form, signup, forgot-password and email-verification screens are
removed. Login goldens return to the established Google-only design. Verified
Google subject, PKCE, server sessions, account-scoped progress, duplicate-submit
guard, cancellation, loading and errors remain. Typing an email never authenticates
a Google account. Existing backend contracts/data for older clients are retained;
no account/progress deletion or production configuration change was performed.

Installed profile4c2ab1c and debug22ea794 contain the superseded password UI and
are not final artifacts. Google-only auth/brand/transport and catalogue regression
tests:39 passed, including direct Google dispatch, disabled loading CTA, retry,
light/dark goldens, three languages, large text and absent email screens/routes.
A new Google-only APK, static analysis and device verification are pending.

Focused auth validation:49 passed; catalogue deadline/retry:2 passed. These are
targeted counts, not a current full-suite result. Full current-source suite and
analyze are running. A catalogue stalled-response test exposed a harness clock
issue; the corrected test actually cancels after30s and successfully retries.

Samsung staging source320c7a7 baseline: navigation22.4% over budget, warmed repeat
12.85% on the same source. This is run variation, not a demonstrated improvement.
Cold activity2.579/2.688s; catalogue visibility failed. On2026-11-09 the phone
reconnected and the app still showed loading. Public staging health/catalogue200
in approximately6.9s each; no raw phone logs exported, no fatal/ANR category found
in the bounded inspected log. The complete catalogue request now has an absolute
30s cancellation deadline leading to existing retry UI; actual new-build phone
acceptance is pending. The existing global socket timeout alone was insufficient
to establish bounded startup. Sessions/progress are not cleared on timeout.

Backend runtime597b5ac CI passed5362/75skipped; expanded PG18 CI exposed test
fixture errors. Corrections are on the isolated recovery branch, with further
real PostgreSQL acceptance running. Actual private production backup restore and
migration/import rehearsal preserved46tables/21,346originalrows; production was
read-only and remains unchanged. Details: backend docs/beta/FINAL_READINESS_20261109.md.

**NO-GO** pending final current tests, measured startup/navigation acceptance,
production baseline/migration/deploy approval, current privacy/retention/consent
and Console declarations, exposed operator credential rotation, Play-signed
upgrade and newly built/scanned final APK/AAB. Current source fixes are not yet
installed in the phone's profile APK. Old7a2e37e NO-GO AAB is not final.

Follow-up: cancellation inside a stalled interceptor need not settle a request.
The outer30s Future deadline now guarantees a failure/retry state even before
transport dispatch; all3 deadline regressions passed. This is a later delta to
profile4c2ab1c; its actual installation succeeded with data preserved. Device
auto-lock/screen-off prevents accepting subsequent readiness polling; owner unlock
was requested and no PIN or keyguard bypass was attempted. Do not label these
samples a clean startup acceptance or infer an optimized navigation result.

Owner reports previous Play review approved. Google-only entry is implemented as
requested; the mixed-audience Google sign-in policy review remains an unresolved
release gate. No audience declaration was changed. Current staging has no external AI key; verified lesson explanations
remain available. No production, Play, paid-resource or subject-branch action.
