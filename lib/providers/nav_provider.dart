import 'package:flutter/foundation.dart';

/// Tracks which top-level tab (Home / Semester / Subjects / AI Chat /
/// Search / Settings) is currently active.
class NavProvider extends ChangeNotifier {
  int _index = 0;
  int get index => _index;

  void setIndex(int value) {
    if (_index == value) return;
    _index = value;
    notifyListeners();
  }
}
