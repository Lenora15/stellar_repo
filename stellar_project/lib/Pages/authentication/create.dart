import 'dart:ui';
import 'package:flutter/material.dart';
import 'firebase_auth.dart';


class CreateAccount extends StatefulWidget {
  const CreateAccount({super.key});

  @override
  State<CreateAccount> createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  final AuthService _authService = AuthService();
  
  // text editing controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  //storing the user's birthday. initially null
  DateTime? _selectedDate;

  //opening calendar dialog
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() { _selectedDate = picked; });
    }
  }

  //preventing repeating styling code
  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Colors.black), 
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.black54),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black45),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.6),
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

//building the UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                const SizedBox(height: 50),

                //Main title
                const Text(
                  "Stellar",
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 30),

                //contains blur
                ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      padding: const EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            "Create an Account",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),

                          //uses helper function to build input fields
                          _buildTextField(_firstNameController, 'First Name', Icons.person_outline),
                          _buildTextField(_lastNameController, 'Last Name', Icons.person_outline),
                          _buildTextField(_usernameController, 'Choose a username', Icons.account_circle_outlined),
                          _buildTextField(_emailController, 'Email', Icons.email_outlined),
                          _buildTextField(_passwordController, 'Password', Icons.lock_outline, obscure: true),
                          _buildTextField(_phoneController, 'Phone Number', Icons.phone_outlined),
                          
                          const SizedBox(height: 8),

                          //trigger date picker
                          GestureDetector(
                            onTap: () => _selectDate(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_outlined, color: Colors.black54),
                                  const SizedBox(width: 12),
                                  Text(

                                    //date display --> needs fixed. doesnt display selected date
                                    _selectedDate == null 
                                      ? 'Select Birthdate' 
                                      : 'DOB: ${_selectedDate!.toLocal()}'.split(' ')[0],
                                    style: const TextStyle(color: Colors.black87, fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),
                          
                          //sign up
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromARGB(255, 39, 45, 57),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 55),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              elevation: 0,
                            ),
                            onPressed: () async {

                                //makes sure email and password fields arent empty
                                if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Email and Password are required.')),
                                  );
                                  return;
                                }

                                //makes sure date is selected
                                if (_selectedDate == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please select your birthdate.')),
                                  );
                                  return;
                                }

                                //send data to auth service
                                String? result = await _authService.registration(
                                  email: _emailController.text.trim(),
                                  password: _passwordController.text.trim(),
                                  username: _usernameController.text.trim(),
                                  firstName: _firstNameController.text.trim(),
                                  lastName: _lastNameController.text.trim(),
                                  phone: _phoneController.text.trim(),
                                  birthDate: _selectedDate!,
                                );

                                //safety check
                                if (!mounted) return;

                                //results from auth
                                if (result == 'Success') {
                                  final currentContext = context;
                                  Navigator.pop(currentContext);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Account created successfully!')),
                                  );
                                } else{
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(result ?? 'An unknown error occurred.')),
                                  );
                                }
                            },
                            child: const Text('Sign Up', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 25),
                
                //link back to Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? ", style: TextStyle(color: Colors.black)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        "Log In",
                        style: TextStyle(
                          color: Colors.black, 
                          fontWeight: FontWeight.bold, 
                          decoration: TextDecoration.underline, 
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}