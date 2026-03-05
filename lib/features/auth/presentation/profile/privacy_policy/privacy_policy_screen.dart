import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const String companyName = "Medical Simplified";
  static const String website = "www.medicalsimplified.com";
  static const String supportEmail = "support@medicalsimplified.com";
  static const String governingCountry = "India";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Privacy Policy"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _Title("Privacy Policy"),

            _Paragraph(
              "This Privacy Policy describes how Medical Simplified collects, "
              "uses, stores, processes, and protects your personal information "
              "when you access or use our mobile application, website, and "
              "related digital services.",
            ),

            _Heading("1. Information We Collect"),
            _Paragraph(
              "We may collect personal and non-personal information including, "
              "but not limited to:\n\n"
              "• Full name\n"
              "• Mobile number\n"
              "• Email address\n"
              "• Login credentials\n"
              "• Payment and transaction details\n"
              "• Device identifiers and IP address\n"
              "• App usage data and analytics\n",
            ),

            _Heading("2. How We Use Your Information"),
            _Paragraph(
              "The information collected is used for purposes including:\n\n"
              "• Account creation and authentication\n"
              "• Course access and content delivery\n"
              "• Payment processing and invoicing\n"
              "• Customer support and communication\n"
              "• Improving platform performance and user experience\n"
              "• Legal compliance and fraud prevention\n",
            ),

            _Heading("3. Authentication & OTP Services"),
            _Paragraph(
              "We may use third-party authentication services such as OTP-based "
              "verification and identity confirmation providers. Your mobile "
              "number may be shared securely with such providers solely for "
              "authentication purposes.",
            ),

            _Heading("4. Payment Information"),
            _Paragraph(
              "Payments are processed through secure third-party payment gateways. "
              "Medical Simplified does not store or have direct access to your "
              "complete card, UPI, or banking details. Transaction references may "
              "be retained for legal and accounting purposes.",
            ),

            _Heading("5. Cookies & Tracking Technologies"),
            _Paragraph(
              "We may use cookies, analytics tools, and similar technologies to "
              "understand user behavior, improve services, and enhance security. "
              "These technologies do not personally identify you unless you "
              "voluntarily provide such information.",
            ),

            _Heading("6. Data Storage & Security"),
            _Paragraph(
              "We implement reasonable administrative, technical, and physical "
              "security measures to protect your personal data from unauthorized "
              "access, misuse, alteration, or disclosure. However, no system is "
              "completely secure, and absolute security cannot be guaranteed.",
            ),

            _Heading("7. Data Retention"),
            _Paragraph(
              "Your personal information is retained only for as long as necessary "
              "to fulfill the purposes outlined in this Privacy Policy or as "
              "required by applicable laws and regulations.",
            ),

            _Heading("8. Sharing of Information"),
            _Paragraph(
              "We do not sell, rent, or trade your personal data. Information may "
              "be shared only with:\n\n"
              "• Service providers assisting in app operations\n"
              "• Payment and authentication partners\n"
              "• Legal authorities when required by law\n",
            ),

            _Heading("9. Third-Party Services"),
            _Paragraph(
              "The platform may include integrations with third-party tools such "
              "as analytics services, cloud storage providers, and communication "
              "services. Medical Simplified is not responsible for the privacy "
              "practices of these third-party services.",
            ),

            _Heading("10. User Rights"),
            _Paragraph(
              "You may request access, correction, or deletion of your personal "
              "information, subject to applicable legal and operational limitations. "
              "Such requests may be submitted via the contact information below.",
            ),

            _Heading("11. Children’s Privacy"),
            _Paragraph(
              "Our services are not directed toward children under the age of 13. "
              "We do not knowingly collect personal information from minors without "
              "verifiable parental consent.",
            ),

            _Heading("12. Legal Compliance"),
            _Paragraph(
              "This Privacy Policy is designed to comply with applicable Indian "
              "laws, including data protection and information technology regulations.",
            ),

            _Heading("13. Changes to Privacy Policy"),
            _Paragraph(
              "Medical Simplified reserves the right to modify this Privacy Policy "
              "at any time. Continued use of the platform following changes "
              "constitutes acceptance of the updated policy.",
            ),

            _Heading("14. Contact Us"),
            _Paragraph(
              "If you have any questions, concerns, or requests regarding this "
              "Privacy Policy, please contact us at:\n\nsupport@medicalsimplified.com",
            ),

            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

/* ---------- UI Helpers ---------- */

class _Title extends StatelessWidget {
  final String text;
  const _Title(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  final String text;
  const _Heading(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _Paragraph extends StatelessWidget {
  final String text;
  const _Paragraph(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}
