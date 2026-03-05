import 'package:flutter/material.dart';
import 'package:medical_simplified/config/api_config.dart';
import 'package:medical_simplified/core/storage/token_storage.dart';
import 'package:medical_simplified/features/auth/data/courses_api.dart';
import 'package:medical_simplified/features/auth/data/courses_repository.dart';

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
    // Initialize Repository (replicate the logic from original initState)
    final apiClient = ApiClient(baseUrl: ApiConfig.baseUrl, tokenStorage: TokenStorage());
    _coursesRepository = CoursesRepository(CoursesApi(apiClient));
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (mounted) setState(() { _isLoading = true; _error = null; });
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
          // Error handling fallback logic...
          setState(() { _error = e.toString(); _isLoading = false; });
      }
    }
  }

  // ... Insert _buildCourseCard and _buildStatusBadge methods here ...
  // (Copy them from previous code)

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: _showRecommended
          ? SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                   // ... Recommended UI logic ...
                   ..._recommendedCourses.map((c) => _buildCourseCard(c, isRecommended: true)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(top: 16),
              itemCount: _courses.length,
              itemBuilder: (ctx, i) => _buildCourseCard(_courses[i]),
            ),
    );
  }
}