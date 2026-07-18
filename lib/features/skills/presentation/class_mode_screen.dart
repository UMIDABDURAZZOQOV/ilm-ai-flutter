import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../data/skill_extras_models.dart';
import '../data/skill_extras_repository.dart';
import '../data/skill_tree_models.dart';
import '../data/skill_tree_repository.dart';
import 'skill_ui.dart';

class ClassModeScreen extends ConsumerStatefulWidget {
  const ClassModeScreen({super.key});

  @override
  ConsumerState<ClassModeScreen> createState() => _ClassModeScreenState();
}

class _ClassModeScreenState extends ConsumerState<ClassModeScreen> {
  bool _loading = true;
  MyClasses? _classes;
  List<SkillSubject> _subjects = [];
  final _nameCtrl = TextEditingController();
  final _joinCtrl = TextEditingController();
  String? _newSubject;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _joinCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final r = await ref.read(skillExtrasRepositoryProvider).getMyClasses();
      final subs = await ref.read(skillTreeRepositoryProvider).getSubjects();
      _classes = r;
      _subjects = subs;
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _toast(String msg) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _create() async {
    final lang = ref.read(languageProvider);
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref.read(skillExtrasRepositoryProvider).createClass(_nameCtrl.text.trim(), _newSubject);
      _nameCtrl.clear();
      _newSubject = null;
      await _load();
      _toast(str3(lang, 'Sinf yaratildi', 'Класс создан', 'Class created'));
    } catch (_) {
      _toast(str3(lang, 'Xatolik', 'Ошибка', 'Error'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join() async {
    final lang = ref.read(languageProvider);
    if (_joinCtrl.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      final r = await ref.read(skillExtrasRepositoryProvider).joinClass(_joinCtrl.text.trim());
      _joinCtrl.clear();
      await _load();
      _toast(r['already'] == true
          ? str3(lang, "Siz allaqachon a'zosiz", 'Вы уже в классе', 'Already a member')
          : str3(lang, "Sinfga qo'shildingiz", 'Вы вступили в класс', 'Joined the class'));
    } catch (_) {
      _toast(str3(lang, "Kod noto'g'ri", 'Неверный код', 'Invalid code'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    return Scaffold(
      appBar: AppBar(title: Text(str3(lang, 'Sinf rejimi', 'Классы', 'Classes'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_classes!.teaching.isNotEmpty) ...[
                  _label(str3(lang, "Men o'qituvchi", 'Я преподаю', 'I teach')),
                  for (final c in _classes!.teaching)
                    _classTile(
                      icon: Icons.groups_rounded,
                      color: const Color(0xFF4C6EF5),
                      title: c.name,
                      subtitle: '${c.memberCount} ${str3(lang, "o'quvchi", 'учеников', 'students')} · ${str3(lang, 'kod', 'код', 'code')} ${c.joinCode}',
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ClassDetailScreen(classId: c.id))),
                    ),
                  const SizedBox(height: 16),
                ],
                if (_classes!.enrolled.isNotEmpty) ...[
                  _label(str3(lang, "Men o'quvchi", 'Я учусь', "I'm enrolled")),
                  for (final c in _classes!.enrolled)
                    _classTile(
                      icon: Icons.menu_book_rounded,
                      color: const Color(0xFF58CC02),
                      title: c.name,
                      subtitle: '${str3(lang, "O'qituvchi", 'Учитель', 'Teacher')}: ${c.teacherName}',
                    ),
                  const SizedBox(height: 16),
                ],
                _card(
                  title: str3(lang, 'Yangi sinf ochish', 'Создать класс', 'Open a class'),
                  child: Column(
                    children: [
                      TextField(controller: _nameCtrl, decoration: _dec(str3(lang, 'Sinf nomi (masalan: 11-A)', 'Название класса', 'Class name'))),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(child: _subjectDropdown(lang, _newSubject, (v) => setState(() => _newSubject = v))),
                        const SizedBox(width: 8),
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF4C6EF5)),
                          onPressed: _busy ? null : _create,
                          child: Text(str3(lang, 'Yaratish', 'Создать', 'Create')),
                        ),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _card(
                  title: str3(lang, "Sinfga qo'shilish", 'Вступить в класс', 'Join a class'),
                  child: Row(children: [
                    Expanded(child: TextField(controller: _joinCtrl, textCapitalization: TextCapitalization.characters, decoration: _dec('ABC123'))),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF58CC02)),
                      onPressed: _busy ? null : _join,
                      child: Text(str3(lang, "Qo'shilish", 'Вступить', 'Join')),
                    ),
                  ]),
                ),
              ],
            ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8))),
      );

