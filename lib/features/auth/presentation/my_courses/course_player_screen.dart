import 'package:flutter/material.dart';
import 'package:medical_simplified/config/api_config.dart';
import 'package:medical_simplified/core/networking/api_client.dart';
import 'package:medical_simplified/core/storage/token_storage.dart';
import 'package:medical_simplified/features/auth/data/lessons_repository.dart';
import 'video_player_screen.dart';

class CoursePlayerScreen extends StatefulWidget {
  final int courseId;
  final String courseTitle;

  const CoursePlayerScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  State<CoursePlayerScreen> createState() => _CoursePlayerScreenState();
}

class _CoursePlayerScreenState extends State<CoursePlayerScreen> {
  late final LessonsRepository _repository;
  bool _isLoading = true;
  String? _error;
  List<dynamic> _lessons = [];

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient(
      baseUrl: '${ApiConfig.baseUrl}',
      tokenStorage: TokenStorage(),
    );
    _repository = LessonsRepository(apiClient);
    _fetchLessons();
  }

  Future<void> _fetchLessons() async {
    try {
      final data = await _repository.getLessons(widget.courseId);
      setState(() {
        _lessons = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Widget _buildLessonTile(dynamic lesson) {
    final title = lesson['title'] ?? 'Untitled Lesson';
    final description = lesson['description'] ?? '';
    final videoUrl = lesson['videoUrl'];
    final thumbnailUrl = lesson['thumbnailUrl'];
    final duration = lesson['videoDurationMinutes']?.toString() ?? '';
    final isFreePreview = lesson['isFreePreview'] == true;

    return InkWell(
      onTap: () {
  if (videoUrl != null) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(
          videoUrl: videoUrl,
          title: title,
          description: description,
        ),
      ),
    );
  }
},
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: Stack(
                children: [
                  thumbnailUrl != null && thumbnailUrl.isNotEmpty
                      ? Image.network(
                          thumbnailUrl,
                          width: 130,
                          height: 80,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 130,
                          height: 80,
                          color: Colors.grey[300],
                          child: const Icon(Icons.videocam, size: 36, color: Colors.grey),
                        ),
                  // Duration overlay
                  Positioned(
                    bottom: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${duration}m',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Title + description
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    if (isFreePreview)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.courseTitle)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _lessons.isEmpty
                  ? const Center(child: Text('No lessons available'))
                  : RefreshIndicator(
                      onRefresh: _fetchLessons,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 16),
                        itemCount: _lessons.length,
                        itemBuilder: (context, i) =>
                            _buildLessonTile(_lessons[i]),
                      ),
                    ),
    );
  }
}
