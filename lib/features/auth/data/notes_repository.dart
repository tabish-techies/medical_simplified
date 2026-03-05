import 'dart:convert';
import 'notes_api.dart';

class NotesRepository {
  final NotesApi _api;

  // 🧠 In-memory session cache
  List<dynamic>? _cachedNotes;

  NotesRepository(this._api);

  /// ✅ Fetch all notes (cached per app session)
  Future<List<dynamic>> getNotes({bool forceRefresh = false}) async {
    // 🔥 Return cached data if available
    if (!forceRefresh && _cachedNotes != null) {
      return _cachedNotes!;
    }

    final response = await _api.fetchNotes();

    // Handle 404 → empty list
    if (response.statusCode == 404) {
      _cachedNotes = [];
      return _cachedNotes!;
    }

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch notes (${response.statusCode})');
    }

    final Map<String, dynamic> body = jsonDecode(response.body);

    if (body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to load notes');
    }

    _cachedNotes = body['data'] ?? [];
    return _cachedNotes!;
  }

  /// 🔄 Clear cache (call on logout / manual refresh)
  void clearNotesCache() {
    _cachedNotes = null;
  }

  /// 🔐 Fetch purchase status
  Future<Map<String, dynamic>> getPurchaseStatus(int noteId) async {
    final response = await _api.fetchPurchaseStatus(noteId);

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
  Future<Map<String, dynamic>> createOrder(int noteId) async {
    final response = await _api.createNoteOrder(noteId);

    if (response.statusCode != 200) {
      throw Exception('Failed to create order (${response.statusCode})');
    }

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to create order');
    }

    return Map<String, dynamic>.from(body['data'] ?? {});
  }

  /// 📚 Purchased notes
  Future<List<dynamic>> getPurchasedNotes() async {
    final response = await _api.fetchPurchasedNotes();

    if (response.statusCode == 404) {
      return [];
    }

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch purchased notes (${response.statusCode})');
    }

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to load purchased notes');
    }

    return body['data'] ?? [];
  }

  /// 📄 Note content
  Future<Map<String, dynamic>> getNoteContent(int noteId) async {
    final response = await _api.fetchNoteContent(noteId);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch note content (${response.statusCode})');
    }

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to load note content');
    }

    return Map<String, dynamic>.from(body['data'] ?? {});
  }
}
