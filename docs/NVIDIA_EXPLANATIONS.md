# Optional NVIDIA explanations — local candidate, 2026-11-12

This candidate adds display support for the separate backend text explanation
provider. It does not enable a provider, create an account, configure a key,
change grading/rewards, or authorize release. No live NVIDIA response or Android
inference is accepted yet. Production remains NO-GO.

## Protocol and compatibility

Only the existing checked-question help action opens this UI. Requests retain
the existing JSON schema and negotiate `X-ILM-Study-Help: nvidia-text-v1`.
An old backend can ignore the header and return the existing reviewed fallback;
an old client does not receive a new generated response from the new backend.

The repository rejects a generated response before submission, a context/owner
attempt mismatch, a different grader result, unknown provider/model/usage,
missing HTTP/provenance markers, or references outside the returned evidence.
The UI displays the returned paragraphs unchanged, identifies AI-generated text,
and keeps reviewed explanations available for comparison. Account/question
changes close/cancel the existing sheet as before. Provenance hashes are audit
correlation fields, not cryptographic proof of a remote provider or scientific
truth. Exact quotes and numeric checks on the backend do not prove entailment.

Supported wire model: `meta/muse-glimmer-30b`. Uzbek generation is requested;
actual Uzbek quality and factual explanations require a live subject review.
Keys belong only in the backend's private configuration outside Git. No key or
test-login credential belongs in a Flutter define, asset, APK, or report.

## Verification commands

Run normal `flutter analyze` and `flutter test`; the new tests include both
grader outcomes, five subjects, light/dark themes, invalid provenance, pre-answer
rejection, network retry, and 200% portrait/landscape scrolling.

The sheet measures its actual resized viewport as well as keyboard insets.
When large text or the keyboard leaves little space, header, transcript and
composer scroll together; the existing pinned arrangement remains when it fits.
Two regression cases require the send control to remain hit-testable at200%
text with a240px keyboard inset. The initial landscape case reproduced89px
of vertical overflow; its failure receipt is retained in the local artifacts.

The explicit cross-repository check requires the separately exported accepted
backend fixture. It must fail if that fixture is absent; it does not silently
skip and is not a live AI/Android test:

```powershell
flutter test --no-pub tool/qa/nvidia_backend_contract_test.dart --reporter json `
  --dart-define=NVIDIA_CONTRACT_FILE=C:/path/to/nvidia-backend-contract-20261112.json
```

The fixture contains actual reviewed catalogue questions and exact backend
responses from fake provider transport. It contains synthetic ownership IDs,
no user credentials. Ordinary CI does not depend on a machine-local artifact.

## Delivery boundary

Use an isolated Beta package for local USB testing; preserve the learner's
installed production/Staging data. A successful debug build does not prove
Google sign-in, real inference, a Play-signed upgrade, or release readiness.
The previous source130 AAB does not contain this new UI. New pushes,
staging/production delivery, real database changes, and Play uploads require
separate explicit owner approval.

Backend implementation/setup: the matching `qa/nvidia-explanations-20261112`
backend worktree, `docs/beta/NVIDIA_EXPLANATIONS_SETUP.md`.
Current evidence and remaining gates: beta artifacts
`NVIDIA_AI_LIVE_VERIFICATION.md` and `FINAL_GO_NO_GO.md`.
