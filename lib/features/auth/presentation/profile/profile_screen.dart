import 'package:flutter/material.dart';
import 'package:medical_simplified/features/auth/presentation/profile/privacy_policy/privacy_policy_screen.dart';
import 'package:medical_simplified/features/auth/presentation/profile/terms_and_condition/terms_and_condition_screen.dart';
import '../../../auth/data/auth_repository.dart';
import '../login/login_screen.dart';
import 'my_account/my_account_screen.dart';
import 'contact_us/contact_us_screen.dart';
import 'package:medical_simplified/core/storage/token_storage.dart';
import 'package:package_info_plus/package_info_plus.dart'; // ✅ ADD
import 'downloads/downloads_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final storage = TokenStorage();
    final user = await storage.readUser();
    setState(() {
      _user = user;
      _isLoading = false;
    });
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(ctx);
                _logout(context);
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await widget.authRepository.logoutFromServer();
    } catch (_) {
      await widget.authRepository.logout();
    }

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen(authRepository: widget.authRepository)),
      (route) => false,
    );

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logged out successfully')));
  }

  void _showComingSoon(BuildContext context, String title) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$title – Coming Soon!')));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = _user ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.3,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 🔹 Profile Header
          Column(
            children: [
              const CircleAvatar(
                radius: 45,
                backgroundColor: Color(0xFFE8F0FE),
                child: Icon(Icons.person, size: 55, color: Colors.blueAccent),
              ),
              const SizedBox(height: 12),
              Text(
                '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim().isEmpty
                    ? 'User'
                    : '${user['firstName']} ${user['lastName']}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              Text(
                user['email'] ?? 'No email available',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(),

          // 🔹 Menu Options
          _buildMenuItem(
            icon: Icons.person_outline,
            title: 'My Account',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MyAccountScreen(authRepository: widget.authRepository)),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.download_outlined,
            title: 'Downloads',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DownloadsScreen()));
            },
          ),
          // _buildMenuItem(icon: Icons.download_outlined, title: 'My Transactions'),
          _buildMenuItem(
            icon: Icons.article_outlined,
            title: 'Terms & Conditions',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsAndConditionsScreen()));
            },
          ),
          _buildMenuItem(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Policy',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()));
            },
          ),
          _buildMenuItem(
            icon: Icons.contact_support_outlined,
            title: 'Contact Us',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactUsScreen()));
            },
          ),
          // _buildMenuItem(
          //   icon: Icons.star_rate_outlined,
          //   title: 'Rate Us',
          //   onTap: () => _showComingSoon(context, 'Rate Us'),
          // ),
          _buildMenuItem(
            icon: Icons.card_giftcard_outlined,
            title: 'Refer & Earn',
            onTap: () => _showComingSoon(context, 'Refer & Earn'),
          ),

          const Divider(height: 32),

          // 🔹 Logout option
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.logout, color: Colors.red),
            ),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
            onTap: () => _showLogoutDialog(context),
          ),

          const SizedBox(height: 24),
          // 🔹 App Version Display
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    'Version ${snapshot.data!.version} (${snapshot.data!.buildNumber})',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  // 🔹 Reusable styled menu item
  Widget _buildMenuItem({required IconData icon, required String title, VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: Colors.blueAccent),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}
