import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

enum IlmoActivity {
  greeting,
  listening,
  thinking,
  explaining,
  encouraging,
  success,
  celebrating,
}

/// Original ILM AI atlas, rendered as independent articulated body parts.
/// No image processing occurs on animation frames, and only this canvas repaints.
class IlmoRig extends StatefulWidget {
  const IlmoRig({
    super.key,
    required this.activity,
    this.staticProgress = 1,
    this.motion,
    this.idle,
    required this.size,
    required this.fallback,
    this.onReady,
  });
  final IlmoActivity activity;
  final double staticProgress, size;
  final Animation<double>? motion;

  /// Looping 0..1 phase for the settled "alive" state (breathing, sway, blink).
  final Animation<double>? idle;
  double get progress => motion?.value ?? staticProgress;
  final Widget fallback;
  final VoidCallback? onReady;
  @override
  State<IlmoRig> createState() => _IlmoRigState();
}

class _IlmoRigState extends State<IlmoRig> {
  ImageStream? _stream;
  ImageInfo? _info;
  late final ImageStreamListener _listener = ImageStreamListener(
    (info, _) {
      if (!mounted) {
        info.dispose();
        return;
      }
      final firstFrame = _info == null;
      setState(() {
        _info?.dispose();
        _info = info;
      });
      if (firstFrame) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onReady?.call();
        });
      }
    },
    onError: (Object error, StackTrace? stack) {
      if (mounted) {
        setState(() {
          _info?.dispose();
          _info = null;
        });
      }
    },
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final stream = const AssetImage(
      'assets/mascot/ilmo_rig_v1.png',
    ).resolve(createLocalImageConfiguration(context));
    if (_stream?.key == stream.key) return;
    _stream?.removeListener(_listener);
    _stream = stream..addListener(_listener);
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    _info?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: widget.size,
    child: _info == null
        ? widget.fallback
        : CustomPaint(
            painter: IlmoRigPainter(
              _info!.image,
              widget.activity,
              widget.staticProgress,
              motion: widget.motion,
              idle: widget.idle,
            ),
          ),
  );
}

