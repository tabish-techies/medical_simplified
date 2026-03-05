import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class NoteReaderScreen extends StatelessWidget {
  final String title;
  final String pdfUrl;
  final String? filePath; // Optional local path

  const NoteReaderScreen({
    super.key,
    required this.title,
    required this.pdfUrl,
    this.filePath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: filePath != null
          ? SfPdfViewer.file(
              File(filePath!),
              canShowScrollHead: true,
              canShowScrollStatus: true,
              enableDoubleTapZooming: true,
              onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to load local PDF: ${details.error}'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
            )
          : SfPdfViewer.network(
              pdfUrl,
              canShowScrollHead: true,
              canShowScrollStatus: true,
              enableDoubleTapZooming: true,
              onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to load cloud PDF: ${details.error}'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
            ),
    );
  }
}
