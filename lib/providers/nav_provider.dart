import 'package:flutter/foundation.dart';

/// Tracks which top-level tab (Home / Subjects / AI Chat / Search) is
/// currently active. Semester and Settings live behind RootShell's
/// "More" sheet instead of being tabs — see `root_shell.dart`.
class NavProvider extends ChangeNotifier {
  int _index = 0;
  int get index => _index;

  void setIndex(int value) {
    if (_index == value) return;
    _index = value;
    notifyListeners();
  }
}