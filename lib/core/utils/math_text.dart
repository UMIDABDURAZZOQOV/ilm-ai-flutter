/// Turns raw LaTeX/markdown math into readable plain text so questions and
/// explanations don't show things like `$\frac{x^2+1}{x-1}$`, `*f*(x)` or
/// `2x<sup>2</sup>`. Display-only — never mutate values sent back for grading.
///
///   `$2x+3=x-7$`               -> `2x+3=x-7`
///   `\frac{12}{5}`             -> `12/5`
///   `x^2`, `x^{10}`, `x^{-1}`  -> `x²`, `x¹⁰`, `x⁻¹`
///   `2x<sup>2</sup>`           -> `2x²`
///   `*f*(x)`                    -> `f(x)`
String cleanMath(String input) {
  var s = input;

  // 1. Drop math delimiters.
  s = s.replaceAll(r'$$', '').replaceAll(r'$', '');
  s = s.replaceAll(r'\(', '').replaceAll(r'\)', '').replaceAll(r'\[', '').replaceAll(r'\]', '');

  // 2. \frac{A}{B} -> (A)/(B). Repeat to unwrap simple nesting.
  final frac = RegExp(r'\\frac\s*\{([^{}]*)\}\s*\{([^{}]*)\}');
  for (var i = 0; i < 4 && frac.hasMatch(s); i++) {
    s = s.replaceAllMapped(frac, (m) => '(${m[1]})/(${m[2]})');
  }
  // \sqrt{A} -> √(A)
  s = s.replaceAllMapped(RegExp(r'\\sqrt\s*\{([^{}]*)\}'), (m) => '√(${m[1]})');

  // 3. Common LaTeX commands -> unicode.
  const cmd = {
    r'\times': '×', r'\cdot': '·', r'\div': '÷', r'\pm': '±', r'\mp': '∓',
    r'\leq': '≤', r'\geq': '≥', r'\neq': '≠', r'\le': '≤', r'\ge': '≥', r'\ne': '≠',
    r'\approx': '≈', r'\pi': 'π', r'\theta': 'θ', r'\alpha': 'α', r'\beta': 'β',
    r'\infty': '∞', r'\sqrt': '√', r'\%': '%', r'\left': '', r'\right': '',
    r'\,': ' ', r'\;': ' ', r'\!': '', r'\quad': '  ', r'\ ': ' ',
  };
  cmd.forEach((k, v) => s = s.replaceAll(k, v));

  // 4. Superscripts: x^{...} and x^N (digits/sign) -> unicode superscript.
  s = s.replaceAllMapped(RegExp(r'\^\{([^{}]*)\}'), (m) => _sup(m[1]!));
  s = s.replaceAllMapped(RegExp(r'\^(-?[0-9]+)'), (m) => _sup(m[1]!));
  // <sup>..</sup> / <sub>..</sub>
  s = s.replaceAllMapped(RegExp(r'<sup>(.*?)</sup>', caseSensitive: false), (m) => _sup(m[1]!));
  s = s.replaceAllMapped(RegExp(r'<sub>(.*?)</sub>', caseSensitive: false), (m) => _sub(m[1]!));

  // 5. Markdown emphasis around variables/words: **x** or *x* -> x.
  s = s.replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (m) => m[1]!);
  s = s.replaceAllMapped(RegExp(r'\*(.+?)\*'), (m) => m[1]!);

  // 6. Any leftover braces/backslashes from unhandled commands.
  s = s.replaceAll('{', '').replaceAll('}', '');
  return s.replaceAll(RegExp(r'[ ]{2,}'), ' ').trim();
}

const _supMap = {
  '0': '⁰', '1': '¹', '2': '²', '3': '³', '4': '⁴', '5': '⁵', '6': '⁶', '7': '⁷',
  '8': '⁸', '9': '⁹', '-': '⁻', '+': '⁺', '=': '⁼', '(': '⁽', ')': '⁾', 'n': 'ⁿ',
};
const _subMap = {
  '0': '₀', '1': '₁', '2': '₂', '3': '₃', '4': '₄', '5': '₅', '6': '₆', '7': '₇',
  '8': '₈', '9': '₉', '-': '₋', '+': '₊', '=': '₌', '(': '₍', ')': '₎',
};

// Only convert when every char has a superscript glyph; otherwise keep ^(...)
// so nothing becomes unreadable.
String _sup(String s) {
  if (s.split('').every((c) => _supMap.containsKey(c))) {
    return s.split('').map((c) => _supMap[c]).join();
  }
  return '^($s)';
}

String _sub(String s) {
  if (s.split('').every((c) => _subMap.containsKey(c))) {
    return s.split('').map((c) => _subMap[c]).join();
  }
  return '_($s)';
}
