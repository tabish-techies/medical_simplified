import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:medical_simplified/config/api_config.dart';
import 'package:medical_simplified/core/networking/api_client.dart';
import 'package:medical_simplified/core/storage/token_storage.dart';
import 'package:medical_simplified/features/auth/data/courses_api.dart';
import 'package:medical_simplified/features/auth/data/courses_repository.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:medical_simplified/core/services/payment_service.dart';
import '../../../payment/presentation/payment_success_screen.dart';
import '../../../payment/presentation/payment_failed_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final int courseId;
  final Map<String, dynamic>? initialData;

  const CourseDetailScreen({super.key, required this.courseId, this.initialData});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  late final CoursesRepository _repository;
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _course;
  bool _isPurchased = false;
  List<dynamic> _lessons = [];
  late PaymentService _paymentService;
  double? _purchaseAmount; // To track amount for success screen

  @override
  void initState() {
    super.initState();

    // Show initial data immediately
    if (widget.initialData != null) {
      _course = widget.initialData;
      _isLoading = false;
    }

    _paymentService = PaymentService(
      onSuccess: _handlePaymentSuccess,
      onFailure: _handlePaymentError,
      onExternalWallet: _handleExternalWallet,
    );
    _paymentService.init();

    final apiClient = ApiClient(baseUrl: '${ApiConfig.baseUrl}', tokenStorage: TokenStorage());
    _repository = CoursesRepository(CoursesApi(apiClient));

    _loadCourseData();
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentSuccessScreen(
            amount: _purchaseAmount ?? 0.0,
            transactionId: response.paymentId ?? 'Unknown',
            date: DateTime.now(),
            paymentMode: 'Online Payment',
          ),
        ),
      );
    }
    _loadCourseData();
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentFailedScreen()));
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentFailedScreen()));
    }
  }

  Future<void> _openCheckout() async {
    if (_course == null) return;

    try {
      final orderData = await _repository.createOrder(widget.courseId);
      final String orderId = orderData['orderId'];
      final String key = orderData['razorpayKey'];
      final double amount = (orderData['amount'] as num).toDouble();
      final price = amount / 100.0;
      _purchaseAmount = price; // Store for success screen

      _paymentService.openCheckout(
        key: key,
        orderId: orderId,
        price: price,
        title: _course!['title'] ?? 'Course',
        description: _course!['title'],
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to initiate payment: $e')));
    }
  }

  Future<void> _loadCourseData() async {
    try {
      final course = await _repository.getCourseDetail(widget.courseId);
      final purchaseStatus = await _repository.getPurchaseStatus(widget.courseId);
      final isPurchased = purchaseStatus['isPurchased'] ?? false;

      List<dynamic> lessons = [];
      if (isPurchased) {
        lessons = await _repository.getCourseLessons(widget.courseId);
      }

      if (mounted) {
        setState(() {
          _course = course;
          _isPurchased = isPurchased;
          _lessons = lessons;
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _course == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null && _course == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Course Details')),
        body: Center(child: Text(_error!)),
      );
    }

    final course = _course!;
    final instructor = course['instructor'] ?? {};
    final thumbnailUrl = course['thumbnailUrl'];

    return Scaffold(
      appBar: AppBar(title: Text(course['title'] ?? 'Course Detail')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼️ HERO IMAGE SECTION
            Hero(
              // 🔥 STABLE TAG: Must match the List Screen tag EXACTLY
              tag: 'course_image_${widget.courseId}',

              // 🔥 WRAPPER: Material -> ClipRRect -> Image
              // This structure ensures the corners animate smoothly during flight
              child: Material(
                type: MaterialType.transparency,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: thumbnailUrl ?? '',
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,

                    // 🔥 FLICKER FIX: Zero fade ensures instant swap
                    fadeInDuration: Duration.zero,

                    // 🔥 MEMORY SYNC: Must match List Screen to use same RAM image
                    memCacheWidth: 800,
                    maxWidthDiskCache: 1000,

                    placeholder: (context, url) => Container(height: 200, color: Colors.grey.shade300),
                    errorWidget: (context, url, error) =>
                        Container(height: 200, color: Colors.grey[300], child: const Icon(Icons.broken_image)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(course['title'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),

            const SizedBox(height: 8),
            Text(course['description'] ?? '', style: const TextStyle(fontSize: 15, color: Colors.black87)),
            const SizedBox(height: 12),

            // Price or Status
            if (!_isPurchased)
              Row(
                children: [
                  if (course['discountPrice'] != null)
                    Text(
                      '₹${course['price'].toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 14, decoration: TextDecoration.lineThrough),
                    ),
                  const SizedBox(width: 6),
                  Text(
                    '₹${(course['discountPrice'] ?? course['price']).toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              )
            else
              const Text(
                '✅ Purchased',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
              ),

            const SizedBox(height: 16),

            // Instructor
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(instructor['profileImageUrl'] ?? ''),
                  radius: 30,
                  onBackgroundImageError: (_, __) {},
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        instructor['fullName'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        instructor['bio'] ?? '',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.black54, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Course Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfo('⏱ Duration', '${course['durationMinutes']} mins'),
                _buildInfo('🎯 Level', course['level'] ?? 'All Levels'),
                _buildInfo('🌐 Language', course['language'] ?? 'English'),
              ],
            ),

            const SizedBox(height: 20),

            // Lessons List
            if (_isPurchased && _lessons.isNotEmpty) ...[
              const Divider(),
              const Text('Course Lessons', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _lessons.length,
                itemBuilder: (context, index) {
                  final lesson = _lessons[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.play_circle_fill, color: Colors.blue),
                      title: Text(lesson['title'] ?? 'Lesson ${index + 1}'),
                      subtitle: Text('${lesson['videoDurationMinutes'] ?? 0} mins'),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Playing video...')));
                      },
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: 40),

            // Buy Button
            if (!_isPurchased)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _openCheckout,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Buy Now', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }
}
