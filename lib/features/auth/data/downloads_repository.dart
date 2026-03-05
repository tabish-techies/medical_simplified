import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class DownloadsRepository {
  static const String _fileName = 'downloads.json';

  Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<List<Map<String, dynamic>>> getDownloads() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return [];

      final content = await file.readAsString();
      if (content.isEmpty) return [];

      final List<dynamic> jsonList = jsonDecode(content);
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      print('❌ Error reading downloads: $e');
      return [];
    }
  }

  Future<void> saveDownload(Map<String, dynamic> item) async {
    try {
      final downloads = await getDownloads();

      // Check if already exists, update if so
      final index = downloads.indexWhere((d) => d['id'] == item['id']);
      if (index != -1) {
        downloads[index] = item;
      } else {
        downloads.add(item);
      }

      final file = await _getFile();
      await file.writeAsString(jsonEncode(downloads));
      print('✅ Download saved: ${item['title']}');
    } catch (e) {
      print('❌ Error saving download: $e');
    }
  }

  Future<void> deleteDownload(String id) async {
    try {
      final downloads = await getDownloads();
      final item = downloads.firstWhere((d) => d['id'].toString() == id, orElse: () => {});

      if (item.isNotEmpty) {
        downloads.removeWhere((d) => d['id'].toString() == id);
        final file = await _getFile();
        await file.writeAsString(jsonEncode(downloads));

        // Also delete the actual file
        if (item['filePath'] != null) {
          final localFile = File(item['filePath']);
          if (await localFile.exists()) {
            await localFile.delete();
            print('🗑️ Deleted local file: ${localFile.path}');
          }
        }
      }
    } catch (e) {
      print('❌ Error deleting download: $e');
    }
  }
}
