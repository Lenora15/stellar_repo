import 'package:flutter/material.dart';
import 'authentication/firebaseAuth.dart'; // Required for authentication

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService _authService = AuthService();

    return ListView(
      children: [
        GestureDetector(
          onTap: () async {
            // For testing: This triggers the Firebase reset email.
            await _authService.resetPassword(email: 'llr50@pitt.edu');
            
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Test Reset Email Sent!')),
            );
          },
          child: Container(
            height: 100,
            color: Colors.blue.withValues(alpha: 0.3), // Different color to distinguish it
            child: const Center(
              child: Text(
                'TEST: Change Password (Send Email)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        Container(
          height: 100,
          color: Colors.white.withValues(alpha: 0.3),
          child: const Center(child: Text('some text')),
        ),
        const SizedBox(height: 10),
        Container(
          height: 100,
          color: Colors.white.withValues(alpha: 0.3),
          child: const Center(child: Text('some text')),
        ),
        const SizedBox(height: 10),
        Container(
          height: 100,
          color: Colors.white.withValues(alpha: 0.3),
          child: const Center(child: Text('some text')),
        ),
        const SizedBox(height: 10),
        Container(
          height: 100,
          color: Colors.white.withValues(alpha: 0.3),
          child: const Center(child: Text('some text')),
        ),
      ],
    );
  }
}