import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';

class DeckSummary {
  final int id;
  final String title;
  final int total;
  final int due;
  const DeckSummary({required this.id, required this.title, required this.total, required this.due});
  factory DeckSummary.fromJson(Map<String, dynamic> j) => DeckSummary(
        id: (j['id'] ?? 0) as int,
        title: (j['title'] ?? '').toString(),
        total: (j['total'] ?? 0) as int,
        due: (j['due'] ?? 0) as int,
      );
}

class DueCard {
  final int index;
  final String front;
  final String back;
  const DueCard({required this.index, required this.front, required this.back});
  factory DueCard.fromJson(Map<String, dynamic> j) => DueCard(
        index: (j['index'] ?? 0) as int,
        front: (j['front'] ?? '').toString(),
        back: (j['back'] ?? '').toString(),
      );
}

class DecksRepository {
  final Dio _dio;
  const DecksRepository(this._dio);

  Future<List<DeckSummary>> listDecks(int userId) async {
    final res = await _dio.get('/decks/$userId');
    final data = res.data as Map<String, dynamic>;
    return ((data['decks'] as List?) ?? [])
        .map((e) => DeckSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<DueCard>> getDue(int userId, int deckId) async {
    final res = await _dio.get('/decks/$userId/$deckId');
    final data = res.data as Map<String, dynamic>;
    return ((data['cards'] as List?) ?? [])
        .map((e) => DueCard.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> review(int userId, int deckId, List<Map<String, dynamic>> results) async {
    await _dio.post('/decks/review', data: {'user_id': userId, 'deck_id': deckId, 'results': results});
  }

  Future<void> deleteDeck(int userId, int deckId) async {
    await _dio.delete('/decks/$userId/$deckId');
  }
}

final decksRepositoryProvider =
    Provider<DecksRepository>((ref) => DecksRepository(ref.watch(dioProvider)));
