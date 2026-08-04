/// Strips LaTeX math delimiters/commands so questions read plainly instead of
/// showing raw `$2x+3=x-7$`. Display-only — never mutate values that are sent
/// back to the server for grading. Full LaTeX rendering is a future upgrade.
String cleanMath(String s) {
  var r = s.replaceAll(r'$$', '').replaceAll(r'$', '');
  r = r
      .replaceAll(r'\(', '').replaceAll(r'\)', '')
      .replaceAll(r'\[', '').replaceAll(r'\]', '')
      .replaceAll(r'\left', '').replaceAll(r'\right', '')
      .replaceAll(r'\times', '×').replaceAll(r'\cdot', '·')
      .replaceAll(r'\div', '÷')
      .replaceAll(r'\leq', '≤').replaceAll(r'\geq', '≥').replaceAll(r'\neq', '≠')
      .replaceAll(r'\le', '≤').replaceAll(r'\ge', '≥').replaceAll(r'\ne', '≠')
      .replaceAll(r'\pm', '±').replaceAll(r'\pi', 'π')
      .replaceAll(r'\sqrt', '√').replaceAll(r'\infty', '∞')
      .replaceAll(r'\%', '%');
  return r;
}
