import 'package:flutter/material.dart';

// --- THEME CONSTANTS ---
const Color kErrorColor = Color(0xFFDC2626); // Professional Red (Red-600)
const Color kPrimaryColor = Color(0xFF2563EB); // Royal Blue
const Color kTextPrimary = Color(0xFF1E293B);
const Color kTextSecondary = Color(0xFF64748B);

class PaymentFailedScreen extends StatefulWidget {
  const PaymentFailedScreen({super.key});

  @override
  State<PaymentFailedScreen> createState() => _PaymentFailedScreenState();
}

class _PaymentFailedScreenState extends State<PaymentFailedScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _crossAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

    // 1. Scale Circle Background (Elastic pop)
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.elasticOut),
      ),
    );

    // 2. Cross (X) Animation Progress
    _crossAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.7, curve: Curves.easeOutBack),
      ),
    );

    // 3. Fade in Content
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background: Subtle Red/Warm Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Colors.red.shade50.withOpacity(0.5)],
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
                    // --- ANIMATED FAILURE ICON ---
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer Ripple (Red)
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red.shade100),
                          ),
                        ),
                        // Main Circle (Red)
                        ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: kErrorColor,
                              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
                            ),
                            // Custom Cross (X) Painter
                            child: Center(
                              child: SizedBox(
                                width: 40,
                                height: 40,
                                child: AnimatedBuilder(
                                  animation: _crossAnimation,
                                  builder: (context, child) {
                                    return CustomPaint(painter: CrossMarkPainter(progress: _crossAnimation.value));
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
                              "Payment Failed",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: kTextPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                "Something went wrong with your transaction. Please try again or contact support.",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 16, color: kTextSecondary, height: 1.4),
                              ),
                            ),

                            const SizedBox(height: 40),

                            // --- ACTION BUTTONS ---
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Logic to Retry Payment (Pop back to payment options)
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        kErrorColor, // Red for "Retry" in error state is common, or stick to Brand Blue
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    elevation: 2,
                                    shadowColor: kErrorColor.withOpacity(0.4),
                                  ),
                                  child: const Text(
                                    "Try Again",
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            TextButton(
                              onPressed: () {
                                // Logic to Close / Go Home
                                Navigator.of(context).popUntil((route) => route.isFirst);
                              },
                              child: const Text(
                                "Cancel",
                                style: TextStyle(color: kTextSecondary, fontWeight: FontWeight.w600, fontSize: 16),
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
}

// --- CUSTOM PAINTER FOR ANIMATED CROSS (X) ---
class CrossMarkPainter extends CustomPainter {
  final double progress;

  CrossMarkPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Path path = Path();

    // Define the two lines of the 'X'
    // Line 1: Top-Left to Bottom-Right
    final Offset p1Start = Offset(size.width * 0.2, size.height * 0.2);
    final Offset p1End = Offset(size.width * 0.8, size.height * 0.8);

    // Line 2: Top-Right to Bottom-Left
    final Offset p2Start = Offset(size.width * 0.8, size.height * 0.2);
    final Offset p2End = Offset(size.width * 0.2, size.height * 0.8);

    // Animation Logic
    // 0.0 -> 0.5: Draw Line 1
    // 0.5 -> 1.0: Draw Line 2

    if (progress > 0) {
      // Draw first line partially or fully
      double t1 = (progress > 0.5 ? 0.5 : progress) / 0.5;
      path.moveTo(p1Start.dx, p1Start.dy);
      path.lineTo(p1Start.dx + (p1End.dx - p1Start.dx) * t1, p1Start.dy + (p1End.dy - p1Start.dy) * t1);

      // Draw second line if progress > 0.5
      if (progress > 0.5) {
        double t2 = (progress - 0.5) / 0.5;
        path.moveTo(p2Start.dx, p2Start.dy);
        path.lineTo(p2Start.dx + (p2End.dx - p2Start.dx) * t2, p2Start.dy + (p2End.dy - p2Start.dy) * t2);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CrossMarkPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
