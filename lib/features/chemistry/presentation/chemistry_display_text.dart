/// Portable display spelling for fonts without Unicode sub/superscript glyphs.
/// Source payloads, typed answers and server grading remain unchanged.
String chemistryDisplayText(String text) {
  const sub = '₀₁₂₃₄₅₆₇₈₉';
  const sup = '⁰¹²³⁴⁵⁶⁷⁸⁹⁺⁻⁼⁽⁾';
  const plain = '0123456789+-=()';
  final digits = text
      .replaceAll('→', ' -> ')
      .replaceAll('⇌', ' <=> ')
      .replaceAllMapped(
        RegExp('[$sub]'),
        (match) => sub.indexOf(match[0]!).toString(),
      );
  final portable = digits.replaceAllMapped(
    RegExp('[$sup]+'),
    (match) =>
        '^(${match[0]!.split('').map((c) => plain[sup.indexOf(c)]).join()})',
  );
  // Roboto does not contain the triple-bond glyph on every target. Keep the
  // source/answer payload intact and explain the ASCII display spelling.
  return portable.contains('≡')
      ? '${portable.replaceAll('≡', '#')} (# — uch bog‘)'
      : portable;
}
