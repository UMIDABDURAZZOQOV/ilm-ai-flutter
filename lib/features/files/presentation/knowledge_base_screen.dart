import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/network/error_message.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../auth/application/auth_controller.dart';
import '../data/files_models.dart';
import '../data/files_repository.dart';

final _filesListProvider = FutureProvider.autoDispose<List<FileItem>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  return ref.read(filesRepositoryProvider).list(userId);
});

/// Text-paste upload only for Phase 2 -- native file picking (PDF/Word)
/// depends on the `file_picker` plugin, which is currently incompatible
/// with this project's AGP9/Kotlin toolchain (see pubspec.yaml note).
/// Revisited once that's resolved.
class KnowledgeBaseScreen extends ConsumerStatefulWidget {
  const KnowledgeBaseScreen({super.key});

  @override
  ConsumerState<KnowledgeBaseScreen> createState() => _KnowledgeBaseScreenState();
}

class _KnowledgeBaseScreenState extends ConsumerState<KnowledgeBaseScreen> {
  String? _error;

  Future<void> _confirmDelete(String filename) async {
    final language = ref.read(languageProvider);
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('files.delete.confirm', language)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t('common.cancel', language))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(t('common.delete', language), style: TextStyle(color: colors.error))),
        ],
      ),
    );
    if (confirmed != true) return;
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    try {
      await ref.read(filesRepositoryProvider).delete(userId: userId, filename: filename);
      ref.invalidate(_filesListProvider);
    } catch (e) {
      setState(() => _error = extractError(e));
    }
  }

  Future<void> _showEditTopicSheet(FileItem file) async {
    final language = ref.read(languageProvider);
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final topicCtrl = TextEditingController(text: file.topic);
    bool saving = false;
    String? sheetError;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(file.filename, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.text), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 16),
              ErrorBanner(message: sheetError, onDismiss: () => setSheetState(() => sheetError = null)),
              TextField(
                controller: topicCtrl,
                decoration: InputDecoration(
                  hintText: t('files.topic.placeholder', language),
                  filled: true,
                  fillColor: colors.inputBackground,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.border)),
                ),
              ),
              const SizedBox(height: 16),
              GradientButton(
                loading: saving,
                onPressed: () async {
                  final userId = ref.read(currentUserIdProvider);
                  if (userId == null) return;
                  setSheetState(() => saving = true);
                  try {
                    await ref.read(filesRepositoryProvider).updateTopic(userId: userId, filename: file.filename, newTopic: topicCtrl.text.trim());
                    ref.invalidate(_filesListProvider);
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    setSheetState(() {
                      sheetError = extractError(e);
                      saving = false;
                    });
                  }
                },
                child: Text(t('common.save', language)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showUploadTextSheet() async {
    final language = ref.read(languageProvider);
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final filenameCtrl = TextEditingController();
    final topicCtrl = TextEditingController();
    final textCtrl = TextEditingController();
    bool uploading = false;
    String? sheetError;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t('files.upload.text.button', language), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colors.text)),
              const SizedBox(height: 16),
              ErrorBanner(message: sheetError, onDismiss: () => setSheetState(() => sheetError = null)),
              TextField(
                controller: filenameCtrl,
                decoration: InputDecoration(
                  hintText: t('files.filename.placeholder', language),
                  filled: true,
                  fillColor: colors.inputBackground,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.border)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: topicCtrl,
                decoration: InputDecoration(
                  hintText: t('files.topic.placeholder', language),
                  filled: true,
                  fillColor: colors.inputBackground,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.border)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: textCtrl,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: t('files.text.placeholder', language),
                  filled: true,
                  fillColor: colors.inputBackground,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colors.border)),
                ),
              ),
              const SizedBox(height: 16),
              GradientButton(
                loading: uploading,
                onPressed: () async {
                  final userId = ref.read(currentUserIdProvider);
                  if (userId == null || filenameCtrl.text.trim().isEmpty || textCtrl.text.trim().isEmpty) return;
                  setSheetState(() => uploading = true);
                  try {
                    await ref.read(filesRepositoryProvider).uploadText(
                          userId: userId,
                          filename: filenameCtrl.text.trim(),
                          text: textCtrl.text.trim(),
                          topic: topicCtrl.text.trim(),
                        );
                    ref.invalidate(_filesListProvider);
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    setSheetState(() {
                      sheetError = extractError(e);
                      uploading = false;
                    });
                  }
                },
                child: Text(t('files.upload.text.button', language)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final language = ref.watch(languageProvider);
    final filesAsync = ref.watch(_filesListProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t('files.title', language))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showUploadTextSheet,
        icon: const Icon(Icons.note_add_outlined),
        label: Text(t('files.upload.text.button', language)),
        backgroundColor: colors.primary,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ErrorBanner(message: _error, onDismiss: () => setState(() => _error = null)),
              Expanded(
                child: filesAsync.when(
                  data: (files) {
                    if (files.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.folder_open, size: 48, color: colors.textMuted),
                            const SizedBox(height: 12),
                            Text(t('files.empty', language), style: TextStyle(color: colors.text, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(t('files.empty.desc', language), style: TextStyle(color: colors.textMuted)),
                          ],
                        ),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () async => ref.invalidate(_filesListProvider),
                      child: ListView.separated(
                        itemCount: files.length,
                        separatorBuilder: (context, i) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final f = files[i];
                          return InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _showEditTopicSheet(f),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(color: colors.primaryLight, borderRadius: BorderRadius.circular(10)),
                                    child: Icon(Icons.description, color: colors.primary, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(f.filename, style: TextStyle(fontWeight: FontWeight.w600, color: colors.text), overflow: TextOverflow.ellipsis),
                                        if (f.topic.isNotEmpty) Text(f.topic, style: TextStyle(fontSize: 12, color: colors.textSecondary)),
                                        Text('${f.chunks} ${t('files.chunks', language)}', style: TextStyle(fontSize: 11, color: colors.textMuted)),
                                      ],
                                    ),
                                  ),
                                  IconButton(icon: Icon(Icons.edit_outlined, color: colors.textMuted, size: 18), onPressed: () => _showEditTopicSheet(f)),
                                  IconButton(icon: Icon(Icons.delete_outline, color: colors.error, size: 20), onPressed: () => _confirmDelete(f.filename)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text(extractError(e), style: TextStyle(color: colors.error))),
                ),
              ),
              const SizedBox(height: 72),
            ],
          ),
        ),
      ),
    );
  }
}
