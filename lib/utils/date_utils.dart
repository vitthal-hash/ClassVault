/// Small date-formatting helpers. Kept dependency-free on purpose —
/// swap for `intl` later if localization is ever needed.
class AppDateUtils {
  AppDateUtils._();

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// e.g. "26 Jul 2026"
  static String short(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')} '
        '${_months[date.month - 1]} ${date.year}';
  }
}
