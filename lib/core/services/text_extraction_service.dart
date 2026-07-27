import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../models/enums.dart';
import 'settings_service.dart';

/// Turns an uploaded image or PDF into raw text. This is the ONLY place
/// that talks to ML Kit / the PDF library — screens and services never
/// touch these packages directly.
///
/// Originally written for Phase 3 (timetable upload), and reused as-is
/// from Phase 5 onward for Syllabus PDFs, Phase 6 Resources, and Phase 9
/// lecture photos — one OCR/PDF-text code path for the whole app rather
/// than a separate ML Kit recognizer per feature. Phase 16 added the
/// "OCR Language" setting; the recognizer is rebuilt only when that
/// script actually changes, not on every call.
class TextExtractionService {
  TextExtractionService._();
  static final TextExtractionService instance = TextExtractionService._();

  TextRecognizer? _recognizer;
  OcrScript? _recognizerScript;

  Future<TextRecognizer> _currentRecognizer() async {
    final script = (await SettingsService.instance.getOrCreate()).ocrScript;
    if (_recognizer != null && _recognizerScript == script) {
      return _recognizer!;
    }
    await _recognizer?.close();
    _recognizer = TextRecognizer(script: _toMlkitScript(script));
    _recognizerScript = script;
    return _recognizer!;
  }

  /// Kept here rather than on `OcrScript` itself so `models/enums.dart`
  /// doesn't need to import the ML Kit plugin — this file is already
  /// the app's one designated ML Kit touchpoint.
  TextRecognitionScript _toMlkitScript(OcrScript script) {
    switch (script) {
      case OcrScript.latin:
        return TextRecognitionScript.latin;
      case OcrScript.chinese:
        return TextRecognitionScript.chinese;
      case OcrScript.devanagari:
        return TextRecognitionScript.devanagiri;
      case OcrScript.japanese:
        return TextRecognitionScript.japanese;
      case OcrScript.korean:
        return TextRecognitionScript.korean;
    }
  }

  Future<String> extractFromImage(File imageFile) async {
    final recognizer = await _currentRecognizer();
    final inputImage = InputImage.fromFile(imageFile);
    final result = await recognizer.processImage(inputImage);
    return result.text;
  }

  Future<String> extractFromPdf(File pdfFile) async {
    final bytes = await pdfFile.readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    try {
      final buffer = StringBuffer();
      for (var i = 0; i < document.pages.count; i++) {
        final pageText = PdfTextExtractor(document).extractText(
          startPageIndex: i,
          endPageIndex: i,
        );
        buffer.writeln(pageText);
      }
      return buffer.toString();
    } finally {
      document.dispose();
    }
  }

  Future<void> dispose() async {
    await _recognizer?.close();
    _recognizer = null;
    _recognizerScript = null;
  }
}
