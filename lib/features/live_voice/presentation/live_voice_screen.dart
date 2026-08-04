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
  static const _silenceThresholdDb = -38.0; // a touch more sensitive
  static const _silenceHoldMs = 650;        // faster turn-end (was 800/1200)
  static const _minSpeechMs = 400;
  static const _maxSpeechMs = 14000;        // hard stop so noise can't listen forever

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
    _ampSub = _recorder.onAmplitudeChanged(const Duration(milliseconds: 150)).listen((amp) {
      final now = DateTime.now();
      if (amp.current > _silenceThresholdDb) {
        _speechStartedAt ??= now;
        _lastLoudAt = now;
      }
    });

    _silenceCheckTimer?.cancel();
    _silenceCheckTimer = Timer.periodic(const Duration(milliseconds: 150), (_) => _checkSilence());
  }

  void _checkSilence() {
    if (_ended || _phase != _VoicePhase.listening) return;
    final started = _speechStartedAt;
    final lastLoud = _lastLoudAt;
    if (started == null || lastLoud == null) return;
    final spokeLongEnough = DateTime.now().difference(started).inMilliseconds >= _minSpeechMs;
    final quietLongEnough = DateTime.now().difference(lastLoud).inMilliseconds >= _silenceHoldMs;
    // Hard cap so a noisy room (which keeps _lastLoudAt fresh) can't keep the
    // mic "listening" forever — end the turn after _maxSpeechMs regardless.
    final tooLong = DateTime.now().difference(started).inMilliseconds >= _maxSpeechMs;
    if ((spokeLongEnough && quietLongEnough) || tooLong) {
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

    // Sequential playback chain: each audio segment is queued to play right
    // after the previous one finishes, WHILE later segments are still streaming
    // in — so the reply starts speaking the first sentence almost immediately.
    Future<void> playChain = Future.value();
    final List<String> onDeviceSay = [];
    var switchedToSpeaking = false;

    void toSpeaking() {
      if (switchedToSpeaking) return;
      switchedToSpeaking = true;
      if (mounted) setState(() => _phase = _VoicePhase.speaking);
    }

    try {
      final stream = ref.read(assistantRepositoryProvider).askVoiceStream(userId: userId, language: language, audioPath: path);
      await for (final ev in stream) {
        if (_ended) return;
        switch (ev['type']) {
          case 'audio':
            final b64 = (ev['b64'] as String?) ?? '';
            if (b64.isEmpty) break;
            final bytes = base64Decode(b64);
            if (bytes.length < 512) break; // empty/garbage segment
            final dir = await getTemporaryDirectory();
            final file = File('${dir.path}/seg_${DateTime.now().microsecondsSinceEpoch}.mp3');
            await file.writeAsBytes(bytes);
            toSpeaking();
            playChain = playChain.then((_) => _playFile(file));
            break;
          case 'say':
            // Backend TTS failed for this sentence — collect it to speak on-device.
            final txt = (ev['text'] as String?) ?? '';
            if (txt.trim().isNotEmpty) onDeviceSay.add(txt);
            break;
          case 'error':
            // Whole turn failed server-side — nothing to play; loop back.
            break;
        }
      }
      // Let every queued segment finish playing before we listen again.
      await playChain;
      // Speak any sentences the backend couldn't synthesize, on-device.
      if (onDeviceSay.isNotEmpty && !_ended) {
        toSpeaking();
        await _speakOnDevice(onDeviceSay.join(' '), language);
      }
    } catch (_) {
      // transient turn failure -- just go back to listening
    } finally {
      if (!_ended) _startListening();
    }
  }

  /// Plays a single mp3 segment to completion. Errors are swallowed so one bad
  /// segment can't break the whole spoken reply.
  Future<void> _playFile(File file) async {
    if (_ended) return;
    try {
      await _player.setFilePath(file.path);
      await _player.play();
      await _player.playerStateStream.firstWhere((s) => s.processingState == ProcessingState.completed);
    } catch (_) {
      // skip this segment
    }
  }

  /// On-device speech synthesis fallback (used only when the backend TTS fails).
  Future<void> _speakOnDevice(String text, String language) async {
    final locale = language == 'ru' ? 'ru-RU' : language == 'uz' ? 'uz-UZ' : 'en-US';
    try {
      await _tts.setLanguage(locale);
    } catch (_) {
      await _tts.setLanguage('en-US'); // device may lack the uz voice
    }
    await _tts.setSpeechRate(0.5);
    await _tts.awaitSpeakCompletion(true);
    await _tts.speak(text);
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
