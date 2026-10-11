import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../providers/app_providers.dart';

abstract class SoundService {
  Future<void> playCorrect();
  Future<void> playIncorrect();
  Future<void> playLessonComplete();
  void dispose();
}

class AppSoundService implements SoundService {
  final bool enabled;
  AudioPlayer? _correctPlayer;
  AudioPlayer? _incorrectPlayer;
  AudioPlayer? _completePlayer;
  bool _initialized = false;

  AppSoundService({this.enabled = true}) {
    _init();
  }

  Future<void> _init() async {
    try {
      _correctPlayer = AudioPlayer();
      _incorrectPlayer = AudioPlayer();
      _completePlayer = AudioPlayer();
      await Future.wait([
        _correctPlayer!.setAsset('assets/sounds/correct.wav'),
        _incorrectPlayer!.setAsset('assets/sounds/incorrect.wav'),
        _completePlayer!.setAsset('assets/sounds/complete.wav'),
      ]);
      _initialized = true;
    } catch (_) {
      // Audio driver might be absent or fail in test/headless environments
    }
  }

  @override
  Future<void> playCorrect() async {
    if (!enabled || !_initialized) return;
    try {
      await _correctPlayer?.seek(Duration.zero);
      await _correctPlayer?.play();
    } catch (_) {}
  }

  @override
  Future<void> playIncorrect() async {
    if (!enabled || !_initialized) return;
    try {
      await _incorrectPlayer?.seek(Duration.zero);
      await _incorrectPlayer?.play();
    } catch (_) {}
  }

  @override
  Future<void> playLessonComplete() async {
    if (!enabled || !_initialized) return;
    try {
      await _completePlayer?.seek(Duration.zero);
      await _completePlayer?.play();
    } catch (_) {}
  }

  @override
  void dispose() {
    _correctPlayer?.dispose();
    _incorrectPlayer?.dispose();
    _completePlayer?.dispose();
  }
}

class FakeSoundService implements SoundService {
  int playCorrectCount = 0;
  int playIncorrectCount = 0;
  int playLessonCompleteCount = 0;

  @override
  Future<void> playCorrect() async {
    playCorrectCount++;
  }

  @override
  Future<void> playIncorrect() async {
    playIncorrectCount++;
  }

  @override
  Future<void> playLessonComplete() async {
    playLessonCompleteCount++;
  }

  @override
  void dispose() {}
}

final soundServiceProvider = Provider<SoundService>((ref) {
  final enabled = ref.watch(soundEffectsProvider);
  final service = AppSoundService(enabled: enabled);
  ref.onDispose(service.dispose);
  return service;
});
