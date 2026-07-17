import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../assistant/data/assistant_repository.dart';
import '../../auth/application/auth_controller.dart';

enum _VoicePhase { listening, thinking, speaking }

/// Ported from ilm-ai-mobile's LiveVoiceScreen.tsx: continuous hands-free
/// voice conversation. Records with silence-detection to auto-stop a turn,
/// sends the clip for a combined transcribe+answer call, plays back the
/// answer (backend ElevenLabs TTS, falling back to on-device flutter_tts on
/// failure), then loops back to listening. This is the highest-risk screen
/// in the whole port (audio session lifecycle + VAD heuristics), so the
/// thresholds below are a reasonable starting point, not tuned in the field.
class LiveVoiceScreen extends ConsumerStatefulWidget {
  const LiveVoiceScreen({super.key});

  @override
  ConsumerState<LiveVoiceScreen> createState() => _LiveVoiceScreenState();
}

class _LiveVoiceScreenState extends ConsumerState<LiveVoiceScreen> with SingleTickerProviderStateMixin {
  static const _silenceThresholdDb = -35.0;
  static const _silenceHoldMs = 1200;
  static const _minSpeechMs = 400;

  final _recorder = AudioRecorder();
  final _player = AudioPlayer();
  final _tts = FlutterTts();

  late final AnimationController _orbController;
  _VoicePhase _phase = _VoicePhase.listening;
  bool _ended = false;
  String? _error;

  StreamSubscription<Amplitude>? _ampSub;
  DateTime? _speechStartedAt;
  DateTime? _lastLoudAt;
  Timer? _silenceCheckTimer;

  @override
  void initState() {
    super.initState();
    _orbController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _startListening();
  }

  @override
  void dispose() {
    _ended = true;
    _ampSub?.cancel();
    _silenceCheckTimer?.cancel();
    _orbController.dispose();
    _recorder.dispose();
    _player.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _startListening() async {
    if (_ended) return;
    if (!await _recorder.hasPermission()) {
      setState(() => _error = 'Microphone permission denied');
      return;
    }
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/live_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    _speechStartedAt = null;
    _lastLoudAt = null;

    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: path);
    if (!mounted) return;
    setState(() => _phase = _VoicePhase.listening);

    _ampSub?.cancel();
    _ampSub = _recorder.onAmplitudeChanged(const Duration(milliseconds: 250)).listen((amp) {
      final now = DateTime.now();
      if (amp.current > _silenceThresholdDb) {
        _speechStartedAt ??= now;
        _lastLoudAt = now;
      }
    });

    _silenceCheckTimer?.cancel();
    _silenceCheckTimer = Timer.periodic(const Duration(milliseconds: 300), (_) => _checkSilence());
  }

  void _checkSilence() {
    if (_ended || _phase != _VoicePhase.listening) return;
    final started = _speechStartedAt;
    final lastLoud = _lastLoudAt;
    if (started == null || lastLoud == null) return;
    final spokeLongEnough = DateTime.now().difference(started).inMilliseconds >= _minSpeechMs;
    final quietLongEnough = DateTime.now().difference(lastLoud).inMilliseconds >= _silenceHoldMs;
    if (spokeLongEnough && quietLongEnough) {
      _finishTurn();
    }
  }

  Future<void> _finishTurn() async {
    _silenceCheckTimer?.cancel();
    _ampSub?.cancel();
    if (mounted) setState(() => _phase = _VoicePhase.thinking);

    final path = await _recorder.stop();
    final userId = ref.read(currentUserIdProvider);
    final language = ref.read(languageProvider);
    if (path == null || userId == null) {
      if (!_ended) _startListening();
      return;
    }

    try {
      final answer = await ref.read(assistantRepositoryProvider).askVoice(userId: userId, language: language, audioPath: path);
      if (_ended) return;
      if (mounted) setState(() => _phase = _VoicePhase.speaking);
      await _speak(answer, language);
    } catch (_) {
      // transient turn failure -- just go back to listening
    } finally {
      if (!_ended) _startListening();
    }
  }

  Future<void> _speak(String text, String language) async {
    try {
      final base64Audio = await ref.read(assistantRepositoryProvider).speak(text: text, language: language);
      final bytes = base64Decode(base64Audio);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/tts_${DateTime.now().millisecondsSinceEpoch}.mp3');
      await file.writeAsBytes(bytes);
      await _player.setFilePath(file.path);
      await _player.play();
      await _player.playerStateStream.firstWhere((s) => s.processingState == ProcessingState.completed);
    } catch (_) {
      // Backend TTS unavailable -- fall back to on-device speech synthesis.
      await _tts.setLanguage(language == 'ru' ? 'ru-RU' : 'en-US');
      final completer = Completer<void>();
      _tts.setCompletionHandler(() => completer.complete());
      await _tts.speak(text);
      await completer.future.timeout(const Duration(seconds: 30), onTimeout: () {});
    }
  }

  void _endCall() {
    _ended = true;
    _ampSub?.cancel();
    _silenceCheckTimer?.cancel();
    _recorder.stop();
    _player.stop();
    _tts.stop();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);

    final phaseLabel = switch (_phase) {
      _VoicePhase.listening => t('live.listening', language),
      _VoicePhase.thinking => t('live.thinking', language),
      _VoicePhase.speaking => t('live.speaking', language),
    };

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text(t('live.badge', language), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(_error!, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
              ),
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: _orbController,
                  builder: (context, child) {
                    final pulse = _phase == _VoicePhase.listening
                        ? 1.0 + _orbController.value * 0.15
                        : _phase == _VoicePhase.speaking
                            ? 1.0 + _orbController.value * 0.25
                            : 1.0 + _orbController.value * 0.06;
                    return Transform.scale(scale: pulse, child: child);
                  },
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFA855F7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.5), blurRadius: 40, spreadRadius: 10)],
                    ),
                    child: Icon(
                      _phase == _VoicePhase.thinking ? Icons.hourglass_top_rounded : _phase == _VoicePhase.speaking ? Icons.volume_up_rounded : Icons.mic_rounded,
                      color: Colors.white,
                      size: 56,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(phaseLabel, style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: GestureDetector(
                onTap: _endCall,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: const Icon(Icons.call_end, color: Colors.white, size: 28),
                ),
              ),
            ),
            Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(t('live.end', language), style: const TextStyle(color: Colors.white38, fontSize: 12))),
          ],
        ),
      ),
    );
  }
}
