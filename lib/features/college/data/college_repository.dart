import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'college_models.dart';

String _norm(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

/// Loads the bundled US/EU college JSON assets plus the curated
/// professor-rich list, sorted by name. Ported from ilm-ai-mobile's
/// collegesData.ts -- curated entries win on name collision so top
/// universities keep their richer detail.
class CollegeRepository {
  List<College>? _cache;

  Future<List<College>> getAll() async {
    if (_cache != null) return _cache!;
    final curatedRaw = await rootBundle.loadString('assets/data/colleges-curated.json');
    final usRaw = await rootBundle.loadString('assets/data/colleges-us.json');
    final euRaw = await rootBundle.loadString('assets/data/colleges-eu.json');

    final curated = (jsonDecode(curatedRaw) as List).cast<Map<String, dynamic>>().map(College.fromJson).toList();
    final us = (jsonDecode(usRaw) as List).cast<Map<String, dynamic>>().map(College.fromJson);
    final eu = (jsonDecode(euRaw) as List).cast<Map<String, dynamic>>().map(College.fromJson);

    final seen = curated.map((c) => _norm(c.name)).toSet();
    final extra = <College>[];
    for (final c in [...us, ...eu]) {
      if (c.name.isEmpty) continue;
      final n = _norm(c.name);
      if (seen.contains(n)) continue;
      seen.add(n);
      extra.add(c);
    }

    final all = [...curated, ...extra]..sort((a, b) => a.name.compareTo(b.name));
    _cache = all;
    return all;
  }

  Future<College?> getById(String id) async {
    final all = await getAll();
    for (final c in all) {
      if (c.id == id) return c;
    }
    return null;
  }
}

final collegeRepositoryProvider = Provider<CollegeRepository>((ref) => CollegeRepository());

final allCollegesProvider = FutureProvider<List<College>>((ref) => ref.watch(collegeRepositoryProvider).getAll());
