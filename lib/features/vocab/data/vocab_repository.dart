import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';

class VocabSense {
  final String? partOfSpeech;
  final String definition;
  final String? example;
  final List<String> synonyms;
  VocabSense({this.partOfSpeech, required this.definition, this.example, this.synonyms = const []});
  factory VocabSense.fromJson(Map<String, dynamic> j) => VocabSense(
        partOfSpeech: j['part_of_speech'] as String?,
        definition: (j['definition'] ?? '').toString(),
        example: j['example'] as String?,
        synonyms: ((j['synonyms'] as List?) ?? []).map((e) => e.toString()).toList(),
      );
}

class VocabDefinition {
  final String word;
  final bool found;
  final String? phonetic;
  final List<VocabSense> senses;
  VocabDefinition({required this.word, required this.found, this.phonetic, this.senses = const []});
  factory VocabDefinition.fromJson(Map<String, dynamic> j) => VocabDefinition(
        word: (j['word'] ?? '').toString(),
        found: j['found'] == true,
        phonetic: j['phonetic'] as String?,
        senses: ((j['senses'] as List?) ?? []).map((e) => VocabSense.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

class VocabExample {
  final String sentence;
  final String source;
  VocabExample({required this.sentence, required this.source});
  factory VocabExample.fromJson(Map<String, dynamic> j) => VocabExample(
        sentence: (j['sentence'] ?? '').toString(),
        source: (j['source'] ?? '').toString(),
      );
}

class StarredWord {
  final String word;
  final String? note;
  StarredWord({required this.word, this.note});
  factory StarredWord.fromJson(Map<String, dynamic> j) => StarredWord(
        word: (j['word'] ?? '').toString(),
        note: j['note'] as String?,
      );
}

class VocabRepository {
  final Dio _dio;
  const VocabRepository(this._dio);

  Future<VocabDefinition> define(String word) async {
    final res = await _dio.get('/vocab/define', queryParameters: {'word': word});
    return VocabDefinition.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<VocabExample>> examples(String word) async {
    final res = await _dio.get('/vocab/examples', queryParameters: {'word': word});
    return ((res.data as Map<String, dynamic>)['examples'] as List? ?? [])
        .map((e) => VocabExample.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<StarredWord>> listStarred(int userId) async {
    final res = await _dio.get('/vocab/$userId/starred');
    return ((res.data as Map<String, dynamic>)['words'] as List? ?? [])
        .map((e) => StarredWord.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> star(int userId, String word, {String? note}) async {
    await _dio.post('/vocab/starred', data: {'user_id': userId, 'word': word, 'note': ?note});
  }

  Future<void> unstar(int userId, String word) async {
    await _dio.delete('/vocab/starred', queryParameters: {'user_id': userId, 'word': word});
  }
}

final vocabRepositoryProvider = Provider<VocabRepository>((ref) => VocabRepository(ref.watch(dioProvider)));
