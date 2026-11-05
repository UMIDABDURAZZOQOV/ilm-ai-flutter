import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/storage/prefs_service.dart';
import '../../../core/widgets/mascot_image.dart';
import '../data/math_repository.dart';
import 'math_models.dart';

class MathPreviewScreen extends StatefulWidget {
  final MathRepository repository;
  final PrefsService preferences;
  final int userId;
  const MathPreviewScreen({
    super.key,
    required this.repository,
    required this.preferences,
    required this.userId,
  });
  @override
  State<MathPreviewScreen> createState() => _MathPreviewScreenState();
}

class _MathPreviewScreenState extends State<MathPreviewScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  CancelToken _cancel = CancelToken();
  MathJson? _catalog, _attempt, _feedback, _result, _pending;
  String? _lessonKey, _request, _choice, _error;
  List<String> _order = [];
  bool _busy = false, _practicing = false;
  int _page = 0, _generation = 0;
  int _grade = 1, _part = 1;
  Future<void> _writes = Future.value();
  String get _namespace =>
      'math_preview_v1:${sha256.convert(utf8.encode(widget.repository.dio.options.baseUrl))}:${widget.userId}';
  List<MathJson> get _questions => mathRows(_attempt!['questions']);
  Set<String> get _solved => mathRows(_attempt!['answers'])
      .where((a) => a['is_correct'] == true)
      .map((a) => a['question_id'] as String)
      .toSet();
  MathJson? get _question =>
      _questions.where((q) => !_solved.contains(q['id'])).firstOrNull;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(MathPreviewScreen old) {
    super.didUpdateWidget(old);
    if (old.userId != widget.userId || old.repository != widget.repository) {
      _generation++;
      _cancel.cancel();
      _cancel = CancelToken();
      _catalog = _attempt = _feedback = _result = _pending = null;
      _lessonKey = _request = _choice = _error = null;
      _busy = false;
      _order = [];
      _practicing = false;
      _page = 0;
      _grade = _part = 1;
      _input.clear();
      unawaited(_load());
    }
  }

  @override
  void dispose() {
    _generation++;
    _cancel.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String _message(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      final detail = data is Map ? data['detail'] : null;
      if (detail is Map && detail['feedback'] is String) {
        return detail['feedback'] as String;
      }
      if (detail == 'attempt_expired') {
        return 'Urinish muddati tugadi. Mavzuga qaytib yangi mashq oching; oldingi progress saqlanadi.';
      }
      if (detail == 'finish_previous_lesson') {
        return 'Avval oldingi mavzuni yakunlang.';
      }
      if (detail == 'finish_previous_book') {
        return 'Avval oldingi kitob qismini yakunlang.';
      }
      if (detail == 'math_source_gap_preview_disabled') {
        return 'Bu manba kamchiligi bilan sinash sozlamasi o‘chirilgan. Qoralamani o‘zgartirmay, test sozlamasi tiklangach shu urinishni davom ettiring.';
      }
      if (detail == 'mathematics_preview_disabled') {
        return 'Matematika bu test serverida yoqilmagan.';
      }
      if (detail == 'answer_request_id_conflict') {
        return 'Saqlangan jo‘natish bilan javob mos kelmadi. Mavzuni qayta ochib tekshiring.';
      }
      return 'Aloqa uzildi yoki server javob bermadi. Saqlangan jo‘natishni qayta urinib ko‘ring.';
    }
    return 'Davom etib bo‘lmadi. Qayta urinib ko‘ring.';
  }

  Future<void> _run(Future<void> Function(int) action) async {
    if (_busy) return;
    final generation = _generation;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action(generation);
    } catch (error) {
      if (mounted && generation == _generation) {
        setState(() => _error = _message(error));
        if (_attempt == null) _top();
      }
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  bool _active(int generation) => mounted && generation == _generation;
  Future<void> _save() {
    if (_lessonKey == null) return Future.value();
    final key = '$_namespace:$_lessonKey';
    final value = jsonEncode({
      'request': _request,
      'page': _page,
      'practicing': _practicing,
      'choice': _choice,
      'order': _order,
      'value': _input.text,
      'pending': _pending,
    });
    final preferences = widget.preferences;
    final activeKey = '$_namespace:active', lesson = _lessonKey!;
    _writes = _writes
        .catchError((_) {})
        .then((_) async {
          await preferences.setString(key, value);
          await preferences.setString(activeKey, lesson);
        })
        .timeout(const Duration(seconds: 5));
    return _writes;
  }

  void _persistDraft() {
    unawaited(
      _save().catchError((Object error) {
        if (mounted) {
          setState(
            () => _error =
                'Qoralamani saqlab bo‘lmadi. Davom etishdan oldin qayta urinib ko‘ring.',
          );
        }
      }),
    );
  }

  Future<void> _load() => _run((generation) async {
    final catalog = await widget.repository.catalog(
      _cancel,
      grade: _grade,
      part: _part,
    );
    if (!_active(generation)) return;
    setState(() => _catalog = catalog);
  });

  Future<void> _selectBook(String value) => _run((generation) async {
    final values = value.split(':').map(int.parse).toList();
    final catalog = await widget.repository.catalog(
      _cancel,
      grade: values[0],
      part: values[1],
    );
    if (!_active(generation)) return;
    setState(() {
      _grade = values[0];
      _part = values[1];
      _catalog = catalog;
      _lessonKey = null;
    });
    _top();
  });

  Future<void> _open(String key, {bool fresh = false}) => _run((
    generation,
  ) async {
    final repository = widget.repository, cancel = _cancel;
    _lessonKey = key;
    MathJson saved = {};
    try {
      saved =
          jsonDecode(widget.preferences.getString('$_namespace:$key') ?? '{}')
              as MathJson;
    } on FormatException {
      saved = {};
    }
    _request = fresh
        ? mathRequestId()
        : (saved['request'] as String? ?? mathRequestId());
    _page = fresh ? 0 : (saved['page'] as int? ?? 0);
    _practicing = !fresh && saved['practicing'] == true;
    _choice = fresh ? null : saved['choice'] as String?;
    _order = fresh ? [] : ((saved['order'] as List?)?.cast<String>() ?? []);
    _input.text = fresh ? '' : (saved['value'] as String? ?? '');
    _pending = fresh ? null : saved['pending'] as MathJson?;
    await _save(); // Persist the stable start UUID before issuing a request.
    if (!_active(generation)) return;
    final attempt = await repository.start(key, _request!, cancel);
    if (!_active(generation)) return;
    setState(() {
      _attempt = attempt;
      _feedback = null;
      _result = attempt['result'] as MathJson?;
    });
    final cards = mathRows((_attempt!['content'] as Map)['cards']);
    if (_page < 0 || _page > cards.length) _page = 0;
    _top();
  });

  void _top() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) _scroll.jumpTo(0);
    });
  }

  void _teachNext() {
    final cards = mathRows((_attempt!['content'] as Map)['cards']);
    setState(() {
      if (_page < cards.length) {
        _page++;
      } else {
        _practicing = true;
      }
    });
    _persistDraft();
    _top();
  }

  Future<void> _submit() => _run((generation) async {
    final repository = widget.repository, cancel = _cancel;
    final attemptId = _attempt!['attempt_id'] as String;
    if (_pending == null) {
      final question = _question;
      if (question == null) return;
      final answer = question['response_kind'] == 'choice'
          ? {'choice_id': _choice}
          : question['response_kind'] == 'ordering'
          ? {'order': List<String>.of(_order)}
          : {'value': _input.text.trim()};
      _pending = {
        'request_id': mathRequestId(),
        'question_id': question['id'],
        'answer': answer,
      };
      await _save();
    }
    if (!_active(generation)) return;
    MathJson response;
    try {
      response = await repository.answer(attemptId, _pending!, cancel);
    } on DioException catch (error) {
      if (_active(generation) && error.response?.statusCode == 422) {
        // Server rejected syntax without grading it: editing is safe. A timeout
        // retains the UUID/payload because the server may already have accepted it.
        setState(() => _pending = null);
        await _save();
      }
      rethrow;
    }
    if (!_active(generation)) return;
    setState(() {
      _feedback = response;
      _pending = null;
      final answers = mathRows(_attempt!['answers']);
      answers.removeWhere((a) => a['request_id'] == response['request_id']);
      answers.add(response);
      _attempt!['answers'] = answers;
    });
    await _save();
    _top();
  });

  void _continue() {
    setState(() {
      _feedback = null;
      _choice = null;
      _order = [];
      _input.clear();
    });
    _persistDraft();
    _top();
  }

  Future<void> _complete() => _run((generation) async {
    final result = await widget.repository.complete(
      _attempt!['attempt_id'] as String,
      _request!,
      _cancel,
    );
    if (!_active(generation)) return;
    setState(() => _result = result);
    final catalog = await widget.repository.catalog(
      _cancel,
      grade: _grade,
      part: _part,
    );
    if (_active(generation)) setState(() => _catalog = catalog);
    await _save();
    _top();
  });

  void _topics() {
    setState(() {
      _attempt = _feedback = _result = null;
      _pending = null;
      _error = null;
    });
    _top();
  }

  Widget _sources(dynamic refs) {
    final reference = mathRows(refs).first;
    final roman = {1: 'I', 2: 'II', 3: 'III', 4: 'IV'}[reference['part']];
    final book = mathRows(
      _catalog?['available_books'] ?? [],
    ).where((b) => b['book_id'] == reference['book_id']).firstOrNull;
    final bibliography = book?['bibliography'] as Map?;
    final year = bibliography?['year'];
    return ExpansionTile(
      title: const Text('Manba'),
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            '${reference['grade']}-sinf Matematika, ${roman ?? reference['part']} qism${year == null ? '' : ', $year'}. PDF: ${(reference['pdf_pages'] as List).join('–')}. Bosma: ${(reference['printed_pages'] as List).join('–')}.${bibliography?['isbn'] == null ? '' : ' ISBN: ${bibliography!['isbn']}.'}',
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    if (_attempt == null) {
      children.add(
        Text(
          _catalog?['book']?['label'] as String? ??
              '$_grade-sinf · ${const {1: 'I', 2: 'II', 3: 'III', 4: 'IV'}[_part]} qism',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      );
      if (_catalog != null) {
        final books = mathRows(_catalog!['available_books'] ?? []);
        if (books.length > 1) {
          children.add(
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Sinf va kitob qismi',
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  key: ValueKey('math-book-$_grade-$_part'),
                  value: '$_grade:$_part',
                  isExpanded: true,
                  items: [
                    for (final book in books)
                      DropdownMenuItem(
                        value: '${book['grade']}:${book['part']}',
                        child: Text(book['label'] as String),
                      ),
                  ],
                  onChanged: _busy
                      ? null
                      : (value) {
                          if (value != null) unawaited(_selectBook(value));
                        },
                ),
              ),
            ),
          );
        }
        final book = _catalog!['book'] as Map?;
        if (book?['source_topic_count'] is int) {
          children.add(
            Text(
              'Hozir mavjud darslar: ${book!['implemented_sections']} / ${book['source_topic_count']}.',
            ),
          );
        } else if (book?['source_body_topic_count'] is int) {
          children.add(
            Text(
              'Darslikdagi matnli mavzulardan: ${book!['implemented_sections']} / ${book['source_body_topic_count']}.',
            ),
          );
        }
        final bridge = _catalog!['source_gap_bridge'] as Map?;
        final sequenceBridge = _catalog!['source_sequence_gap_bridge'] as Map?;
        if (sequenceBridge != null) {
          children.add(Text(sequenceBridge['message'] as String));
        } else if (bridge != null) {
          children.add(Text(bridge['message'] as String));
        } else if (_catalog!['previous_book_complete'] == false) {
          children.add(
            const Text(
              'Bu qismni boshlash uchun avval oldingi kitob qismini yakunlang.',
            ),
          );
        } else if ((book?['source_gaps'] as List?)?.isNotEmpty == true) {
          children.add(
            Text(
              (book!['source_gaps'] as List).any(
                    (v) => v['kind'] == 'toc_scheduled_activity_no_body',
                  )
                  ? 'Mundarijadagi ayrim nazorat va o‘yin mashg‘ulotlarining alohida matni berilmagan. Ular tayyor dars hisoblanmaydi.'
                  : 'Bu kitobning ayrim manba sahifalari yetishmaydi. Faqat tekshirilgan mavjud mavzular ko‘rsatilgan.',
            ),
          );
        }
        if (bridge != null &&
            book?['source_body_topic_count'] == book?['implemented_sections'] &&
            (book?['source_gaps'] as List?)?.any(
                  (v) => v['kind'] == 'toc_scheduled_activity_no_body',
                ) ==
                true) {
          children.add(
            const Text(
              'Matnli mavzular qamrab olindi. Alohida matni berilmagan nazorat va o‘yin mashg‘ulotlari hali tayyor emas.',
            ),
          );
        }
        for (final lesson in mathRows(_catalog!['lessons'])) {
          children.add(
            Card(
              child: ListTile(
                key: ValueKey(lesson['key']),
                title: Text(lesson['title'] as String),
                subtitle:
                    lesson.containsKey('source_number') &&
                        lesson['source_number'] == null
                    ? null
                    : Text(
                        '${lesson['source_number'] ?? lesson['sequence']}-mavzu',
                      ),
                leading: Icon(
                  lesson['state'] == 'locked'
                      ? Icons.lock_outline
                      : lesson['state'] == 'completed'
                      ? Icons.check_circle_outline
                      : Icons.play_circle_outline,
                ),
                onTap: _busy || lesson['state'] == 'locked'
                    ? null
                    : () => _open(lesson['key'] as String),
              ),
            ),
          );
        }
      }
    } else if (_result != null) {
      children.addAll([
        const MascotImage(pose: MascotPose.happy, size: 100),
        const Text(
          'Mashq yakunlandi!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          'Bajarilgan topshiriq: ${_result!['completed_questions']}. XP: +${_result!['xp_awarded']}.',
        ),
        const Text(
          'Yordam olish o‘rganishning bir qismi. Istasang, mavzuni yana ko‘rib chiq.',
        ),
        FilledButton(
          onPressed: _busy ? null : _topics,
          child: const Text('Mavzularga qaytish'),
        ),
        TextButton(
          onPressed: _busy ? null : () => _open(_lessonKey!, fresh: true),
          child: const Text('Yana mashq qilish'),
        ),
      ]);
    } else if (!_practicing) {
      final content = _attempt!['content'] as Map;
      final cards = mathRows(content['cards']);
      children.add(
        Text(
          _attempt!['title'] as String,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      );
      final bridge =
          (_attempt!['source_sequence_gap_bridge'] ??
                  _attempt!['source_gap_bridge'])
              as Map?;
      if (bridge != null) {
        children.add(
          ExpansionTile(
            title: const Text('Sinov rejimi'),
            children: [Text(bridge['message'] as String)],
          ),
        );
      }
      if (_page < cards.length) {
        final card = cards[_page];
        children.addAll([
          const MascotImage(pose: MascotPose.explaining),
          Text(
            card['title'] as String,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),
          Text(card['body'] as String),
          MathExplorer(
            key: ValueKey(content['explorer']['type']),
            mode: content['explorer']['type'] as String,
          ),
          _sources(card['source_refs']),
        ]);
      } else {
        for (final notation in mathRows(content['formulas'])) {
          children.add(
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notation['title'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      notation['expression'] as String,
                      style: const TextStyle(fontSize: 24),
                    ),
                    Text(notation['meaning'] as String),
                    _sources(notation['source_refs']),
                  ],
                ),
              ),
            ),
          );
        }
        for (final example in mathRows(content['examples'])) {
          if (example['visual'] != null) {
            children.add(MathBoard(scene: example['visual'] as MathJson));
          }
          children.add(
            Text(
              example['title'] as String,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
          );
          for (final step in mathRows(example['steps'])) {
            children.add(
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(step['action'] as String),
                      const SizedBox(height: 8),
                      Text(step['why'] as String),
                    ],
                  ),
                ),
              ),
            );
          }
          children.add(_sources(example['source_refs']));
        }
      }
      children.add(
        FilledButton(
          onPressed: _busy ? null : _teachNext,
          child: Text(_page < cards.length ? 'Davom etish' : 'Birga yechamiz'),
        ),
      );
      if (_page > 0) {
        children.add(
          TextButton(
            onPressed: _busy
                ? null
                : () {
                    setState(() => _page--);
                    _persistDraft();
                    _top();
                  },
            child: const Text('Oldingi tushuntirish'),
          ),
        );
      }
    } else if (_feedback != null) {
      final correct = _feedback!['is_correct'] == true;
      children.addAll([
        MascotImage(
          pose: correct ? MascotPose.happy : MascotPose.thinking,
          size: 90,
        ),
        Semantics(
          liveRegion: true,
          child: Text(
            correct ? 'Topding!' : 'Birga o‘ylab ko‘ramiz',
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
          ),
        ),
        Text(_feedback!['feedback'] as String),
        FilledButton(
          onPressed: _busy ? null : _continue,
          child: Text(correct ? 'Davom etish' : 'Yana urinib ko‘rish'),
        ),
        _sources(_feedback!['source_refs']),
      ]);
    } else if (_question == null) {
      children.addAll([
        const Text('Mashqlar bajarildi. Natijani saqlaymiz.'),
        FilledButton(
          onPressed: _busy ? null : _complete,
          child: const Text('Natijani saqlash'),
        ),
      ]);
    } else {
      final q = _question!;
      final answered = _solved.length;
      final duration = MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 200);
      children.addAll([
        TweenAnimationBuilder<double>(
          tween: Tween(end: answered / _questions.length),
          duration: duration,
          builder: (_, v, _) => LinearProgressIndicator(
            value: v,
            semanticsLabel: 'Dars progressi',
          ),
        ),
        Text(
          q['phase'] == 'guided'
              ? 'Birga yechamiz'
              : q['phase'] == 'transfer'
              ? 'Yangi vaziyatda sinab ko‘r'
              : 'O‘zing yechib ko‘r',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          q['prompt'] as String,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ]);
      if (q['visual'] != null) {
        children.add(
          MathBoard(
            scene: q['visual'] as MathJson,
            selected: _choice,
            onSelect:
                q['response_kind'] != 'choice' || _pending != null || _busy
                ? null
                : (id) {
                    if (mathRows(q['choices']).any((c) => c['id'] == id)) {
                      setState(() => _choice = id);
                      _persistDraft();
                    }
                  },
          ),
        );
      }
      if (q['response_kind'] == 'choice') {
        children.add(
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final choice in mathRows(q['choices']))
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: 56,
                    minWidth: 64,
                  ),
                  child: ChoiceChip(
                    label: Text(choice['label'] as String),
                    selected: _choice == choice['id'],
                    onSelected: _busy || _pending != null
                        ? null
                        : (_) {
                            setState(() => _choice = choice['id'] as String);
                            _persistDraft();
                          },
                  ),
                ),
            ],
          ),
        );
      } else if (q['response_kind'] == 'ordering') {
        final items = mathRows(q['items']);
        children.add(const Text('Qadamlarni birinchisidan boshlab tanla.'));
        for (var i = 0; i < _order.length; i++) {
          final label = items.firstWhere(
            (item) => item['id'] == _order[i],
          )['label'];
          children.add(Text('${i + 1}. $label'));
        }
        children.add(
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in items)
                ActionChip(
                  label: Text(item['label'] as String),
                  onPressed:
                      _busy || _pending != null || _order.contains(item['id'])
                      ? null
                      : () {
                          setState(() => _order.add(item['id'] as String));
                          _persistDraft();
                        },
                ),
            ],
          ),
        );
        children.add(
          TextButton(
            onPressed: _busy || _pending != null || _order.isEmpty
                ? null
                : () {
                    setState(() => _order.removeLast());
                    _persistDraft();
                  },
            child: const Text('Oxirgi tanlovni qaytarish'),
          ),
        );
      } else {
        children.add(
          TextField(
            controller: _input,
            enabled: !_busy && _pending == null,
            maxLength: q['response_kind'] == 'exact_number' ? 160 : 80,
            decoration: const InputDecoration(
              labelText: 'Javobing',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) {
              setState(() {});
              _persistDraft();
            },
            keyboardType: q['response_kind'] == 'exact_number'
                ? const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  )
                : TextInputType.text,
          ),
        );
      }
      children.add(
        FilledButton(
          onPressed:
              _busy ||
                  (_pending == null &&
                      (q['response_kind'] == 'choice'
                          ? _choice == null
                          : q['response_kind'] == 'ordering'
                          ? _order.length != (q['items'] as List).length
                          : _input.text.trim().isEmpty))
              ? null
              : _submit,
          child: Text(
            _pending == null
                ? 'Tekshirish'
                : 'Saqlangan javobni qayta jo‘natish',
          ),
        ),
      );
      children.add(
        TextButton(
          onPressed: _busy
              ? null
              : () {
                  setState(() {
                    _practicing = false;
                    _page = 0;
                  });
                  _persistDraft();
                  _top();
                },
          child: const Text('Tushuntirishga qaytish'),
        ),
      );
      children.add(_sources(q['source_refs']));
    }
    if (_error != null) {
      children.insert(
        _attempt == null ? 0 : children.length,
        Semantics(
          liveRegion: true,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(_error!),
                  if (_attempt == null)
                    TextButton(
                      onPressed: _busy ? null : _load,
                      child: const Text('Qayta yuklash'),
                    ),
                  if (_lessonKey != null)
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => _open(_lessonKey!, fresh: true),
                      child: const Text('Yangi urinish ochish'),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    if (_busy) {
      children.add(
        const Center(
          child: CircularProgressIndicator(semanticsLabel: 'Yuklanmoqda'),
        ),
      );
    }
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ILM AI · Matematika'),
          leading: _attempt == null
              ? null
              : IconButton(
                  tooltip: 'Mavzularga qaytish',
                  onPressed: _busy ? null : _topics,
                  icon: const Icon(Icons.arrow_back),
                ),
        ),
        body: SafeArea(
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.all(16),
            children: [
              for (final child in children)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: child,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
