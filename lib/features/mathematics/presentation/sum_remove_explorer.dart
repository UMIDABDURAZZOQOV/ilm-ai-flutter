part of 'math_models.dart';

/// Alternative teaching paths with explicit nonnegative component constraints.
class _SumRemoveExplorer extends StatefulWidget {
  const _SumRemoveExplorer();
  @override
  State<_SumRemoveExplorer> createState() => _SumRemoveExplorerState();
}

class _SumRemoveExplorerState extends State<_SumRemoveExplorer> {
  int sample = 0, route = 0, step = 0;
  static const samples = [(28, 17, 7), (34, 27, 18), (18, 26, 20)];
  @override
  Widget build(BuildContext context) {
    final (a, b, c) = samples[sample];
    final total = a + b, result = a + b - c;
    final expressions = route == 0
        ? ['($a + $b) − $c', '$total − $c', '$result']
        : route == 1
        ? ['($a − $c) + $b', '${a - c} + $b', '$result']
        : ['$a + ($b − $c)', '$a + ${b - c}', '$result'];
    final reasons = [
      route == 0
          ? 'Avval ikkala guruhni jamlang.'
          : 'Ayriluvchi faqat bitta yetarli guruhdan olinadi.',
      route == 0
          ? 'Butundan $c bir marta olinadi.'
          : route == 1
          ? 'Ikkinchi guruh o‘zgarmadi. Qolgan ikki qism jamlanadi.'
          : 'Birinchi guruh o‘zgarmadi. Qolgan ikki qism jamlanadi.',
      'Javob $result. Tekshiruv: $result + $c = $total. Ikkala guruhdan $c tadan olish boshqa hisob bo‘lardi.',
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Yig‘indidan bir marta ayiring'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < samples.length; i++)
                  ChoiceChip(
                    label: Text(
                      '(${samples[i].$1} + ${samples[i].$2}) − ${samples[i].$3}',
                    ),
                    selected: sample == i,
                    onSelected: (_) => setState(() {
                      sample = i;
                      route = 0;
                      step = 0;
                    }),
                  ),
              ],
            ),
            Text(
              'Birinchi guruh $a, ikkinchi guruh $b. Jami $total. Olinadigan qism $c.',
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < 3; i++)
                  ChoiceChip(
                    key: ValueKey('sum-remove-route-$i'),
                    label: Text(['Jamidan', '1-qismdan', '2-qismdan'][i]),
                    selected: route == i,
                    onSelected: (i == 1 && c > a || i == 2 && c > b)
                        ? null
                        : (_) => setState(() {
                            route = i;
                            step = 0;
                          }),
                  ),
              ],
            ),
            if (c > a)
              const Text(
                'Birinchi guruh ayirish uchun yetmaydi. Bu darsda manfiy qoldiq hosil qiladigan yo‘l tanlanmaydi.',
              ),
            if (c > b) const Text('Ikkinchi guruh ayirish uchun yetmaydi.'),
            Semantics(
              liveRegion: true,
              child: Text(
                expressions[step],
                key: const ValueKey('sum-remove-expression'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              'Qadam: ${step + 1} / 3',
              key: const ValueKey('sum-remove-step'),
            ),
            Text(reasons[step]),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  key: const ValueKey('sum-remove-back'),
                  onPressed: step == 0 ? null : () => setState(() => step--),
                  child: const Text('Oldingi qadam'),
                ),
                FilledButton(
                  key: const ValueKey('sum-remove-next'),
                  onPressed: step == 2 ? null : () => setState(() => step++),
                  child: const Text('Keyingi qadam'),
                ),
              ],
            ),
            const Text(
              'Bu original o‘quv modeli; mustaqil savol javobi serverda tekshiriladi.',
            ),
          ],
        ),
      ),
    );
  }
}
