import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  static const String phoneNumber = '+917887559633';
  static const String email = 'medicalsimplified11@gmail.com';
  static const String whatsappNumber = '+917887559633';

  // ✅ Static helper methods used across app
  static Future<void> launchPhone(BuildContext context) async {
    final Uri uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone app not available')),
      );
    }
  }

  static Future<void> launchEmail(BuildContext context) async {
    final Uri uri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Support Request&body=Hi Medical Simplified Team,',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No email app found')),
      );
    }
  }

  static Future<void> launchWhatsApp(BuildContext context) async {
    final String message = Uri.encodeComponent('Hi Medical Simplified Team, I need help!');
    final String mobile = whatsappNumber.replaceAll('+', '');
    
    // 1. Try Native App Scheme
    final Uri appUri = Uri.parse('whatsapp://send?phone=$mobile&text=$message');
    
    // 2. Fallback Web URL
    final Uri webUri = Uri.parse('https://wa.me/$mobile?text=$message');

    try {
      if (await canLaunchUrl(appUri)) {
        await launchUrl(appUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch WhatsApp';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp not installed or could not launch')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Us'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Need Help?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Our support team is here to assist you 24/7.',
              style: TextStyle(color: Colors.grey, fontSize: 15),
            ),
            const SizedBox(height: 30),

            _buildContactTile(
              icon: Icons.phone_in_talk_rounded,
              title: 'Call Us',
              subtitle: phoneNumber,
              color: Colors.green,
              onTap: () => launchPhone(context),
            ),
            const SizedBox(height: 12),

            _buildContactTile(
              icon: Icons.email_outlined,
              title: 'Email Us',
              subtitle: email,
              color: Colors.blueAccent,
              onTap: () => launchEmail(context),
            ),
            const SizedBox(height: 12),

            _buildContactTile(
              icon: FontAwesomeIcons.whatsapp,
              title: 'Chat on WhatsApp',
              subtitle: whatsappNumber,
              color: Colors.teal,
              onTap: () => launchWhatsApp(context),
            ),

            const Spacer(),
            const Center(
              child: Text(
                'We usually respond within 2–4 hours.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withOpacity(0.05),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
