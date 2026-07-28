import 'package:flutter/material.dart';

import '../screens/classvault_bot_screen.dart';

/// Wraps the whole app (via `MaterialApp.builder`) so this floats over
/// every screen — the main tabs, any pushed screen, all of it — the
/// same way a chat app's "chat head" persists everywhere.
///
/// Default spot: bottom-RIGHT, same corner as the screens' own FABs
/// (Subjects' "Quick Capture," the Subject Workspace's "Add a note,"
/// Semester's "New Semester"), but lifted well clear above them —
/// see [_bottomClearance] — so it never overlaps those buttons or the
/// bottom nav bar. It's also draggable if it ever needs to move.
class ClassVaultBubbleOverlay extends StatefulWidget {
  const ClassVaultBubbleOverlay({super.key});

  @override
  State<ClassVaultBubbleOverlay> createState() =>
      _ClassVaultBubbleOverlayState();
}

class _ClassVaultBubbleOverlayState extends State<ClassVaultBubbleOverlay> {
  static const _size = 56.0;

  // Bottom nav bar (~80) + a standard FAB's height and margin (~56+16)
  // + breathing room, so the bubble always sits above "New Semester",
  // "Add a note," etc. instead of stacking on top of them.
  static const _bottomClearance = 172.0;

  Offset? _position;

  // Tracks total finger movement during a press so we can tell a tap
  // from a drag ourselves. This is done with raw pointer events
  // (Listener) rather than GestureDetector's onTap/onPanUpdate, which
  // go through Flutter's gesture-arena recognizers. Those recognizers
  // have to negotiate with each other over multiple frames to decide
  // "was that a tap or a drag?", and for a quick, near-still touch that
  // negotiation doesn't always resolve in time or in the callback you'd
  // expect — which is why taps on the bubble weren't opening anything.
  // Listener's onPointerDown/Move/Up fire immediately and always, with
  // no arena, no negotiation, no ambiguity.
  double _dragDistance = 0;

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

    // Default spot: bottom-right, lifted above the bottom nav bar and
    // any per-screen FAB so it never collides with them.
    _position ??= Offset(
      screenSize.width - _size - 16,
      screenSize.height - _size - _bottomClearance,
    );
    _clampToScreen(screenSize, mediaQuery.padding);

    return Positioned(
      left: _position!.dx,
      top: _position!.dy,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => _dragDistance = 0,
        onPointerMove: (event) {
          setState(() {
            _dragDistance += event.delta.distance;
            _position = _position! + event.delta;
            _clampToScreen(screenSize, mediaQuery.padding);
          });
        },
        onPointerUp: (_) {
          // Barely moved (or didn't move at all) → treat it as a tap.
          if (_dragDistance < 8) {
            _openBot(context);
          }
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