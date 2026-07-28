import 'package:flutter/material.dart';

import '../screens/classvault_bot_screen.dart';

/// Wraps the whole app (via `MaterialApp.builder`) so this floats over
/// every screen — the main tabs, any pushed screen, all of it — the
/// same way a chat app's "chat head" persists everywhere.
///
/// Defaults to the bottom-LEFT corner, not bottom-right: several
/// screens already have their own FAB in the standard bottom-right spot
/// (Subjects' "Quick Capture," the Subject Workspace's "Add a note,"
/// Semester's "New Semester"), and a second floating circle in that
/// same corner would just recreate the exact overlap problem those
/// screens used to have. It's also draggable, so it can be moved out of
/// the way of anything it happens to sit over.
class ClassVaultBubbleOverlay extends StatefulWidget {
  const ClassVaultBubbleOverlay({super.key});

  @override
  State<ClassVaultBubbleOverlay> createState() =>
      _ClassVaultBubbleOverlayState();
}

class _ClassVaultBubbleOverlayState extends State<ClassVaultBubbleOverlay> {
  static const _size = 56.0;

  Offset? _position;

  void _openBot(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => const ClassVaultBotScreen()),
    );
  }

  void _clampToScreen(Size screenSize, EdgeInsets safePadding) {
    final maxX = screenSize.width - _size - 8;
    final maxY = screenSize.height - _size - safePadding.bottom - 8;
    final minY = safePadding.top + 8;
    _position = Offset(
      _position!.dx.clamp(8, maxX < 8 ? 8 : maxX),
      _position!.dy.clamp(minY, maxY < minY ? minY : maxY),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;

    // Default spot: bottom-left, clear of the bottom nav bar (~80dp)
    // on the screens that have one, with a little breathing room.
    _position ??= Offset(16, screenSize.height - _size - 96);
    _clampToScreen(screenSize, mediaQuery.padding);

    return Positioned(
      left: _position!.dx,
      top: _position!.dy,
      child: GestureDetector(
        onTap: () => _openBot(context),
        onPanUpdate: (details) {
          setState(() {
            _position = _position! + details.delta;
            _clampToScreen(screenSize, mediaQuery.padding);
          });
        },
        child: Material(
          shape: const CircleBorder(),
          elevation: 4,
          color: Theme.of(context).colorScheme.primary,
          child: SizedBox(
            width: _size,
            height: _size,
            child: Icon(
              Icons.school_rounded,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}