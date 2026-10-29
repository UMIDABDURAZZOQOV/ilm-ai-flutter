import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/network/dio_client.dart';
import '../../core/widgets/mascot_image.dart';
import '../chemistry/presentation/chemistry_preview_screen.dart';
import '../physics/presentation/physics_preview_screen.dart';
import '../skills/presentation/subject_home_screen.dart';
import '../uzbekistan_history/presentation/history_preview_screen.dart';
import '../world_history/presentation/world_history_preview_screen.dart';

final phoneQaSummaryProvider = FutureProvider<Map<String, dynamic>>(
  (ref) async =>
      (await ref.watch(dioProvider).get<Map<String, dynamic>>('/qa/me')).data!,
);

class PhoneQaHub extends ConsumerWidget {
  const PhoneQaHub({super.key});
  static const subjects = [
    (
      title: 'Biologiya',
      count: 406,
      icon: Icons.eco_outlined,
      screen: SubjectHomeScreen(),
    ),
    (
      title: 'Fizika',
      count: 316,
      icon: Icons.bolt_outlined,
      screen: PhysicsPreviewScreen(),
    ),
    (
      title: 'Kimyo',
      count: 268,
      icon: Icons.science_outlined,
      screen: ChemistryPreviewScreen(),
    ),
    (
      title: 'O‘zbekiston tarixi',
      count: 172,
      icon: Icons.account_balance_outlined,
      screen: UzbekistanHistoryPreviewScreen(),
    ),
    (
      title: 'Jahon tarixi',
      count: 219,
      icon: Icons.public,
      screen: WorldHistoryPreviewScreen(),
    ),
  ];
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(phoneQaSummaryProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('ILM AI QA'),
        actions: [
          IconButton(
            tooltip: 'Sozlamalar',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(phoneQaSummaryProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const MascotImage(pose: MascotPose.hello, size: 96),
            Text(
              'Bugun nimani o‘rganamiz?',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              '5 fan • USB orqali lokal sandbox. Darslar mavjud manba tekshiruvi va preview qoidalari bilan ishlaydi.',
            ),
            summary.when(
              data: (me) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  '${me['name']} • ${me['xp_total']} XP • ${me['streak_days']} kun',
                ),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => TextButton(
                onPressed: () => ref.invalidate(phoneQaSummaryProvider),
                child: const Text('Lokal serverga ulanishni qayta tekshirish'),
              ),
            ),
            for (final subject in subjects)
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  leading: Icon(subject.icon),
                  title: Text(subject.title),
                  subtitle: Text(
                    '${subject.count} dars • ${subject.title == 'Biologiya' ? 'nazariya va MCQ' : 'nazariya, MCQ va FRQ'}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => subject.screen),
                    );
                    ref.invalidate(phoneQaSummaryProvider);
                  },
                ),
              ),
            const SizedBox(height: 16),
            const Text(
              'Biologiya mavjud v1 tizimida. Qolgan fanlar mavjud v2 preview ekranlarida. Google login, barcha fanlar uchun yagona progress oynasi va production tayyorligi tasdiqlanmagan.',
            ),
          ],
        ),
      ),
    );
  }
}
