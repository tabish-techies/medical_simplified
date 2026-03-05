import 'package:http/http.dart' as http;
import '../../../core/networking/api_client.dart';

class CoursesApi {
  final ApiClient _client;
  CoursesApi(this._client);

  // ✅ 1. Fetch all courses
  Future<http.Response> fetchCourses() async {
    return _client.get('/api/public/courses');
  }

  // ✅ 2. Fetch single course details by ID
  Future<http.Response> fetchCourseDetail(int courseId) async {
    return _client.get('/api/public/courses/$courseId');
  }

  // ✅ 3. Fetch purchase status for a given course
  Future<http.Response> fetchPurchaseStatus(int courseId) async {
    return _client.get('/api/public/courses/$courseId/purchase-status');
  }

  // ✅ 4. Fetch purchased courses for authenticated user
  Future<http.Response> fetchPurchasedCourses() async {
    return _client.get('/api/public/courses/purchased');
  }

  // ✅ 5. Create Payment Order
  Future<http.Response> createOrder(int courseId) async {
    return _client.post(
      '/api/payment/create-order',
      body: {'courseId': courseId},
    );
  }

  // ✅ 6. Fetch Course Lessons (After Purchase)
  Future<http.Response> fetchCourseLessons(int courseId) async {
    return _client.get('/api/public/courses/$courseId/lessons');
  }
}
