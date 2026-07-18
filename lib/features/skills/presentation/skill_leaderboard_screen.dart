import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../data/skill_extras_models.dart';
import '../data/skill_extras_repository.dart';
import 'skill_ui.dart';

final _leaderboardProvider = FutureProvider.autoDispose<LeaderboardResponse>((ref) async {
  return ref.read(skillExtrasRepositoryProvider).getLeaderboard();
});

const _leagueColors = {
  'diamond': Color(0xFF7DD3FC),
  'gold': Color(0xFFFFC800),
  'silver': Color(0xFFC0C0C0),
  'bronze': Color(0xFFCD7F32),
};

class SkillLeaderboardScreen extends ConsumerWidget {
  const SkillLeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final async = ref.watch(_leaderboardProvider);
    return Scaffold(
      appBar: AppBar(title: Text(str3(lang, 'Haftalik reyting', 'Рейтинг недели', 'Weekly leaderboard'))),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(str3(lang, 'Xatolik', 'Ошибка', 'Error'))),
        data: (d) => d.entries.isEmpty
            ? Center(child: Text(str3(lang, "Hali ishtirokchi yo'q", 'Пока нет участников', 'No participants yet'), style: TextStyle(color: Colors.grey.shade600)))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (d.ownRank != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text('${str3(lang, 'Sizning o\'rningiz', 'Ваше место', 'Your rank')}: #${d.ownRank}  ·  ${d.totalParticipants} ${str3(lang, 'ishtirokchi', 'участников', 'participants')}',
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  for (final e in d.entries) _row(lang, e),
                ],
              ),
      ),
    );
  }

  Widget _row(String lang, LeaderboardEntry e) {
    final medal = e.rank == 1 ? '🥇' : e.rank == 2 ? '🥈' : e.rank == 3 ? '🥉' : null;
    final leagueColor = _leagueColors[e.league] ?? const Color(0xFFCD7F32);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: e.isMe ? const Color(0xFF58CC02).withValues(alpha: 0.10) : null,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: e.isMe ? const Color(0xFF58CC02) : Colors.black12, width: e.isMe ? 2 : 1),
      ),
      child: Row(children: [
        SizedBox(width: 30, child: medal != null ? Text(medal, style: const TextStyle(fontSize: 18)) : Text('${e.rank}', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey.shade500))),
        CircleAvatar(radius: 16, backgroundColor: leagueColor.withValues(alpha: 0.25), child: Text(e.name.isNotEmpty ? e.name[0].toUpperCase() : '?', style: TextStyle(fontWeight: FontWeight.w800, color: leagueColor, fontSize: 13))),
        const SizedBox(width: 10),
        Expanded(child: Text(e.name, style: TextStyle(fontWeight: e.isMe ? FontWeight.w900 : FontWeight.w700))),
        const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFFFFC800)),
        Text('${e.weeklyXp}', style: const TextStyle(fontWeight: FontWeight.w900)),
      ]),
    );
  }
}
