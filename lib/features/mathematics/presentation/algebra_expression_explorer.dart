part of 'math_models.dart';

class _AlgebraExpressionExplorer extends StatefulWidget {
  final String mode;
  const _AlgebraExpressionExplorer({required this.mode});
  @override
  State<_AlgebraExpressionExplorer> createState() =>
      _AlgebraExpressionExplorerState();
}

class _AlgebraExpressionExplorerState
    extends State<_AlgebraExpressionExplorer> {
  int leftA = 31,
      leftB = 12,
      rightA = 25,
      rightB = 11,
      expression = 0,
      variable = 4,
      partA = 4,
      partB = 5,
      x = 4;
  int? guess;
  @override
  void didUpdateWidget(_AlgebraExpressionExplorer old) {
    super.didUpdateWidget(old);
    if (old.mode != widget.mode) {
      leftA = 31;
      leftB = 12;
      rightA = 25;
      rightB = 11;
      expression = 0;
      variable = 4;
      partA = 4;
      partB = 5;
      x = 4;
      guess = null;
    }
  }

  Widget live(String s, String key) => Semantics(
    liveRegion: true,
    child: Text(
      s,
      key: ValueKey(key),
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
    ),
  );
  Widget slider(
    String key,
    int value,
    int maximum,
    String label,
    ValueChanged<int> change,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('$label: $value'),
      Slider(
        key: ValueKey(key),
        value: value.toDouble(),
        min: 0,
        max: maximum.toDouble(),
        divisions: maximum,
        semanticFormatterCallback: (v) => '$label ${v.round()}',
        onChanged: (v) => setState(() => change(v.round())),
      ),
    ],
  );
  Widget bars(int left, int right, int limit) => Semantics(
    label: 'Chap $left, o‘ng $right; bir xil sonli masshtab',
    child: ExcludeSemantics(
      child: SizedBox(
        height: 90,
        width: double.infinity,
        child: CustomPaint(painter: _ExpressionBarsPainter(left, right, limit)),
      ),
    ),
  );
  String comparison(int a, int b) => a == b
      ? '='
      : a > b
      ? '>'
      : '<';
  String meaning(int a, int b) => a == b
      ? 'Ikkala qiymat teng.'
      : a > b
      ? 'Chap qiymat kattaroq.'
      : 'Chap qiymat kichikroq.';
  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    if (widget.mode == 'algebra_compare_sums') {
      final left = leftA + leftB, right = rightA + rightB;
      rows.addAll([
        const Text(
          'Har ikki tomonni avval to‘liq hisoblang. Bu bir xil birlikdagi sonli model; rasmga qarab haqiqiy buyum massasini taxmin qilmaymiz.',
        ),
        slider(
          'sums-left-a',
          leftA,
          40,
          'Chap birinchi qism',
          (v) => leftA = v,
        ),
        slider(
          'sums-left-b',
          leftB,
          40,
          'Chap ikkinchi qism',
          (v) => leftB = v,
        ),
        slider(
          'sums-right-a',
          rightA,
          40,
          'O‘ng birinchi qism',
          (v) => rightA = v,
        ),
        slider(
          'sums-right-b',
          rightB,
          40,
          'O‘ng ikkinchi qism',
          (v) => rightB = v,
        ),
        bars(left, right, 80),
        live(
          '$leftA + $leftB = $left; $rightA + $rightB = $right',
          'sum-values',
        ),
        live('$left ${comparison(left, right)} $right', 'sum-relation'),
        Text('${meaning(left, right)} Farq: ${(left - right).abs()} birlik.'),
      ]);
    } else if (widget.mode == 'algebra_expression_kind') {
      const expressions = ['9 + 7', 'a + 7', '20 − 6', '15 − a'];
      final letter = expression == 1 || expression == 3;
      final value = switch (expression) {
        0 => 16,
        1 => variable + 7,
        2 => 14,
        _ => 15 - variable,
      };
      rows.addAll([
        const Text(
          'Ifodani tanlang: unda harf bormi yoki faqat son va amal belgilarimi? Keyin sonli qiymatini tekshiring.',
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < expressions.length; i++)
              ChoiceChip(
                label: Text(expressions[i]),
                selected: expression == i,
                onSelected: (_) => setState(() {
                  expression = i;
                  guess = null;
                }),
              ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < 2; i++)
              ChoiceChip(
                label: Text(i == 0 ? 'Sonli' : 'Harfiy'),
                selected: guess == i,
                onSelected: (_) => setState(() => guess = i),
              ),
          ],
        ),
        if (guess != null)
          Text(
            guess == (letter ? 1 : 0)
                ? 'Mos: ${letter ? 'a harfi bor, bu harfiy ifoda.' : 'harf yo‘q, bu sonli ifoda.'}'
                : 'Yozuvda a harfi bor-yo‘qligini qayta tekshiring.',
          ),
        if (letter)
          slider(
            'expression-a',
            variable,
            15,
            'Berilgan a qiymati',
            (v) => variable = v,
          ),
        if (letter)
          Text(
            expression == 1
                ? 'a + 7 = $variable + 7'
                : '15 − a = 15 − $variable',
          ),
        live(
          '${expressions[expression]} ning qiymati: $value',
          'expression-value',
        ),
        const Text(
          'Harfning qiymati shartdan olinadi. a harfi doim 1 degani emas; ifoda yozuvi bilan uning sonli qiymati farqlanadi.',
        ),
      ]);
    } else if (widget.mode == 'algebra_parts_variables') {
      final whole = partA + partB;
      rows.addAll([
        const Text(
          'Bir xil birlikdagi ikki qism: a va b. Butun c. Qiymatlarni almashtirib, jami va teskari ayirishlarni tekshiring.',
        ),
        slider('parts-a', partA, 20, 'a qism', (v) => partA = v),
        slider('parts-b', partB, 20, 'b qism', (v) => partB = v),
        Semantics(
          label: 'a $partA, b $partB, butun c $whole',
          child: ExcludeSemantics(
            child: SizedBox(
              height: 70,
              width: double.infinity,
              child: CustomPaint(painter: _VariablePartsPainter(partA, partB)),
            ),
          ),
        ),
        live('a = $partA; b = $partB; c = $whole', 'parts-values'),
        Text('c = a + b: $partA + $partB = $whole'),
        Text('a = c − b: $whole − $partB = $partA'),
        Text('b = c − a: $whole − $partA = $partB'),
        const Text(
          'Butun shu ikki qismdan tuzilgan. Harfning qiymati o‘zgarsa, sonli hisob ham yangilanadi. Javobda qaysi qism so‘ralganini o‘qing.',
        ),
      ]);
    } else {
      final left = x + 4, right = 12 - x;
      rows.addAll([
        const Text(
          'Ikkala ifodaga ham ayni x ni qo‘yamiz. x faqat 0–12 oralig‘ida, shuning uchun 12 − x manfiy bo‘lmaydi.',
        ),
        slider('value-x', x, 12, 'x nomzodi', (v) => x = v),
        Text('Chap: x + 4 = $x + 4 = $left'),
        Text('O‘ng: 12 − x = 12 − $x = $right'),
        bars(left, right, 16),
        live('$left ${comparison(left, right)} $right', 'variable-relation'),
        Text(meaning(left, right)),
        if (left == right)
          const Text(
            'Shu x ikkala tomonni teng qildi. Nomzod ikkala ifodada tekshirildi.',
          ),
        const Text(
          'Nol qo‘shilganda qiymat teng qoladi. Qat’iy kattalik yoki kichiklik uchun shartlarni tekshiring.',
        ),
      ]);
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        ),
      ),
    );
  }
}

