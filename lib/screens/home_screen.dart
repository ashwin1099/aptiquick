// lib/screens/home_screen.dart

// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'login_screen.dart';
import '../main.dart';
import 'mock_test_screen.dart';
import 'practice_questions_screen.dart';
import 'feedback.dart';

// A custom scroll behavior to remove the scrollbar on web.
class NoScrollbarBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// ✅ FIX: Added WidgetsBindingObserver to manage app lifecycle for time tracking.
class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? studentData;
  bool isLoading = true;
  String? errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // ✅ FIX: Moved time tracking logic from QuickStatsCard to here.
  final String _prefsKey = 'totalTimeSpentSeconds';
  int totalTimeSpentSeconds = 0;
  DateTime? _sessionStartTime;
  Timer? _timer;

  bool get isDarkMode => themeNotifier.value == ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // For lifecycle state

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    // Load data immediately on init.
    _fetchStudentData();
    _loadTotalTimeSpent();
  }

  // ✅ FIX: Added App Lifecycle State handling.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _startSessionTimer();
    } else if (state == AppLifecycleState.paused) {
      _addSessionTimeAndSave();
      _stopSessionTimer();
    }
  }

  Future<void> _fetchStudentData() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw FirebaseAuthException(
            code: 'no-user',
            message: "User session expired. Please login again.");
      }

      final docRef = _firestore.collection('students').doc(user.uid);
      DocumentSnapshot doc;

      // Try fetching from the server first with a timeout.
      doc = await docRef
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 7));

      if (doc.exists) {
        _processDocumentData(doc);
      } else {
        // If not found on the server, try the cache as a fallback.
        try {
          doc = await docRef.get(const GetOptions(source: Source.cache));
          if (doc.exists) {
            _processDocumentData(doc);
          } else {
            throw FirebaseException(
                plugin: 'Firestore',
                code: 'not-found',
                message: "Student data not found! Please login again.");
          }
        } catch (_) {
          // If cache also fails, throw the original not-found error.
          throw FirebaseException(
              plugin: 'Firestore',
              code: 'not-found',
              message: "Student data not found! Please login again.");
        }
      }
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        errorMessage = "Slow network connection. Please try again.";
        isLoading = false;
      });
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = "Database error: ${e.message}";
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = "An unexpected error occurred: ${e.toString()}";
        isLoading = false;
      });
    }
  }

  void _processDocumentData(DocumentSnapshot doc) {
    if (!mounted) return;

    setState(() {
      studentData = doc.data() as Map<String, dynamic>?;
      isLoading = false;
      errorMessage = null;
    });

    _animationController.forward(from: 0.0);
  }

  // ✅ FIX: Added all time tracking functions here
  Future<void> _loadTotalTimeSpent() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      totalTimeSpentSeconds = prefs.getInt(_prefsKey) ?? 0;
    });
    _startSessionTimer();
  }

  Future<void> _addSessionTimeAndSave() async {
    if (_sessionStartTime != null) {
      final now = DateTime.now();
      final sessionSeconds = now.difference(_sessionStartTime!).inSeconds;
      if (sessionSeconds > 0) {
        totalTimeSpentSeconds += sessionSeconds;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_prefsKey, totalTimeSpentSeconds);
      }
    }
    _sessionStartTime = null; // Reset for the next session
  }

  void _startSessionTimer() {
    _sessionStartTime ??= DateTime.now();
    _timer?.cancel();
    // This timer just updates the UI every few seconds to show live time.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {}); // Just rebuild to update the timer display
      }
    });
  }

  void _stopSessionTimer() {
    _timer?.cancel();
    _timer = null;
  }
  // --- End of time tracking functions ---

  void _logout(BuildContext context) async {
    await _animationController.reverse();
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  void _toggleDarkMode(bool value) {
    themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  void dispose() {
    _animationController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _addSessionTimeAndSave(); // Save any remaining time before screen is disposed
    super.dispose();
  }

  Widget _buildContent(bool isDesktop) {
    // Calculate display time here
    int displaySeconds = totalTimeSpentSeconds;
    if (_sessionStartTime != null) {
      displaySeconds += DateTime.now().difference(_sessionStartTime!).inSeconds;
    }

    final content = RefreshIndicator(
      onRefresh: _fetchStudentData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EnhancedUserProfileCard(
              greeting: _getGreeting(),
              fullName: studentData?['fullName'] ?? "User",
              hallTicket: studentData?['hallTicket'] ?? "N/A",
              college: studentData?['college'] ?? "N/A",
              email: _auth.currentUser?.email ?? "N/A",
            ),
            const SizedBox(height: 24),
            // ✅ FIX: Pass data directly to the new stateless QuickStatsCard
            QuickStatsCard(
              testsTaken: studentData?['numberTestAttempted'] ?? 0,
              timeSpentInSeconds: displaySeconds,
            ),
            const SizedBox(height: 24),
            Text(
              'Main Features',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: isDesktop ? 4 : 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 0.85,
              children: [
                _AnimatedOptionTile(
                  index: 0,
                  icon: Icons.quiz_outlined,
                  label: 'Mock Tests',
                  subtitle: 'Practice exams',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MockTestScreen(),
                      ),
                    );
                  },
                ),
                _AnimatedOptionTile(
                  index: 1,
                  icon: Icons.psychology_outlined,
                  label: 'Practice',
                  subtitle: 'Q&A Sessions',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PracticeQuestionsScreen(),
                      ),
                    );
                  },
                ),
                _AnimatedOptionTile(
                  index: 2,
                  icon: Icons.feedback_outlined,
                  label: 'Feedback',
                  subtitle: 'Give your feedback & Suggestion',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const FeedbackScreen()),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return kIsWeb
        ? ScrollConfiguration(
      behavior: NoScrollbarBehavior(),
      child: content,
    )
        : content;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AptiQuick',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            color: Colors.white,
            onPressed: () async {
              final uri = Uri.parse('https://www.google.com');
              try {
                // Updated to use the modern, recommended way to launch URLs.
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: Could not open website.')),
                  );
                }
              }
            },
          ),
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
              UserAccountsDrawerHeader(
                accountName: Text(studentData?['fullName'] ?? 'User'),
                accountEmail: Text(studentData?['hallTicket'] ?? 'N/A'),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    (studentData?['fullName'] ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.deepPurple, Colors.purple],
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Help & Support'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => const FeedbackScreen()),
                  );
                },
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
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
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
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: isLoading
            ? const Center(key: ValueKey('loading'), child: LoadingPulseAnimation())
            : errorMessage != null
            ? Center(
          key: const ValueKey('error'),
          child: ErrorRetryCard(
            errorMessage: errorMessage!,
            onRetry: _fetchStudentData,
            onLogout: () => _logout(context),
          ),
        )
            : FadeTransition(
          key: const ValueKey('content'),
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: isDesktop
                ? Center(
              child: Container(
                constraints:
                const BoxConstraints(maxWidth: 1000),
                child: _buildContent(isDesktop),
              ),
            )
                : _buildContent(isDesktop),
          ),
        ),
      ),
    );
  }
}

