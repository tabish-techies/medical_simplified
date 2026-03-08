import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../config/api_config.dart';
import '../../../../core/networking/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../data/syllabus_api.dart';
import '../../data/syllabus_repository.dart';
import '../../../../core/services/payment_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../payment/presentation/payment_success_screen.dart';
import '../../../payment/presentation/payment_failed_screen.dart';

class SyllabusDetailScreen extends StatefulWidget {
  final int syllabusId;
  final Map<String, dynamic>? initialSyllabus;

  const SyllabusDetailScreen({super.key, required this.syllabusId, this.initialSyllabus});

  @override
  State<SyllabusDetailScreen> createState() => _SyllabusDetailScreenState();
}

class _SyllabusDetailScreenState extends State<SyllabusDetailScreen> {
  late final SyllabusRepository _repository;
  late final PaymentService _paymentService;

  bool _isLoading = true;
  String? _error;
  bool _isPurchasing = false;
  bool _checkingPurchaseStatus = true;
  bool _isPurchased = false;
  Map<String, dynamic>? _syllabusDetails;
  String? _displayThumbnailUrl;

  String? _userPhone;
  String? _userEmail;
  double? _purchaseAmount;

  @override
  void initState() {
    super.initState();
    _paymentService = PaymentService(
      onSuccess: _handlePaymentSuccess,
      onFailure: _handlePaymentError,
      onExternalWallet: _handleExternalWallet,
    );
    _paymentService.init();

    final apiClient = ApiClient(baseUrl: ApiConfig.baseUrl, tokenStorage: TokenStorage());
    _repository = SyllabusRepository(SyllabusApi(apiClient));

    if (widget.initialSyllabus != null) {
      _syllabusDetails = widget.initialSyllabus;
      _displayThumbnailUrl = widget.initialSyllabus!['thumbnailUrl'];
      _isLoading = false;
      _fetchDetails(background: true);
    } else {
      _fetchDetails();
    }
    _loadUserData();
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  // --- LOGIC METHODS (Unchanged) ---
  Future<void> _fetchDetails({bool background = false}) async {
    if (!background) setState(() => _isLoading = true);
    setState(() => _checkingPurchaseStatus = true);
    try {
      final data = await _repository.getPurchaseStatus(widget.syllabusId);
      if (mounted) {
        setState(() {
          _isPurchased = data['isPurchased'] ?? false;
          final newDetails = data['details'];
          if (newDetails != null) {
            _syllabusDetails = newDetails;
            if (_displayThumbnailUrl == null || _displayThumbnailUrl!.isEmpty) {
              _displayThumbnailUrl = newDetails['thumbnailUrl'];
            }
          }
          _isLoading = false;
          _checkingPurchaseStatus = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (_syllabusDetails == null) _error = e.toString();
          _isLoading = false;
          _checkingPurchaseStatus = false;
        });
      }
    }
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
    _fetchDetails(background: true);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _isPurchasing = false);
    if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentFailedScreen()));
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() => _isPurchasing = false);
    if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentFailedScreen()));
  }

  Future<void> _loadUserData() async {
    try {
      final user = await TokenStorage().readUser();
      if (user != null) {
        String? phone = user['phoneNumber'];
        final String? email = user['email'];
        if (phone != null) {
          phone = phone.replaceAll(RegExp(r'\D'), '');
          if (phone.length > 10) phone = phone.substring(phone.length - 10);
          if (phone.length != 10) phone = null;
        }
        if (mounted) setState(() { _userPhone = phone; _userEmail = email; });
      }
    } catch (e) { debugPrint('User data load fail: $e'); }
  }

  Future<void> _handlePurchase() async {
    if (_checkingPurchaseStatus || _isPurchased || _syllabusDetails == null) return;
    setState(() => _isPurchasing = true);
    try {
      final orderData = await _repository.createOrder(widget.syllabusId);
      final String orderId = orderData['orderId'];
      final String key = orderData['razorpayKey'];
      final double amountInPaise = (orderData['amount'] as num).toDouble();
      final double price = amountInPaise / 100.0;
      _purchaseAmount = price;

      _paymentService.openCheckout(
        key: key,
        orderId: orderId,
        price: price,
        title: _syllabusDetails!['title'] ?? 'Syllabus',
        description: 'Purchase Syllabus',
        contact: _userPhone ?? '',
        email: _userEmail ?? '',
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isPurchasing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  // --- UI COMPONENTS ---

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _syllabusDetails == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF4F7CFF))));
    }

    if (_error != null || _syllabusDetails == null) {
      return Scaffold(
        appBar: AppBar(elevation: 0, backgroundColor: Colors.white),
        body: Center(child: Text(_error ?? 'Syllabus not found')),
      );
    }

    final title = _syllabusDetails!['title'] ?? 'Untitled Syllabus';
    final description = _syllabusDetails!['description'] ?? 'No description available.';
    final price = (_syllabusDetails!['price'] ?? 0).toDouble();
    final discount = _syllabusDetails!['discountedPrice']?.toDouble();
    final hasDiscount = discount != null && discount > 0 && discount < price;
    final finalPrice = hasDiscount ? discount : price;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Fixed Thumbnail with Parallax Effect
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: Hero(
              tag: 'syllabus_image_${widget.syllabusId}',
              child: CachedNetworkImage(
                imageUrl: _displayThumbnailUrl ?? '',
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(color: Colors.grey.shade200),
              ),
            ),
          ),

          // 2. Scrollable Content overlapping the image
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Invisible spacer to push content down
                  SizedBox(height: MediaQuery.of(context).size.height * 0.38),

                  // The Content Card
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -10)),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Drag Handle
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Category Label
                        Text(
                          "SYLLABUS DETAILS",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF4F7CFF).withOpacity(0.8),
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Title
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1A1C1E),
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Pricing Row
                        Row(
                          children: [
                            Text(
                              '₹${finalPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF4F7CFF),
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (hasDiscount) ...[
                              Text(
                                '₹${price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "${(((price - discount) / price) * 100).toStringAsFixed(0)}% OFF",
                                  style: const TextStyle(
                                    color: Color(0xFF2E7D32),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),

                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Divider(color: Color(0xFFF1F4F8), thickness: 1.5),
                        ),

                        // Description
                        const Text(
                          'About this Syllabus',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1C1E)),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.black.withOpacity(0.6),
                            height: 1.6,
                          ),
                        ),

                        const SizedBox(height: 30),
                        _buildFeatureItem(Icons.verified_user_outlined, "Official Curriculum"),
                        _buildFeatureItem(Icons.cloud_download_outlined, "Offline Resources"),
                        _buildFeatureItem(Icons.update_rounded, "Latest 2024 Updates"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Floating Glass Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  height: 40,
                  width: 40,
                  color: Colors.black.withOpacity(0.2),
                  child: IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      // 4. Fixed Bottom Action Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))
          ],
        ),
        child: SizedBox(
          height: 56,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_checkingPurchaseStatus || _isPurchased) ? null : _handlePurchase,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isPurchased ? const Color(0xFF2E7D32) : const Color(0xFF4F7CFF),
              disabledBackgroundColor: _isPurchased ? const Color(0xFF2E7D32).withOpacity(0.7) : Colors.grey.shade300,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: (_isPurchasing || _checkingPurchaseStatus)
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(
              _isPurchased ? 'ALREADY OWNED' : 'ENROLL NOW',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 1.1, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF4F7CFF)),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}