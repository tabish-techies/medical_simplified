import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import '../../../../config/api_config.dart';
import '../../../../core/networking/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../data/syllabus_api.dart';
import '../../data/syllabus_repository.dart';
import '../notes/note_reader_screen.dart'; // We reuse the PDF reader
import '../notes/download_service.dart'; // We reuse the download service

class SyllabusContentScreen extends StatefulWidget {
  final int syllabusId;

  const SyllabusContentScreen({super.key, required this.syllabusId});

  @override
  State<SyllabusContentScreen> createState() => _SyllabusContentScreenState();
}

class _SyllabusContentScreenState extends State<SyllabusContentScreen> {
  late final SyllabusRepository _repository;
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _content;

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient(baseUrl: ApiConfig.baseUrl, tokenStorage: TokenStorage());
    _repository = SyllabusRepository(SyllabusApi(apiClient));
    _fetchContent();
  }

  Future<void> _fetchContent() async {
    try {
      final data = await _repository.getSyllabusContent(widget.syllabusId);
      setState(() {
        _content = data;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleReadSyllabus(String urlString, String title) async {
    // Generate a unique ID for the download service, safely shifting it out of the range of standard notes
    // (A bit of a hack since DownloadService takes an int id, but perfectly safe)
    final int downloadId = widget.syllabusId + 100000;

    final isDownloading = DownloadService.instance.isDownloading(downloadId);
    if (isDownloading) return;

    // 1. Get Secure Local Path
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'syllabus_${widget.syllabusId}.pdf';
      final file = File('${dir.path}/$fileName');

      // 2. Check if file exists
      if (await file.exists()) {
        print('📂 Opening from cache: ${file.path}');
        if (!mounted) return;
        _navigateToReader(file.path, title);
        return;
      }

      // 3. Download via Service
      DownloadService.instance.startDownload(
        id: downloadId,
        url: urlString,
        savePath: file.path,
        title: title,
        onSuccess: () {
          print('✅ Download finished callback');
          if (mounted) {
            _navigateToReader(file.path, title);
          }
        },
        onError: (error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to download syllabus: $error')));
          }
        },
      );
    } catch (e) {
      print('❌ Error in _handleReadSyllabus: $e');
    }
  }

  void _navigateToReader(String filePath, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteReaderScreen(
          title: title,
          pdfUrl: '', // Not used when filePath is provided
          filePath: filePath,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Syllabus Content')),
        body: Center(child: Text('Error: $_error')),
      );
    }

    if (_content == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Syllabus Content')),
        body: const Center(child: Text('Content not found')),
      );
    }

    final title = _content!['title'] ?? 'Untitled Syllabus';
    final description = _content!['description'] ?? '';
    final resourceUrl = _content!['resourceUrl'];

    // Use shifted ID for download service listener
    final int downloadId = widget.syllabusId + 100000;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(description, style: const TextStyle(fontSize: 16, height: 1.5)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ValueListenableBuilder<double>(
                valueListenable: DownloadService.instance.getProgressNotifier(downloadId),
                builder: (context, progress, child) {
                  final isDownloading = DownloadService.instance.isDownloading(downloadId);

                  return ElevatedButton.icon(
                    onPressed: (resourceUrl != null && resourceUrl.isNotEmpty && !isDownloading)
                        ? () => _handleReadSyllabus(resourceUrl, title)
                        : null,
                    icon: isDownloading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 2.5,
                              color: Colors.white,
                              backgroundColor: Colors.transparent,
                            ),
                          )
                        : const Icon(Icons.school),
                    label: Text(
                      isDownloading ? 'Downloading ${(progress * 100).toStringAsFixed(0)}%' : 'Read Syllabus Now',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
