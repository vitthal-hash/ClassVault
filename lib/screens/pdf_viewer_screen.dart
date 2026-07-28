import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

/// Opens a stored PDF exactly as it looks natively — the original file,
/// not a re-flowed text dump. Used by Resources, Syllabus, and
/// Assignments so "open the file" always means "see the real document."
class PdfViewerScreen extends StatelessWidget {
  const PdfViewerScreen({super.key, required this.filePath, required this.title});

  final String filePath;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.share_rounded),
            onPressed: () => SharePlus.instance.share(
              ShareParams(files: [XFile(filePath)], text: title),
            ),
          ),
        ],
      ),
      body: SfPdfViewer.file(File(filePath)),
    );
  }
}