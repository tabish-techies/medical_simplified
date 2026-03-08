import 'package:http/http.dart' as http;
import '../../../core/networking/api_client.dart';

class SyllabusApi {
  final ApiClient _client;

  SyllabusApi(this._client);

  // Fetch all syllabus items
  Future<http.Response> fetchSyllabus() async {
    return _client.get('/api/public/syllabus');
  }

  // Fetch syllabus purchase status
  Future<http.Response> fetchPurchaseStatus(int syllabusId) async {
    return _client.get('/api/public/syllabus/$syllabusId/purchase-status');
  }

  // Create Payment Order for Syllabus
  Future<http.Response> createSyllabusOrder(int syllabusId) async {
    return _client.post('/api/payment/create-order', body: {'syllabusId': syllabusId});
  }

  // Fetch purchased syllabus
  Future<http.Response> fetchPurchasedSyllabus() async {
    return _client.get('/api/public/syllabus/purchased');
  }

  // Fetch syllabus content (PDF link etc.)
  Future<http.Response> fetchSyllabusContent(int syllabusId) async {
    return _client.get('/api/public/syllabus/$syllabusId/content');
  }
}
