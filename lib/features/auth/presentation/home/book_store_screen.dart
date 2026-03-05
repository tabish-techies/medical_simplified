import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../config/api_config.dart';
import '../../../../core/networking/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../data/notes_api.dart';
import '../../data/notes_repository.dart';
import '../notes/note_detail_screen.dart';

class BookStoreScreen extends StatefulWidget {
  const BookStoreScreen({super.key});

  @override
  State<BookStoreScreen> createState() => _BookStoreScreenState();
}

class _BookStoreScreenState extends State<BookStoreScreen> with AutomaticKeepAliveClientMixin {
  late final NotesRepository _repository;

  bool _isLoading = true;
  String? _error;
  List<dynamic> _notes = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    final apiClient = ApiClient(
      baseUrl: ApiConfig.baseUrl,
      tokenStorage: TokenStorage(),
    );

    _repository = NotesRepository(NotesApi(apiClient));
    _fetchNotes();
  }

  Future<void> _fetchNotes() async {
    try {
      final data = await _repository.getNotes();

      // 🔥 PRE-WARMING
      for (var i = 0; i < data.length && i < 3; i++) {
        final url = data[i]['thumbnailUrl'];
        if (url != null && url.isNotEmpty) {
          if (mounted) {
            precacheImage(
              CachedNetworkImageProvider(url),
              context,
            );
          }
        }
      }

      if (mounted) {
        setState(() {
          _notes = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildNoteItem(dynamic note) {
    final title = note['title'] ?? 'Untitled Note';
    final price = (note['price'] ?? 0).toDouble();
    final discount = note['discountedPrice']?.toDouble();
    final thumbnailUrl = note['thumbnailUrl'];
    final noteId = note['id']; // 🔑 Crucial for stable Hero tag

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NoteDetailScreen(
              noteId: noteId, // Ensure this ID is passed correctly
              initialNote: note,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🖼️ Large Thumbnail Area
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                width: double.infinity,
                color: Colors.grey.shade300,
                child: thumbnailUrl != null && thumbnailUrl.isNotEmpty
                    ? Hero(
                        // 🔥 STABLE TAG: Using ID instead of URL prevents backend mismatches
                        tag: 'course_image_$noteId',
                        
                        // 🔥 WRAPPER: Material ensures no texture glitches during flight
                        child: Material(
                          type: MaterialType.transparency,
                          child: CachedNetworkImage(
                            imageUrl: thumbnailUrl,
                            memCacheWidth: 800,
                            maxWidthDiskCache: 1000,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _imageSkeleton(),
                            // Only fade in on the list screen (first load)
                            fadeInDuration: const Duration(milliseconds: 150),
                            errorWidget: (_, __, ___) => _imageFallback(),
                          ),
                        ),
                      )
                    : _imageFallback(),
              ),
            ),

            /// 📄 Details Section
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.book, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  
                  // Text Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (discount != null) ...[
                              Text(
                                '₹${price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              '₹${(discount ?? price).toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: discount != null
                                    ? Colors.green
                                    : Colors.black87,
                              ),
                            ),
                            const Spacer(),
                            const Text(
                              'View Details',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF4F7CFF),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey.shade300,
      ),
    );
  }

  Widget _imageFallback() {
    return Center(
      child: Icon(
        Icons.menu_book,
        size: 36,
        color: Colors.grey.shade400,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Book Store'),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 20),
                  cacheExtent: 800,
                  itemCount: _notes.length,
                  itemBuilder: (context, i) => _buildNoteItem(_notes[i]),
                ),
    );
  }
}