class _ExpressionBarsPainter extends CustomPainter {
  final int left, right, limit;
  _ExpressionBarsPainter(this.left, this.right, this.limit);
  @override
  void paint(Canvas c, Size s) {
    final u = (s.width - 24) / limit;
    final pen = Paint()
      ..color = mathIndigo
      ..strokeWidth = 1;
    for (final y in [20.0, 60.0]) {
      c.drawLine(Offset(12, y + 16), Offset(s.width - 12, y + 16), pen);
    }
    if (left > 0) {
      c.drawRect(
        Rect.fromLTWH(12, 8, left * u, 28),
        Paint()..color = mathIndigo,
      );
    }
    if (right > 0) {
      c.drawRect(
        Rect.fromLTWH(12, 48, right * u, 28),
        Paint()..color = mathTurquoise,
      );
    }
  }

  @override
  bool shouldRepaint(_ExpressionBarsPainter old) =>
      old.left != left || old.right != right || old.limit != limit;
}

class _VariablePartsPainter extends CustomPainter {
  final int a, b;
  _VariablePartsPainter(this.a, this.b);
  @override
  void paint(Canvas c, Size s) {
    final u = (s.width - 24) / 40;
    if (a > 0) {
      c.drawRect(Rect.fromLTWH(12, 15, a * u, 28), Paint()..color = mathYellow);
    }
    if (b > 0) {
      c.drawRect(
        Rect.fromLTWH(12 + a * u, 15, b * u, 28),
        Paint()..color = mathTurquoise,
      );
    }
    c.drawLine(
      const Offset(12, 48),
      Offset(12 + (a + b) * u, 48),
      Paint()
        ..color = mathIndigo
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_VariablePartsPainter old) => old.a != a || old.b != b;
}
