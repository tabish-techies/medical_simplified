import 'package:http/http.dart' as http;
import '../../../core/networking/api_client.dart';

class NotesApi {
  final ApiClient _client;

  NotesApi(this._client);

  // Fetch all notes
  Future<http.Response> fetchNotes() async {
    return _client.get('/api/notes');
  }
  // Fetch note purchase status
  Future<http.Response> fetchPurchaseStatus(int noteId) async {
    return _client.get('/api/notes/$noteId/purchase-status');
  }

  // Create Payment Order for Note
  Future<http.Response> createNoteOrder(int noteId) async {
    return _client.post(
      '/api/payment/create-order',
      body: {'noteId': noteId},
    );
  }

  // Fetch purchased notes
  Future<http.Response> fetchPurchasedNotes() async {
    return _client.get('/api/notes/purchased');
  }

  // Fetch note content
  Future<http.Response> fetchNoteContent(int noteId) async {
    return _client.get('/api/notes/$noteId/content');
  }
}
