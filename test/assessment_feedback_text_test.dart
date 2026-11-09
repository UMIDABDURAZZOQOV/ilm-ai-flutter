import 'package:flutter_test/flutter_test.dart';
import 'package:ilm_ai_flutter/core/utils/reviewed_text.dart';

void main() {
  test('checked feedback does not repeat the identical explanation', () {
    expect(
      assessmentFeedbackText('To‘g‘ri. Tekshirilgan izoh.', [
        'Tekshirilgan izoh.',
      ]),
      'To‘g‘ri. Tekshirilgan izoh.',
    );
  });
  test('duplicate exact steps collapse while distinct steps retain order', () {
    expect(
      assessmentFeedbackText('Natija.', [
        'Birinchi qadam.',
        'Birinchi qadam.',
        'Ikkinchi qadam.',
      ]),
      'Natija.\n\nBirinchi qadam.\n\nIkkinchi qadam.',
    );
  });
  test('whitespace-only repetitions do not take extra feedback space', () {
    expect(
      assessmentFeedbackText('To‘g‘ri. Ikki  qator\nizoh.', [
        'Ikki qator izoh.',
      ]),
      'To‘g‘ri. Ikki  qator\nizoh.',
    );
  });
  test('different calculation and different capitalization are preserved', () {
    expect(
      assessmentFeedbackText('H = 2.', ['H = 2n + 2.', 'h = 2.']),
      'H = 2.\n\nH = 2n + 2.\n\nh = 2.',
    );
  });
  test('empty feedback and steps do not render blank paragraphs', () {
    expect(assessmentFeedbackText(' ', ['', 'Yechim.', ' ']), 'Yechim.');
    expect(assessmentFeedbackText('', []), '');
  });
  test('partial overlaps remain independently visible', () {
    expect(
      assessmentFeedbackText('Birinchi bosqich bajarildi.', [
        'Birinchi bosqich',
        'Keyingi bosqich bajarildi.',
      ]),
      'Birinchi bosqich bajarildi.\n\nBirinchi bosqich\n\nKeyingi bosqich bajarildi.',
    );
  });
  test('retained evidence objects and source references are unchanged', () {
    final first = {
      'text': 'To‘g‘ri. Izoh.',
      'source_refs': [1],
    };
    final duplicate = {
      'text': 'Izoh.',
      'source_refs': [2],
    };
    final next = {
      'text': 'Boshqa qadam.',
      'source_refs': [3],
    };
    final rows = distinctReviewedText([
      first,
      duplicate,
      next,
    ], (row) => row['text'] as String).toList();
    expect(rows, [first, next]);
    expect(identical(rows.first, first), isTrue);
    expect(duplicate['source_refs'], [2]);
  });
}
