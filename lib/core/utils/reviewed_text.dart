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
