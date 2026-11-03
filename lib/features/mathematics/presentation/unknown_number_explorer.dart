part of 'math_models.dart';

class _UnknownNumberExplorer extends StatefulWidget {
  final String mode;
  const _UnknownNumberExplorer({required this.mode});
  @override
  State<_UnknownNumberExplorer> createState() => _UnknownNumberExplorerState();
}

class _UnknownNumberExplorerState extends State<_UnknownNumberExplorer> {
  int known = 3;
  bool reveal = false;
  @override
  void didUpdateWidget(_UnknownNumberExplorer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode) {
      known = 3;
      reveal = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final add = widget.mode == 'missing_addend';
    final sub = widget.mode == 'missing_subtrahend';
    final missing = add || sub ? 8 - known : 4 + known;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              add
                  ? 'Noma’lum qo‘shiluvchi'
                  : sub
                  ? 'Noma’lum ayriluvchi'
                  : 'Noma’lum kamayuvchi',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              add
                  ? '□ + $known = 8'
                  : sub
                  ? '8 − □ = $known'
                  : '□ − $known = 4',
              style: const TextStyle(fontSize: 24),
              semanticsLabel: add
                  ? 'Noma’lum songa $known qo‘shsak sakkiz'
                  : sub
                  ? 'Sakkizdan noma’lum sonni ayirsak $known'
                  : 'Noma’lum sondan $known ni ayirsak to‘rt',
            ),
            Text(
              add
                  ? 'Yig‘indi 8, ma’lum qo‘shiluvchi $known.'
                  : sub
                  ? 'Kamayuvchi 8, ayirma $known.'
                  : 'Ayirma 4, ayriluvchi $known.',
            ),
            Slider(
              value: known.toDouble(),
              min: 0,
              max: add || sub ? 8 : 6,
              divisions: add || sub ? 8 : 6,
              semanticFormatterCallback: (v) => 'Ma’lum had ${v.round()}',
              onChanged: (v) => setState(() {
                known = v.round();
                reveal = false;
              }),
            ),
            FilledButton(
              onPressed: () => setState(() => reveal = true),
              child: const Text('Qanday topishni ko‘r'),
            ),
            if (reveal) ...[
              Text(
                add || sub ? '8 − $known = $missing' : '4 + $known = $missing',
              ),
              Text(
                add
                    ? 'Butundan ma’lum qismini oldik. Tekshirish: $missing + $known = 8.'
                    : sub
                    ? 'Butundan qolgan qismini oldik. Tekshirish: 8 − $missing = $known.'
                    : 'Qolgan bilan olinganni birlashtirdik. Tekshirish: $missing − $known = 4.',
              ),
            ] else
              const Text(
                'Qaysi had noma’lum? Butunni tiklash kerakmi yoki butundan qismni ajratishmi?',
              ),
          ],
        ),
      ),
    );
  }
}
