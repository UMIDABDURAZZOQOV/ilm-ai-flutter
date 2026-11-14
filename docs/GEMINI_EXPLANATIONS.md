# Gemini result-panel contract

Flutter sends `X-ILM-Study-Help: reviewed-text-v2`. The post-answer panel accepts
only the existing NVIDIA pair or `gemini` / `gemini-3.1-flash-lite`, with checked
question ownership/context, matching grade/result, source references and
complete server provenance. Provider/model mismatches fail closed.

The generated text is labeled with its actual provider. Source-verified fallback
remains distinct. No key, private configuration, account-age override or provider
call is added to Flutter. Existing question-result-only entry, tap-to-open,
cancellation, keyboard layout, XP and progress behavior are preserved.

The old internal widget key is retained for existing regressions; it does not
determine the visible provider or accept arbitrary response models.

Tests: `gemini_explanation_test.dart`, `nvidia_explanation_test.dart`,
`study_help_test.dart`. Synthetic widget tests are not live AI evidence.

Local debug builds must define **both** `API_URL` and `BETA_API_ORIGIN` to the
same loopback origin, plus `INTEGRATED_BETA=true`. Omitting API_URL selects the
production default, correctly rejected by the Beta guard before runApp. Do not
remove that guard to make an incorrectly configured APK open.
