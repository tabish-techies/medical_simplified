import 'package:flutter/material.dart';
import '../../../../../../config/api_config.dart';
import '../../../../../../core/networking/api_client.dart';
import '../../../../../../core/storage/token_storage.dart';
import '../../../data/notes_api.dart';
import '../../../data/notes_repository.dart';
import '../../home/book_store_screen.dart'; // ✅ Import for Explore More
import '../../notes/note_detail_screen.dart'; // ✅ Import for Purchase Flow
import '../../notes/note_content_screen.dart'; // Correct relative import
import '../my_courses_screen.dart'; // Import for constants

class PurchasedNotesTab extends StatefulWidget {
  const PurchasedNotesTab({super.key});

  @override
  State<PurchasedNotesTab> createState() => _PurchasedNotesTabState();
}

class _PurchasedNotesTabState extends State<PurchasedNotesTab> with AutomaticKeepAliveClientMixin {
  late final NotesRepository _notesRepository;

  bool _isLoading = true;
  String? _error;
  List<dynamic> _notes = [];
  List<dynamic> _recommendedNotes = [];
  bool _showRecommendedNotes = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient(baseUrl: ApiConfig.baseUrl, tokenStorage: TokenStorage());
    _notesRepository = NotesRepository(NotesApi(apiClient));
    _fetchNotes();
  }

  Future<void> _fetchNotes() async {
    if (_notes.isNotEmpty && !_showRecommendedNotes) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final purchasedNotes = await _notesRepository.getPurchasedNotes();

      if (purchasedNotes.isEmpty) {
        final allNotes = await _notesRepository.getNotes();
        if (mounted) {
          setState(() {
            _notes = [];
            _recommendedNotes = allNotes;
            _showRecommendedNotes = true;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _notes = purchasedNotes;
            _showRecommendedNotes = false;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        // Fallback to recommendations on error (optional, but good for UX)
        try {
          final allNotes = await _notesRepository.getNotes();
          setState(() {
            _notes = [];
            _recommendedNotes = allNotes;
            _showRecommendedNotes = true;
            _isLoading = false;
          });
        } catch (_) {
          setState(() {
            _error = e.toString();
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _notes = [];
      _showRecommendedNotes = false;
      _isLoading = true;
    });
    await _fetchNotes();
  }

  Widget _buildNoteCard(dynamic note, {bool isRecommended = false}) {
    final title = note['title'] ?? 'Untitled Note';
    final thumbnailUrl = note['thumbnailUrl'];
    // 🔍 Try 'noteId', fallback to 'id', handling both String and Int types safely
    final rawId = note['noteId'] ?? note['id'];
    final int? noteId = rawId is int ? rawId : (rawId is String ? int.tryParse(rawId) : null);

    if (noteId == null) {
      print('⚠️ Warning: Note ID is null for note: $title. Keys: ${note.keys}');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(kRadius),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(kRadius),
          onTap: noteId == null
              ? null // 🚫 Disable tap if ID is missing to prevent crash
              : () {
                  if (isRecommended) {
                    // 🛒 If recommended, go to Detail Screen for purchase
                    Navigator.push(context, MaterialPageRoute(builder: (_) => NoteDetailScreen(noteId: noteId)));
                  } else {
                    // 📖 If purchased, go to Content Screen for reading
                    Navigator.push(context, MaterialPageRoute(builder: (_) => NoteContentScreen(noteId: noteId)));
                  }
                },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(color: Colors.indigo.shade50),
                        child: (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
                            ? Image.network(thumbnailUrl, fit: BoxFit.cover)
                            : Icon(Icons.menu_book_rounded, color: Colors.indigo.shade300, size: 30),
                      ),
                      if (isRecommended)
                        Positioned(
                          top: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.star, color: Colors.amber, size: 10),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          'PDF Note',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber.shade800),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kTextPrimary),
                      ),
                      const SizedBox(height: 6),
                      if (!isRecommended)
                        Row(
                          children: const [
                            Icon(Icons.check_circle, size: 14, color: Colors.green),
                            SizedBox(width: 4),
                            Text('Purchased', style: TextStyle(fontSize: 12, color: Colors.green)),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
    }

    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );
    }

    return RefreshIndicator(
      color: kPrimaryColor,
      onRefresh: _refreshData,
      child: _showRecommendedNotes
          ? SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.library_books_outlined, size: 40, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'No Purchased Notes',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kTextPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Explore our collection of notes.",
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome, size: 18, color: Colors.amber.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          'Recommended Notes',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextPrimary),
                        ),
                      ],
                    ),
                  ),
                  ..._recommendedNotes.take(3).map((n) => _buildNoteCard(n, isRecommended: true)),

                  // ✨ Explore More Button
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const BookStoreScreen()));
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: kPrimaryColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text(
                          'Explore More Notes',
                          style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 16),
              itemCount: _notes.length,
              itemBuilder: (context, i) => _buildNoteCard(_notes[i], isRecommended: false),
            ),
    );
  }
}
