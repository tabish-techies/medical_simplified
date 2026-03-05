import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Use the same constants as your Dashboard for consistency
const Color kPrimaryColor = Color(0xFF2563EB); // Royal Blue
const Color kTextPrimary = Color(0xFF1E293B);  // Slate 800
const Color kTextSecondary = Color(0xFF64748B); // Slate 500

class PaymentSuccessScreen extends StatefulWidget {
  final double amount;
  final String transactionId;
  final DateTime date;
  final String paymentMode;

  const PaymentSuccessScreen({
    super.key,
    required this.amount,
    required this.transactionId,
    required this.date,
    this.paymentMode = 'UPI',
  });

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

    // 1. Scale Circle Background
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.elasticOut),
      ),
    );

    // 2. Draw Checkmark Path
    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.6, curve: Curves.easeOut),
      ),
    );

    // 3. Fade in Content (Text/Buttons)
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('MMM dd, yyyy, h:mm a').format(widget.date);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background: Subtle Blue Gradient (Matches EdTech Theme)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Colors.blue.shade50.withOpacity(0.6)],
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // --- ANIMATED SUCCESS ICON (Kept Green for Standard Semantic Success) ---
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer Ripple
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle, 
                              color: Colors.green.shade100, // Success usually remains green
                            ),
                          ),
                        ),
                        // Main Circle
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green,
                              boxShadow: [
                                BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5)),
                              ],
                            ),
                            // Custom Checkmark Painter
                            child: Center(
                              child: SizedBox(
                                width: 50,
                                height: 50,
                                child: AnimatedBuilder(
                                  animation: _checkAnimation,
                                  builder: (context, child) {
                                    return CustomPaint(painter: CheckMarkPainter(progress: _checkAnimation.value));
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // --- STAGGERED TEXT CONTENT ---
                    FadeTransition(
                      opacity: _opacityAnimation,
                      child: SlideTransition(
                        position: _opacityAnimation.drive(Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)),
                        child: Column(
                          children: [
                            const Text(
                              "Payment Successful!",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: kTextPrimary, // EdTech Slate
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Your transaction has been completed.",
                              style: TextStyle(fontSize: 16, color: kTextSecondary),
                            ),

                            const SizedBox(height: 32),

                            // --- RECEIPT CARD ---
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 24),
                              padding: const EdgeInsets.all(24), // Increased padding for cleaner look
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  _buildTransactionRow(
                                    "Total Amount",
                                    "₹${widget.amount.toStringAsFixed(0)}",
                                    isBold: true,
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 20),
                                    child: Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                                  ),
                                  _buildTransactionRow("Transaction ID", "#${widget.transactionId}"),
                                  const SizedBox(height: 16),
                                  _buildTransactionRow("Date", formattedDate),
                                  const SizedBox(height: 16),
                                  _buildTransactionRow("Payment Mode", widget.paymentMode),
                                ],
                              ),
                            ),

                            const SizedBox(height: 40),

                            // --- BACK TO HOME BUTTON (Themed) ---
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).popUntil((route) => route.isFirst);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kPrimaryColor, // EdTech Blue
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    elevation: 2,
                                    shadowColor: kPrimaryColor.withOpacity(0.4),
                                  ),
                                  child: const Text(
                                    "Back to Home",
                                    style: TextStyle(
                                      fontSize: 16, 
                                      fontWeight: FontWeight.w700, 
                                      color: Colors.white
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: kTextSecondary, fontSize: 14, fontWeight: FontWeight.w500)),
        const SizedBox(width: 20),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: kTextPrimary,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontSize: isBold ? 18 : 14,
            ),
          ),
        ),
      ],
    );
  }
}

// --- CUSTOM PAINTER (Unchanged) ---
class CheckMarkPainter extends CustomPainter {
  final double progress;

  CheckMarkPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Path path = Path();
    final Offset p1 = Offset(size.width * 0.2, size.height * 0.5);
    final Offset p2 = Offset(size.width * 0.45, size.height * 0.75);
    final Offset p3 = Offset(size.width * 0.8, size.height * 0.25);

    if (progress > 0) {
      path.moveTo(p1.dx, p1.dy);
      if (progress <= 0.35) {
        final double t = progress / 0.35;
        path.lineTo(p1.dx + (p2.dx - p1.dx) * t, p1.dy + (p2.dy - p1.dy) * t);
      } else {
        path.lineTo(p2.dx, p2.dy);
        final double t = (progress - 0.35) / 0.65;
        path.lineTo(p2.dx + (p3.dx - p2.dx) * t, p2.dy + (p3.dy - p2.dy) * t);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CheckMarkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}