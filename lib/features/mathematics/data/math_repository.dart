import 'dart:math';
import 'package:dio/dio.dart';

typedef MathJson = Map<String, dynamic>;
const mathExplorerModes = {
  'equation_root_check',
  'inverse_story_family',
  'equation_initial_remaining',
  'review_sort_quantity',
  'review_word_expression',
  'review_segment_parts',

  'algebra_value_table',
  'algebra_addition_properties',
  'algebra_integer_inequalities',
  'notation_roman_100',
  'equation_unknown_component',
  'equation_solution_steps',
  'geometry_shape_axes',
  'geometry_solid_views',
  'algebra_compare_sums',
  'algebra_expression_kind',
  'algebra_parts_variables',
  'algebra_value_comparison',
  'geometry_quadrilateral',
  'geometry_regions',
  'geometry_congruent_overlay',
  'geometry_tangram_guide',
  'geometry_mirror_axis',
  'geometry_perimeter_trace',
  'geometry_perimeter_missing',
  'geometry_rectangle_perimeter',
  'geometry_parallel_paper_fit',
  'geometry_angle_comparison',
  'geometry_ruler_interval',
  'geometry_construct_segment',
  'geometry_segment_partition',
  'geometry_polyline_length',
  'geometry_polygon_boundary',
  'quantity_mass_batches',
  'quantity_litre_addition',
  'quantity_capacity_content',
  'quantity_conserving_pour',
  'quantity_commutative_units',
  'quantity_unknown_components',
  'quantity_course_review',

  'measurement_segments',
  'measurement_decimetre_intro',
  'measurement_dm_cm_conversion',
  'measurement_rectangles',
  'measurement_mass_balance',

  'problem_missing_information',
  'problem_unordered_pairs',
  'problem_related_total',
  'problem_weekday_reasoning',
  'measurement_centimetre',

  'comparison_count_gap',
  'comparison_dataset',
  'comparison_picture_counts',
  'comparison_same_symbol',
  'compound_linked_steps',

  'problem_route_times',
  'comparison_more_less',
  'comparison_partitions',
  'comparison_independent_branches',
  'comparison_difference_family',

  'problem_parts',
  'problem_algorithm',
  'problem_part_whole',
  'problem_representations',
  'problem_table_totals',
  'problem_whole_sum',
  'problem_criteria',
  'problem_arrow_chain',
  'problem_missing_part',
  'problem_inverse_table',
  'tens_units_20',
  'number_pairs_12',
  'number_pairs_14',
  'number_pairs_16',
  'number_pairs_18',
  'number_pairs_20',
  'compare_place_value_20',
  'brackets_single',
  'brackets_double',
  'bridge_ten_intro',
  'bridge_ten_apply',
  'bridge_ten_line',
  'subtract_units_20',
  'subtract_bridge_ten',
  'subtract_from_ten',
  'round_tens_100',
  'hundred_chart',
  'place_value_100',
  'abacus_100',
  'compare_place_value_100',
  'two_digit_addition',
  'two_digit_missing_addend',
  'two_digit_subtraction',
  'two_digit_inverse',
  'multi_addition',
  'addition_grouping',
  'multi_addition_table',
  'brackets_composite',
  'missing_subtrahend',
  'inverse_family',
  'commutative',
  'addition_table',
  'compare_same_addend',
  'expression_steps',
  'segments',
  'missing_addend',
  'missing_minuend',
  'shape_properties',
  'compare_lengths',
  'positions',
  'count_once',
  'flat_solid',
  'timeline',
  'group_members',
  'pair_groups',
  'number_line',
  'addition',
  'subtraction',
  'comparison',
  'one_two',
  'compose_three',
  'compose_four',
  'compose_five',
  'compose_six',
  'compose_seven',
  'compose_eight',
  'compose_nine',
  'compose_ten',
  'part_whole_five',
  'steps_five',
  'zero',
  'ordering_numbers',
  'natural_numbers',
  'parity',
  'point_line',
};
List<MathJson> mathRows(dynamic value) =>
    (value as List).map((v) => Map<String, dynamic>.from(v as Map)).toList();

