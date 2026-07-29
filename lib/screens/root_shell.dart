import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/nav_provider.dart';
import 'home_screen.dart';
import 'semester_screen.dart';
import 'subjects_screen.dart';
import 'ai_chat_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

/// The single Scaffold that hosts bottom navigation. Only Home,
/// Subjects, AI Chat, and Search are real tabs (kept alive in an
/// IndexedStack, switched via [NavProvider]) — Material's own guidance
/// caps a bottom nav at 5 comfortable destinations, and 6 full labels
/// ("Semester", "AI Chat", "Settings") was already clipping on
/// standard phone widths. Semester and Settings are the two
/// lowest-frequency sections (set up once per semester / visited
/// occasionally), so they live behind the 5th "More" destination
/// instead — tapping it opens a sheet and pushes the chosen screen,
/// it doesn't join the tab set.
class RootShell extends StatelessWidget {
  const RootShell({super.key});

  static const _screens = [
    HomeScreen(),
    SubjectsScreen(),
    AiChatScreen(),
    SearchScreen(),
  ];

  static const _tabDestinations = [
    NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
    NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book_rounded), label: 'Subjects'),
    NavigationDestination(icon: Icon(Icons.smart_toy_outlined), selectedIcon: Icon(Icons.smart_toy_rounded), label: 'AI Chat'),
    NavigationDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search_rounded), label: 'Search'),
    NavigationDestination(icon: Icon(Icons.more_horiz_rounded), selectedIcon: Icon(Icons.more_horiz_rounded), label: 'More'),
  ];

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavProvider>();

    return Scaffold(
      body: IndexedStack(
        index: nav.index,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        // nav.index only ever spans the real tabs (0-3) — "More" at
        // index 4 is an action, not a persisted selection, so it's
        // never the selectedIndex and just shows its icon.
        selectedIndex: nav.index,
        onDestinationSelected: (index) {
          if (index == _screens.length) {
            _showMore(context);
            return;
          }
          context.read<NavProvider>().setIndex(index);
        },
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: _tabDestinations,
      ),
    );
  }

  void _showMore(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_month_rounded),
              title: const Text('Semester'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const SemesterScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_rounded),
              title: const Text('Settings'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}