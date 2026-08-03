import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart' show languageProvider;
import '../../auth/application/auth_controller.dart' show currentUserIdProvider;
import '../data/studio_repository.dart';
import 'studio_more_tools.dart' show StudioQuizRunner;

String _tr(String lang, String uz, String ru, String en) =>
    lang == 'ru' ? ru : lang == 'en' ? en : uz;

String _ttsLocale(String lang) => lang == 'ru' ? 'ru-RU' : lang == 'en' ? 'en-US' : 'uz-UZ';

/// Audio recap — a spoken-style script read aloud on-device via TTS.
class StudioAudioRecapScreen extends ConsumerStatefulWidget {
  const StudioAudioRecapScreen({super.key});
  @override
  ConsumerState<StudioAudioRecapScreen> createState() => _StudioAudioRecapScreenState();
}

class _StudioAudioRecapScreenState extends ConsumerState<StudioAudioRecapScreen> {
  final FlutterTts _tts = FlutterTts();
  bool _busy = false;
  bool _speaking = false;
  String? _script;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tts.setCompletionHandler(() { if (mounted) setState(() => _speaking = false); });
    _generate();
  }

  @override
  void dispose() { _tts.stop(); super.dispose(); }

  Future<void> _generate() async {
    final userId = ref.read(currentUserIdProvider);
    final lang = ref.read(languageProvider);
    if (userId == null) return;
    setState(() { _busy = true; _error = null; });
    try {
      final r = await ref.read(studioRepositoryProvider).audioRecap(userId, lang);
      if (mounted) setState(() => _script = r.script);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().contains('no_materials') ? 'no_materials' : 'failed');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleSpeak() async {
    final lang = ref.read(languageProvider);
    if (_speaking) {
      await _tts.stop();
      if (mounted) setState(() => _speaking = false);
      return;
    }
    if (_script == null || _script!.isEmpty) return;
    await _tts.setLanguage(_ttsLocale(lang));
    await _tts.setSpeechRate(0.48);
    setState(() => _speaking = true);
    await _tts.speak(_script!);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final lang = ref.watch(languageProvider);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0, iconTheme: IconThemeData(color: colors.text),
        title: Text(_tr(lang, 'Audio xulosa', 'Аудио-обзор', 'Audio recap'), style: TextStyle(color: colors.text, fontWeight: FontWeight.w700)),
        actions: [if (_script != null && !_busy) IconButton(onPressed: _generate, icon: Icon(Icons.refresh_rounded, color: colors.textSecondary))],
      ),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(error: _error!, lang: lang, onRetry: _generate)
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.border)),
                      child: Text(_script ?? '', style: TextStyle(color: colors.text, fontSize: 15, height: 1.6)),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _toggleSpeak,
                      style: ElevatedButton.styleFrom(backgroundColor: _speaking ? colors.error : colors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      icon: Icon(_speaking ? Icons.stop_rounded : Icons.play_arrow_rounded),
                      label: Text(_speaking ? _tr(lang, 'To\'xtatish', 'Стоп', 'Stop') : _tr(lang, 'Tinglash', 'Слушать', 'Listen'), style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ]),
                ),
    );
  }
}

/// Podcast — a two-host script, read aloud alternating between two TTS voices.
class StudioPodcastScreen extends ConsumerStatefulWidget {
  const StudioPodcastScreen({super.key});
  @override
  ConsumerState<StudioPodcastScreen> createState() => _StudioPodcastScreenState();
}

class _StudioPodcastScreenState extends ConsumerState<StudioPodcastScreen> {
  final FlutterTts _tts = FlutterTts();
  bool _busy = false;
  bool _playing = false;
  int _current = -1;
  String _title = '';
  List<({String speaker, String text})> _turns = [];
  String? _error;

  @override
  void initState() { super.initState(); _generate(); }

  @override
  void dispose() { _tts.stop(); super.dispose(); }

