import 'package:flutter/material.dart';
import 'package:medical_simplified/config/api_config.dart';
import 'package:medical_simplified/core/storage/token_storage.dart';
import 'package:medical_simplified/features/auth/data/courses_api.dart';
import 'package:medical_simplified/features/auth/data/courses_repository.dart';
import '../courses/courses_detail_screen.dart';
import '../courses/courses_screen.dart';
import 'course_player_screen.dart';
import 'my_courses_screen.dart'; // For constants

import '../../../../core/networking/api_client.dart';

class CoursesTabView extends StatefulWidget {
  const CoursesTabView({super.key});

  @override
  State<CoursesTabView> createState() => _CoursesTabViewState();
}

class _CoursesTabViewState extends State<CoursesTabView> {
  late final CoursesRepository _coursesRepository;
  bool _isLoading = true;
  String? _error;
  List<dynamic> _courses = [];
  List<dynamic> _recommendedCourses = [];
  bool _showRecommended = false;

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient(baseUrl: ApiConfig.baseUrl, tokenStorage: TokenStorage());
    _coursesRepository = CoursesRepository(CoursesApi(apiClient));
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final purchased = await _coursesRepository.getPurchasedCourses();
      if (purchased.isEmpty) {
        final all = await _coursesRepository.getCourses();
        if (mounted) {
          setState(() {
            _courses = [];
            _recommendedCourses = all;
            _showRecommended = true;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _courses = purchased;
            _showRecommended = false;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        try {
          final allCourses = await _coursesRepository.getCourses();
          setState(() {
            _courses = [];
            _recommendedCourses = allCourses;
            _showRecommended = true;
            _isLoading = false;
          });
        } catch (inner) {
          setState(() {
            _error = e.toString();
            _isLoading = false;
          });
        }
      }
    }
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String text = status.toUpperCase();

    switch (status.toLowerCase()) {
      case 'archived':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        break;
      case 'active':
      case 'published':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        break;
      default:
        bgColor = Colors.blue.shade50;
        textColor = kPrimaryColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: textColor, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildCourseCard(dynamic course, {bool isRecommended = false}) {
    final title = course['title'] ?? 'Untitled Course';
    final price = (course['price'] ?? 0).toDouble();
    final discount = course['discountPrice']?.toDouble();
    final thumbnailUrl = course['thumbnailUrl'];
    final courseId = course['courseId'];
    final status = course['status'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(kRadius),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(kRadius),
          onTap: () {
            if (isRecommended) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => CourseDetailScreen(courseId: courseId)));
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CoursePlayerScreen(courseId: courseId, courseTitle: title),
                ),
              );
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
                      (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
                          ? Image.network(thumbnailUrl, width: 100, height: 100, fit: BoxFit.cover)
                          : Image.asset(
                              'assets/images/default_thumbnail.png',
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                      if (isRecommended)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.star, color: Colors.amber, size: 12),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (status.isNotEmpty) ...[_buildStatusBadge(status), const SizedBox(height: 6)],
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: kTextPrimary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${(discount ?? price).toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kTextPrimary),
                          ),
                          if (discount != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              '₹${price.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: kTextSecondary,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
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
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: kPrimaryColor));
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));

    return RefreshIndicator(
      color: kPrimaryColor,
      onRefresh: _fetchData,
      child: _showRecommended
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
                        Icon(Icons.school_outlined, size: 40, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text(
                          'No Purchased Courses',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kTextPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Start your learning journey today.",
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
                          'Recommended For You',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kTextPrimary),
                        ),
                      ],
                    ),
                  ),
                  ..._recommendedCourses.take(3).map((c) => _buildCourseCard(c, isRecommended: true)),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const CoursesScreen()));
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: kPrimaryColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text(
                          'Explore More Courses',
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
              itemCount: _courses.length,
              itemBuilder: (context, i) => _buildCourseCard(_courses[i]),
            ),
    );
  }
}
