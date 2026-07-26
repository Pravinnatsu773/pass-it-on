import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFA),
      appBar: AppBar(
        title: const Text('Privacy Policy', style: TextStyle(color: Color(0xFF1A1C1E), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1C1E)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: const [
          Text(
            'Privacy Policy for Pass It On',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F4C3A)),
          ),
          SizedBox(height: 16),
          Text(
            'Last updated: October 2023\n\n'
            'Welcome to Pass It On. We respect your privacy and want you to understand how we collect, use, and share data about you. This Privacy Policy covers our data collection practices and describes your rights to access, correct, or restrict our use of your personal data.\n\n'
            '1. What Data We Get\n'
            'We collect certain data from you directly, like information you enter yourself (such as your name and profile picture), data about your location to show relevant products, and your activity within the app.\n\n'
            '2. How We Get Data About You\n'
            'We use tools like Firebase to store your account details securely. When you sign in with Google, we receive basic profile information to create your account.\n\n'
            '3. What We Use Your Data For\n'
            'We use your data to provide our services, communicate with you, troubleshoot issues, secure against fraud and abuse, improve and update our app, and analyze how people use our features.\n\n'
            '4. Who We Share Your Data With\n'
            'We share certain data about you with other users (like your display name when you post an item) and with companies performing services for us (like Google Cloud/Firebase). We do not sell your personal data to third parties.\n\n'
            '5. Security\n'
            'We use appropriate security based on the type and sensitivity of data being stored. However, remember that no system can be 100% secure, so we cannot guarantee that communications between you and Pass It On, or any information provided to us, will be free from unauthorized access.\n\n'
            'If you have any questions about this Privacy Policy, please contact our support team.',
            style: TextStyle(fontSize: 16, color: Color(0xFF5A5A5A), height: 1.5),
          ),
        ],
      ),
    );
  }
}
