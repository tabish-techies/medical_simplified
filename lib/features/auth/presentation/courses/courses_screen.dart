import 'package:flutter/material.dart';
import 'package:medical_simplified/config/api_config.dart';
import 'package:medical_simplified/core/networking/api_client.dart';
import 'package:medical_simplified/core/storage/token_storage.dart';
import 'package:medical_simplified/features/auth/data/courses_api.dart';
import 'package:medical_simplified/features/auth/data/courses_repository.dart';
import 'package:medical_simplified/features/auth/presentation/courses/courses_detail_screen.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  late final CoursesRepository _repository;
  bool _isLoading = true;
  String? _error;
  List<dynamic> _courses = [];

  @override
  void initState() {
    super.initState();

    final apiClient = ApiClient(
      baseUrl: '${ApiConfig.baseUrl}',
      tokenStorage: TokenStorage(),
    );
    _repository = CoursesRepository(CoursesApi(apiClient));

    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    try {
      // 1. Fetch all courses and purchased courses in parallel
      final results = await Future.wait([
        _repository.getCourses(),
        _repository.getPurchasedCourses(),
      ]);

      final allCourses = results[0] as List<dynamic>;
      final purchasedCourses = results[1] as List<dynamic>;

      // 2. Create a set of purchased course IDs for efficient lookup
      final purchasedCourseIds = purchasedCourses
          .map((c) => c['courseId'])
          .toSet();

      // 3. Filter out purchased courses from the all courses list
      final unpurchasedCourses = allCourses.where((course) {
        final courseId = course['courseId'];
        return !purchasedCourseIds.contains(courseId);
      }).toList();

      setState(() {
        _courses = unpurchasedCourses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Widget _buildCourseCard(dynamic course) {
  final title = course['title'] ?? 'Untitled Course';
  final price = (course['price'] ?? 0).toDouble();
  final discount = course['discountPrice']?.toDouble();
  final thumbnailUrl = course['thumbnailUrl'];
  final courseId = course['courseId'];

  return InkWell(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CourseDetailScreen(courseId: courseId),
        ),
      );
    },
    child: Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
            child: (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
                ? Image.network(
                    thumbnailUrl,
                    width: 120,
                    height: 90,
                    fit: BoxFit.cover,
                  )
                : Image.asset(
                    'assets/images/default_thumbnail.png',
                    width: 120,
                    height: 90,
                    fit: BoxFit.cover,
                  ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (discount != null)
                        Text(
                          '₹${price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      const SizedBox(width: 6),
                      Text(
                        '₹${(discount ?? price).toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color:
                              discount != null ? Colors.green : Colors.black87,
                        ),
                      ),
                    ],
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
      appBar: AppBar(title: const Text('Courses')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _courses.length,
                  itemBuilder: (context, i) => _buildCourseCard(_courses[i]),
                ),
    );
  }
}
