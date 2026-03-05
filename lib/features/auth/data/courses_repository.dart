import 'dart:convert';
import 'courses_api.dart';

class CoursesRepository {
  final CoursesApi _api;
  CoursesRepository(this._api);

  // ✅ 1. Fetch all published courses
  Future<List<dynamic>> getCourses() async {
    final response = await _api.fetchCourses();

    if (response.statusCode == 404) {
      return [];
    }

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch courses (${response.statusCode})');
    }

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (body['success'] != true) {
      // If standard error format
      if (body['error'] != null && body['statusCode'] == 404) {
        return [];
      }
      throw Exception(body['message'] ?? 'Failed to load courses');
    }

    return body['data'] ?? [];
  }

  // ✅ 2. Fetch a specific course detail
  Future<Map<String, dynamic>> getCourseDetail(int courseId) async {
    final response = await _api.fetchCourseDetail(courseId);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch course details (${response.statusCode})');
    }

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to load course details');
    }

    return Map<String, dynamic>.from(body['data'] ?? {});
  }

  // ✅ 3. Fetch purchase status for a given course
  Future<Map<String, dynamic>> getPurchaseStatus(int courseId) async {
    final response = await _api.fetchPurchaseStatus(courseId);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch purchase status (${response.statusCode})');
    }

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to load purchase status');
    }

    return Map<String, dynamic>.from(body['data'] ?? {});
  }

  // ✅ 4. Fetch purchased courses for the logged-in user
  Future<List<dynamic>> getPurchasedCourses() async {
    final response = await _api.fetchPurchasedCourses();

    if (response.statusCode == 404) {
      return [];
    }

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch purchased courses (${response.statusCode})');
    }

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (body['success'] != true) {
      // Handle business logic error that might be 200 OK but success=false (less likely for 404 but possible)
      // If backend returns success=false with 404-like message
      if (body['statusCode'] == 404 || body['message'].toString().contains('not purchased any')) {
        return [];
      }
      throw Exception(body['message'] ?? 'Failed to load purchased courses');
    }

    return body['data'] ?? [];
  }

  // ✅ 5. Create Payment Order
  Future<Map<String, dynamic>> createOrder(int courseId) async {
    final response = await _api.createOrder(courseId);

    if (response.statusCode != 200) {
      throw Exception('Failed to create order (${response.statusCode})');
    }

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to create order');
    }

    return Map<String, dynamic>.from(body['data'] ?? {});
  }

  // ✅ 6. Fetch Course Lessons
  Future<List<dynamic>> getCourseLessons(int courseId) async {
    final response = await _api.fetchCourseLessons(courseId);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch lessons (${response.statusCode})');
    }

    final Map<String, dynamic> body = jsonDecode(response.body);
    if (body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to load lessons');
    }

    return body['data'] ?? [];
  }
}