class IlmoRigPainter extends CustomPainter {
  IlmoRigPainter(
    this.atlas,
    this.activity,
    this.progress, {
    this.motion,
    this.idle,
  }) : super(
         repaint: Listenable.merge([?motion, ?idle]),
       );
  final ui.Image atlas;
  final IlmoActivity activity;
  final double progress;
  final Animation<double>? motion;
  final Animation<double>? idle;
  static const parts = <Rect>[
    Rect.fromLTRB(0, 27, 314, 397), // neutral head
    Rect.fromLTRB(329, 104, 622, 384), // torso
    Rect.fromLTRB(697, 78, 858, 396), // left arm
    Rect.fromLTRB(997, 76, 1217, 287), // right arm
    Rect.fromLTRB(46, 502, 249, 785), // left boot
    Rect.fromLTRB(375, 502, 579, 784), // right boot
    Rect.fromLTRB(627, 420, 940, 790), // smiling head
    Rect.fromLTRB(940, 420, 1254, 789), // thoughtful head
    Rect.fromLTRB(0, 838, 314, 1208), // encouraging head
    Rect.fromLTRB(314, 838, 627, 1207), // explaining head
    Rect.fromLTRB(627, 838, 940, 1207), // blink head
    Rect.fromLTRB(940, 838, 1254, 1208), // celebrating head
  ];
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    // Stable stage for all poses, including the full jump and head rotation.
    // Reserve headroom instead of clipping the antenna or shrinking mid-jump.
    final scale = math.min(size.width / 248, size.height / 360);
    canvas.translate(
      (size.width - 240 * scale) / 2,
      (size.height - 360 * scale) / 2 + 56 * scale,
    );
    canvas.scale(scale);
    final t = (motion?.value ?? progress).clamp(0.0, 1.0);
    final envelope = math.sin(t * math.pi);
    final wave = math.sin(t * math.pi * 6) * envelope;
    // Anticipation, action and recovery are independent, not a whole-image bob.
    // Ease into two readable waves, then allow the hand to rest.
    final wavePhase = ((t - .12) / .58).clamp(0.0, 1.0);
    final waveEnvelope = math.sin(wavePhase * math.pi);
    final greetingWave = math.sin(wavePhase * math.pi * 4) * waveEnvelope;
    final anticipation = t < .16 ? math.sin(t / .16 * math.pi) : 0.0;
    final flight = t > .16 && t < .72
        ? math.sin((t - .16) / .56 * math.pi)
        : 0.0;
    final landing = t > .72 && t < .9
        ? math.sin((t - .72) / .18 * math.pi)
        : 0.0;
    final joyous =
        activity == IlmoActivity.success ||
        activity == IlmoActivity.celebrating;
    // Settled "alive" layer: only after a reaction has finished, so it never
    // fights a reaction. Small amplitudes keep every frame inside the stage.
    final settled = idle != null && t >= 1;
    final phase = settled ? idle!.value * math.pi * 2 : 0.0;
    final breathe = settled ? math.sin(phase) : 0.0;
    final sway = settled ? math.sin(phase + .9) : 0.0;
    final idleBlink =
        settled &&
        ((idle!.value > .58 && idle!.value < .62) ||
            (idle!.value > .66 && idle!.value < .69));
    final jumpHeight = activity == IlmoActivity.celebrating ? 38.0 : 18.0;
    final jump = joyous
        ? -jumpHeight * flight + 6 * anticipation + 4 * landing
        : activity == IlmoActivity.encouraging
        ? -4 * envelope
        : 0.0;
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(120, 293),
        width: 86 + jump,
        height: 8,
      ),
      Paint()..color = const Color(0x142A1F6B),
    );
    canvas.translate(0, jump);
    // Keep the feet anchored during the squash; recover to the same rest pose.
    final squash = joyous ? .10 * anticipation + .07 * landing : 0.0;
    final stretch = joyous ? .045 * flight : 0.0;
    canvas.translate(120, 291);
    canvas.scale(
      1 + squash - stretch - .006 * breathe,
      1 - squash + stretch + .016 * breathe,
    );
    canvas.rotate(
      activity == IlmoActivity.greeting
          ? .045 * wave
          : activity == IlmoActivity.explaining
          ? -.035 * wave
          : 0,
    );
    canvas.translate(-120, -291);
    final spritePaint = Paint()..filterQuality = FilterQuality.medium;
    void part(int index, Rect target, {double angle = 0, Offset? pivot}) {
      canvas.save();
      if (pivot != null) {
        canvas.translate(pivot.dx, pivot.dy);
        canvas.rotate(angle);
        canvas.translate(-pivot.dx, -pivot.dy);
      }
      canvas.drawImageRect(atlas, parts[index], target, spritePaint);
      canvas.restore();
    }

    part(
      4,
      const Rect.fromLTWH(78, 232, 42, 59),
      angle: joyous ? .32 * flight + .12 * wave : 0,
      pivot: const Offset(99, 237),
    );
    part(
      5,
      const Rect.fromLTWH(119, 232, 42, 59),
      angle: joyous ? -.32 * flight - .12 * wave : 0,
      pivot: const Offset(140, 237),
    );
    final left =
        (joyous
            ? .9 + .55 * flight + .3 * wave
            : activity == IlmoActivity.explaining
            ? .4 * wave
            : 0.0) +
        .07 * sway;
    final right = switch (activity) {
      IlmoActivity.greeting => -.35 - .19 * waveEnvelope + .73 * greetingWave,
      IlmoActivity.explaining => -.2 + .48 * wave,
      IlmoActivity.thinking => .35 + .22 * wave,
      IlmoActivity.encouraging => -.1 + .35 * envelope,
      IlmoActivity.success ||
      IlmoActivity.celebrating => -.55 - .38 * flight + .25 * wave,
      _ => 0.0,
    } - .07 * sway;
    part(
      2,
      const Rect.fromLTWH(53, 174, 38, 75),
      angle: left,
      pivot: const Offset(72, 182),
    );
    part(
      3,
      const Rect.fromLTWH(149, 172, 63, 61),
      angle: right,
      pivot: const Offset(161, 182),
    );
    part(1, const Rect.fromLTWH(72, 166, 96, 92));
    final blink = (t > .26 && t < .30) || (t > .76 && t < .80);
    final head = switch (activity) {
      IlmoActivity.success => 6,
      IlmoActivity.celebrating => 11,
      IlmoActivity.thinking => 7,
      IlmoActivity.encouraging => 8,
      IlmoActivity.explaining => t < 1 && math.sin(t * math.pi * 8) > 0 ? 9 : 0,
      _ => blink || idleBlink ? 10 : 0,
    };
    final tilt = activity == IlmoActivity.greeting
        ? -.10 * waveEnvelope + .04 * greetingWave
        : activity == IlmoActivity.listening
        ? -.18 * envelope + .06 * wave
        : activity == IlmoActivity.encouraging
        ? .12 * math.sin(t * math.pi * 4) * envelope
        : activity == IlmoActivity.thinking
        ? -.12 * envelope
        : .085 * wave;
    final headTilt = tilt + .035 * sway;
    part(
      head,
      const Rect.fromLTWH(36, 1, 168, 198),
      angle: headTilt,
      pivot: const Offset(120, 173),
    );
    if (activity == IlmoActivity.celebrating && t > 0 && t < 1) {
      final paint = Paint()
        ..color = const Color(0xFFF9A825).withValues(alpha: envelope);
      for (var i = 0; i < 6; i++) {
        final angle = i * math.pi / 3;
        final point = Offset(
          120 + math.cos(angle) * (70 + 25 * t),
          120 + math.sin(angle) * (65 + 25 * t),
        );
        canvas.save();
        canvas.translate(point.dx, point.dy);
        canvas.rotate(angle + t);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(-2, -6, 4, 12),
            const Radius.circular(2),
          ),
          paint,
        );
        canvas.restore();
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(IlmoRigPainter old) =>
      old.atlas != atlas ||
      old.activity != activity ||
      old.motion != motion ||
      old.idle != idle ||
      old.progress != progress;
}
