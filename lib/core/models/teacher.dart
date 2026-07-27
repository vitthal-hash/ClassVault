import 'package:isar/isar.dart';

part 'teacher.g.dart';

/// A faculty member, extracted from the timetable. Kept separate from
/// Subject so the same teacher can be linked to multiple subjects/slots.
@collection
class Teacher {
  Id id = Isar.autoIncrement;

  @Index()
  late String name;

  DateTime createdAt = DateTime.now();
}