String mathRequestId() {
  final random = Random.secure();
  final bytes = List.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final hex = bytes.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// Public DTOs only; the client never computes correctness or XP.
class MathRepository {
  final Dio dio;
  const MathRepository(this.dio);
  static const prefix = '/preview/mathematics/v1';
  Options get options => Options(
    sendTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20),
  );

  MathJson checked(dynamic value, String type) {
    if (value is! Map || value['assessment_version'] != 1) {
      throw const FormatException('Matematika API versiyasi mos emas.');
    }
    final result = Map<String, dynamic>.from(value);
    try {
      void text(dynamic v) {
        if (v is! String || v.isEmpty) throw const FormatException();
      }

      if (type == 'catalog') {
        if (result['subject'] != 'mathematics') throw const FormatException();
        if (result['source_gap_bridge'] != null) {
          final bridge = result['source_gap_bridge'] as Map;
          text(bridge['message']);
          if (bridge['kind'] != 'local_qa_known_source_gap' ||
              result['previous_book_complete'] != false ||
              result['previous_book_navigation_ready'] != true) {
            throw const FormatException();
          }
        }
        if (result['available_books'] != null) {
          for (final book in mathRows(result['available_books'])) {
            text(book['book_id']);
            text(book['label']);
            if (book['grade'] is! int || book['part'] is! int) {
              throw const FormatException();
            }
          }
        }
        for (final lesson in mathRows(result['lessons'])) {
          text(lesson['key']);
          text(lesson['title']);
          if (!(lesson['key'] as String).startsWith('math-') ||
              !{'locked', 'available', 'completed'}.contains(lesson['state'])) {
            throw const FormatException();
          }
        }
      } else if (type == 'attempt') {
        text(result['attempt_id']);
        text(result['title']);
        if (!(result['lesson_key'] as String).startsWith('math-') ||
            result['answers'] is! List) {
          throw const FormatException();
        }
        final content = result['content'] as Map;
        if (!mathExplorerModes.contains(content['explorer']['type'])) {
          throw const FormatException();
        }
        for (final notation in mathRows(content['formulas'])) {
          if (notation['kind'] != 'worked_identity') {
            throw const FormatException();
          }
          text(notation['title']);
          text(notation['expression']);
          text(notation['meaning']);
        }
        for (final card in mathRows(content['cards'])) {
          text(card['title']);
          text(card['body']);
        }
        for (final example in mathRows(content['examples'])) {
          text(example['title']);
          for (final step in mathRows(example['steps'])) {
            text(step['action']);
            text(step['why']);
          }
        }
        final questions = mathRows(result['questions']);
        if (questions.isEmpty || questions.length > 50) {
          throw const FormatException();
        }
        for (final q in questions) {
          text(q['id']);
          text(q['prompt']);
          if (!{
            'choice',
            'short_text',
            'exact_number',
            'ordering',
          }.contains(q['response_kind'])) {
            throw const FormatException();
          }
          if (q['response_kind'] == 'choice' &&
              mathRows(q['choices']).isEmpty) {
            throw const FormatException();
          }
          if (q['response_kind'] == 'ordering') {
            final items = mathRows(q['items']);
            if (items.length < 2 ||
                items.length > 10 ||
                items.map((v) => v['id']).toSet().length != items.length) {
              throw const FormatException();
            }
            for (final item in items) {
              text(item['id']);
              text(item['label']);
            }
          }
          if (q['visual'] != null) {
            final scene = q['visual'] as Map;
            if (!{'shape_board', 'bars'}.contains(scene['type'])) {
              throw const FormatException();
            }
            final items = mathRows(scene['items']);
            if (items.isEmpty || items.length > 10) {
              throw const FormatException();
            }
            for (final item in items) {
              text(item['id']);
              if (!{
                    'circle',
                    'square',
                    'triangle',
                    'rectangle',
                    'sphere',
                    'cube',
                  }.contains(item['shape']) ||
                  !{'indigo', 'yellow', 'turquoise'}.contains(item['color'])) {
                throw const FormatException();
              }
              for (final coordinate in ['x', 'y', 'size']) {
                final v = item[coordinate];
                if (v is! num ||
                    !v.isFinite ||
                    v < (coordinate == 'size' ? .4 : .1) ||
                    v > (coordinate == 'size' ? 1.4 : .9)) {
                  throw const FormatException();
                }
              }
            }
          }
        }
      } else if (type == 'answer') {
        text(result['feedback']);
        text(result['question_id']);
        if (result['is_correct'] is! bool || result['request_id'] is! String) {
          throw const FormatException();
        }
      } else if (result['xp_awarded'] is! int || result['passed'] is! bool) {
        throw const FormatException();
      }
    } on TypeError {
      throw const FormatException('Matematika API javobi mos emas.');
    }
    return result;
  }

  Future<MathJson> catalog(
    CancelToken cancel, {
    int grade = 1,
    int part = 1,
  }) async => checked(
    (await dio.get(
      '$prefix/catalog',
      queryParameters: {'grade': grade, 'part': part},
      options: options,
      cancelToken: cancel,
    )).data,
    'catalog',
  );
  Future<MathJson> start(
    String key,
    String request,
    CancelToken cancel,
  ) async => checked(
    (await dio.post(
      '$prefix/lessons/$key/start',
      data: {'assessment_version': 1, 'request_id': request},
      options: options,
      cancelToken: cancel,
    )).data,
    'attempt',
  );
  Future<MathJson> answer(
    String attempt,
    MathJson submission,
    CancelToken cancel,
  ) async => checked(
    (await dio.post(
      '$prefix/attempts/$attempt/answers',
      data: {'assessment_version': 1, ...submission},
      options: options,
      cancelToken: cancel,
    )).data,
    'answer',
  );
  Future<MathJson> complete(
    String attempt,
    String request,
    CancelToken cancel,
  ) async => checked(
    (await dio.post(
      '$prefix/attempts/$attempt/complete',
      data: {'assessment_version': 1, 'request_id': request},
      options: options,
      cancelToken: cancel,
    )).data,
    'result',
  );
}