  Future<void> _generate() async {
    final userId = ref.read(currentUserIdProvider);
    final lang = ref.read(languageProvider);
    if (userId == null) return;
    setState(() { _busy = true; _error = null; });
    try {
      final r = await ref.read(studioRepositoryProvider).podcast(userId, lang);
      if (mounted) setState(() { _title = r.title; _turns = r.turns; });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().contains('no_materials') ? 'no_materials' : 'failed');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _play() async {
    final lang = ref.read(languageProvider);
    if (_playing) { await _stop(); return; }
    if (_turns.isEmpty) return;
    setState(() => _playing = true);
    await _tts.setLanguage(_ttsLocale(lang));
    for (var i = 0; i < _turns.length; i++) {
      if (!_playing || !mounted) break;
      setState(() => _current = i);
      // Host A slightly higher & faster, Host B lower & slower — two "voices".
      final isA = _turns[i].speaker.toUpperCase().startsWith('A');
      await _tts.setPitch(isA ? 1.12 : 0.9);
      await _tts.setSpeechRate(isA ? 0.5 : 0.46);
      await _tts.awaitSpeakCompletion(true);
      await _tts.speak(_turns[i].text);
    }
    if (mounted) setState(() { _playing = false; _current = -1; });
  }

  Future<void> _stop() async {
    _playing = false;
    await _tts.stop();
    if (mounted) setState(() { _playing = false; _current = -1; });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final lang = ref.watch(languageProvider);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0, iconTheme: IconThemeData(color: colors.text),
        title: Text(_tr(lang, 'Podkast', 'Подкаст', 'Podcast'), style: TextStyle(color: colors.text, fontWeight: FontWeight.w700)),
        actions: [if (_turns.isNotEmpty && !_busy) IconButton(onPressed: _generate, icon: Icon(Icons.refresh_rounded, color: colors.textSecondary))],
      ),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(error: _error!, lang: lang, onRetry: _generate)
              : Column(children: [
                  if (_title.isNotEmpty)
                    Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: Text(_title, style: TextStyle(color: colors.text, fontSize: 16, fontWeight: FontWeight.w800))),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _turns.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final t = _turns[i];
                        final isA = t.speaker.toUpperCase().startsWith('A');
                        final active = i == _current;
                        return Align(
                          alignment: isA ? Alignment.centerLeft : Alignment.centerRight,
                          child: Container(
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: active ? colors.primary.withValues(alpha: 0.18) : colors.card,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: active ? colors.primary : colors.border, width: active ? 1.6 : 1),
                            ),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(isA ? _tr(lang, 'Boshlovchi A', 'Ведущий A', 'Host A') : _tr(lang, 'Boshlovchi B', 'Ведущий B', 'Host B'),
                                  style: TextStyle(color: isA ? const Color(0xFF06B6D4) : const Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 4),
                              Text(t.text, style: TextStyle(color: colors.text, fontSize: 14, height: 1.4)),
                            ]),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _play,
                        style: ElevatedButton.styleFrom(backgroundColor: _playing ? colors.error : colors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        icon: Icon(_playing ? Icons.stop_rounded : Icons.play_arrow_rounded),
                        label: Text(_playing ? _tr(lang, 'To\'xtatish', 'Стоп', 'Stop') : _tr(lang, 'Eshitish', 'Слушать', 'Play episode'), style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ]),
    );
  }
}

/// Photo → study kit (summary + flashcards + a mini quiz).
class StudioPhotoKitScreen extends ConsumerStatefulWidget {
  const StudioPhotoKitScreen({super.key});
  @override
  ConsumerState<StudioPhotoKitScreen> createState() => _StudioPhotoKitScreenState();
}

class _StudioPhotoKitScreenState extends ConsumerState<StudioPhotoKitScreen> {
  bool _busy = false;
  PhotoKit? _kit;
  String? _error;

