import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../i18n/app_localizations.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import 'duo_icon.dart';

/// Hosts the 6 bottom-tab branches, each with its own persistent nested
/// stack via StatefulShellRoute.indexedStack -- mirrors RN's bottom-tabs
/// navigator wrapping per-tab nested native-stacks (Quiz has 6 nested
/// screens, Profile has 9).
class MainShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  const MainShell({super.key, required this.navigationShell});

  static const _icons = [
    Icons.home_rounded,
    Icons.chat_bubble_rounded,
    Icons.auto_awesome_rounded,
    Icons.folder_rounded,
    Icons.edit_rounded,
    Icons.person_rounded,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final labels = [
      t('nav.home', language),
      t('nav.chat', language),
      t('nav.assistant', language),
      t('nav.files', language),
      t('nav.quiz', language),
      t('nav.profile', language),
    ];

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          for (var i = 0; i < _icons.length; i++)
            NavigationDestination(
              icon: Icon(_icons[i], color: colors.textMuted),
              selectedIcon: DuoIcon(_icons[i], color: colors.primary, size: 26),
              label: labels[i],
            ),
        ],
      ),
    );
  }
}
