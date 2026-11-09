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

Earlier profile4c2ab1c and debug22ea794 contain the superseded password UI and
are not final artifacts. Google-only auth/brand/transport and catalogue regression
tests:39 passed, including direct Google dispatch, disabled loading CTA, retry,
light/dark goldens, three languages, large text and absent email screens/routes.
Google callback/PKCE contracts:15 further tests passed in a clean single-file
run; a prior command also named a nonexistent file and is not a passing suite.
Static analysis:No issues found317.0s. Google-only debug APK built196.5s,
installed-r Success onSamsungSM-A125F without data clear. Actual login screenshot
shows one Google CTA and no email/password fields. First direct Google attempt
timed out; warm retry opened Chrome's Google flow and owner completed it below.

APK:`ILM-AI-Staging-GoogleOnly-1.0.3-code4-68d0697-arm64.apk`,139072397bytes,
SHA256`646e8728fba664d40a8c3685fa57a145de9072b1bf584c623e0cedaaf27ab7cf`.
Source68d069705d714a49acf83d40bbd1b3d4a9d27f7e;674ZIPentries scanned,
zero tested credential matches, actual HTTPS staging origin. Initial public
preflight timed out on health/auth; warm exact597b5ac preflight9/9 passed.
Owner completed the third test Google account selection. Actual Learn screen
returned without onboarding; profile shows the existing fresh account state.
Force-stop/reopen restored the authenticated session and selectedPhysics6 path
without another Google prompt or onboarding. No answers/progress were modified.
Temporary USB-awake setting restored to original0 after this QA segment.

Signed Google-only AAB built362.9s from68d0697:
`ILM-AI-1.0.3-code4-GoogleOnly-68d0697-NO-GO.aab`,77582586bytes,
SHA256`7ff6f1823aa0f1f14b78774d1ae59022503bde0ed5d235cc1af35c72cf58bfff`.
Bundletool/JAR signature, approved upload certificate, com.ilmai.app/1.0.3/code4,
exact auth/deletion callbacks, no-backup flags and8 native64-bit ELF16KiB alignment
passed. Bounded known-secret/JWT/credential-format and forbidden-file scan clear.
This is a verified candidate, **not production approval**; no Play upload occurred.
Complete current Google-only Flutter suite: **1428 passed in17:20**, serial,
`release-google-only-full-tests-20261109.log`. The54 focused tests overlap that
suite and are not added to its total. Dart/native implementation remained68d0697
during both builds and the full suite; subsequent changes are documentation only.

Historical49-case auth validation covered the now-removed password experiment;
it is superseded by the54 focused Google-only tests above. Current deadline
coverage is3 tests, including an interceptor stall, transport stall and successful
retry. No assertion or auth/source guard was disabled to produce these results.

Samsung staging source320c7a7 baseline: navigation22.4% over budget, warmed repeat
12.85% on the same source. This is run variation, not a demonstrated improvement.
Cold activity2.579/2.688s; catalogue visibility failed. On2026-11-09 the phone
reconnected and the app still showed loading. Public staging health/catalogue200
in approximately6.9s each; no raw phone logs exported, no fatal/ANR category found
in the bounded inspected log. The complete catalogue request now has an absolute
30s cancellation deadline leading to existing retry UI; actual new-build phone
acceptance is pending. The existing global socket timeout alone was insufficient
to establish bounded startup. Sessions/progress are not cleared on timeout.

Backend deployed runtime597b5ac CI passed5362/75skipped; expanded PG18 CI exposed
fixture errors. Recoverycc239d0 completes83/83 actual coverage gaps:57PostgreSQL,
15sourcePDF,11WindowsACL; plus one SQLite guard control. Full new CI42570996008
pending. Existing Free staging actually Livecc239d0; exact-source9/9 public
HTTPS contracts passed. ProductionLivee97c029/configuration unchanged.
Actual private production backup restore and
migration/import rehearsal preserved46tables/21,346originalrows; production was
read-only and remains unchanged. Details: backend docs/beta/FINAL_READINESS_20261109.md.

**NO-GO** pending final current tests, measured startup/navigation acceptance,
production baseline/migration/deploy approval, current privacy/retention/consent
and Console declarations, exposed operator credential rotation, Play-signed
upgrade. Google-only APK/AAB are built and scanned above; the actual installed
debug APK has current fixes. Old profile4c2ab1c and7a2e37e AAB are superseded.

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
