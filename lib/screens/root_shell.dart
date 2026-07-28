import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/nav_provider.dart';
import 'home_screen.dart';
import 'semester_screen.dart';
import 'subjects_screen.dart';
import 'ai_chat_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

/// The single Scaffold that hosts bottom navigation and swaps between
/// the six top-level sections defined in the project structure:
/// Home, Semester, Subjects, AI Chat, Search, Settings.
class RootShell extends StatelessWidget {
  const RootShell({super.key});

  static const _screens = [
    HomeScreen(),
    SemesterScreen(),
    SubjectsScreen(),
    AiChatScreen(),
    SearchScreen(),
    SettingsScreen(),
  ];

  static const _destinations = [
    NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
    NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month_rounded), label: 'Semester'),
    NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book_rounded), label: 'Subjects'),
    NavigationDestination(icon: Icon(Icons.smart_toy_outlined), selectedIcon: Icon(Icons.smart_toy_rounded), label: 'AI Chat'),
    NavigationDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search_rounded), label: 'Search'),
    NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings_rounded), label: 'Settings'),
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
        selectedIndex: nav.index,
        onDestinationSelected: context.read<NavProvider>().setIndex,
        // 6 destinations is one past Material 3's comfortable limit for
        // always-on labels — "Semester", "AI Chat", and "Settings" were
        // wrapping/clipping on standard phone widths, made worse by the
        // selected label going bold (wider). Showing only the selected
        // label keeps every icon comfortably spaced.
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: _destinations,
      ),
    );
  }
}