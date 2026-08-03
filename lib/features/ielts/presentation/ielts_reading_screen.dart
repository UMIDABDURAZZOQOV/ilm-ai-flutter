import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart' show languageProvider;
import '../data/ielts_models.dart';
import '../data/ielts_repository.dart';
import 'ielts_answer_sheet.dart';

String _tr(String lang, String uz, String ru, String en) =>
    lang == 'ru' ? ru : lang == 'en' ? en : uz;

class IeltsReadingScreen extends ConsumerStatefulWidget {
  const IeltsReadingScreen({super.key});
  @override
  ConsumerState<IeltsReadingScreen> createState() => _IeltsReadingScreenState();
}

class _IeltsReadingScreenState extends ConsumerState<IeltsReadingScreen> {
  List<IeltsReading>? _items;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final r = await ref.read(ieltsRepositoryProvider).listReading();
      if (mounted) setState(() => _items = r);
    } catch (_) {
      if (mounted) setState(() => _error = 'failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final lang = ref.watch(languageProvider);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0, iconTheme: IconThemeData(color: colors.text),
        title: Text(_tr(lang, 'O\'qish', 'Чтение', 'Reading'), style: TextStyle(color: colors.text, fontWeight: FontWeight.w800)),
      ),
      body: _error != null
          ? Center(child: Text(_tr(lang, 'Yuklab bo\'lmadi.', 'Не удалось загрузить.', 'Failed to load.'), style: TextStyle(color: colors.textSecondary)))
          : _items == null
              ? const Center(child: CircularProgressIndicator())
              : _items!.isEmpty
                  ? Center(child: Text(_tr(lang, 'Hozircha material yo\'q.', 'Пока нет материалов.', 'No material yet.'), style: TextStyle(color: colors.textSecondary)))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items!.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final r = _items![i];
                        return InkWell(
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => IeltsReadingPractice(reading: r))),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.border)),
                            child: Row(children: [
                              Container(
                                width: 40, height: 40, alignment: Alignment.center,
                                decoration: BoxDecoration(color: const Color(0xFF22C55E).withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
                                child: Text('${r.section}', style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w800)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(r.title, style: TextStyle(color: colors.text, fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 2),
                                  Text('${r.difficulty}${r.wordCount != null ? ' · ${r.wordCount} ${_tr(lang, 'so\'z', 'слов', 'words')}' : ''}',
                                      style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                                ]),
                              ),
                              Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
                            ]),
                          ),
                        );
                      },
                    ),
    );
  }
}

/// Passage on top, questions below (scroll together).
class IeltsReadingPractice extends ConsumerStatefulWidget {
  final IeltsReading reading;
  const IeltsReadingPractice({super.key, required this.reading});
  @override
  ConsumerState<IeltsReadingPractice> createState() => _IeltsReadingPracticeState();
}

class _IeltsReadingPracticeState extends ConsumerState<IeltsReadingPractice> {
  List<IeltsQuestion>? _questions;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final q = await ref.read(ieltsRepositoryProvider).readingQuestions(widget.reading.id);
      if (mounted) setState(() => _questions = q);
    } catch (_) {
      if (mounted) setState(() => _questions = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final lang = ref.watch(languageProvider);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0, iconTheme: IconThemeData(color: colors.text),
        title: Text(widget.reading.title, style: TextStyle(color: colors.text, fontWeight: FontWeight.w700, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.border)),
            child: Text(widget.reading.passageText, style: TextStyle(color: colors.text, fontSize: 14.5, height: 1.6)),
          ),
          const SizedBox(height: 18),
          Text(_tr(lang, 'Savollar', 'Вопросы', 'Questions'), style: TextStyle(color: colors.text, fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          if (_questions == null)
            const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))
          else
            IeltsAnswerSheet(questions: _questions!, lang: lang),
        ],
      ),
    );
  }
}
