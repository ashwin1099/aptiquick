import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _hallTicketController = TextEditingController();
  final _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    if (_user != null) {
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    try {
      final doc = await _firestore.collection('students').doc(_user!.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _nameController.text = data['fullName'] ?? '';
          _emailController.text = data['email'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _hallTicketController.text = data['hallTicket'] ?? '';
        });
      }
    } catch (e) {
      // Error handling remains the same
    }
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      if (_user == null) {
        _showSnackBar('User not logged in');
        setState(() => _isSubmitting = false);
        return;
      }

      final uid = _user.uid;

      await _firestore
          .collection('students')
          .doc(uid)
          .collection('feedback')
          .add({
        'fullName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'hallTicket': _hallTicketController.text.trim(),
        'feedback': _feedbackController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      final emailUri = Uri(
        scheme: 'mailto',
        path: 'ashtemp84@gmail.com',
        queryParameters: {
          'subject': 'App Feedback & Suggestions from ${_nameController.text.trim()}',
          'body': '''
User UID: $uid
Name: ${_nameController.text.trim()}
Email: ${_emailController.text.trim()}
Phone: ${_phoneController.text.trim()}
Hall Ticket: ${_hallTicketController.text.trim()}

Feedback/Suggestions:
${_feedbackController.text.trim()}
'''
        },
      );

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      }

      _showSnackBar('Feedback submitted successfully!');
      _feedbackController.clear();

    } catch (e) {
      _showSnackBar('Failed to submit feedback: ${e.toString()}');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _hallTicketController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label, IconData icon, [String? helper]) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey[600]),
      prefixIcon: Icon(icon, color: Colors.blue),
      helperText: helper,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blueGrey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blue, width: 1.5),
      ),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback & Suggestions'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Share Your Thoughts',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We value your feedback to improve our services',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 30),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: _inputDecoration('Full Name', Icons.person_outline),
                          validator: (v) => v!.isEmpty ? 'Please enter your name' : null,
                          enabled: !_isSubmitting,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _emailController,
                          decoration: _inputDecoration('Email Address', Icons.email_outlined),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v!.isEmpty) return 'Please enter your email';
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                          enabled: !_isSubmitting,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _phoneController,
                          decoration: _inputDecoration('Phone Number (Optional)', Icons.phone_outlined),
                          keyboardType: TextInputType.phone,
                          enabled: !_isSubmitting,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _hallTicketController,
                          decoration: _inputDecoration('Hall Ticket Number (Optional)', Icons.badge_outlined),
                          enabled: !_isSubmitting,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _feedbackController,
                          decoration: _inputDecoration(
                            'Your Feedback & Suggestions',
                            Icons.feedback_outlined,
                            'Please share your experience and suggestions',
                          ),
                          maxLines: 5,
                          validator: (v) => v!.isEmpty ? 'Please provide feedback' : null,
                          enabled: !_isSubmitting,
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitFeedback,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Submit Feedback',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'Your feedback will be reviewed by our support team',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}