  Widget _classTile({required IconData icon, required Color color, required String title, required String subtitle, VoidCallback? onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.16), child: Icon(icon, color: color)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: onTap != null ? const Icon(Icons.chevron_right_rounded) : null,
      ),
    );
  }

  Widget _card({required String title, required Widget child}) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          child,
        ]),
      );

  Widget _subjectDropdown(String lang, String? value, ValueChanged<String?> onChanged) => DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: _dec(str3(lang, 'Fan (ixtiyoriy)', 'Предмет (опц.)', 'Subject (optional)')),
        items: [
          DropdownMenuItem(value: null, child: Text(str3(lang, 'Fan (ixtiyoriy)', 'Предмет (опц.)', 'Subject (optional)'))),
          for (final s in _subjects) DropdownMenuItem(value: s.slug, child: Text(s.nameFor(lang))),
        ],
        onChanged: onChanged,
      );

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );
}

// ─── Class detail (teacher) ────────────────────────────────────────────────────

class ClassDetailScreen extends ConsumerStatefulWidget {
  final int classId;
  const ClassDetailScreen({super.key, required this.classId});

  @override
  ConsumerState<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends ConsumerState<ClassDetailScreen> {
  bool _loading = true;
  ClassDetail? _detail;
  List<SkillSubject> _subjects = [];
  final _assignCtrl = TextEditingController();
  String? _assignSubject;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _assignCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      _detail = await ref.read(skillExtrasRepositoryProvider).getClassDetail(widget.classId);
      if (_subjects.isEmpty) _subjects = await ref.read(skillTreeRepositoryProvider).getSubjects();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _assign() async {
    if (_assignCtrl.text.trim().isEmpty) return;
    await ref.read(skillExtrasRepositoryProvider).createAssignment(widget.classId, _assignCtrl.text.trim(), _assignSubject);
    _assignCtrl.clear();
    _assignSubject = null;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final d = _detail;
    return Scaffold(
      appBar: AppBar(
        title: Text(d?.name ?? str3(lang, 'Sinf', 'Класс', 'Class')),
        actions: [
          if (d != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(child: Chip(label: Text('${str3(lang, 'Kod', 'Код', 'Code')}: ${d.joinCode}', style: const TextStyle(fontWeight: FontWeight.w800)))),
            ),
        ],
      ),
      body: _loading || d == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('${str3(lang, "O'quvchilar", 'Ученики', 'Students')} (${d.roster.length})', style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                if (d.roster.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: Text(str3(lang, "Hali o'quvchi yo'q. Kodni ulashing.", 'Пока нет учеников. Поделитесь кодом.', 'No students yet. Share the code.'), style: TextStyle(color: Colors.grey.shade600))),
                  ),
                for (var i = 0; i < d.roster.length; i++) _rosterTile(lang, i + 1, d.roster[i]),
                const SizedBox(height: 20),
                Text(str3(lang, 'Vazifalar', 'Задания', 'Assignments'), style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                for (final a in d.assignments)
                  Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      dense: true,
                      title: Text(a.title),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 20),
                        onPressed: () async {
                          await ref.read(skillExtrasRepositoryProvider).deleteAssignment(widget.classId, a.id);
                          await _load();
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _assignCtrl,
                      decoration: InputDecoration(
                        hintText: str3(lang, 'Vazifa nomi', 'Название задания', 'Assignment title'),
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFF4C6EF5)),
                    onPressed: _assign,
                    child: const Icon(Icons.add_rounded),
                  ),
                ]),
              ],
            ),
    );
  }

  Widget _rosterTile(String lang, int n, StudentRow r) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: Text('$n', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey.shade500)),
        title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Row(children: [
          const Icon(Icons.menu_book_rounded, size: 13),
          Text(' ${r.lessonsCompleted}   '),
          const Icon(Icons.bolt_rounded, size: 13, color: Color(0xFFFFC800)),
          Text(' ${r.weeklyXp}   '),
          const Icon(Icons.local_fire_department_rounded, size: 13, color: Color(0xFFFF9600)),
          Text(' ${r.streakDays}'),
          if (r.activeToday) Text('   ● ${str3(lang, 'faol', 'активен', 'active')}', style: const TextStyle(color: Color(0xFF58CC02), fontWeight: FontWeight.w700, fontSize: 11)),
        ]),
        trailing: IconButton(
          icon: const Icon(Icons.person_remove_outlined, size: 20),
          onPressed: () async {
            await ref.read(skillExtrasRepositoryProvider).removeMember(widget.classId, r.userId);
            await _load();
          },
        ),
      ),
    );
  }
}
