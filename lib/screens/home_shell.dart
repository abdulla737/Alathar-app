import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'athkar_screen.dart';
import 'library_screen.dart';
import 'quran_screen.dart';
import 'settings_screen.dart';
import 'today_screen.dart';

/// Tab indexes, so screens can jump to another tab.
class AppTab {
  static const today = 0;
  static const athkar = 1;
  static const hadith = 2;
  static const quran = 3; // «القرآن» (replaced «العمل»)
  static const more = 4;
}

/// Main app frame with the bottom navigation bar.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = AppTab.today;

  void _goTo(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      TodayScreen(onOpenTab: _goTo),
      const AthkarScreen(),
      const LibraryScreen(),
      const QuranScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _goTo,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.wb_sunny_outlined),
              selectedIcon: const Icon(Icons.wb_sunny),
              label: context.tr('tab_today'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.trip_origin),
              label: context.tr('tab_athkar'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.menu_book_outlined),
              selectedIcon: const Icon(Icons.menu_book),
              label: context.tr('tab_hadith'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.auto_stories_outlined),
              selectedIcon: const Icon(Icons.auto_stories),
              label: context.tr('tab_quran'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings),
              label: context.tr('tab_more'),
            ),
          ],
        ),
      ),
    );
  }
}
