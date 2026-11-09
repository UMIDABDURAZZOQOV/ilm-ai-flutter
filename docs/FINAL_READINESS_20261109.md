# ILM AI1.0.3 readiness checkpoint — not release approval

The existing single primary registration button now opens Google or password
authentication. Google is optional for the mixed-audience app. Existing passwords,
verified provider subjects, server sessions and account-scoped progress are reused;
failed existing-user login never creates a new account. Email-free signup retains
issued tokens; the profile setup state is read using that newly authenticated
owner's bearer, without a previous account's token or refresh retry. Legacy email
verification is used only when explicitly required by the server. Unconfigured
password recovery reports unavailability rather than claiming email was sent.
Modal cancellation and duplicate-submit guards remain. Ilmo and the one primary
CTA are preserved; two changed login goldens were visually inspected light/dark.

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

Owner reports previous Play review approved. Optional password does not itself
establish neutral age handling or parental consent. No audience declaration was
changed. Current staging has no external AI key; verified lesson explanations
remain available. No production, Play, paid-resource or subject-branch action.
