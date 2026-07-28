import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// Opens a stored image full-screen and pinch-zoomable — the original
/// file, not a text extraction of what it contains.
class ImageViewerScreen extends StatelessWidget {
  const ImageViewerScreen({super.key, required this.filePath, required this.title});

  final String filePath;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
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
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 5,
          child: Image.file(File(filePath)),
        ),
      ),
    );
  }
}