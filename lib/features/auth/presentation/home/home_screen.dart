import 'package:flutter/material.dart';
import 'package:medical_simplified/core/storage/token_storage.dart';
import 'package:medical_simplified/features/auth/presentation/home/widgets/banner_carousel.dart';
import 'package:medical_simplified/features/auth/presentation/home/widgets/feature_grid.dart';
import '../profile/contact_us/contact_us_screen.dart';
import '../notifications/notification_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.authRepository});
  final dynamic authRepository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = 'User';
  String _message = '';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final storage = TokenStorage();
    final user = await storage.readUser();
    if (mounted) {
      setState(() {
        _userName = user?['firstName'] ?? 'User';
      });
    }
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search courses, subjects, notes...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  void _openHelpSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            children: [
              const Center(
                child: Text(
                  'Need Help?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.phone, color: Colors.green),
                title: const Text('Call Us'),
                onTap: () {
                  Navigator.pop(ctx);
                  ContactUsScreen.launchPhone(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.email_outlined, color: Colors.blue),
                title: const Text('Email Us'),
                onTap: () {
                  Navigator.pop(ctx);
                  ContactUsScreen.launchEmail(context);
                },
              ),
              ListTile(
                leading:
                    const Icon(FontAwesomeIcons.whatsapp, color: Colors.teal),
                title: const Text('Chat on WhatsApp'),
                onTap: () {
                  Navigator.pop(ctx);
                  ContactUsScreen.launchWhatsApp(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openNotifications(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // ONE base surface
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Text(
            '👋 Hi, $_userName',
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () => _openNotifications(context),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _openHelpSheet(context),
          ),
          const SizedBox(width: 8),
        ],
      ),

      /// 🏠 BODY
      body: SingleChildScrollView(
        child: Column(
          children: [
            /// 🔵 Top gradient section
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF3F6FF),
                    Color(0xFFF5F7FA),
                  ],
                ),
              ),
              child: Column(
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: const BannerCarousel(),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            /// 🔷 Feature section surface (CRITICAL FIX)
            Container(
              width: double.infinity,
              color: const Color(0xFFF7F9FC),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                child: Column(
                  children: [
                    const FeatureGrid(),
                    const SizedBox(height: 32),

                    const Text(
                      'Empowering Future Doctors,\nOne Concept at a Time.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Made in India with ❤️',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    if (_message.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        _message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
