import 'package:flutter/material.dart';
import 'skill_ui.dart';

/// Bibliographic references only; copyrighted PDF pages are never bundled.
class ContentSourceButton extends StatelessWidget {
  final Map<String, dynamic> source;
  final String language;
  const ContentSourceButton({
    super.key,
    required this.source,
    required this.language,
  });
  @override
  Widget build(BuildContext context) {
    String tr(String uz, String ru, String en) => str3(language, uz, ru, en);
    final printed = (source['printed_pages'] as List? ?? []).join(', ');
    final pdf = (source['pdf_pages'] as List? ?? []).join(', ');
    final section = source['paragraph'];
    final activity = source['activity_kind'];
    final number = source['activity_number'];
    final reference = section != null
        ? '§$section'
        : activity == 'laboratory'
        ? tr('Laboratoriya $number', 'Лабораторная $number', 'Lab $number')
        : tr('Amaliy $number', 'Практическая $number', 'Activity $number');
    return TextButton.icon(
      icon: const Icon(Icons.menu_book_outlined, size: 18),
      label: Text(
        tr(
          'Manba: $reference · $printed-bet',
          'Источник: $reference · стр. $printed',
          'Source: $reference · p. $printed',
        ),
      ),
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${source['book_title'] ?? ''} · ${source['year'] ?? ''}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text((source['authors'] as List? ?? []).join(', ')),
                if (source['chapter_title'] != null) ...[
                  const SizedBox(height: 12),
                  Text(source['chapter_title'] as String),
                ],
                const SizedBox(height: 12),
                Text(
                  tr(
                    'Paragraf: $reference\nKitobdagi bet: $printed\nPDF sahifasi: $pdf',
                    'Параграф: $reference\nСтраница учебника: $printed\nСтраница PDF: $pdf',
                    'Section: $reference\nPrinted page: $printed\nPDF page: $pdf',
                  ),
                ),
                for (final segment
                    in (source['source_segments'] as List? ?? [])
                        .whereType<Map>()) ...[
                  const SizedBox(height: 12),
                  Text('${segment['file_name']}'),
                  Text(
                    tr(
                      'Qism ichidagi PDF sahifasi: ${(segment['segment_pdf_pages'] as List? ?? []).join(', ')}',
                      'Страница PDF внутри части: ${(segment['segment_pdf_pages'] as List? ?? []).join(', ')}',
                      'PDF page within this part: ${(segment['segment_pdf_pages'] as List? ?? []).join(', ')}',
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  tr(
                    'Tushuntirish va savollar darslikdagi bilimlar asosida ILM AI uchun qayta tuzilgan.',
                    'Объяснения и вопросы составлены для ILM AI на основе знаний из учебника.',
                    'The explanations and questions were independently written for ILM AI using the textbook as a factual source.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
