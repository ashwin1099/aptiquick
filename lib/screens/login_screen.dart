import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _hallTicketController = TextEditingController();
  final _collegeController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _yearController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _isLogin = true;
  String? _error;


  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _hallTicketController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<bool> hasInternetConnection() async {
    final result = await Connectivity().checkConnectivity();
    return result.contains(ConnectivityResult.mobile) ||
        result.contains(ConnectivityResult.wifi) ||
        result.contains(ConnectivityResult.ethernet);
  }



  Future<void> handleAuth() async {
    setState(() => _loading = true);

    try {
      if (!await hasInternetConnection()) {
        _showSnackBar("No internet connection.");
        setState(() {
          _error = "No internet connection.";
          _loading = false;
        });
        return;
      }

      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        _showSnackBar("Login successful!");
      } else {
        UserCredential userCredential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        final user = userCredential.user;
        if (user != null) {
          await user.updateDisplayName(_fullNameController.text.trim());

          final studentData = {
            'fullName': _fullNameController.text.trim(),
            'hallTicket': _hallTicketController.text.trim().toUpperCase(),
            'email': _emailController.text.trim(),
            'college': _collegeController.text.trim(),
            'phone': _phoneController.text.trim(),
            'year': _yearController.text.trim(),
            'numberTestAttempted': 0,
            'createdAt': FieldValue.serverTimestamp(),
            'uid': user.uid,
          };

          await FirebaseFirestore.instance
              .collection('students')
              .doc(user.uid)
              .set(studentData);

          _showSnackBar("Account created successfully!");
        }
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'network-request-failed') {
        _showSnackBar("Network error. Please check your internet.");
      } else {
        _showSnackBar(e.message ?? "Authentication failed.");
      }
      setState(() => _error = e.message);
    } catch (e) {
      _showSnackBar("Unexpected error: $e");
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _showSnackBar("Enter a valid email to reset password.");
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showSnackBar("Password reset link sent to $email");
    } catch (e) {
      _showSnackBar("Failed to send reset email. Please try again.");
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await handleAuth();
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.deepPurple),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(color: Colors.grey[700]),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isLogin ? "Welcome Back" : "Create Account",
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin ? "Login to continue" : "Sign up to get started",
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (!_isLogin) ...[
                        TextFormField(
                          controller: _fullNameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: _inputDecoration("Full Name"),
                          validator: (value) =>
                          value != null && value.isNotEmpty ? null : "Full name is required",
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _hallTicketController,
                          decoration: _inputDecoration("Hall Ticket Number"),
                          validator: (value) =>
                          value != null && value.isNotEmpty ? null : "Hall ticket is required",
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _collegeController,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: _inputDecoration("College"),
                          validator: (value) =>
                          value != null && value.isNotEmpty ? null : "College name is required",
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: _inputDecoration("Phone Number"),
                          validator: (value) =>
                          value != null && value.isNotEmpty ? null : "Phone number is required",
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _yearController.text.isNotEmpty ? _yearController.text : null,
                          decoration: _inputDecoration("Year"),
                          items: const [
                            DropdownMenuItem(value: '1st', child: Text('1st Year')),
                            DropdownMenuItem(value: '2nd', child: Text('2nd Year')),
                            DropdownMenuItem(value: '3rd', child: Text('3rd Year')),
                            DropdownMenuItem(value: '4th', child: Text('4th Year')),
                          ],
                          onChanged: (value) => setState(() => _yearController.text = value!),
                          validator: (value) =>
                          value != null && value.isNotEmpty ? null : "Please select year",
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: _emailController,
                        decoration: _inputDecoration("Email"),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) =>
                        value != null && value.contains('@') ? null : "Enter a valid email",
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: _inputDecoration("Password"),
                        obscureText: true,
                        validator: (value) =>
                        value != null && value.length >= 6 ? null : "Minimum 6 characters",
                      ),
                      const SizedBox(height: 8),
                      if (_isLogin)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _loading ? null : _resetPassword,
                            child: Text(
                              "Forgot Password?",
                              style: GoogleFonts.poppins(
                                color: Colors.deepPurple,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                      _isLogin ? "Sign In" : "Sign Up",
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                      _error = null;
                      _emailController.clear();
                      _passwordController.clear();
                      _hallTicketController.clear();
                      _fullNameController.clear();
                      _phoneController.clear();
                      _yearController.clear();
                      _collegeController.clear();
                    });
                  },
                  child: Text(
                    _isLogin
                        ? "Don't have an account? Sign Up"
                        : "Already have an account? Login",
                    style: GoogleFonts.poppins(color: Colors.deepPurple),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