  Future<void> _pick(ImageSource source) async {
    final userId = ref.read(currentUserIdProvider);
    final lang = ref.read(languageProvider);
    if (userId == null || _busy) return;
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 85, maxWidth: 2000);
    if (picked == null) return;
    setState(() { _busy = true; _error = null; _kit = null; });
    try {
      final kit = await ref.read(studioRepositoryProvider).photoKit(userId, lang, picked.path);
      if (mounted) setState(() => _kit = kit);
    } catch (e) {
      if (mounted) setState(() => _error = 'failed');
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
        backgroundColor: Colors.transparent, elevation: 0, iconTheme: IconThemeData(color: colors.text),
        title: Text(_tr(lang, 'Rasmdan komplekt', 'Комплект из фото', 'Photo study kit'), style: TextStyle(color: colors.text, fontWeight: FontWeight.w700)),
      ),
      body: _busy
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 14),
              Text(_tr(lang, 'Rasm o\'qilyapti...', 'Читаем изображение...', 'Reading the page...'), style: TextStyle(color: colors.textSecondary)),
            ]))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  Expanded(child: OutlinedButton.icon(onPressed: () => _pick(ImageSource.camera), icon: const Icon(Icons.photo_camera_rounded), label: Text(_tr(lang, 'Kamera', 'Камера', 'Camera')))),
                  const SizedBox(width: 10),
                  Expanded(child: OutlinedButton.icon(onPressed: () => _pick(ImageSource.gallery), icon: const Icon(Icons.image_rounded), label: Text(_tr(lang, 'Galereya', 'Галерея', 'Gallery')))),
                ]),
                if (_error != null) Padding(padding: const EdgeInsets.only(top: 14), child: Text(_tr(lang, 'Bo\'lmadi — aniqroq rasm bilan urinib ko\'ring.', 'Не удалось.', 'Couldn\'t read it — try a clearer photo.'), style: TextStyle(color: colors.error))),
                if (_kit != null) ..._kitBody(colors, lang),
              ]),
            ),
    );
  }

  List<Widget> _kitBody(dynamic colors, String lang) {
    final k = _kit!;
    return [
      const SizedBox(height: 16),
      if (k.title.isNotEmpty) Text(k.title, style: TextStyle(color: colors.text, fontSize: 17, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
        child: Text(k.summary, style: TextStyle(color: colors.text, fontSize: 14, height: 1.5)),
      ),
      if (k.flashcards.isNotEmpty) ...[
        const SizedBox(height: 18),
        Text(_tr(lang, 'Kartochkalar', 'Карточки', 'Flashcards'), style: TextStyle(color: colors.text, fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        ...k.flashcards.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: colors.border)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(f.front, style: TextStyle(color: colors.text, fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(f.back, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                ]),
              ),
            )),
      ],
      if (k.quiz.isNotEmpty) ...[
        const SizedBox(height: 14),
        ElevatedButton.icon(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => StudioQuizRunner(title: _tr(lang, 'Mini-test', 'Мини-тест', 'Mini quiz'), questions: k.quiz, lang: lang),
          )),
          style: ElevatedButton.styleFrom(backgroundColor: colors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          icon: const Icon(Icons.quiz_rounded),
          label: Text('${_tr(lang, 'Mini-testni yechish', 'Пройти мини-тест', 'Take the mini quiz')} (${k.quiz.length})'),
        ),
      ],
    ];
  }
}

/// Photograph handwritten/printed notes → add straight to the RAG library.
class StudioNotesUploadScreen extends ConsumerStatefulWidget {
  const StudioNotesUploadScreen({super.key});
  @override
  ConsumerState<StudioNotesUploadScreen> createState() => _StudioNotesUploadScreenState();
}

class _StudioNotesUploadScreenState extends ConsumerState<StudioNotesUploadScreen> {
  bool _busy = false;
  int? _added;
  String? _error;

  Future<void> _pick(ImageSource source) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null || _busy) return;
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 90, maxWidth: 2200);
    if (picked == null) return;
    setState(() { _busy = true; _error = null; _added = null; });
    try {
      final n = await ref.read(studioRepositoryProvider).uploadNotesImage(userId, picked.path);
      if (mounted) setState(() => _added = n);
    } catch (e) {
      final msg = e.toString();
      if (mounted) setState(() => _error = msg.contains('no_text_found') ? 'no_text' : 'failed');
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
        backgroundColor: Colors.transparent, elevation: 0, iconTheme: IconThemeData(color: colors.text),
        title: Text(_tr(lang, 'Daftardan kutubxonaga', 'Заметки в библиотеку', 'Notes to library'), style: TextStyle(color: colors.text, fontWeight: FontWeight.w700)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _busy
              ? Column(mainAxisSize: MainAxisSize.min, children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 14),
                  Text(_tr(lang, 'O\'qilyapti va qo\'shilyapti...', 'Читаем и добавляем...', 'Reading and adding...'), style: TextStyle(color: colors.textSecondary)),
                ])
              : Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.note_add_rounded, size: 44, color: colors.primary),
                  const SizedBox(height: 12),
                  Text(_tr(lang, 'Qo\'lyozma yoki bosma varaqni suratga oling — AI matnini o\'qib, materiallaringizga qo\'shadi.',
                      'Сфотографируйте страницу — AI прочитает и добавит в материалы.',
                      'Snap a page — the AI reads it and adds it to your materials.'),
                      textAlign: TextAlign.center, style: TextStyle(color: colors.textSecondary, height: 1.5)),
                  const SizedBox(height: 20),
                  if (_added != null)
                    Padding(padding: const EdgeInsets.only(bottom: 14),
                        child: Text('✅ ${_tr(lang, 'Qo\'shildi', 'Добавлено', 'Added')} — $_added ${_tr(lang, 'bo\'lak', 'фрагм.', 'chunks')}', style: TextStyle(color: colors.success, fontWeight: FontWeight.w700))),
                  if (_error == 'no_text')
                    Padding(padding: const EdgeInsets.only(bottom: 14), child: Text(_tr(lang, 'Matn topilmadi — aniqroq rasm oling.', 'Текст не найден.', 'No text found — try a clearer photo.'), style: TextStyle(color: colors.warning))),
                  if (_error == 'failed')
                    Padding(padding: const EdgeInsets.only(bottom: 14), child: Text(_tr(lang, 'Bo\'lmadi — qayta urinib ko\'ring.', 'Не удалось.', 'Couldn\'t add it.'), style: TextStyle(color: colors.error))),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    OutlinedButton.icon(onPressed: () => _pick(ImageSource.camera), icon: const Icon(Icons.photo_camera_rounded), label: Text(_tr(lang, 'Kamera', 'Камера', 'Camera'))),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(onPressed: () => _pick(ImageSource.gallery), icon: const Icon(Icons.image_rounded), label: Text(_tr(lang, 'Galereya', 'Галерея', 'Gallery'))),
                  ]),
                ]),
        ),
      ),
    );
  }
}