// ✅ FIX: Converted QuickStatsCard to a more performant StatelessWidget.
// It no longer fetches its own data or runs a costly timer.
class QuickStatsCard extends StatelessWidget {
  final int testsTaken;
  final int timeSpentInSeconds;

  const QuickStatsCard({
    super.key,
    required this.testsTaken,
    required this.timeSpentInSeconds,
  });

  Widget _buildBadge() {
    String badgeLabel;
    Color badgeColor;
    IconData badgeIcon;

    if (testsTaken < 15) {
      badgeLabel = 'Newbie';
      badgeColor = Colors.grey;
      badgeIcon = Icons.star_border;
    } else if (testsTaken < 35) {
      badgeLabel = 'Intermediate';
      badgeColor = Colors.blue;
      badgeIcon = Icons.star_half;
    } else if (testsTaken < 50) {
      badgeLabel = 'Pro';
      badgeColor = Colors.orange;
      badgeIcon = Icons.star;
    } else {
      badgeLabel = 'Master';
      badgeColor = Colors.purple;
      badgeIcon = Icons.emoji_events;
    }

    return _StatItem(
      icon: badgeIcon,
      label: 'Badge',
      value: badgeLabel,
      color: badgeColor,
    );
  }

  String _formatDuration(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${duration.inHours}h ${twoDigitMinutes}m";
    } else if (duration.inMinutes > 0) {
      return "${duration.inMinutes}m ${twoDigitSeconds}s";
    } else {
      return "${duration.inSeconds}s";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
              icon: Icons.assessment_outlined,
              label: 'Tests Taken',
              value: testsTaken.toString(),
              color: Colors.blue,
            ),
            _buildBadge(),
            _StatItem(
              icon: Icons.timer_outlined,
              label: 'Time Spent',
              value: _formatDuration(timeSpentInSeconds),
              color: Colors.teal, // ✅ FIX: Using a static, performant color.
            ),
          ],
        ),
      ),
    );
  }
}
// --- All other widgets below this line remain the same ---


class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }
}

class EnhancedUserProfileCard extends StatefulWidget {
  final String greeting;
  final String fullName;
  final String hallTicket;
  final String college;
  final String email;

