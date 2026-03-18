import 'dart:ui';
import 'package:flutter/material.dart';
import 'firebaseAuth.dart';
import 'create.dart';
import '../main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, 
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    // 1. Large Title
                    const Text(
                      'Stellar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 40),
                    // 2. Glassmorphism Container
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(25),
                          decoration: BoxDecoration(
                            // Kept your dark base but made it slightly more transparent
                            color: Colors.white.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
                          ),
                          child: Column(
                            children: [
                              _buildInput(_identifierController, 'Username or Email', Icons.person_outline),
                              const SizedBox(height: 15),
                              _buildInput(_passwordController, 'Password', Icons.lock_outline, obscure: true),
                              
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () async {
                                    if (_identifierController.text.isEmpty || !_identifierController.text.contains('@')) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Please enter a valid email to reset your password.')),
                                      );
                                      return;
                                    }
                                    try {
                                      await _authService.resetPassword(email: _identifierController.text.trim());
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Password reset email sent.')),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error: ${e.toString()}')),
                                      );
                                    }
                                  },
                                  child: const Text('Forgot password?',
                                    // Set to blue or white to keep it readable against the dark container
                                    style: TextStyle(color: Color.fromARGB(255, 39, 45, 57), fontSize: 13)),
                                ),
                              ),

                              const SizedBox(height: 10),

                              // 3. Main Login Button
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(255, 39, 45, 57),
                                  minimumSize: const Size(double.infinity, 55),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                ),
                                onPressed: () async {
                                  String? result = await _authService.hybridLogin(
                                    identifier: _identifierController.text.trim(),
                                    password: _passwordController.text,
                                  );
                                  if (!mounted) return;
                                  if (result == 'Success') {
                                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainScreen()));
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result ?? 'Error')));
                                  }
                                },
                                child: const Text('Log In', style: TextStyle(fontSize: 18, color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? ", style: TextStyle(color: Color.fromARGB(255, 39, 45, 57))),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateAccount())),
                          child: const Text("Sign Up", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        ),
                      ],
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

  Widget _buildInput(TextEditingController controller, String hint, IconData icon, {bool obscure = false}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      // 1. Text color set to Black
      style: const TextStyle(color: Colors.black), 
      decoration: InputDecoration(
        // 2. Icon (symbol) color set to Black/Dark Grey
        prefixIcon: Icon(icon, color: Colors.black54),
        hintText: hint,
        // 3. Hint color set to Black/Dark Grey
        hintStyle: const TextStyle(color: Colors.black38),
        filled: true,
        // 4. Fill color set to light white so the black text is visible
        fillColor: Colors.white.withValues(alpha: 0.7), 
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }
}