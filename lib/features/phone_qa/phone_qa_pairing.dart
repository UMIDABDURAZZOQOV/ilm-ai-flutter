import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/dio_client.dart';
import '../auth/application/auth_controller.dart';
import '../auth/data/auth_models.dart';

/// Runtime pairing only. No access/refresh token is compiled into this APK.
class PhoneQaPairing extends ConsumerStatefulWidget {
  const PhoneQaPairing({super.key});
  @override
  ConsumerState<PhoneQaPairing> createState() => _PhoneQaPairingState();
}

class _PhoneQaPairingState extends ConsumerState<PhoneQaPairing> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _pair() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final response = await ref
          .read(dioProvider)
          .post<Map<String, dynamic>>(
            '/qa/pair',
            data: {'code': _code.text.trim().toUpperCase()},
          );
      final data = response.data!;
      await ref
          .read(authControllerProvider.notifier)
          .login(
            AuthResponse.fromJson(data),
            needsOnboarding: data['needs_onboarding'] == true,
          );
      _code.clear();
      if (mounted) {
        context.go(ref.read(needsProfileSetupProvider) ? '/setup' : '/learn');
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'USB ulanishi va yangi bir martalik kodni tekshiring.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 24),
      const Text(
        'Telefon QA • lokal test akkaunti',
        textAlign: TextAlign.center,
      ),
      const Text(
        'Kompyuterdagi bir martalik kodni kiriting. Google OAuth bu sandboxda sozlanmagan.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _code,
        enabled: !_busy,
        maxLength: 8,
        autocorrect: false,
        enableSuggestions: false,
        textCapitalization: TextCapitalization.characters,
        decoration: const InputDecoration(
          labelText: 'QA ulanish kodi',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (_) {
          if (!_busy) _pair();
        },
      ),
      if (_error != null) Text(_error!, semanticsLabel: _error),
      FilledButton(
        onPressed: _busy ? null : _pair,
        child: Text(_busy ? 'Ulanmoqda…' : 'Lokal QA akkauntiga kirish'),
      ),
    ],
  );
}
