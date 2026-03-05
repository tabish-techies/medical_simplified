import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../data/downloads_repository.dart';

class DownloadService {
  // Singleton pattern
  static final DownloadService instance = DownloadService._internal();

  factory DownloadService() {
    return instance;
  }

  DownloadService._internal();

  final Map<int, ValueNotifier<double>> _progressNotifiers = {};
  final Map<int, bool> _activeDownloads = {};

  ValueNotifier<double> getProgressNotifier(int id) {
    if (!_progressNotifiers.containsKey(id)) {
      _progressNotifiers[id] = ValueNotifier(0.0);
    }
    return _progressNotifiers[id]!;
  }

  bool isDownloading(int id) => _activeDownloads[id] ?? false;

  Future<void> startDownload({
    required int id,
    required String url,
    required String savePath,
    required String title,
    required Function(String error) onError,
    required Function() onSuccess,
  }) async {
    if (isDownloading(id)) return;

    _activeDownloads[id] = true;
    final notifier = getProgressNotifier(id);
    notifier.value = 0.0;

    final dio = Dio();

    try {
      print('⬇️ [DownloadService] Starting download for $title');

      await dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            notifier.value = received / total;
          }
        },
      );

      print('✅ [DownloadService] Download complete: $title');

      // Save to repository
      final repo = DownloadsRepository();
      await repo.saveDownload({
        'id': id,
        'title': title,
        'filePath': savePath,
        'date': DateTime.now().toString().split(' ')[0],
      });

      _activeDownloads[id] = false;
      notifier.value = 1.0; // Ensure it shows complete
      onSuccess();
    } catch (e) {
      print('❌ [DownloadService] Error: $e');
      _activeDownloads[id] = false;
      notifier.value = 0.0;
      onError(e.toString());
    }
  }
}
