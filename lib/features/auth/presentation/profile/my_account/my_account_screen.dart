import 'package:flutter/material.dart';
import '../../../../../core/storage/token_storage.dart';
import '../../../data/auth_repository.dart';
import '../contact_us/contact_us_screen.dart'; // 👈 Make sure this exists

class MyAccountScreen extends StatefulWidget {
  const MyAccountScreen({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
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

  void _showEditPopup() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Profile Editing Restricted',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'To update your personal details, please contact our customer care team.',
          style: TextStyle(fontSize: 15, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ContactUsScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Contact Support'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return const Scaffold(
        body: Center(child: Text('No user data available')),
      );
    }

    final user = _user!;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Account',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.3,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
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
                  '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user['email'] ?? '',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // 🔹 Section Title
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Personal Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
              ),
            ),
            const SizedBox(height: 12),

            _buildInfoRow('Phone Number', user['phoneNumber']),
            _buildInfoRow('Gender', user['gender']),
            _buildInfoRow('Date of Birth', user['dob']),

            const SizedBox(height: 22),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Address Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
              ),
            ),
            const SizedBox(height: 12),

            _buildInfoRow('Address 1', user['address1']),
            _buildInfoRow('College Name', user['address2']),
            _buildInfoRow('City', user['city']),
            _buildInfoRow('State', user['state']),
            _buildInfoRow('Pincode', user['pincode']),

            const SizedBox(height: 35),

            // 🔹 Edit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showEditPopup,
                icon: const Icon(Icons.edit, color: Colors.white),
                label: const Text(
                  'Edit Profile',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String? value) {
    final labelStyle = const TextStyle(
      color: Colors.black87,
      fontWeight: FontWeight.w600,
      fontSize: 15,
    );

    final valueStyle = TextStyle(
      color: Colors.grey[700],
      fontSize: 15,
      fontWeight: FontWeight.w400,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: labelStyle),
          const SizedBox(height: 3),
          Text(value?.isNotEmpty == true ? value! : '—', style: valueStyle),
          const Divider(height: 20, thickness: 0.5),
        ],
      ),
    );
  }
}
