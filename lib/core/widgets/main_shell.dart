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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          boxShadow: [
            BoxShadow(
              color: colors.text.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) => navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              height: 65,
              // The pill behind the icon is drawn by our own AnimatedContainer,
              // so kill NavigationBar's built-in indicator to avoid a double
              // highlight ("ikkilik" glow) on the selected tab.
              indicatorColor: Colors.transparent,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: [
                for (var i = 0; i < _icons.length; i++)
                  NavigationDestination(
                    icon: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: navigationShell.currentIndex == i 
                            ? colors.primary.withValues(alpha: 0.15) 
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(_icons[i], color: navigationShell.currentIndex == i ? colors.primary : colors.textMuted, size: 24),
                    ),
                    selectedIcon: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: DuoIcon(_icons[i], color: colors.primary, size: 24),
                    ),
                    label: labels[i],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
