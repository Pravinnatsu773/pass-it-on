import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFA),
      appBar: AppBar(
        title: const Text('About PassItOn', style: TextStyle(color: Color(0xFF1A1C1E), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1C1E)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0F4C3A),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.card_giftcard,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Pass It On',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F4C3A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pass It On is a community-driven platform designed to reduce waste and foster generosity. Our mission is to make it incredibly easy to give away items you no longer need to people in your local community who can use them.\n\n'
              'Instead of throwing things away, simply take a picture, add a quick description, and let the community join a raffle to pick it up. It\'s good for your home, good for your neighbors, and great for the environment.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF5A5A5A),
                height: 1.5,
              ),
            ),
            const Spacer(),
            const Text(
              'Made with ❤️ by the PassItOn Team',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1C1E),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
