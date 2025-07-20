// ignore_for_file: use_build_context_synchronously, deprecated_member_use, duplicate_ignore
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';
import 'mock_test_screen.dart';
import 'practice_questions_screen.dart';
import 'events_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? studentData;
  bool isLoading = true;
  String? errorMessage;

  bool get isDarkMode => themeNotifier.value == ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    _fetchStudentData();
  }

  Future<void> _fetchStudentData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          errorMessage = "User not logged in";
          isLoading = false;
        });
        return;
      }
      final querySnapshot = await _firestore
          .collection('students')
          .where('uid', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          studentData = querySnapshot.docs.first.data();
          isLoading = false;
          errorMessage = null; // Clear any previous errors
        });
      } else {
        setState(() {
          errorMessage = "Student data not found! Please Login Again!";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error fetching data: $e";
        isLoading = false;
      });
    }
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _toggleDarkMode(bool value) {
    themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CareerTrack',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              tooltip: 'Menu',
              color: Colors.white,
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              const ListTile(
                title: Text(
                  'Settings',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('Dark Mode'),
                value: isDarkMode,
                onChanged: _toggleDarkMode,
                secondary: const Icon(Icons.dark_mode),
              ),
              const Spacer(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.of(context).pop();
                  _logout(context);
                },
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Text(
                    errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 16,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchStudentData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(), // Enable pull to refresh even if content is small
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UserProfileCard(
                          fullName: studentData?['fullName'] ?? "User",
                          hallTicket: studentData?['hallTicket'] ?? "N/A",
                          college: studentData?['college'] ?? "N/A",
                          year: studentData?['year'] ?? "N/A",
                        ),
                        GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _HomeOptionTile(
                              icon: Icons.assignment,
                              label: 'Mock Test',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const MockTestScreen()),
                                );
                              },
                            ),
                            _HomeOptionTile(
                              icon: Icons.lightbulb_outline,
                              label: 'Practice Questions',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>  PracticeQuestionsScreen()),
                                );
                              },
                            ),
                            _HomeOptionTile(
                              icon: Icons.event,
                              label: 'Events',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const EventsScreen()),
                                );
                              },
                            ),
                           
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _HomeOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HomeOptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge!.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UserProfileCard extends StatelessWidget {
  final String fullName;
  final String hallTicket;
  final String college;
  final String year;

  const UserProfileCard({
    super.key,
    required this.fullName,
    required this.hallTicket,
    required this.college,
    required this.year,
    
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onBackground;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome,',
              style: TextStyle(
                fontSize: 16,
                color: textColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              fullName,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            InfoRow(icon: Icons.confirmation_num, label: 'Hall Ticket', value: hallTicket),
            const SizedBox(height: 16),
            InfoRow(icon: Icons.school, label: 'College', value: college),
            const SizedBox(height: 16),
            InfoRow(icon: Icons.calendar_today, label: 'Year', value: year),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.onBackground;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: primaryColor),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: textColor),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

