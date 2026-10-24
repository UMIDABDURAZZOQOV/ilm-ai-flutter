/// Portable display spelling for fonts without Unicode sub/superscript glyphs.
/// Source payloads, typed answers and server grading remain unchanged.
String chemistryDisplayText(String text) {
  const sub = '₀₁₂₃₄₅₆₇₈₉';
  const sup = '⁰¹²³⁴⁵⁶⁷⁸⁹⁺⁻⁼⁽⁾';
  const plain = '0123456789+-=()';
  final digits = text
      .replaceAll('→', ' -> ')
      .replaceAllMapped(
        RegExp('[$sub]'),
        (match) => sub.indexOf(match[0]!).toString(),
      );
  return digits.replaceAllMapped(
    RegExp('[$sup]+'),
    (match) =>
        '^(${match[0]!.split('').map((c) => plain[sup.indexOf(c)]).join()})',
  );
}
