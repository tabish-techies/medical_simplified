import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  static const bool isProd =
      bool.fromEnvironment('prod', defaultValue: false);

  static String get baseUrl {
    if (isProd) {
      return 'https://medical-backend-189173329170.asia-south1.run.app';
    }

    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }
}

