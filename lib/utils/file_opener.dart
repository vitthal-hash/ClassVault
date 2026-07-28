import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../screens/image_viewer_screen.dart';
import '../screens/pdf_viewer_screen.dart';

/// Opens a stored file the way a real document should open — as itself,
/// not as a wall of extracted text. PDFs and images render in-app;
/// everything else (PPT, Word, …) is handed off to whatever viewer the
/// user already has installed (Google Slides/Docs, WPS Office, MS
/// Office, etc.), the same way Google Drive or WhatsApp do it.
///
/// [extractedText]/[extractedTextLabel] stay completely separate from
/// this — they only ever power Search and AI features, never replace
/// the file the user sees.
Future<void> openStoredFile(
  BuildContext context, {
  required String path,
  required String title,
}) async {
  final ext = path.split('.').last.toLowerCase();

  if (ext == 'pdf') {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(filePath: path, title: title),
      ),
    );
    return;
  }

  if (const ['jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'].contains(ext)) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ImageViewerScreen(filePath: path, title: title),
      ),
    );
    return;
  }

  // PPT/PPTX/DOC/DOCX and anything else: hand off to an installed app.
  final result = await OpenFilex.open(path);
  if (result.type != ResultType.done && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.type == ResultType.noAppToOpen
              ? 'No app installed on this device can open this file type.'
              : "Couldn't open the file: ${result.message}",
        ),
      ),
    );
  }
}