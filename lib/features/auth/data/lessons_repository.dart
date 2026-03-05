import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:medical_simplified/core/networking/api_client.dart';

class LessonsRepository {
  final ApiClient _client;
  LessonsRepository(this._client);

  Future<List<dynamic>> getLessons(int courseId) async {
    final response = await _client.get('/api/public/courses/$courseId/lessons');

    if (response.statusCode != 200) {
      throw Exception('Failed to load lessons (${response.statusCode})');
    }

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to load lessons');
    }

    return body['data'] ?? [];
  }
}
