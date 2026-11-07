part of 'math_models.dart';

/// Angles are clockwise from12. Hour hand moves continuously with minutes.
class MathClockReading {
  final int hours, minutes;
  const MathClockReading(this.hours, this.minutes)
    : assert(hours >= 0 && hours < 24),
      assert(minutes >= 0 && minutes < 60);
  int get faceHour => hours % 12 == 0 ? 12 : hours % 12;
  double get hourDegrees => (hours % 12) * 30 + minutes * .5;
  double get minuteDegrees => minutes * 6.0;
  String get label => '$faceHour:${minutes.toString().padLeft(2, '0')}';
}

class _AnalogueClockExplorer extends StatefulWidget {
  const _AnalogueClockExplorer();
  @override
  State<_AnalogueClockExplorer> createState() => _AnalogueClockState();
}

class _AnalogueClockState extends State<_AnalogueClockExplorer> {
  int total = 6 * 60 + 20;
  @override
  Widget build(BuildContext context) {
    final reading = MathClockReading(total ~/ 60, total % 60);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Soatni ikki mil bilan o‘qing'),
            Semantics(
              label:
                  'Vaqt${reading.label}. Qisqa qalin soat mili, uzun ingichka minut mili.',
              child: ExcludeSemantics(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: CustomPaint(painter: _TeachingClockPainter(reading)),
                ),
              ),
            ),
            Semantics(
              liveRegion: true,
              child: Text(
                reading.label,
                key: const ValueKey('teaching-clock-time'),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Text(
              '1 soat = 60 minut. Minut mili 12 tepasida bo‘lsa yangi soatning 0 minuti. Qisqa mil ham oldinga siljiydi.',
            ),
            Text('Soat: ${reading.faceHour}'),
            Slider(
              key: const ValueKey('clock-hours'),
              value: reading.faceHour.toDouble(),
              min: 1,
              max: 12,
              divisions: 11,
              onChanged: (v) =>
                  setState(() => total = v.round() % 12 * 60 + total % 60),
            ),
            Text('Minut: ${reading.minutes}'),
            Slider(
              key: const ValueKey('clock-minutes'),
              value: reading.minutes.toDouble(),
              min: 0,
              max: 55,
              divisions: 11,
              semanticFormatterCallback: (v) => '${(v / 5).round() * 5} minut',
              onChanged: (v) => setState(
                () => total = total ~/ 60 * 60 + (v / 5).round() * 5,
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final d in [-5, 5, 60])
                  OutlinedButton(
                    key: ValueKey('clock-add-$d'),
                    onPressed: () =>
                        setState(() => total = (total + d + 720) % 720),
                    child: Text('$d minut'),
                  ),
              ],
            ),
            const Text(
              'Bu 12 soatli siferblat kunduz yoki tun ekanini o‘zi ko‘rsatmaydi. Sana va vaziyat masala shartida aytiladi.',
            ),
          ],
        ),
      ),
    );
  }
}

