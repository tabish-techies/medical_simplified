import 'dart:convert';
import 'syllabus_api.dart';

class SyllabusRepository {
  final SyllabusApi _api;

  // 🧠 In-memory session cache
  List<dynamic>? _cachedSyllabus;

  SyllabusRepository(this._api);

  /// ✅ Fetch all syllabus items (cached per app session)
  Future<List<dynamic>> getSyllabus({bool forceRefresh = false}) async {
    // 🔥 Return cached data if available
    if (!forceRefresh && _cachedSyllabus != null) {
      return _cachedSyllabus!;
    }

    final response = await _api.fetchSyllabus();

    // Handle 404 → empty list
    if (response.statusCode == 404) {
      _cachedSyllabus = [];
      return _cachedSyllabus!;
    }

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch syllabus (${response.statusCode})');
    }

    final Map<String, dynamic> body = jsonDecode(response.body);

    if (body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to load syllabus');
    }

    _cachedSyllabus = body['data'] ?? [];
    return _cachedSyllabus!;
  }

  /// 🔄 Clear cache (call on logout / manual refresh)
  void clearSyllabusCache() {
    _cachedSyllabus = null;
  }

  /// 🔐 Fetch purchase status
  Future<Map<String, dynamic>> getPurchaseStatus(int syllabusId) async {
    final response = await _api.fetchPurchaseStatus(syllabusId);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch purchase status (${response.statusCode})');
    }

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to load purchase status');
    }

    return Map<String, dynamic>.from(body['data'] ?? {});
  }

  /// 💳 Create Payment Order
  Future<Map<String, dynamic>> createOrder(int syllabusId) async {
    final response = await _api.createSyllabusOrder(syllabusId);

    if (response.statusCode != 200) {
      throw Exception('Failed to create order (${response.statusCode})');
    }

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to create order');
    }

    return Map<String, dynamic>.from(body['data'] ?? {});
  }

  /// 📚 Purchased syllabus
  Future<List<dynamic>> getPurchasedSyllabus() async {
    final response = await _api.fetchPurchasedSyllabus();

    if (response.statusCode == 404) {
      return [];
    }

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch purchased syllabus (${response.statusCode})');
    }

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to load purchased syllabus');
    }

    return body['data'] ?? [];
  }

  /// 📄 Syllabus content
  Future<Map<String, dynamic>> getSyllabusContent(int syllabusId) async {
    final response = await _api.fetchSyllabusContent(syllabusId);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch syllabus content (${response.statusCode})');
    }

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to load syllabus content');
    }

    return Map<String, dynamic>.from(body['data'] ?? {});
  }
}
