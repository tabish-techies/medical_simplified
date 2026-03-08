import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../config/api_config.dart';
import '../../../../core/networking/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../data/syllabus_api.dart';
import '../../data/syllabus_repository.dart';
import 'syllabus_detail_screen.dart';

class SyllabusScreen extends StatefulWidget {
  const SyllabusScreen({super.key});

  @override
  State<SyllabusScreen> createState() => _SyllabusScreenState();
}

class _SyllabusScreenState extends State<SyllabusScreen> with AutomaticKeepAliveClientMixin {
  late final SyllabusRepository _repository;

  bool _isLoading = true;
  String? _error;
  List<dynamic> _syllabusItems = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient(baseUrl: ApiConfig.baseUrl, tokenStorage: TokenStorage());
    _repository = SyllabusRepository(SyllabusApi(apiClient));
    _fetchSyllabus();
  }

  Future<void> _fetchSyllabus() async {
    try {
      final data = await _repository.getSyllabus();

      // Pre-warming images for smoother scrolling
      for (var i = 0; i < data.length && i < 3; i++) {
        final url = data[i]['thumbnailUrl'];
        if (url != null && url.isNotEmpty) {
          if (mounted) {
            precacheImage(CachedNetworkImageProvider(url), context);
          }
        }
      }

      if (mounted) {
        setState(() {
          _syllabusItems = data;
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

  Widget _buildSyllabusItem(dynamic item) {
    final title = item['title'] ?? 'Untitled Syllabus';
    final price = (item['price'] ?? 0).toDouble();
    final discount = item['discountedPrice']?.toDouble();
    final thumbnailUrl = item['thumbnailUrl'];
    final id = item['id'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SyllabusDetailScreen(syllabusId: id, initialSyllabus: item),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🖼️ Enhanced Thumbnail Stack
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Hero(
                      tag: 'syllabus_image_$id',
                      child: Material(
                        type: MaterialType.transparency,
                        child: thumbnailUrl != null && thumbnailUrl.isNotEmpty
                            ? CachedNetworkImage(
                          imageUrl: thumbnailUrl,
                          memCacheWidth: 800,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _imageSkeleton(),
                          errorWidget: (_, __, ___) => _imageFallback(),
                        )
                            : _imageFallback(),
                      ),
                    ),
                  ),
                  // Glassy "New" or "Course" Badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        "SYLLABUS",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              /// 📄 Details Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1C1E),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Pricing Column
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (discount != null)
                              Text(
                                '₹${price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            Text(
                              '₹${(discount ?? price).toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: discount != null ? const Color(0xFF00C853) : Colors.black87,
                              ),
                            ),
                          ],
                        ),

                        // Action Button
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF4F7CFF), Color(0xFF3359E0)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4F7CFF).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Text(
                            'View Syllabus',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
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
      ),
    );
  }

  Widget _imageSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.white,
      child: Container(width: double.infinity, height: double.infinity, color: Colors.white),
    );
  }

  Widget _imageFallback() {
    return Container(
      color: Colors.grey.shade100,
      child: Center(child: Icon(Icons.menu_book_rounded, size: 40, color: Colors.grey.shade400)),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE), // Modern light background
      appBar: AppBar(
        title: const Text(
          'Learning Syllabus',
          style: TextStyle(color: Color(0xFF1A1C1E), fontWeight: FontWeight.w800, fontSize: 22),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.black87),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4F7CFF)))
          : _error != null
          ? _buildErrorState()
          : RefreshIndicator(
        onRefresh: _fetchSyllabus,
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 12, bottom: 40),
          cacheExtent: 800,
          itemCount: _syllabusItems.length,
          itemBuilder: (context, i) => _buildSyllabusItem(_syllabusItems[i]),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 64, color: Colors.red.shade200),
          const SizedBox(height: 16),
          Text(_error ?? "Something went wrong", style: const TextStyle(color: Colors.grey)),
          TextButton(onPressed: _fetchSyllabus, child: const Text("Retry")),
        ],
      ),
    );
  }
}