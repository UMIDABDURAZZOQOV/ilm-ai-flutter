part of 'math_models.dart';

class _QuantityPracticeExplorer extends StatefulWidget {
  final String mode;
  const _QuantityPracticeExplorer({required this.mode});
  @override
  State<_QuantityPracticeExplorer> createState() =>
      _QuantityPracticeExplorerState();
}

class _QuantityPracticeExplorerState extends State<_QuantityPracticeExplorer> {
  int amount = 2, from = 0, to = 1, selected = 0, step = 0, split = 0;
  bool swapped = false, onlyFilled = true;
  List<int> volumes = [8, 0, 0];
  final seen = <int>{};
  final order = <String>[];
  String? note;
  @override
  void didUpdateWidget(_QuantityPracticeExplorer old) {
    super.didUpdateWidget(old);
    if (old.mode != widget.mode) {
      amount = 2;
      from = 0;
      to = 1;
      selected = 0;
      step = 0;
      split = 0;
      swapped = false;
      onlyFilled = true;
      volumes = [8, 0, 0];
      seen.clear();
      order.clear();
      note = null;
    }
  }

  Widget result(String s, String key) => Semantics(
    liveRegion: true,
    child: Text(
      s,
      key: ValueKey(key),
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
    ),
  );
  Widget choice(List<String> labels) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (var i = 0; i < labels.length; i++)
        ChoiceChip(
          label: Text(labels[i]),
          selected: selected == i,
          onSelected: (_) => setState(() {
            selected = i;
            step = 0;
          }),
        ),
    ],
  );
  Widget slider(String key, int max, String label) => Slider(
    key: ValueKey(key),
    value: amount.toDouble(),
    min: 0,
    max: max.toDouble(),
    divisions: max,
    semanticFormatterCallback: (v) => '$label ${v.round()}',
    onChanged: (v) => setState(() => amount = v.round()),
  );
  Widget litres(int filled) => Wrap(
    spacing: 5,
    runSpacing: 5,
    children: [
      for (var i = 0; i < 20; i++)
        Semantics(
          label: '${i + 1}-bo‘lak, ${i < filled ? '1 lbor' : 'bo‘sh'}',
          child: ExcludeSemantics(
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: i < filled ? mathTurquoise : Colors.transparent,
                border: Border.all(color: mathIndigo),
              ),
            ),
          ),
        ),
    ],
  );
  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    if (widget.mode == 'quantity_mass_batches') {
      children.addAll([
        const Text('Shart: har ishlovda 4 kg. Ishlovlar sonini tanla.'),
        slider('quantity-batch-count', 5, 'Ishlov'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < amount; i++) const Chip(label: Text('4 kg')),
          ],
        ),
        result('$amount ishlov: ${amount * 4} kg', 'quantity-batch-total'),
        Text(
          amount == 0
              ? 'Hali ishlov yo‘q:0 kg.'
              : "${List.filled(amount, '4').join(' + ')} = ${amount * 4} kg",
        ),
        const Text(
          '4 kgaynan shu shartda berilgan;har bir ishlov bitta guruh.',
        ),
      ]);
    } else if (widget.mode == 'quantity_litre_addition') {
      final total = 6 + amount;
      children.addAll([
        const Text('Boshlang‘ich 6 lsuv. Qo‘shilgan suv yo‘qotilmaydi.'),
        slider('quantity-added-litres', 10, 'Qo‘shilgan litr'),
        result('6 + $amount = $total litr', 'quantity-litre-total'),
        const Text('Har rangli bo‘lak 1 lni bildiradi;20 bo‘lakli son modeli.'),
        litres(total),
        Text(
          'Hozir$total litr; model sig‘imi 20 l. Sig‘im hozirgi miqdor degani emas.',
        ),
      ]);
    } else if (widget.mode == 'quantity_capacity_content') {
      final current = 12 - amount, free = 20 - current;
      children.addAll([
        const Text('Sig‘im 20 l. Dastlab ichida 12 lsuv,20 lemas.'),
        slider('quantity-removed-litres', 12, 'Olingan litr'),
        result(
          'Qolgan: $current litr; bo‘sh joy: $free litr',
          'quantity-capacity-state',
        ),
        litres(current),
        Text('12 − $amount = $current; 20 − $current = $free.'),
        const Text(
          'Rangli/bo‘sh bo‘laklar 1 ldan. Ikkala qism sig‘im 20 lni to‘ldiradi.',
        ),
      ]);
    } else if (widget.mode == 'quantity_conserving_pour') {
      const caps = [8, 5, 3], names = ['A', 'B', 'C'];
      children.add(
        const Text(
          'Ato‘la 8 l,B 5 lvaC 3 lidishlar bo‘sh. Yerga tashlama; idish to‘lguncha yoki manba bo‘shaguncha quy.',
        ),
      );
      for (var i = 0; i < 2; i++) {
        children.add(Text(i == 0 ? 'Qayerdan?' : 'Qayerga?'));
        children.add(
          DropdownButton<int>(
            key: ValueKey('quantity-pour-$i'),
            value: i == 0 ? from : to,
            isExpanded: true,
            items: [
              for (var j = 0; j < 3; j++)
                DropdownMenuItem(
                  value: j,
                  child: Text(
                    '${names[j]}: ${volumes[j]}l / ${caps[j]}lsig‘im',
                  ),
                ),
            ],
            onChanged: (n) {
              if (n != null) {
                setState(() {
                  if (i == 0) {
                    from = n;
                  } else {
                    to = n;
                  }
                  note = null;
                });
              }
            },
          ),
        );
      }
      children.addAll([
        FilledButton(
          onPressed: () => setState(() {
            if (from == to) {
              note = 'Ikki idish turli bo‘lsin.';
              return;
            }
            final n = math.min(volumes[from], caps[to] - volumes[to]);
            volumes[from] -= n;
            volumes[to] += n;
            note = '$n litr ko‘chirildi.';
          }),
          child: const Text('Quyish'),
        ),
        if (note != null) Text(note!),
        result(
          'A:${volumes[0]}l; B:${volumes[1]}l; C:${volumes[2]}l',
          'quantity-pour-state',
        ),
        Text('Jami: ${volumes.reduce((a, b) => a + b)} litr'),
        if (volumes[1] == 2)
          const Text('B da 2 l ajraldi. Suv yo‘qolmadi va sig‘imdan oshmadi.'),
        OutlinedButton(
          onPressed: () => setState(() {
            volumes = [8, 0, 0];
            note = null;
          }),
          child: const Text('Qaytadan'),
        ),
      ]);
    } else if (widget.mode == 'quantity_commutative_units') {
      const units = ['kg', 'litr', 'cm'];
      children.addAll([
        choice(['Qutilar (kg)', 'Alohida idishlar (l)', 'Kesmalar (cm)']),
        Text(
          'Alohida yangi misol:7${units[selected]}va 4${units[selected]}jamlanadi.',
        ),
        SwitchListTile(
          title: const Text('Qo‘shiluvchilarni almashtirish'),
          value: swapped,
          onChanged: (v) => setState(() => swapped = v),
        ),
        result(
          '${swapped ? 4 : 7} + ${swapped ? 7 : 4} = 11 ${units[selected]}',
          'quantity-commutative-result',
        ),
        const Text(
          'Bir xil miqdor qismlarining tartibi o‘zgardi,jami saqlandi. Misollar orasida birlikni konvertatsiya qilganimiz yo‘q.',
        ),
      ]);
    } else if (widget.mode == 'quantity_unknown_components') {
      const questions = [
        '24 l + 13 l = ?l',
        '?dm + 7 dm = 29 dm',
        '14 kg + 5 kg = ?kg',
        '30 cm + ?cm = 38 cm',
      ];
      const solutions = [
        '24 + 13 = 37 litr',
        '29 − 7 = 22 dm',
        '14 + 5 = 19 kg',
        '38 − 30 = 8 cm',
      ];
      children.addAll([
        choice(['Litr', 'Detsimetr', 'Kilogramm', 'Santimetr']),
        Text(questions[selected]),
        FilledButton(
          onPressed: () => setState(() => seen.add(selected)),
          child: const Text('Ustunni tekshirish'),
        ),
        if (seen.contains(selected))
          result(solutions[selected], 'quantity-table-answer'),
        ExpansionTile(
          title: const Text('Ikki teng shaklga ajrat'),
          children: [
            const Text(
              'Original model: eni 8 cm,bo‘yi 4 cm. O‘lchamlar modelda berilgan.',
            ),
            Wrap(
              spacing: 8,
              children: [
                for (var i = 0; i < 3; i++)
                  ChoiceChip(
                    label: Text(['Tik', 'Yotiq', 'Diagonal'][i]),
                    selected: split == i,
                    onSelected: (_) => setState(() => split = i),
                  ),
              ],
            ),
            Semantics(
              label: [
                'Ikki 4 cmli kvadrat',
                'Ikki eni 8 cm bo‘yi 2 cm to‘rtburchak',
                'Ikki mos uchburchak',
              ][split],
              child: ExcludeSemantics(
                child: SizedBox(
                  height: 150,
                  child: CustomPaint(painter: _EqualPartitionPainter(split)),
                ),
              ),
            ),
            Text(
              [
                '8 cmni 4 va 4 ga bo‘ldik:ikki 4 cmli kvadrat.',
                '4 cmni 2 va 2 ga bo‘ldik:ikki bir xil to‘rtburchak.',
                'Qarama-qarshi uchlar tutashdi:ikki mos uchburchak.',
              ][split],
            ),
          ],
        ),
      ]);
    } else {
      children.add(choice(['Noma’lum qism', 'To‘la va bo‘sh', 'Tartib']));
      if (selected == 0) {
        children.addAll([
          const Text(
            'Jami 25,birinchi 11,ikkinchi 6. Uchinchi sonni taklif qil.',
          ),
          slider('quantity-review-proposal', 15, 'Taklif'),
          result('11 + 6 + $amount = ${17 + amount}', 'quantity-review-sum'),
          Text(
            amount == 8
                ? 'Butun 25 tiklandi.'
                : 'Hali 25 hosil bo‘lmadi;25 dan 17 ni ayirib ko‘r.',
          ),
        ]);
      } else if (selected == 1) {
        children.addAll([
          const Text('6 va 8 ta to‘la,3 ta bo‘sh idish. Litrlar berilmagan.'),
          SwitchListTile(
            title: const Text('Faqat to‘la idishlar'),
            value: onlyFilled,
            onChanged: (v) => setState(() => onlyFilled = v),
          ),
          result(
            onlyFilled ? 'To‘la: 14 ta idish' : 'Barchasi: 17 ta idish',
            'quantity-review-jars',
          ),
          const Text('Idish soni hajm emas. Har idishdagi litr soni kerak.'),
        ]);
      } else {
        children.addAll([
          const Text('D eng kam,B eng ko‘p,C Adan kam. O‘sish tartibini tuz.'),
          Wrap(
            spacing: 8,
            children: [
              for (final id in ['a', 'b', 'c', 'd'])
                if (!order.contains(id))
                  ActionChip(
                    label: Text(id.toUpperCase()),
                    onPressed: () => setState(() => order.add(id)),
                  ),
            ],
          ),
          result(
            order.map((v) => v.toUpperCase()).join(' → '),
            'quantity-review-order',
          ),
          if (order.length == 4)
            Text(
              order.join() == 'dcab'
                  ? 'Barcha shartga mos:D,C,A,B.'
                  : 'Shartlarni yana tekshir:D eng kam,B eng ko‘p,C Adan kam.',
            ),
          OutlinedButton(
            onPressed: () => setState(order.clear),
            child: const Text('Qaytadan'),
          ),
        ]);
      }
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final c in children)
              Padding(padding: const EdgeInsets.only(bottom: 12), child: c),
          ],
        ),
      ),
    );
  }
}

class _EqualPartitionPainter extends CustomPainter {
  final int split;
  const _EqualPartitionPainter(this.split);
  @override
  void paint(Canvas canvas, Size size) {
    final width = math.min(size.width - 20, 260.0),
        height = width / 2,
        rect = Rect.fromLTWH(10, 4, width, height);
    final ink = Paint()
      ..color = mathIndigo
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawRect(rect, Paint()..color = mathYellow.withValues(alpha: .3));
    canvas.drawRect(rect, ink);
    if (split == 0) {
      canvas.drawLine(
        Offset(rect.center.dx, rect.top),
        Offset(rect.center.dx, rect.bottom),
        ink,
      );
    } else if (split == 1) {
      canvas.drawLine(
        Offset(rect.left, rect.center.dy),
        Offset(rect.right, rect.center.dy),
        ink,
      );
    } else {
      canvas.drawLine(rect.topLeft, rect.bottomRight, ink);
    }
  }

  @override
  bool shouldRepaint(_EqualPartitionPainter old) => old.split != split;
}
