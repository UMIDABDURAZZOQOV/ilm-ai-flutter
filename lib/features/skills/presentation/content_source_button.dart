import 'package:flutter/material.dart';
import 'skill_ui.dart';

/// Bibliographic references only; copyrighted PDF pages are never bundled.
class ContentSourceButton extends StatelessWidget {
  final Map<String, dynamic> source;
  final String language;
  final String? referenceLabel;
  final String? sectionTitle;
  final String locatorSeparator;
  const ContentSourceButton({
    super.key,
    required this.source,
    required this.language,
    this.referenceLabel,
    this.sectionTitle,
    this.locatorSeparator = '→',
  });
  @override
  Widget build(BuildContext context) {
    String tr(String uz, String ru, String en) => str3(language, uz, ru, en);
    final printed = (source['printed_pages'] as List? ?? []).join(', ');
    final pdf = (source['pdf_pages'] as List? ?? []).join(', ');
    final section = source['paragraph'];
    final activity = source['activity_kind'];
    final number = source['activity_number'];
    final reference =
        referenceLabel ??
        (section != null
            ? '§$section'
            : activity == 'laboratory'
            ? tr('Laboratoriya $number', 'Лабораторная $number', 'Lab $number')
            : tr('Amaliy $number', 'Практическая $number', 'Activity $number'));
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
                if (sectionTitle != null) ...[
                  const SizedBox(height: 12),
                  Text(sectionTitle!),
                ],
                if (source['chapter_title'] != null) ...[
                  const SizedBox(height: 12),
                  Text(source['chapter_title'] as String),
                ],
                const SizedBox(height: 12),
                Text(
                  tr(
                    '${referenceLabel == null ? 'Paragraf' : 'Manba bo‘limi'}: $reference\nKitobdagi bet: $printed\nPDF sahifasi: $pdf',
                    '${referenceLabel == null ? 'Параграф' : 'Раздел источника'}: $reference\nСтраница учебника: $printed\nСтраница PDF: $pdf',
                    'Section: $reference\nPrinted page: $printed\nPDF page: $pdf',
                  ),
                ),
                if (source['page_scope'] ==
                    'before_first_teaching_heading') ...[
                  const SizedBox(height: 12),
                  Text(
                    tr(
                      'Sahifadagi joy: paragraf sarlavhasidan oldingi bob kirishi.',
                      'Место на странице: введение главы до заголовка параграфа.',
                      'Page location: chapter introduction before the paragraph heading.',
                    ),
                  ),
                ],
                if (source['regions'] is List) ...[
                  const SizedBox(height: 12),
                  if (source['file_name'] is String)
                    Text(source['file_name'] as String),
                  for (final (index, region)
                      in (source['regions'] as List).indexed)
                    Text(
                      '${(source['printed_pages'] as List)[index]} $locatorSeparator PDF ${(source['pdf_pages'] as List)[index]} · ${region == 'left'
                          ? tr('chap sahifa', 'левая страница', 'left page')
                          : region == 'right'
                          ? tr('o‘ng sahifa', 'правая страница', 'right page')
                          : tr('Yakka sahifa', 'Одиночная страница', 'Single page')}',
                    ),
                ],
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
