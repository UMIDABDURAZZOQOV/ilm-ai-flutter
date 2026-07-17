import 'dart:async';

import 'package:flutter/widgets.dart';

/// Ported from ilm-ai-mobile's useCountdown hook: stores an absolute target
/// timestamp rather than decrementing a naive counter, and recomputes on
/// every tick plus whenever the app resumes -- self-corrects after being
/// backgrounded instead of drifting/freezing from OS-throttled timers.
class CountdownController extends ChangeNotifier with WidgetsBindingObserver {
  DateTime? _target;
  Timer? _timer;
  int remaining = 0;

  CountdownController() {
    WidgetsBinding.instance.addObserver(this);
  }

  void start(int seconds) {
    _target = DateTime.now().add(Duration(seconds: seconds));
    _tick();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (_target == null) return;
    final diff = _target!.difference(DateTime.now()).inSeconds;
    remaining = diff > 0 ? diff : 0;
    if (remaining == 0) _timer?.cancel();
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _tick();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
