/// Remove only whole reviewed passages already visible, preserving their text,
/// order and original objects. This is presentation, never grading or storage.
Iterable<T> distinctReviewedText<T>(
  Iterable<T> rows,
  String Function(T) text,
) sync* {
  final shown = <String>[];
  for (final row in rows) {
    final normalized = text(row).trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty ||
        shown.any(
          (prior) => prior == normalized || prior.endsWith(' $normalized'),
        )) {
      continue;
    }
    shown.add(normalized);
    yield row;
  }
}

String assessmentFeedbackText(
  String feedback,
  Iterable<String> solutionBodies,
) => distinctReviewedText([
  feedback,
  ...solutionBodies,
], (text) => text).map((text) => text.trim()).join('\n\n');

/// Keep every distinct explanation passage; the answer is already rendered.
/// Only an exact whole passage (optionally with the known retry preface) is
/// redundant. Never compare substrings, ignore case, or simplify formulas.
String explanationAfterCorrectAnswer(String explanation, String answer) {
  String normalized(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ');
  final shown = normalized(answer);
  if (shown.isEmpty) return explanation;
  return explanation
      .split(RegExp(r'\n\s*\n'))
      .where((passage) {
        var content = normalized(passage);
        for (final prefix in ['Yana o‘ylab ko‘r:', "Yana o'ylab ko'r:"]) {
          if (content.startsWith(prefix)) {
            content = content.substring(prefix.length).trim();
            break;
          }
        }
        return content != shown;
      })
      .join('\n\n');
}
