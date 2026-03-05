import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../config/api_config.dart';
import '../../../../core/networking/api_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../data/notes_api.dart';
import '../../data/notes_repository.dart';
import '../../../../core/services/payment_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../payment/presentation/payment_success_screen.dart';
import '../../../payment/presentation/payment_failed_screen.dart';

class NoteDetailScreen extends StatefulWidget {
  final int noteId;
  final Map<String, dynamic>? initialNote;

  const NoteDetailScreen({super.key, required this.noteId, this.initialNote});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late final NotesRepository _repository;
  late final PaymentService _paymentService;

  bool _isLoading = true;
  String? _error;
  bool _isPurchasing = false;
  bool _checkingPurchaseStatus = true;

  bool _isPurchased = false;
  Map<String, dynamic>? _noteDetails;

  // 🔥 FIX 1: Variable to lock the URL and prevent updates
  String? _displayThumbnailUrl;

  // 🔥 FIX (Razorpay): User data for checkout
  String? _userPhone;
  String? _userEmail;
  double? _purchaseAmount; // To track amount for success screen

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
    _repository = NotesRepository(NotesApi(apiClient));

    // Initialize with data passed from previous screen
    if (widget.initialNote != null) {
      _noteDetails = widget.initialNote;

      // 🔥 FIX 1: Lock the URL immediately.
      // We will use THIS variable for the image widget, never the one from the API refresh.
      _displayThumbnailUrl = widget.initialNote!['thumbnailUrl'];

      _isLoading = false;
      _fetchDetails(background: true);
    } else {
      _fetchDetails();
    }

    // Load user data for checkout
    _loadUserData();
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    // Navigate to Success Screen
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
    // Refresh details in background so if they come back, it's updated
    _fetchDetails(background: true);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() {
      _isPurchasing = false;
    });
    // Navigate to Failure Screen
    if (mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentFailedScreen()));
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() {
      _isPurchasing = false;
    });
    // Navigate to Failure Screen (or specific wallet handling if needed, but usually treated as incomplete flow if not successful)
    if (mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentFailedScreen()));
    }
  }

  Future<void> _fetchDetails({bool background = false}) async {
    if (!background) {
      setState(() => _isLoading = true);
    }

    setState(() => _checkingPurchaseStatus = true);

    try {
      final data = await _repository.getPurchaseStatus(widget.noteId);
      if (mounted) {
        setState(() {
          _isPurchased = data['isPurchased'] ?? false;

          final newDetails = data['details'];
          if (newDetails != null) {
            _noteDetails = newDetails;

            // 🔥 FIX 1 (Logic): If we didn't have a URL before, set it now.
            // BUT if we already have one, DO NOT overwrite it with the API data.
            // This prevents the flicker if the API URL is slightly different.
            if (_displayThumbnailUrl == null || _displayThumbnailUrl!.isEmpty) {
              _displayThumbnailUrl = newDetails['thumbnailUrl'];
            }
          }

          _isLoading = false;
          _isPurchasing = false;
          _checkingPurchaseStatus = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (_noteDetails == null) {
            _error = e.toString();
          }
          _isLoading = false;
          _isPurchasing = false;
          _checkingPurchaseStatus = false;
        });
      }
    }
  }

  Future<void> _loadUserData() async {
    try {
      final user = await TokenStorage().readUser();
      if (user != null) {
        String? phone = user['phoneNumber'];
        final String? email = user['email'];

        // Validate and sanitize phone
        if (phone != null) {
          // Remove all non-digit characters
          phone = phone.replaceAll(RegExp(r'\D'), '');

          // Take last 10 digits if longer
          if (phone.length > 10) {
            phone = phone.substring(phone.length - 10);
          }

          // Only use if it is exactly 10 digits
          if (phone.length != 10) {
            phone = null;
          }
        }

        if (mounted) {
          setState(() {
            _userPhone = phone;
            _userEmail = email;
          });
          print('✅ [NoteDetail] Loaded user for checkout: Phone=$_userPhone, Email=$_userEmail');
        }
      }
    } catch (e) {
      print('⚠️ [NoteDetail] Failed to load user data: $e');
    }
  }

  Future<void> _handlePurchase() async {
    if (_checkingPurchaseStatus || _isPurchased || _noteDetails == null) return;

    setState(() {
      _isPurchasing = true;
    });

    try {
      final orderData = await _repository.createOrder(widget.noteId);
      final String orderId = orderData['orderId'];
      final String key = orderData['razorpayKey'];
      final double amountInPaise = (orderData['amount'] as num).toDouble();
      final double price = amountInPaise / 100.0;
      _purchaseAmount = price; // Store for success screen

      _paymentService.openCheckout(
        key: key,
        orderId: orderId,
        price: price,
        title: _noteDetails!['title'] ?? 'Note',
        description: 'Purchase Notes',
        contact: _userPhone ?? '', // ✅ Pass validated phone
        email: _userEmail ?? '', // ✅ Pass email
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPurchasing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to initiate payment: $e')));
      }
    }
  }

  Widget _imageFallback() {
    return Center(child: Icon(Icons.menu_book, size: 64, color: Colors.grey.shade400));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _noteDetails == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Note Details')),
        body: Center(child: Text('Error: $_error')),
      );
    }

    if (_noteDetails == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Note Details')),
        body: const Center(child: Text('Note not found')),
      );
    }

    final title = _noteDetails!['title'] ?? 'Untitled Note';
    final description = _noteDetails!['description'] ?? '';
    final price = (_noteDetails!['price'] ?? 0).toDouble();
    final discount = _noteDetails!['discountedPrice']?.toDouble();

    // 🔥 FIX 1: Use the Locked URL variable
    final thumbnailUrl = _displayThumbnailUrl;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 250,
              width: double.infinity,
              child: thumbnailUrl != null && thumbnailUrl.isNotEmpty
                  ? Hero(
                      // Tag MUST MATCH BookStoreScreen
                      tag: 'course_image_${widget.noteId}',
                      child: Material(
                        type: MaterialType.transparency,
                        child: CachedNetworkImage(
                          imageUrl: thumbnailUrl,
                          fit: BoxFit.cover,

                          // 🔥 FIX 2: Zero fade + Use Old Image
                          fadeInDuration: Duration.zero,
                          fadeOutDuration: Duration.zero,
                          useOldImageOnUrlChange: true,

                          // 🔥 FIX 3: Match Memory Cache width from List Screen
                          memCacheWidth: 800,
                          maxWidthDiskCache: 1000,

                          // Simple placeholder (no loading spinner)
                          placeholder: (context, url) => Container(color: Colors.grey.shade200),
                          errorWidget: (_, __, ___) => _imageFallback(),
                        ),
                      ),
                    )
                  : _imageFallback(),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (discount != null && discount > 0) ...[
                        Text(
                          '₹${price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '₹${discount.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ] else
                        Text(
                          '₹${price.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(description, style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            // Logic to disable button if loading or purchased
            onPressed: (_checkingPurchaseStatus || _isPurchased) ? null : _handlePurchase,

            style: ElevatedButton.styleFrom(
              backgroundColor: _isPurchased ? Colors.green : Colors.blueAccent,
              disabledBackgroundColor: _isPurchased ? Colors.grey.shade300 : Colors.blueAccent.shade100,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: (_isPurchasing || _checkingPurchaseStatus)
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _checkingPurchaseStatus ? 'Checking...' : 'Processing...',
                        style: const TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ],
                  )
                : Text(
                    _isPurchased ? 'Already Purchased' : 'Buy Now',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
          ),
        ),
      ),
    );
  }
}
