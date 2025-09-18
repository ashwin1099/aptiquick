// lib/screens/login_screen.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/gestures.dart';
import 'home_screen.dart'; // For navigation after login/signup

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _buttonOpacity;
  final List<Bubble> _bubbles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _createBubbles(3);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _buttonOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );
    _controller.forward();
  }

  void _createBubbles(int count) {
    for (int i = 0; i < count; i++) {
      _bubbles.add(Bubble(
        size: _random.nextDouble() * 15 + 5,
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        opacity: _random.nextDouble() * 0.15 + 0.1,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFF6A5AE0),
      body: Stack(
        children: [
          // Floating bubbles background
          for (var bubble in _bubbles)
            Positioned(
              left: bubble.x * size.width,
              top: bubble.y * size.height,
              child: Container(
                width: bubble.size,
                height: bubble.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(bubble.opacity),
                ),
              ),
            ),

          // Main content
          Center(
            child: Padding(
              padding: EdgeInsets.all(isDesktop ? 60.0 : 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF7C6EF6), Color(0xFF5A4BD6)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          )
                        ],
                      ),
                      child: const Icon(Icons.school, size: 56, color: Colors.white),
                    ),
                  ),
                  SizedBox(height: isDesktop ? 40 : 30),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Text(
                      "Apti Quick",
                      style: TextStyle(
                        fontSize: isDesktop ? 48 : 38,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  SizedBox(height: isDesktop ? 15 : 12),
                  FadeTransition(
                    opacity: Tween(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _controller,
                        curve: const Interval(0.4, 1.0),
                      ),
                    ),
                    child: ConstrainedBox(
                      constraints:
                      BoxConstraints(maxWidth: isDesktop ? 600 : 350),
                      child: Text(
                        "Master aptitude tests with hundreds of practice questions and detailed solutions.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isDesktop ? 18 : 15,
                          color: Colors.white.withOpacity(0.95),
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  FadeTransition(
                    opacity: _buttonOpacity,
                    child: ScaleTransition(
                      scale: Tween(begin: 0.9, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _controller,
                          curve: const Interval(0.5, 1.0, curve: Curves.easeOutBack),
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) => const LoginScreen(),
                              transitionDuration:
                              const Duration(milliseconds: 300),
                              transitionsBuilder: (_, animation, __, child) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: child,
                                );
                              },
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF6A5AE0),
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 50 : 40,
                            vertical: isDesktop ? 18 : 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 5,
                          shadowColor: Colors.black.withOpacity(0.2),
                        ),
                        child: Text(
                          "Get Started",
                          style: TextStyle(
                            fontSize: isDesktop ? 20 : 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Bubble {
  double size;
  double x;
  double y;
  double opacity;

  Bubble({
    required this.size,
    required this.x,
    required this.y,
    required this.opacity,
  });
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _hallTicketController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _collegeController = TextEditingController();

  bool _collegeEditedManually = false;
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _isLogin = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _hallTicketController.addListener(_onHallTicketChanged);
    // ✅ FIX: The incorrect listener on _collegeController has been removed.
    // The logic is now handled by the `onChanged` property in the TextFormField.
  }

  void _onHallTicketChanged() {
    if (_collegeEditedManually) return; // Don't override manual input

    final hallTicket = _hallTicketController.text.toUpperCase();
    if (hallTicket.length >= 4) {
      final prefix = hallTicket.substring(2, 4);
      String collegeName = '';

      switch (prefix) {
        case '7W':
          collegeName = 'SMIC';
          break;
        case 'BH':
          collegeName = 'SMEC';
          break;
        case 'D0':
          collegeName = 'SMGIOH';
          break;
        default:
          collegeName = 'NONE';
      }

      // No need to check for the flag here, as the check at the top handles it.
      _collegeController.text = collegeName;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _hallTicketController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _collegeController.dispose();
    super.dispose();
  }

  Future<bool> hasInternetConnection() async {
    final results = await Connectivity().checkConnectivity();
    return !results.contains(ConnectivityResult.none);
  }

  Future<void> handleAuth() async {
    setState(() => _loading = true);

    try {
      if (!await hasInternetConnection()) {
        _showSnackBar("No internet connection");
        setState(() {
          _error = "No internet connection";
          _loading = false;
        });
        return;
      }

      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        UserCredential userCredential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        final user = userCredential.user;
        if (user != null) {
          await FirebaseFirestore.instance.collection('students').doc(user.uid).set({
            'fullName': _fullNameController.text.trim(),
            'hallTicket': _hallTicketController.text.trim().toUpperCase(),
            'email': _emailController.text.trim(),
            'college': _collegeController.text.trim(),
            'phone': _phoneController.text.trim().isEmpty
                ? 'N/A'
                : _phoneController.text.trim(),
            'numberTestAttempted': 0,
            'createdAt': FieldValue.serverTimestamp(),
            'uid': user.uid,
          }, SetOptions(merge: true));
        }
      }
      // Common navigation logic after success
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      _showSnackBar(e.message ?? "Authentication failed");
      setState(() => _error = e.message);
    } catch (e) {
      _showSnackBar("Unexpected error: $e");
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showSnackBar("Enter a valid email to reset password");
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showSnackBar("Password reset link sent to $email");
    } catch (e) {
      _showSnackBar("Failed to send reset email");
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await handleAuth();
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF6A5AE0),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final cardWidth = isDesktop ? 500.0 : double.infinity;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F5FD),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: cardWidth),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0EEFF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.school,
                          size: 42,
                          color: const Color(0xFF6A5AE0),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _isLogin ? "Welcome Back" : "Create Account",
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D1D2B),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isLogin
                            ? "Login to continue"
                            : "Sign up to get started",
                        style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 20),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            if (!_isLogin) ...[
                              _buildTextField(
                                _fullNameController,
                                "Full Name",
                                validator: (value) =>
                                value!.isEmpty ? "Required" : null,
                                icon: Icons.person_outline,
                              ),
                              const SizedBox(height: 14),
                              _buildTextField(
                                _hallTicketController,
                                "Hall Ticket Number",
                                validator: (value) =>
                                value!.isEmpty ? "Required" : null,
                                icon: Icons.badge_outlined,
                              ),
                              const SizedBox(height: 14),
                              // ✅ FIX: Added the missing College text field.
                              _buildTextField(
                                _collegeController,
                                "College",
                                icon: Icons.school_outlined,
                                // ✅ FIX: Use onChanged to detect manual edits.
                                onChanged: (value) {
                                  if (value.isNotEmpty) {
                                    _collegeEditedManually = true;
                                  }
                                },
                              ),
                              const SizedBox(height: 14),
                              _buildTextField(
                                _phoneController,
                                "Phone Number (optional)",
                                keyboardType: TextInputType.phone,
                                icon: Icons.phone_outlined,
                              ),
                              const SizedBox(height: 14),
                            ],
                            _buildTextField(
                              _emailController,
                              "Email",
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) =>
                              value!.contains('@') ? null : "Invalid email",
                              icon: Icons.email_outlined,
                            ),
                            const SizedBox(height: 14),
                            _buildTextField(
                              _passwordController,
                              "Password",
                              obscureText: true,
                              validator: (value) => value!.length >= 6
                                  ? null
                                  : "Min 6 characters",
                              icon: Icons.lock_outline,
                            ),
                            const SizedBox(height: 8),
                            if (_isLogin)
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _loading ? null : _resetPassword,
                                  child: const Text(
                                    "Forgot Password?",
                                    style: TextStyle(
                                        color: Color(0xFF6A5AE0),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0F1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Color(0xFFFF5C6C), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: const TextStyle(
                                      color: Color(0xFFFF5C6C), fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6A5AE0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: _loading
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : Text(
                            _isLogin ? "Sign In" : "Sign Up",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isLogin
                                ? "Don't have an account? "
                                : "Already have an account? ",
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 14),
                          ),
                          GestureDetector(
                            onTap: _loading ? null : _toggleAuthMode,
                            child: Text(
                              _isLogin ? "Sign Up" : "Login",
                              style: const TextStyle(
                                  color: Color(0xFF6A5AE0),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ FIX: Added the new `onChanged` parameter to the function signature.
  Widget _buildTextField(
      TextEditingController controller,
      String label, {
        TextInputType? keyboardType,
        bool obscureText = false,
        String? Function(String?)? validator,
        IconData? icon,
        void Function(String)? onChanged,
      }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      enabled: !_loading,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[700], fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF6F5FD),
        contentPadding:
        const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6A5AE0), width: 1.5),
        ),
        prefixIcon: icon != null
            ? Icon(icon, color: const Color(0xFF6A5AE0), size: 22)
            : null,
      ),
      validator: validator,
      onChanged: onChanged, // ✅ FIX: Applied the onChanged callback here.
      style: const TextStyle(fontSize: 14),
    );
  }
}