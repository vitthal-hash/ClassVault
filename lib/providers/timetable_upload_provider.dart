import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../core/parsing/timetable_parser.dart';
import '../core/services/text_extraction_service.dart';
import '../core/services/timetable_service.dart';

enum UploadStage { idle, extracting, reviewing, saving, done }

/// Holds the state for the whole "upload timetable" flow so the screen
/// stays dumb: pick a source, we extract + parse, the person reviews/
/// edits rows, then we commit.
class TimetableUploadProvider extends ChangeNotifier {
  UploadStage stage = UploadStage.idle;
  String? error;
  String rawText = '';
  List<ParsedTimetableRow> rows = [];
  int savedCount = 0;

  final _picker = ImagePicker();

  Future<void> pickFromCamera() => _runImageExtraction(ImageSource.camera);
  Future<void> pickFromGallery() => _runImageExtraction(ImageSource.gallery);

  Future<void> _runImageExtraction(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 90);
      if (picked == null) return; // user cancelled
      _setStage(UploadStage.extracting);
      final text = await TextExtractionService.instance
          .extractFromImage(File(picked.path));
      _applyExtractedText(text);
    } catch (e) {
      _setError('Could not read that image: $e');
    }
  }

  Future<void> pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      final path = result?.files.single.path;
      if (path == null) return; // user cancelled
      _setStage(UploadStage.extracting);
      final text =
          await TextExtractionService.instance.extractFromPdf(File(path));
      _applyExtractedText(text);
    } catch (e) {
      _setError('Could not read that PDF: $e');
    }
  }

  void _applyExtractedText(String text) {
    rawText = text;
    rows = TimetableParser.parse(text);
    if (rows.isEmpty) {
      _setError(
        "Couldn't find any timetable rows in that file. Try a clearer "
        'photo, or edit rows in manually below.',
      );
      rows = [];
    }
    _setStage(UploadStage.reviewing);
  }

  void addBlankRow() {
    rows = [
      ...rows,
      ParsedTimetableRow(subjectName: '', sourceLine: '(added manually)'),
    ];
    notifyListeners();
  }

  void updateRow(int index, ParsedTimetableRow updated) {
    rows[index] = updated;
    notifyListeners();
  }

  void removeRow(int index) {
    rows = [...rows]..removeAt(index);
    notifyListeners();
  }

  Future<bool> confirmAndSave(int semesterId) async {
    _setStage(UploadStage.saving);
    try {
      savedCount = await TimetableService.instance.commitRows(
        rows: rows,
        semesterId: semesterId,
      );
      _setStage(UploadStage.done);
      return true;
    } catch (e) {
      _setError('Could not save the timetable: $e');
      return false;
    }
  }

  void reset() {
    stage = UploadStage.idle;
    error = null;
    rawText = '';
    rows = [];
    savedCount = 0;
    notifyListeners();
  }

  void _setStage(UploadStage s) {
    stage = s;
    error = null;
    notifyListeners();
  }

  void _setError(String message) {
    error = message;
    stage = UploadStage.idle;
    notifyListeners();
  }
}