  const EnhancedUserProfileCard({
    super.key,
    required this.greeting,
    required this.fullName,
    required this.hallTicket,
    required this.college,
    required this.email,
  });

  @override
  State<EnhancedUserProfileCard> createState() =>
      _EnhancedUserProfileCardState();
}

class _EnhancedUserProfileCardState extends State<EnhancedUserProfileCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _animations = List.generate(4, (index) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(0.2 + index * 0.2, 1, curve: Curves.easeOut),
        ),
      );
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;

    return Card(
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      margin: const EdgeInsets.only(bottom: 24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade700,
              Colors.purple.shade600,
              Colors.deepPurple.shade800,
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: isDesktop ? 40 : 32,
            horizontal: isDesktop ? 40 : 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeTransition(
                          opacity: _animations[0],
                          child: Text(
                            widget.greeting,
                            style: TextStyle(
                              fontSize: isDesktop ? 20 : 16,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        FadeTransition(
                          opacity: _animations[0],
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(-0.5, 0),
                              end: Offset.zero,
                            ).animate(_animations[0]),
                            child: Text(
                              widget.fullName,
                              style: TextStyle(
                                fontSize: isDesktop ? 32 : 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: isDesktop ? 45 : 35,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(
                      widget.fullName.isNotEmpty
                          ? widget.fullName[0].toUpperCase()
                          : 'U',
                      style: TextStyle(
                        fontSize: isDesktop ? 36 : 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildAnimatedInfoRow(
                index: 1,
                icon: Icons.confirmation_num_outlined,
                label: 'Hall Ticket',
                value: widget.hallTicket,
                isDesktop: isDesktop,
              ),
              // ✅ This logic correctly hides the college if it's "NONE" or empty.
              if (widget.college != 'NONE' && widget.college.isNotEmpty)
                ...[
                  const SizedBox(height: 16),
                  _buildAnimatedInfoRow(
                    index: 2,
                    icon: Icons.school_outlined,
                    label: 'College',
                    value: widget.college,
                    isDesktop: isDesktop,
                  ),
                ],
              const SizedBox(height: 16),
              _buildAnimatedInfoRow(
                index: 3,
                icon: Icons.email_outlined,
                label: 'Email',
                value: widget.email,
                isDesktop: isDesktop,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedInfoRow({
    required int index,
    required IconData icon,
    required String label,
    required String value,
    required bool isDesktop,
  }) {
    return FadeTransition(
      opacity: _animations[index],
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.5, 0),
          end: Offset.zero,
        ).animate(_animations[index]),
        child: InfoRow(
          icon: icon,
          label: label,
          value: value,
          color: Colors.white,
          isDesktop: isDesktop,
        ),
      ),
    );
  }
}

class LoadingPulseAnimation extends StatefulWidget {
  const LoadingPulseAnimation({super.key});

  @override
  State<LoadingPulseAnimation> createState() => _LoadingPulseAnimationState();
}

class _LoadingPulseAnimationState extends State<LoadingPulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _colorAnimation = ColorTween(
      begin: Colors.deepPurple.shade300,
      end: Colors.deepPurple.shade700,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _colorAnimation.value,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.school, color: Colors.white, size: 40),
          ),
        );
      },
    );
  }
}

class ErrorRetryCard extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;
  final VoidCallback onLogout;

  const ErrorRetryCard({
    super.key,
    required this.errorMessage,
    required this.onRetry,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 50, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 20),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 25),
              if (!errorMessage.contains("not found"))
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Retry"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: onLogout,
                child: const Text(
                  "Logout",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDesktop;

  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: isDesktop ? 28 : 24),
        SizedBox(width: isDesktop ? 16 : 12),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: isDesktop ? 18 : 16,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: isDesktop ? 18 : 16,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _AnimatedOptionTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final int index;

  const _AnimatedOptionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    required this.index,
  });

  @override
  State<_AnimatedOptionTile> createState() => _AnimatedOptionTileState();
}

class _AnimatedOptionTileState extends State<_AnimatedOptionTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    // Start animation after a delay based on index
    Future.delayed(Duration(milliseconds: widget.index * 100), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final isDesktop = MediaQuery.of(context).size.width > 600;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.deepPurple.withOpacity(0.2),
          highlightColor: Colors.deepPurple.withOpacity(0.1),
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
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, size: isDesktop ? 36 : 32, color: color),
                const SizedBox(height: 8),
                Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: isDesktop ? 16 : 14,
                    color: Theme.of(context).textTheme.bodyLarge!.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isDesktop ? 12 : 10,
                    color: Theme.of(context).textTheme.bodySmall!.color,
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