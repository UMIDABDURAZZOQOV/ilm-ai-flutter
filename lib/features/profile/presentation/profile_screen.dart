import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/network/error_message.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animated_pressable.dart';
import '../../../core/widgets/duo_icon.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/premium_button.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/data/auth_models.dart';
import '../../auth/data/auth_repository.dart';

/// Downscales + JPEG-compresses a picked photo to a small base64 data URI,
/// mirroring ilm-ai-mobile's pickAndPrepareAvatar() (expo-image-manipulator
/// equivalent, using the `image` package for pure-Dart resize/encode).
Future<String?> _pickAndPrepareAvatar() async {
  final picker = ImagePicker();
  final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
  if (file == null) return null;

  final bytes = await file.readAsBytes();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;

  final resized = img.copyResizeCropSquare(decoded, size: 256);
  final Uint8List jpg = img.encodeJpg(resized, quality: 70);
  return 'data:image/jpeg;base64,${base64Encode(jpg)}';
}

final _profileProvider = FutureProvider.autoDispose<UserProfile?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  return ref.read(authRepositoryProvider).getProfile(userId);
});

class _NavLink {
  final IconData icon;
  final String labelKey;
  final String location;
  const _NavLink({required this.icon, required this.labelKey, required this.location});
}

const _links = [
  _NavLink(icon: Icons.calculate_rounded, labelKey: 'math.title', location: '/profile/math-solver'),
  _NavLink(icon: Icons.star_rounded, labelKey: 'payment.title', location: '/profile/subscription'),
  _NavLink(icon: Icons.school_rounded, labelKey: 'college.title', location: '/profile/college'),
  _NavLink(icon: Icons.calendar_month_rounded, labelKey: 'plan.title', location: '/profile/learning-plan'),
  _NavLink(icon: Icons.gps_fixed_rounded, labelKey: 'gaps.title', location: '/profile/gaps'),
  _NavLink(icon: Icons.send_rounded, labelKey: 'telegram.title', location: '/profile/telegram'),
  _NavLink(icon: Icons.forum_rounded, labelKey: 'feedback.title', location: '/profile/feedback'),
  _NavLink(icon: Icons.settings_rounded, labelKey: 'settings.title', location: '/profile/settings'),
];

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _goal = TextEditingController();
  final _targetDate = TextEditingController();
  bool _saving = false;
  bool _saved = false;
  String? _error;
  bool _initialized = false;
  String? _avatar;
  bool _avatarSaving = false;

  Future<void> _handlePickAvatar() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final dataUri = await _pickAndPrepareAvatar();
    if (dataUri == null) return;
    final previous = _avatar;
    setState(() {
      _avatar = dataUri;
      _avatarSaving = true;
    });
    try {
      await ref.read(authRepositoryProvider).updateProfile(UpdateProfileRequest(userId: userId, avatar: dataUri));
    } catch (e) {
      setState(() {
        _avatar = previous;
        _error = extractError(e);
      });
    } finally {
      if (mounted) setState(() => _avatarSaving = false);
    }
  }

  Future<void> _save() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).updateProfile(UpdateProfileRequest(
            userId: userId,
            learningGoal: _goal.text,
            targetDate: _targetDate.text,
          ));
      setState(() => _saved = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _saved = false);
      });
    } catch (e) {
      setState(() => _error = extractError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmLogout() async {
    final language = ref.read(languageProvider);
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('auth.logout', language)),
        content: Text('${t('common.confirm', language)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t('common.cancel', language))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(t('auth.logout', language), style: TextStyle(color: colors.error))),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final language = ref.watch(languageProvider);
    final user = ref.watch(authControllerProvider).valueOrNull;
    final profileAsync = ref.watch(_profileProvider);

    profileAsync.whenData((profile) {
      if (!_initialized && profile != null) {
        _initialized = true;
        _goal.text = profile.learningGoal ?? '';
        _targetDate.text = profile.targetDate ?? '';
        _avatar = profile.profilePicture;
      }
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(t('profile.title', language), style: TextStyle(color: colors.text, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.5)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: _avatarSaving ? null : _handlePickAvatar,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 38,
                        backgroundColor: colors.primary,
                        backgroundImage: _avatar != null ? MemoryImage(base64Decode(_avatar!.split(',').last)) : null,
                        child: _avatar == null
                            ? Text(
                                (user?.name?.isNotEmpty == true ? user!.name![0] : 'U').toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                              )
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(color: colors.secondary, shape: BoxShape.circle, border: Border.all(color: colors.background, width: 2)),
                          child: _avatarSaving
                              ? const Padding(padding: EdgeInsets.all(4), child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.camera_alt_rounded, size: 13, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name ?? '—', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: colors.text)),
                      const SizedBox(height: 4),
                      Text(user?.email ?? '—', style: TextStyle(fontSize: 14, color: colors.textMuted, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            PremiumCard(
              borderRadius: 20,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ErrorBanner(message: _error, onDismiss: () => setState(() => _error = null)),
                  Text(t('profile.goal.placeholder', language), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: colors.textSecondary)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _goal,
                    maxLines: 2,
                    style: TextStyle(color: colors.text, fontSize: 15, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: t('profile.goal.placeholder', language),
                      hintStyle: TextStyle(color: colors.textMuted, fontSize: 14),
                      filled: true,
                      fillColor: colors.inputBackground,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(t('profile.date.placeholder', language), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: colors.textSecondary)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _targetDate,
                    style: TextStyle(color: colors.text, fontSize: 15, fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'YYYY-MM-DD',
                      hintStyle: TextStyle(color: colors.textMuted, fontSize: 14),
                      filled: true,
                      fillColor: colors.inputBackground,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 18),
                  PremiumButton(
                    onPressed: _saving ? null : _save,
                    loading: _saving,
                    borderRadius: 18,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(_saved ? t('profile.saved', language) : t('profile.save', language)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            for (var i = 0; i < _links.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AnimatedPressable(
                  onTap: () => context.push(_links[i].location),
                  child: PremiumCard(
                    borderRadius: 18,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(color: colors.primaryLight, borderRadius: BorderRadius.circular(12)),
                          child: DuoIcon(_links[i].icon, size: 20, color: colors.primary),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Text(t(_links[i].labelKey, language), style: TextStyle(fontWeight: FontWeight.w800, color: colors.text, fontSize: 15))),
                        Icon(Icons.chevron_right_rounded, color: colors.textMuted, size: 22),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: (60 * i).ms, duration: 280.ms).slideX(begin: 0.05, end: 0, curve: Curves.easeOutCubic),
            const SizedBox(height: 16),
            PremiumButton(
              onPressed: _confirmLogout,
              backgroundColor: colors.error,
              borderRadius: 18,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(t('auth.logout', language), style: const TextStyle(fontSize: 15)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