/// Knowledge map — concepts grouped by theme, with their relations listed.
class StudioKnowledgeMapScreen extends ConsumerStatefulWidget {
  const StudioKnowledgeMapScreen({super.key});
  @override
  ConsumerState<StudioKnowledgeMapScreen> createState() => _StudioKnowledgeMapScreenState();
}

class _StudioKnowledgeMapScreenState extends ConsumerState<StudioKnowledgeMapScreen> {
  bool _busy = false;
  KnowledgeMap? _map;
  String? _error;

  @override
  void initState() { super.initState(); _generate(); }

  Future<void> _generate() async {
    final userId = ref.read(currentUserIdProvider);
    final lang = ref.read(languageProvider);
    if (userId == null) return;
    setState(() { _busy = true; _error = null; });
    try {
      final m = await ref.read(studioRepositoryProvider).knowledgeMap(userId, lang);
      if (mounted) setState(() => _map = m);
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
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0, iconTheme: IconThemeData(color: colors.text),
        title: Text(_tr(lang, 'Bilim xaritasi', 'Карта знаний', 'Knowledge map'), style: TextStyle(color: colors.text, fontWeight: FontWeight.w700)),
        actions: [if (_map != null && !_busy) IconButton(onPressed: _generate, icon: Icon(Icons.refresh_rounded, color: colors.textSecondary))],
      ),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(error: _error!, lang: lang, onRetry: _generate)
              : _map == null
                  ? const SizedBox.shrink()
                  : _buildMap(colors, lang),
    );
  }

  Widget _buildMap(dynamic colors, String lang) {
    final groups = <String, List<MapNode>>{};
    for (final n in _map!.nodes) {
      groups.putIfAbsent(n.group.isEmpty ? _tr(lang, 'Umumiy', 'Общее', 'General') : n.group, () => []).add(n);
    }
    final labelById = {for (final n in _map!.nodes) n.id: n.label};
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...groups.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.border)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(e.key, style: TextStyle(color: colors.primary, fontSize: 13, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: e.value.map((n) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: colors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                        child: Text(n.label, style: TextStyle(color: colors.text, fontSize: 12, fontWeight: FontWeight.w600)),
                      )).toList()),
                ]),
              ),
            )),
        if (_map!.edges.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(_tr(lang, 'Bog\'lanishlar', 'Связи', 'Connections'), style: TextStyle(color: colors.text, fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          ..._map!.edges.map((ed) {
            final from = labelById[ed.from] ?? ed.from;
            final to = labelById[ed.to] ?? ed.to;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                Icon(Icons.arrow_right_alt_rounded, size: 18, color: colors.textSecondary),
                const SizedBox(width: 6),
                Expanded(child: Text(
                  ed.label.isEmpty ? '$from → $to' : '$from → $to  (${ed.label})',
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                )),
              ]),
            );
          }),
        ],
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final String lang;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.lang, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            error == 'no_materials'
                ? _tr(lang, 'Avval material yuklang.', 'Сначала загрузите материал.', 'Upload material first.')
                : _tr(lang, 'Bo\'lmadi — qayta urinib ko\'ring.', 'Не удалось.', 'Couldn\'t generate it.'),
            textAlign: TextAlign.center, style: TextStyle(color: colors.textSecondary)),
          const SizedBox(height: 14),
          OutlinedButton(onPressed: onRetry, child: Text(_tr(lang, 'Qayta', 'Заново', 'Retry'))),
        ]),
      ),
    );
  }
}
