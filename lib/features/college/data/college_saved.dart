import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/storage/prefs_service.dart';

class SavedCollegesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final raw = ref.read(prefsServiceProvider).getString(PrefsKeys.collegeSaved);
    if (raw == null || raw.isEmpty) return {};
    return raw.split(',').toSet();
  }

  void toggle(String id) {
    final next = Set<String>.from(state);
    if (!next.remove(id)) next.add(id);
    state = next;
    ref.read(prefsServiceProvider).setString(PrefsKeys.collegeSaved, next.join(','));
  }
}

final savedCollegesProvider = NotifierProvider<SavedCollegesNotifier, Set<String>>(SavedCollegesNotifier.new);
