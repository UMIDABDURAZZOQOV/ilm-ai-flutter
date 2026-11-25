import 'package:flutter/material.dart';
import 'mascot_image.dart';
import 'ilmo_rig.dart';
import '../theme/ilmo_tokens.dart';
export 'ilmo_rig.dart' show IlmoActivity;

/// Our own Ilmo artwork with pose-specific, bounded motion. No third-party art.
/// Reactions settle; only an active AI request loops. Reduced motion and route
/// visibility pause the ticker, and the artwork is isolated from page repaint.
class AnimatedIlmo extends StatefulWidget {
  const AnimatedIlmo({
    super.key,
    required this.pose,
    this.size = 90,
    this.thinking = false,
    this.reactionKey,
    this.activity,
    this.motionEnabled = true,
    this.reactionDuration,
  });
  const AnimatedIlmo.hero({
    super.key,
    required this.pose,
    this.thinking = false,
    this.reactionKey,
    this.activity,
    this.motionEnabled = true,
    this.reactionDuration,
  }) : size = IlmoSizes.hero * 1.4;
  final MascotPose pose;
  final IlmoActivity? activity;
  final double size;
  final bool thinking;
  final bool motionEnabled;
  final Object? reactionKey;
  final Duration? reactionDuration;

  /// After a reaction settles Ilmo keeps "breathing" (Duolingo-style idle):
  /// a slow loop of breath, sway and blinks. Widget tests switch it off in
  /// test/flutter_test_config.dart so pumpAndSettle and goldens stay stable.
  static bool ambientIdle = true;
  @override
  State<AnimatedIlmo> createState() => _AnimatedIlmoState();
}

class _AnimatedIlmoState extends State<AnimatedIlmo>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final _motion = AnimationController(
    vsync: this,
    duration: _reactionDuration,
  )..addStatusListener(_reactionStatus);
  late final _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  );
  bool _foreground = true;
  bool _artReady = false;
  bool _reactionPlayed = false;

  IlmoActivity get _activity =>
      widget.activity ??
      switch (widget.pose) {
        MascotPose.hello => IlmoActivity.greeting,
        MascotPose.happy => IlmoActivity.success,
        MascotPose.thinking => IlmoActivity.thinking,
        MascotPose.explaining => IlmoActivity.explaining,
        MascotPose.sad => IlmoActivity.encouraging,
      };

  Duration get _reactionDuration =>
      widget.reactionDuration ??
      Duration(
        milliseconds: switch (_activity) {
          IlmoActivity.greeting => 2400,
          IlmoActivity.listening => 1450,
          IlmoActivity.thinking => 2800,
          IlmoActivity.explaining => 2600,
          IlmoActivity.encouraging => 1650,
          IlmoActivity.success => 1100,
          IlmoActivity.celebrating => 2900,
        },
      );
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(AnimatedIlmo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pose != widget.pose ||
        oldWidget.activity != widget.activity ||
        oldWidget.thinking != widget.thinking ||
        oldWidget.motionEnabled != widget.motionEnabled ||
        oldWidget.reactionDuration != widget.reactionDuration ||
        oldWidget.reactionKey != widget.reactionKey) {
      _start();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncMotion();
  }

  void _reactionStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _syncIdle();
  }

  bool get _motionAllowed =>
      _artReady &&
      widget.motionEnabled &&
      _foreground &&
      !MediaQuery.disableAnimationsOf(context) &&
      TickerMode.valuesOf(context).enabled;

  void _syncIdle() {
    if (!mounted) return;
    final run =
        AnimatedIlmo.ambientIdle &&
        _motionAllowed &&
        !widget.thinking &&
        !_motion.isAnimating;
    if (run) {
      if (!_idle.isAnimating) _idle.repeat();
    } else if (_idle.isAnimating) {
      _idle.stop();
    }
  }

  void _start() {
    _reactionPlayed = false;
    _idle.stop();
    _motion.stop();
    _motion.duration = _reactionDuration;
    _syncMotion();
  }

  void _syncMotion() {
    if (!mounted) return;
    if (!_motionAllowed) {
      _motion.stop();
      _motion.value = 1;
      _syncIdle();
    } else if (widget.thinking) {
      if (!_motion.isAnimating) _motion.repeat();
    } else if (!_reactionPlayed) {
      _reactionPlayed = true;
      _motion.forward(from: 0);
    } else {
      _syncIdle();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _motion.dispose();
    _idle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: IlmoRig(
      // The atlas is painted before starting the reaction. The still fallback
      // does not schedule animation frames while the texture is loading.
      onReady: () {
        _artReady = true;
        _syncMotion();
      },
      activity: _activity,
      motion: _motion,
      idle: AnimatedIlmo.ambientIdle ? _idle : null,
      size: widget.size,
      fallback: MascotImage(
        pose: widget.pose,
        size: widget.size,
        animate: false,
      ),
    ),
  );
}
