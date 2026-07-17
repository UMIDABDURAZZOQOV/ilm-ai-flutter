import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/charts/math_graph_painter.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/network/error_message.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../auth/application/auth_controller.dart';
import '../data/math_models.dart';
import '../data/math_repository.dart';

enum _Mode { camera, type }

class MathSolverScreen extends ConsumerStatefulWidget {
  const MathSolverScreen({super.key});

  @override
  ConsumerState<MathSolverScreen> createState() => _MathSolverScreenState();
}

class _MathSolverScreenState extends ConsumerState<MathSolverScreen> {
  _Mode _mode = _Mode.camera;
  String? _imagePath;
  final _problemText = TextEditingController();
  bool _solving = false;
  String? _error;
  MathSolveResult? _result;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 85);
    if (file == null) return;
    setState(() {
      _imagePath = file.path;
      _result = null;
      _error = null;
    });
  }

  Future<void> _solve() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final language = ref.read(languageProvider);
    if (_mode == _Mode.camera && _imagePath == null) return;
    if (_mode == _Mode.type && _problemText.text.trim().isEmpty) return;

    setState(() {
      _solving = true;
      _error = null;
    });
    try {
      final result = _mode == _Mode.camera
          ? await ref.read(mathRepositoryProvider).solveImage(userId: userId, language: language, imagePath: _imagePath!)
          : await ref.read(mathRepositoryProvider).solveText(userId: userId, problem: _problemText.text.trim(), language: language);
      setState(() => _result = result);
    } catch (e) {
      final msg = extractError(e);
      setState(() => _error = msg.toLowerCase().contains('403') || msg.toLowerCase().contains('limit')
          ? t('math.limit.reached', language)
          : t('math.error.generic', language));
    } finally {
      if (mounted) setState(() => _solving = false);
    }
  }

  void _reset() {
    setState(() {
      _imagePath = null;
      _problemText.clear();
      _result = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final language = ref.watch(languageProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t('math.title', language))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_result == null) ...[
                Text(t('math.subtitle', language), style: TextStyle(color: colors.textSecondary, fontSize: 14)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _ModeTab(label: t('math.mode.camera', language), selected: _mode == _Mode.camera, colors: colors, onTap: () => setState(() => _mode = _Mode.camera)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ModeTab(label: t('math.mode.type', language), selected: _mode == _Mode.type, colors: colors, onTap: () => setState(() => _mode = _Mode.type)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ErrorBanner(message: _error, onDismiss: () => setState(() => _error = null)),
                if (_mode == _Mode.camera) ...[
                  if (_imagePath != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(File(_imagePath!), height: 220, width: double.infinity, fit: BoxFit.cover),
                    )
                  else
                    Container(
                      height: 180,
                      decoration: BoxDecoration(color: colors.primaryLight, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
                      child: Center(child: Icon(Icons.photo_camera_outlined, size: 48, color: colors.primary)),
                    ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: GradientButton(outline: true, onPressed: () => _pickImage(ImageSource.camera), child: Text(t('math.take.photo', language))),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GradientButton(outline: true, onPressed: () => _pickImage(ImageSource.gallery), child: Text(t('math.choose.gallery', language))),
                      ),
                    ],
                  ),
                ] else
                  TextField(
                    controller: _problemText,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: t('math.input.placeholder', language),
                      filled: true,
                      fillColor: colors.inputBackground,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.border)),
                    ),
                  ),
                const SizedBox(height: 20),
                GradientButton(
                  onPressed: _solving ? null : _solve,
                  loading: _solving,
                  child: Text(_solving ? t('math.solving', language) : t('math.solve.button', language)),
                ),
                const SizedBox(height: 20),
                Text(t('math.empty.hint', language), style: TextStyle(color: colors.textMuted, fontSize: 12), textAlign: TextAlign.center),
              ] else ...[
                _ResultView(result: _result!, colors: colors, language: language),
                const SizedBox(height: 20),
                GradientButton(outline: true, onPressed: _reset, child: Text(t('math.result.new.problem', language))),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final bool selected;
  final ThemeColors colors;
  final VoidCallback onTap;
  const _ModeTab({required this.label, required this.selected, required this.colors, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? colors.primary : colors.border, width: 1.5),
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(color: selected ? Colors.white : colors.text, fontWeight: FontWeight.w700),
          child: Text(label),
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  final MathSolveResult result;
  final ThemeColors colors;
  final String language;
  const _ResultView({required this.result, required this.colors, required this.language});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t('math.result.recognized', language), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.textMuted)),
              const SizedBox(height: 4),
              Text(result.recognizedProblem, style: TextStyle(color: colors.text, fontSize: 15)),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.06, end: 0, curve: Curves.easeOutCubic),
        const SizedBox(height: 16),
        Text(t('math.result.steps.title', language), style: TextStyle(fontWeight: FontWeight.w700, color: colors.text, fontSize: 15)),
        const SizedBox(height: 10),
        for (var i = 0; i < result.steps.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: colors.primaryLight, shape: BoxShape.circle),
                  child: Text('${i + 1}', style: TextStyle(color: colors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(result.steps[i].expression, style: TextStyle(fontWeight: FontWeight.w700, color: colors.text, fontFamily: 'monospace')),
                      const SizedBox(height: 4),
                      Text(result.steps[i].explanation, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: (80 + i * 70).ms, duration: 280.ms).slideX(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
        if (result.graph != null) ...[
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
              child: MathGraphPlot(graph: result.graph!),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(gradient: LinearGradient(colors: [colors.primary, colors.secondary]), borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t('math.result.answer.title', language), style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(result.finalAnswer, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
            ],
          ),
        ).animate().fadeIn(delay: 200.ms, duration: 350.ms).scale(begin: const Offset(0.94, 0.94), end: const Offset(1, 1), curve: Curves.easeOutBack),
      ],
    );
  }
}
