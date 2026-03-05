import 'dart:io';
import 'package:flutter/material.dart';
import '../../../data/downloads_repository.dart';
import '../../notes/note_reader_screen.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  final DownloadsRepository _repository = DownloadsRepository();
  List<Map<String, dynamic>> _downloads = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDownloads();
  }

  Future<void> _loadDownloads() async {
    final items = await _repository.getDownloads();
    if (mounted) {
      setState(() {
        _downloads = items;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteItem(String id) async {
    await _repository.deleteDownload(id);
    _loadDownloads(); // Refresh list
  }

  void _openDownload(Map<String, dynamic> item) {
    final filePath = item['filePath'];
    final title = item['title'] ?? 'Untitled';

    if (filePath != null && File(filePath).existsSync()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NoteReaderScreen(title: title, pdfUrl: '', filePath: filePath),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('File not found. It may have been deleted.')));
      _deleteItem(item['id'].toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Downloads')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _downloads.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.download, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No downloads yet', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _downloads.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final item = _downloads[index];
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.picture_as_pdf, color: Colors.blue),
                  ),
                  title: Text(item['title'] ?? 'Unknown Note', style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    'Downloaded on ${item['date'] ?? 'Unknown date'}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deleteItem(item['id'].toString()),
                  ),
                  onTap: () => _openDownload(item),
                );
              },
            ),
    );
  }
}
