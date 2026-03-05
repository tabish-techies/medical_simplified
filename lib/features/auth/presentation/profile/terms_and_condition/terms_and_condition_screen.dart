import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  static const String companyName = "Medical Simplified";
  static const String website = "www.medicalsimplified.com";
  static const String supportEmail = "support@medicalsimplified.com";
  static const String governingCountry = "India";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Terms & Conditions"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _Title("Terms & Conditions"),

            _Paragraph(
              "These Terms and Conditions govern your access to and use of the "
              "Medical Simplified mobile application, website, and all related "
              "services, content, and products. These terms constitute a legally "
              "binding agreement between you and Medical Simplified.",
            ),

            _Heading("1. Acceptance of Terms"),
            _Paragraph(
              "By accessing, browsing, registering, purchasing, or using any "
              "portion of the platform, you acknowledge that you have read, "
              "understood, and agreed to be bound by these Terms and Conditions, "
              "whether or not you have read them in full.",
            ),

            _Heading("2. Nature of Services"),
            _Paragraph(
              "Medical Simplified provides digital educational services, including "
              "but not limited to video lectures, recorded sessions, PDFs, notes, "
              "mock tests, and other academic resources. All services are provided "
              "electronically and are deemed delivered once access is granted.",
            ),

            _Heading("3. Eligibility & User Responsibility"),
            _Paragraph(
              "You confirm that you are at least 18 years of age or are accessing "
              "the platform under the supervision of a legal guardian. You agree "
              "to provide accurate, current, and complete information during "
              "registration and to maintain the confidentiality of your account.",
            ),

            _Heading("4. No Refund, No Cancellation Policy"),
            _Paragraph(
              "ALL PURCHASES MADE ON THE PLATFORM ARE FINAL AND NON-REFUNDABLE.\n\n"
              "Once a course, subscription, or digital content is purchased and "
              "access is provided, no refunds, cancellations, chargebacks, or "
              "reversals shall be permitted under any circumstances whatsoever. "
              "This applies regardless of:\n\n"
              "• Change of personal preference or expectations\n"
              "• Partial or non-completion of the course\n"
              "• Technical issues on the user's device or network\n"
              "• Pricing changes or promotional offers\n"
              "• Dissatisfaction with content or teaching methodology\n\n"
              "You expressly waive any right to dispute or claim a refund.",
            ),

            _Heading("5. Course Access & Availability"),
            _Paragraph(
              "Access to purchased courses is provided on a limited, non-transferable, "
              "and revocable basis. The platform does not guarantee perpetual or "
              "lifetime access unless explicitly stated at the time of purchase. "
              "Medical Simplified reserves the right to modify, suspend, or remove "
              "any content without prior notice.",
            ),

            _Heading("6. Intellectual Property Rights"),
            _Paragraph(
              "All content available on the platform, including videos, text, "
              "graphics, logos, audio, software, and study materials, are the "
              "exclusive intellectual property of Medical Simplified and are "
              "protected under applicable copyright and intellectual property laws.\n\n"
              "Any unauthorized reproduction, distribution, recording, sharing, "
              "resale, or public display of content is strictly prohibited and may "
              "result in immediate termination of access and legal proceedings.",
            ),

            _Heading("7. Prohibited Activities"),
            _Paragraph(
              "Users shall not:\n\n"
              "• Share account credentials with others\n"
              "• Attempt to download, record, or redistribute course content\n"
              "• Circumvent platform security features\n"
              "• Use the platform for unlawful or commercial purposes\n"
              "• Engage in abusive or disruptive behavior\n",
            ),

            _Heading("8. Account Suspension & Termination"),
            _Paragraph(
              "Medical Simplified reserves the sole right to suspend or permanently "
              "terminate user accounts found in violation of these Terms without "
              "prior notice and without any refund or compensation.",
            ),

            _Heading("9. Limitation of Liability"),
            _Paragraph(
              "Under no circumstances shall Medical Simplified be liable for any "
              "direct, indirect, incidental, special, or consequential damages "
              "arising out of or related to your use or inability to use the platform, "
              "including but not limited to loss of data, revenue, or academic results.",
            ),

            _Heading("10. Disclaimer of Warranties"),
            _Paragraph(
              "All services are provided on an 'as-is' and 'as-available' basis "
              "without warranties of any kind, either express or implied. "
              "Medical Simplified does not guarantee accuracy, completeness, "
              "or outcomes from the use of its content.",
            ),

            _Heading("11. Third-Party Services"),
            _Paragraph(
              "The platform may integrate or link to third-party services. "
              "Medical Simplified shall not be responsible for the content, "
              "policies, or practices of any third-party platforms.",
            ),

            _Heading("12. Governing Law & Jurisdiction"),
            _Paragraph(
              "These Terms shall be governed and interpreted in accordance with "
              "the laws of India. Any disputes shall be subject to the exclusive "
              "jurisdiction of courts located in India.",
            ),

            _Heading("13. Changes to Terms"),
            _Paragraph(
              "Medical Simplified reserves the right to update or modify these "
              "Terms and Conditions at any time without prior notice. Continued "
              "use of the platform constitutes acceptance of the revised terms.",
            ),

            _Heading("14. Contact Information"),
            _Paragraph(
              "For any queries or concerns related to these Terms and Conditions, "
              "please contact us at:\n\nsupport@medicalsimplified.com",
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
