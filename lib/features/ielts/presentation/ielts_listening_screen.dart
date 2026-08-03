import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart' show languageProvider;
import '../data/ielts_models.dart';
import '../data/ielts_repository.dart';
import 'ielts_answer_sheet.dart';

String _tr(String lang, String uz, String ru, String en) =>
    lang == 'ru' ? ru : lang == 'en' ? en : uz;

class IeltsListeningScreen extends ConsumerStatefulWidget {
  const IeltsListeningScreen({super.key});
  @override
  ConsumerState<IeltsListeningScreen> createState() => _IeltsListeningScreenState();
}

class _IeltsListeningScreenState extends ConsumerState<IeltsListeningScreen> {
  List<IeltsListening>? _items;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final r = await ref.read(ieltsRepositoryProvider).listListening();
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
        title: Text(_tr(lang, 'Tinglash', 'Аудирование', 'Listening'), style: TextStyle(color: colors.text, fontWeight: FontWeight.w800)),
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
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => IeltsListeningPractice(listening: r))),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.border)),
                            child: Row(children: [
                              Container(
                                width: 40, height: 40, alignment: Alignment.center,
                                decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
                                child: Text('${r.section}', style: const TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.w800)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(r.title, style: TextStyle(color: colors.text, fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 2),
                                  Text(r.difficulty, style: TextStyle(color: colors.textSecondary, fontSize: 11)),
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

class IeltsListeningPractice extends ConsumerStatefulWidget {
  final IeltsListening listening;
  const IeltsListeningPractice({super.key, required this.listening});
  @override
  ConsumerState<IeltsListeningPractice> createState() => _IeltsListeningPracticeState();
}

class _IeltsListeningPracticeState extends ConsumerState<IeltsListeningPractice> {
  final AudioPlayer _player = AudioPlayer();
  List<IeltsQuestion>? _questions;
  bool _audioReady = false;
  bool _audioFailed = false;

  List<String> get _sources {
    final l = widget.listening;
    if (l.audioParts.isNotEmpty) return l.audioParts;
    if (l.audioUrl != null && l.audioUrl!.isNotEmpty) return [l.audioUrl!];
    return [];
  }

  @override
  void initState() {
    super.initState();
    _load();
    _initAudio();
  }

  Future<void> _initAudio() async {
    final srcs = _sources;
    if (srcs.isEmpty) { setState(() => _audioFailed = true); return; }
    try {
      if (srcs.length == 1) {
        await _player.setUrl(IeltsRepository.resolveUrl(srcs.first));
      } else {
        await _player.setAudioSource(ConcatenatingAudioSource(
          children: srcs.map((s) => AudioSource.uri(Uri.parse(IeltsRepository.resolveUrl(s)))).toList(),
        ));
      }
      if (mounted) setState(() => _audioReady = true);
    } catch (_) {
      if (mounted) setState(() => _audioFailed = true);
    }
  }

  Future<void> _load() async {
    try {
      final q = await ref.read(ieltsRepositoryProvider).listeningQuestions(widget.listening.id);
      if (mounted) setState(() => _questions = q);
    } catch (_) {
      if (mounted) setState(() => _questions = []);
    }
  }

  @override
  void dispose() { _player.dispose(); super.dispose(); }

  String _fmt(Duration d) => '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final lang = ref.watch(languageProvider);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0, iconTheme: IconThemeData(color: colors.text),
        title: Text(widget.listening.title, style: TextStyle(color: colors.text, fontWeight: FontWeight.w700, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Audio player card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: _audioFailed
                ? Text(_tr(lang, 'Audio mavjud emas.', 'Аудио недоступно.', 'Audio unavailable.'), style: const TextStyle(color: Colors.white))
                : !_audioReady
                    ? const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(color: Colors.white)))
                    : Column(children: [
                        StreamBuilder<Duration>(
                          stream: _player.positionStream,
                          builder: (context, snap) {
                            final pos = snap.data ?? Duration.zero;
                            final total = _player.duration ?? Duration.zero;
                            final max = total.inMilliseconds.toDouble();
                            return Column(children: [
                              SliderTheme(
                                data: SliderThemeData(trackHeight: 3, thumbColor: Colors.white, activeTrackColor: Colors.white, inactiveTrackColor: Colors.white38, overlayShape: SliderComponentShape.noOverlay),
                                child: Slider(
                                  value: pos.inMilliseconds.clamp(0, max <= 0 ? 1 : max.toInt()).toDouble(),
                                  max: max <= 0 ? 1 : max,
                                  onChanged: (v) => _player.seek(Duration(milliseconds: v.toInt())),
                                ),
                              ),
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                Text(_fmt(pos), style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                Text(_fmt(total), style: const TextStyle(color: Colors.white70, fontSize: 11)),
                              ]),
                            ]);
                          },
                        ),
                        const SizedBox(height: 4),
                        StreamBuilder<PlayerState>(
                          stream: _player.playerStateStream,
                          builder: (context, snap) {
                            final playing = snap.data?.playing ?? false;
                            return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              IconButton(
                                onPressed: () => _player.seek(Duration(seconds: (_player.position.inSeconds - 10).clamp(0, 1 << 30))),
                                icon: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 28),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => playing ? _player.pause() : _player.play(),
                                child: Container(
                                  width: 56, height: 56,
                                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                  child: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: const Color(0xFF7C3AED), size: 32),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () => _player.seek(Duration(seconds: _player.position.inSeconds + 10)),
                                icon: const Icon(Icons.forward_10_rounded, color: Colors.white, size: 28),
                              ),
                            ]);
                          },
                        ),
                      ]),
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