class _TeachingClockPainter extends CustomPainter {
  final MathClockReading reading;
  _TeachingClockPainter(this.reading);
  @override
  void paint(Canvas c, Size s) {
    final center = Offset(s.width / 2, s.height / 2),
        r = math.min(s.width, s.height) / 2 - 12;
    Offset at(double degrees, double radius) =>
        center +
        Offset(
              math.cos((degrees - 90) * math.pi / 180),
              math.sin((degrees - 90) * math.pi / 180),
            ) *
            radius;
    c.drawCircle(center, r, Paint()..color = Colors.white);
    c.drawCircle(
      center,
      r,
      Paint()
        ..color = mathIndigo
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    for (int n = 0; n < 60; n++) {
      c.drawLine(
        at(n * 6.0, r * .83),
        at(n * 6.0, r * (n % 5 == 0 ? 0.91 : 0.87)),
        Paint()
          ..color = mathIndigo
          ..strokeWidth = n % 5 == 0 ? 2 : 1,
      );
    }
    void text(String value, Offset p, double font) {
      final t = TextPainter(
        text: TextSpan(
          text: value,
          style: TextStyle(
            fontSize: font,
            color: mathIndigo,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      t.paint(c, p - Offset(t.width / 2, t.height / 2));
    }

    for (int n = 1; n <= 12; n++) {
      text('$n', at(n * 30.0, r * .68), 15);
      text('${n == 12 ? 0 : n * 5}', at(n * 30.0, r * .98), 10);
    }
    c.drawLine(
      center,
      at(reading.hourDegrees, r * .47),
      Paint()
        ..color = mathIndigo
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    c.drawLine(
      center,
      at(reading.minuteDegrees, r * .77),
      Paint()
        ..color = const Color(0xFF0F766E)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    c.drawCircle(center, 4, Paint()..color = mathIndigo);
  }

  @override
  bool shouldRepaint(_TeachingClockPainter old) =>
      old.reading.hours != reading.hours ||
      old.reading.minutes != reading.minutes;
}

String _duration(int minutes) => '${minutes ~/ 60} soat ${minutes % 60} minut';

class _TimeArithmeticExplorer extends StatefulWidget {
  const _TimeArithmeticExplorer();
  @override
  State<_TimeArithmeticExplorer> createState() => _TimeArithmeticState();
}

class _TimeArithmeticState extends State<_TimeArithmeticExplorer> {
  int sample = 0, step = 0;
  @override
  Widget build(BuildContext context) {
    final a = [135, 250, 45, 555][sample], b = [110, 95, 50, 705][sample];
    final result = sample == 1
        ? a - b
        : sample == 3
        ? b - a
        : a + b;
    final operations = [
      '2 soat 15 min + 1 soat 50 min',
      '4 soat 10 min − 1 soat 35 min',
      '45 min + 50 min',
      'O‘sha kuni 9:15 →11:45',
    ];
    final notes = [
      sample == 3
          ? '9:15 — 555 minut,11:45 — 705 minut;bir kunning ichida.'
          : '${_duration(a)} = $a minut; ${_duration(b)} = $b minut.',
      sample == 1
          ? '4 soat 10 min = 3 soat 70 min; 70 − 35 = 35 min, 3 − 1 = 2 soat. $a − $b = $result minut.'
          : sample == 3
          ? '$b − $a = $result minut.'
          : '$a + $b = $result minut. Har 60 minut bir soat.',
      '$result minut = ${_duration(result)}. Qoldiq minut 60 dan kichik.',
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Vaqtni 60 asosida hisoblang'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int i = 0; i < 4; i++)
                  ChoiceChip(
                    key: ValueKey('time-example-$i'),
                    label: Text(operations[i]),
                    selected: sample == i,
                    onSelected: (_) => setState(() {
                      sample = i;
                      step = 0;
                    }),
                  ),
              ],
            ),
            Semantics(
              liveRegion: true,
              child: Text(
                notes[step],
                key: const ValueKey('time-arithmetic-step'),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  key: const ValueKey('time-back'),
                  onPressed: step == 0 ? null : () => setState(() => step--),
                  child: const Text('Oldingi qadam'),
                ),
                FilledButton(
                  key: const ValueKey('time-next'),
                  onPressed: step == 2 ? null : () => setState(() => step++),
                  child: const Text('Keyingi qadam'),
                ),
              ],
            ),
            if (step == 2)
              Text(
                '$result minut = ${_duration(result)}',
                key: const ValueKey('time-arithmetic-result'),
              ),
            const Text(
              'Davomiylik kunning soat ko‘rsatishi bilan bir xil tushuncha emas. Oraliqda sana almashsa yoki tanaffus bo‘lsa, qo‘shimcha ma’lumot kerak.',
            ),
          ],
        ),
      ),
    );
  }
}
