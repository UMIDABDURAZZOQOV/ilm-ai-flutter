import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart' show languageProvider;
import '../../auth/application/auth_controller.dart' show currentUserIdProvider;
import '../data/studio_repository.dart';

String _tr(String lang, String uz, String ru, String en) =>
    lang == 'ru' ? ru : lang == 'en' ? en : uz;

/// Semantic search over the learner's materials.
class StudioSearchScreen extends ConsumerStatefulWidget {
  const StudioSearchScreen({super.key});
  @override
  ConsumerState<StudioSearchScreen> createState() => _StudioSearchScreenState();
}

class _StudioSearchScreenState extends ConsumerState<StudioSearchScreen> {
  final _ctrl = TextEditingController();
  bool _busy = false;
  SearchResult? _result;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final userId = ref.read(currentUserIdProvider);
    final q = _ctrl.text.trim();
    if (userId == null || q.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final r = await ref.read(studioRepositoryProvider).search(userId, q);
      if (mounted) setState(() => _result = r);
    } catch (_) {
      if (mounted) setState(() => _result = const SearchResult(results: [], noMaterials: false));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final lang = ref.watch(languageProvider);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.text),
        title: Text(_tr(lang, 'Daftaringizni qidirish', 'Поиск по заметкам', 'Search your notes'),
            style: TextStyle(color: colors.text, fontWeight: FontWeight.w700)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  onSubmitted: (_) => _run(),
                  decoration: InputDecoration(
                    hintText: _tr(lang, 'Nimani qidiryapsiz?', 'Что ищете?', 'What are you looking for?'),
                    filled: true,
                    fillColor: colors.card,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _busy ? null : _run,
                style: IconButton.styleFrom(backgroundColor: colors.primary),
                icon: _busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.search_rounded, color: Colors.white),
              ),
            ]),
            const SizedBox(height: 16),
            if (_result != null && _result!.noMaterials)
              Text(_tr(lang, 'Avval material yuklang.', 'Сначала загрузите материал.', 'Upload material first.'),
                  style: TextStyle(color: colors.warning)),
            if (_result != null && !_result!.noMaterials)
              Expanded(
                child: _result!.results.isEmpty
                    ? Center(child: Text(_tr(lang, 'Mos parcha topilmadi.', 'Ничего не найдено.', 'No matching passages.'),
                        style: TextStyle(color: colors.textSecondary)))
                    : ListView.separated(
                        itemCount: _result!.results.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final h = _result!.results[i];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colors.card,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: colors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Icon(Icons.description_outlined, size: 13, color: colors.textSecondary),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text(h.filename, style: TextStyle(color: colors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600))),
                                  Text('${(h.score * 100).round()}%', style: TextStyle(color: colors.primary, fontSize: 11, fontWeight: FontWeight.w700)),
                                ]),
                                const SizedBox(height: 6),
                                Text(h.text, style: TextStyle(color: colors.text, fontSize: 13, height: 1.4)),
                              ],
                            ),
                          );
                        },
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Shared screen for the markdown-producing tools (cheat sheet, translate).
class StudioMarkdownScreen extends ConsumerStatefulWidget {
  final String kind; // 'cheat' | 'translate'
  const StudioMarkdownScreen({super.key, required this.kind});
  @override
  ConsumerState<StudioMarkdownScreen> createState() => _StudioMarkdownScreenState();
}

class _StudioMarkdownScreenState extends ConsumerState<StudioMarkdownScreen> {
  bool _busy = false;
  String? _md;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    final userId = ref.read(currentUserIdProvider);
    final lang = ref.read(languageProvider);
    if (userId == null) return;
    setState(() { _busy = true; _error = null; });
    try {
      final repo = ref.read(studioRepositoryProvider);
      final md = widget.kind == 'translate'
          ? await repo.translate(userId, lang)
          : await repo.cheatSheet(userId, lang);
      if (mounted) setState(() => _md = md);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().contains('no_materials') ? 'no_materials' : 'failed');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final lang = ref.watch(languageProvider);
    final title = widget.kind == 'translate'
        ? _tr(lang, 'Tarjima + tushuntirish', 'Перевод + объяснение', 'Translate & explain')
        : _tr(lang, 'Bir sahifa shpargalka', 'Шпаргалка', 'Cheat sheet');
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.text),
        title: Text(title, style: TextStyle(color: colors.text, fontWeight: FontWeight.w700)),
        actions: [
          if (_md != null && !_busy)
            IconButton(onPressed: _generate, icon: Icon(Icons.refresh_rounded, color: colors.textSecondary)),
        ],
      ),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(
                        _error == 'no_materials'
                            ? _tr(lang, 'Avval material yuklang.', 'Сначала загрузите материал.', 'Upload material first.')
                            : _tr(lang, 'Bo\'lmadi — qayta urinib ko\'ring.', 'Не удалось.', 'Couldn\'t generate it.'),
                        textAlign: TextAlign.center, style: TextStyle(color: colors.textSecondary)),
                      const SizedBox(height: 14),
                      OutlinedButton(onPressed: _generate, child: Text(_tr(lang, 'Qayta', 'Заново', 'Retry'))),
                    ]),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.border),
                    ),
                    child: Text(_md ?? '', style: TextStyle(color: colors.text, fontSize: 14, height: 1.5)),
                  ),
                ),
    );
  }
}
