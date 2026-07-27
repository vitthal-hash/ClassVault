import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/models/semester.dart';
import '../core/services/semester_service.dart';

class SemesterProvider extends ChangeNotifier {
  SemesterProvider() {
    _sub = SemesterService.instance.watchAll().listen((list) {
      _semesters = list;
      notifyListeners();
    });
  }

  List<Semester> _semesters = [];
  List<Semester> get semesters => _semesters;

  Semester? get active =>
      _semesters.where((s) => s.isActive).cast<Semester?>().firstOrNull;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  late final StreamSubscription<List<Semester>> _sub;

  Future<void> createSemester({
    required String name,
    required int semesterNumber,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _isSaving = true;
    notifyListeners();
    try {
      await SemesterService.instance.createSemester(
        name: name,
        semesterNumber: semesterNumber,
        startDate: startDate,
        endDate: endDate,
      );
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> setActive(Semester semester) =>
      SemesterService.instance.setActive(semester);

  Future<void> delete(Semester semester) =>
      SemesterService.instance.delete(semester);

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
