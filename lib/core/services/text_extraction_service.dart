import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:xml/xml.dart';

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

  /// .docx is a zip archive containing `word/document.xml`, where every
  /// run of text sits in a `<w:t>` element. Paragraph breaks (`<w:p>`)
  /// are turned into newlines so the extracted text roughly keeps the
  /// document's paragraph structure instead of becoming one long run.
  ///
  /// Returns null for the legacy binary `.doc` format (pre-2007) — that
  /// isn't a zip at all, and needs a completely different parser this
  /// service doesn't have. `.docx` (2007+, what nearly everyone uploads
  /// today) works fully.
  Future<String?> extractFromDocx(File docxFile) async {
    final xmlString = await _readEntryText(docxFile, 'word/document.xml');
    if (xmlString == null) return null;
    return _extractRunsAndParagraphs(
      xmlString,
      textTag: 'w:t',
      paragraphTag: 'w:p',
    );
  }

  /// Same idea as [extractFromDocx] but for `.pptx`: one XML file per
  /// slide under `ppt/slides/`, text runs in `<a:t>` elements. Slides
  /// are concatenated in file order with a heading per slide so the
  /// chat can still tell the model which slide something came from.
  ///
  /// Returns null for legacy binary `.ppt` for the same reason as
  /// `.doc` above.
  Future<String?> extractFromPptx(File pptxFile) async {
    final bytes = await pptxFile.readAsBytes();
    Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      return null; // not a zip — almost certainly legacy binary .ppt
    }

    final slideFiles = archive.files
        .where((f) =>
            f.isFile &&
            f.name.startsWith('ppt/slides/slide') &&
            f.name.endsWith('.xml'))
        .toList()
      // Slide files are named slide1.xml, slide2.xml, ... — sort
      // numerically so the extracted text follows the deck's actual
      // slide order rather than whatever order the zip happens to list
      // entries in.
      ..sort((a, b) => _slideNumber(a.name).compareTo(_slideNumber(b.name)));

    if (slideFiles.isEmpty) return null;

    final buffer = StringBuffer();
    for (var i = 0; i < slideFiles.length; i++) {
      final xmlString = utf8.decode(slideFiles[i].content as List<int>, allowMalformed: true);
      final slideText = _extractRunsAndParagraphs(xmlString, textTag: 'a:t');
      if (slideText.trim().isEmpty) continue;
      buffer.writeln('--- Slide ${i + 1} ---');
      buffer.writeln(slideText);
    }
    return buffer.toString();
  }

  int _slideNumber(String entryName) {
    final match = RegExp(r'slide(\d+)\.xml$').firstMatch(entryName);
    return match != null ? int.parse(match.group(1)!) : 0;
  }

  /// Unzips [file] and returns the decoded text of the single entry
  /// named [entryPath], or null if the file isn't a zip or doesn't
  /// contain that entry.
  Future<String?> _readEntryText(File file, String entryPath) async {
    final bytes = await file.readAsBytes();
    Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      return null;
    }
    final entry = archive.files.firstWhere(
      (f) => f.isFile && f.name == entryPath,
      orElse: () => ArchiveFile(entryPath, 0, const <int>[]),
    );
    if (entry.content is! List<int> || (entry.content as List<int>).isEmpty) {
      return null;
    }
    return utf8.decode(entry.content as List<int>, allowMalformed: true);
  }

  /// Reads every [textTag] element's text out of [xmlString] in
  /// document order and joins them with spaces; if [paragraphTag] is
  /// given, a newline is inserted after each closing paragraph so
  /// output isn't one giant run-on line. Malformed XML (shouldn't
  /// normally happen, but a corrupted upload is possible) is treated as
  /// no text rather than thrown.
  String _extractRunsAndParagraphs(
    String xmlString, {
    required String textTag,
    String? paragraphTag,
  }) {
    XmlDocument document;
    try {
      document = XmlDocument.parse(xmlString);
    } catch (_) {
      return '';
    }

    if (paragraphTag == null) {
      return document
          .findAllElements(textTag)
          .map((e) => e.innerText)
          .where((t) => t.isNotEmpty)
          .join(' ');
    }

    final buffer = StringBuffer();
    for (final paragraph in document.findAllElements(paragraphTag)) {
      final runs = paragraph
          .findAllElements(textTag)
          .map((e) => e.innerText)
          .where((t) => t.isNotEmpty)
          .join(' ');
      if (runs.isNotEmpty) buffer.writeln(runs);
    }
    return buffer.toString();
  }
}