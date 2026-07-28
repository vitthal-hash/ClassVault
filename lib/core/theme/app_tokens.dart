import 'package:flutter/material.dart';

/// Spacing scale used across every screen. Pick from here instead of
/// hardcoding numbers so rhythm stays consistent as screens get redone.
class AppSpacing {
  AppSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Reserve this much bottom padding on any scrollable list that sits
  /// under a Scaffold's `floatingActionButton` — a standard FAB's
  /// footprint (56dp circle, extended FABs a bit taller, plus Material's
  /// 16dp margin) needs more clearance than xxxl alone gives, or the
  /// last item ends up partly hidden behind the button.
  static const double fabClearance = 88;
}

/// Corner radius scale. Bigger radii read as "soft/modern"; keep them
/// consistent so the app doesn't feel like it's mixing design systems.
class AppRadius {
  AppRadius._();

  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
  static const double pill = 999;

  static BorderRadius get smRadius => BorderRadius.circular(sm);
  static BorderRadius get mdRadius => BorderRadius.circular(md);
  static BorderRadius get lgRadius => BorderRadius.circular(lg);
  static BorderRadius get xlRadius => BorderRadius.circular(xl);
}

/// Shared motion durations/curves so transitions feel like one app.
class AppMotion {
  AppMotion._();

  static const Duration fast = Duration(milliseconds: 160);
  static const Duration medium = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 420);

  static const Curve standard = Curves.easeOutCubic;
  static const Curve enter = Curves.easeOutQuart;
}

/// A small, fixed palette used to color-code subjects deterministically
/// (same subject always gets the same color, no color field needed on
/// the model). Chosen to look good as both a solid chip and a tinted
/// container in light/dark.
class SubjectPalette {
  SubjectPalette._();

  static const List<Color> _colors = [
    Color(0xFF6366F1), // indigo
    Color(0xFF0EA5E9), // sky
    Color(0xFF14B8A6), // teal
    Color(0xFFF59E0B), // amber
    Color(0xFFEC4899), // pink
    Color(0xFF8B5CF6), // violet
    Color(0xFFEF4444), // red
    Color(0xFF22C55E), // green
  ];

  static Color colorFor(Object key) {
    final hash = key.toString().codeUnits.fold<int>(0, (a, b) => a + b);
    return _colors[hash % _colors.length];
  }
}

/// A soft, low-contrast shadow used in place of Material's default
/// elevation tint, which tends to look muddy in Material 3. Use this
/// wherever a hand-built container needs to look "lifted" without a
/// heavy drop shadow.
List<BoxShadow> softShadow(BuildContext context, {double strength = 1}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return [
    BoxShadow(
      color: (isDark ? Colors.black : const Color(0xFF1A1B2E))
          .withOpacity((isDark ? 0.35 : 0.06) * strength),
      blurRadius: 24 * strength,
      offset: Offset(0, 8 * strength),
    ),
    BoxShadow(
      color: (isDark ? Colors.black : const Color(0xFF1A1B2E))
          .withOpacity((isDark ? 0.25 : 0.04) * strength),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];
}