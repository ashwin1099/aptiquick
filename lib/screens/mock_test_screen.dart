import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // ✅ Added import

class MockTestScreen extends StatefulWidget {
  const MockTestScreen({super.key});

  @override
  State<MockTestScreen> createState() => _MockTestScreenState();
}

class _MockTestScreenState extends State<MockTestScreen>
    with TickerProviderStateMixin {
  String searchQuery = "";
  Map<String, Map<String, dynamic>> completedTests = {};
  final userId = FirebaseAuth.instance.currentUser?.uid ?? "demoUser";
  bool _isLoading = true;

  late AnimationController _animationController;
  final Map<String, Animation<double>> _cardAnimations = {};
  final Map<String, Animation<Color?>> _colorAnimations = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loadCompletedTestsFromFirestore();
  }

  @override
  void dispose() {
    _animationController.stop();
    _animationController.dispose();
    super.dispose();
  }

  void _setupCardAnimation(String testId) {
    if (_cardAnimations.containsKey(testId)) return;

    final delay = (_cardAnimations.length * 100).toDouble();

    _cardAnimations[testId] = CurvedAnimation(
      parent: _animationController,
      curve: Interval(
        delay / 1000,
        1.0,
        curve: Curves.easeOut,
      ),
    );

    _colorAnimations[testId] = ColorTween(
      begin: Colors.transparent,
      end: Theme.of(context).primaryColor.withOpacity(0.05),
    ).animate(_animationController);

    if (!_animationController.isAnimating &&
        _animationController.status != AnimationStatus.completed) {
      _animationController.forward();
    }
  }

  Future<void> _loadCompletedTestsFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('mock_test_results')
          .where('userId', isEqualTo: userId)
          .get();

      final Map<String, Map<String, dynamic>> loaded = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final testId = data['testId'] as String?;
        if (testId != null) {
          loaded[testId] = data;
        }
      }

      if (!mounted) return;

      setState(() {
        completedTests = loaded;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading tests: ${e.toString()}')),
      );
    }
  }

  void _onTestTap(Map<String, dynamic> testData, String testId) {
    final bool isCompleted = completedTests.containsKey(testId);
    final bool showResults = testData['showResults'] ?? true;
    final bool isActive = testData['active'] ?? true;

    if (!isActive && !isCompleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("This test is currently not available."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (isCompleted) {
      final selectedAnswers =
          (completedTests[testId]?['answers'] as List<dynamic>?)
              ?.map<int?>((e) => e == null ? null : (e as int))
              .toList() ??
              [];

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TestResultScreen(
            testData: testData,
            selectedOptions: selectedAnswers,
            showAnswers: showResults,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TestInstructionsScreen(
            testData: testData,
            testId: testId,
            onTestCompleted: (answers) async {
              final questions = testData['questions'] as List<dynamic>;
              int score = 0;

              for (int i = 0; i < questions.length; i++) {
                final correctIndex = questions[i]['correctIndex'] as int?;
                if (correctIndex != null && answers[i] == correctIndex) {
                  score++;
                }
              }

              final total = questions.length;
              final percentage = ((score / total) * 100).toStringAsFixed(2);
              final docId = '${userId}_$testId';

              try {
                await FirebaseFirestore.instance
                    .collection('mock_test_results')
                    .doc(docId)
                    .set({
                  'userId': userId,
                  'testId': testId,
                  'answers': answers,
                  'score': score,
                  'total': total,
                  'percentage': percentage,
                  'timestamp': FieldValue.serverTimestamp(),
                }, SetOptions(merge: false));

                await _loadCompletedTestsFromFirestore();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error saving results: ${e.toString()}'),
                  ),
                );
              }
            },
          ),
        ),
      );
    }
  }

  Widget _buildTestCard(
      Map<String, dynamic> data,
      String testId,
      bool isCompleted,
      ) {
    _setupCardAnimation(testId);
    final theme = Theme.of(context);
    final animation = _cardAnimations[testId]!;
    final colorAnimation = _colorAnimations[testId]!;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - animation.value) * 20),
          child: Opacity(
            opacity: animation.value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.15),
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: isCompleted ? theme.cardColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: () => _onTestTap(data, testId),
            borderRadius: BorderRadius.circular(20),
            child: AnimatedBuilder(
              animation: colorAnimation,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: isCompleted ? null : colorAnimation.value,
                  ),
                  child: child,
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? theme.colorScheme.secondary.withOpacity(0.1)
                            : theme.primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        isCompleted
                            ? Icons.assignment_turned_in
                            : Icons.assignment,
                        color: isCompleted
                            ? theme.colorScheme.secondary
                            : theme.primaryColor,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['title'] ?? 'Untitled Test',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (isCompleted) ...[
                            _buildScoreRow(theme, completedTests[testId]!),
                          ] else ...[
                            Text(
                              data['description'] ?? 'No description available',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.textTheme.bodyMedium?.color
                                    ?.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildTestDetails(theme, data),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildActionButton(theme, isCompleted),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreRow(ThemeData theme, Map<String, dynamic> testResult) {
    final score = testResult['score'];
    final total = testResult['total'];
    final percentage = testResult['percentage'];
    final timestamp = testResult['timestamp'] as Timestamp?;
    final formattedDate = timestamp != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate())
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.score, size: 16, color: theme.hintColor),
            const SizedBox(width: 6),
            Text(
              "$score/$total",
              style:
              theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 16),
            Icon(Icons.trending_up, size: 16, color: theme.hintColor),
            const SizedBox(width: 6),
            Text(
              "$percentage%",
              style:
              theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: theme.hintColor),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                formattedDate ?? '',
                style: theme.textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTestDetails(ThemeData theme, Map<String, dynamic> data) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer, size: 16, color: theme.hintColor),
            const SizedBox(width: 4),
            Text(
              "${data['duration']} minutes",
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.question_answer, size: 16, color: theme.hintColor),
            const SizedBox(width: 4),
            Text(
              "${(data['questions'] as List).length} Questions",
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(ThemeData theme, bool isCompleted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isCompleted
            ? theme.colorScheme.secondary.withOpacity(0.1)
            : theme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted
              ? theme.colorScheme.secondary.withOpacity(0.3)
              : theme.primaryColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Text(
        isCompleted ? "REVIEW" : "START",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 0.5,
          color: isCompleted ? theme.colorScheme.secondary : theme.primaryColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final testsCollection = FirebaseFirestore.instance.collection('mock_tests');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mock Tests"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search tests...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
              ),
              onChanged: (val) =>
                  setState(() => searchQuery = val.trim().toLowerCase()),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
        stream: testsCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/no_tests.svg',
                    height: 150,
                    semanticsLabel: 'No tests available',
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "No tests available",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  const Text("Check back later for new tests"),
                ],
              ),
            );
          }

          final filteredDocs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final title = (data['title'] ?? '').toString().toLowerCase();
            return title.contains(searchQuery);
          }).toList();

          if (filteredDocs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/no_results.svg',
                    height: 150,
                    semanticsLabel: 'No matching tests',
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "No tests match your search",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  const Text("Try a different search term"),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 16, bottom: 24),
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) {
              final doc = filteredDocs[index];
              final data = doc.data() as Map<String, dynamic>;
              final testId = doc.id;
              final isCompleted = completedTests.containsKey(testId);
              return _buildTestCard(data, testId, isCompleted);
            },
          );
        },
      ),
    );
  }
}

class TestInstructionsScreen extends StatelessWidget {
  final Map<String, dynamic> testData;
  final String testId;
  final Function(List<int?>) onTestCompleted;

  const TestInstructionsScreen({
    super.key,
    required this.testData,
    required this.testId,
    required this.onTestCompleted,
  });

  Future<bool> _hasAlreadySubmitted(String uid, String testId) async {
    try {
      final docId = '${uid}_$testId';
      final doc = await FirebaseFirestore.instance
          .collection('mock_test_results')
          .doc(docId)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _isOngoingTest(String testId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('submissionPending_$testId') ?? false;
  }

  void _startTest(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login to take tests")),
      );
      return;
    }

    final bool isActive = testData['active'] ?? true;
    final bool isOngoing = await _isOngoingTest(testId);

    if (!isActive && !isOngoing) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("This test is currently not active."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final alreadySubmitted = await _hasAlreadySubmitted(user.uid, testId);

    if (alreadySubmitted) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You have already attempted this test"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TestTakingScreen(
          testData: testData,
          testId: testId,
          onSubmit: onTestCompleted,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final questions = testData['questions'] as List<dynamic>;
    final totalQuestions = questions.length;
    final duration = testData['duration'] ?? 30;

    return Scaffold(
      appBar: AppBar(title: const Text("Test Instructions")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  testData['title'] ?? 'Mock Test',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 30),
            _buildInfoCard(
              icon: Icons.timer_outlined,
              title: "Time Limit",
              value: "$duration minutes",
              context: context,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              icon: Icons.question_answer_outlined,
              title: "Total Questions",
              value: "$totalQuestions questions",
              context: context,
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              icon: Icons.grade_outlined,
              title: "Passing Score",
              value: "70% required",
              context: context,
            ),
            const SizedBox(height: 30),
            Text(
              "Test Guidelines:",
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInstructionItem(
                "1. Ensure stable internet connection.", context),
            _buildInstructionItem(
                "2. Do not switch tabs or applications.", context),
            _buildInstructionItem(
                "3. Test will auto-submit when the timer ends.", context),
            _buildInstructionItem(
                "4. You can review answers before final submission.", context),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _startTest(context),
                icon: const Icon(Icons.play_arrow),
                label: const Text("START TEST"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
      {required IconData icon,
        required String title,
        required String value,
        required BuildContext context}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Theme.of(context).hintColor)),
              const SizedBox(height: 4),
              Text(value,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String text, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Icon(Icons.circle,
                size: 8, color: Theme.of(context).hintColor),
          ),
          const SizedBox(width: 12),
          Expanded(
              child:
              Text(text, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

// ✅ THIS IS THE FULLY CORRECTED WIDGET

class TestTakingScreen extends StatefulWidget {
  final Map<String, dynamic> testData;
  final String testId;
  final Function(List<int?>) onSubmit;

  const TestTakingScreen({
    super.key,
    required this.testData,
    required this.testId,
    required this.onSubmit,
  });

  @override
  State<TestTakingScreen> createState() => _TestTakingScreenState();
}

class _TestTakingScreenState extends State<TestTakingScreen>
    with WidgetsBindingObserver {
  // Loading State
  bool _isLoading = true;

  // Test State
  int currentIndex = 0;
  late List<int?> selectedOptions;
  Timer? _timer;
  int remainingSeconds = 0;

  // UI State
  bool isSubmitting = false; // For showing a loading indicator during an attempt
  bool _showConfirmDialog = false;
  bool _isSubmissionPending = false; // Locks the UI for pending submission

  // Anti-cheating variables
  int _focusLossCount = 0;
  bool _isAppInBackground = false;
  final int _maxFocusLossAllowed = 5;

  // Randomized questions state
  final List<Map<String, dynamic>> _randomizedQuestions = [];
  final List<List<String>> _randomizedOptions = [];
  late List<int> _questionOrder;
  late List<List<int>> _optionOrders;

  // Connectivity Listener
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadStateAndInitialize();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _connectivitySubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Checks for a pending submission first, otherwise initializes the test.
  Future<void> _loadStateAndInitialize() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('submissionPending_${widget.testId}') ?? false) {
      if (mounted) {
        setState(() {
          _isSubmissionPending = true;
          _isLoading = false; // Not loading if we're on the submission screen
        });
        _listenForConnectivityAndRetry();
        _attemptSubmission(); // Try submitting immediately on load
      }
    } else {
      await _initializeTest(); // Await the full test initialization
      if (mounted) {
        setState(() {
          _isLoading = false; // Turn off loading state once done
        });
      }
    }
  }

  /// Initializes a new test session.
  Future<void> _initializeTest() async {
    _focusLossCount = 0;
    _isAppInBackground = false;
    _randomizedQuestions.clear();
    _randomizedOptions.clear();

    _initializeRandomizedTest();

    remainingSeconds = (widget.testData['duration'] ?? 10) * 60;

    await _loadProgress(); // Await progress before starting the timer

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds <= 0) {
        timer.cancel();
        _initiateSubmissionProcess(isForced: true);
      } else {
        if (!_isAppInBackground) {
          if (mounted) setState(() => remainingSeconds--);
          if (remainingSeconds % 10 == 0) _saveProgress();
        }
      }
    });
  }

  void _initializeRandomizedTest() {
    final questions = widget.testData['questions'] as List<dynamic>? ?? [];
    _questionOrder = List<int>.generate(questions.length, (i) => i)..shuffle();
    selectedOptions = List<int?>.filled(questions.length, null);
    _optionOrders = [];

    for (int i = 0; i < questions.length; i++) {
      final originalQuestion =
      questions[_questionOrder[i]] as Map<String, dynamic>;
      _randomizedQuestions.add(Map<String, dynamic>.from(originalQuestion));

      final options =
      (originalQuestion['options'] as List<dynamic>).cast<String>();
      final optionOrder = List<int>.generate(options.length, (i) => i)..shuffle();
      _optionOrders.add(optionOrder);
      _randomizedOptions
          .add(optionOrder.map((index) => options[index]).toList());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final isBackground = state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden;

    if (isBackground && !_isAppInBackground) {
      _isAppInBackground = true;
      _focusLossCount++;
      _saveProgress();
      if (mounted) setState(() {});

      if (_focusLossCount >= _maxFocusLossAllowed) {
        _initiateSubmissionProcess(isForced: true);
      }
    } else if (state == AppLifecycleState.resumed && _isAppInBackground) {
      _isAppInBackground = false;
      if (mounted) setState(() {});
    }
  }

  /// Initiates the submission process by saving state and flagging for submission.
  Future<void> _initiateSubmissionProcess({bool isForced = false}) async {
    if (isSubmitting || _isSubmissionPending) return;

    if (mounted) {
      setState(() {
        isSubmitting = true;
        _showConfirmDialog = false;
      });
    }
    _timer?.cancel();

    // 1. Calculate final answers in their original order
    final List<int?> originalSelections =
    List<int?>.filled(_questionOrder.length, null);
    for (int i = 0; i < selectedOptions.length; i++) {
      if (selectedOptions[i] != null) {
        final originalQuestionIndex = _questionOrder[i];
        final originalOptionIndex =
        _getOriginalOptionIndex(i, selectedOptions[i]!);
        originalSelections[originalQuestionIndex] = originalOptionIndex;
      }
    }

    // 2. Persist submission data and flag
    final prefs = await SharedPreferences.getInstance();
    final submissionData = jsonEncode({
      'selectedOptions': originalSelections,
      'testData': widget.testData,
    });
    await prefs.setString(
        'pendingSubmissionData_${widget.testId}', submissionData);
    await prefs.setBool('submissionPending_${widget.testId}', true);

    // 3. Update UI to the pending state and start retrying
    if (mounted) {
      setState(() {
        _isSubmissionPending = true;
        isSubmitting = false;
      });
      _listenForConnectivityAndRetry();
      _attemptSubmission();
    }
  }

  /// Listens for connectivity changes to trigger a submission attempt.
  void _listenForConnectivityAndRetry() {
    _connectivitySubscription?.cancel(); // Cancel any existing listener
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((_) {
          _attemptSubmission();
        });
  }

  /// Attempts to submit the test if there is an internet connection.
  Future<void> _attemptSubmission() async {
    if (isSubmitting) return; // Prevent concurrent attempts

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      print("Submission attempt skipped: No internet connection.");
      return;
    }

    if (mounted) setState(() => isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final dataString =
      prefs.getString('pendingSubmissionData_${widget.testId}');
      if (dataString == null) {
        // Safeguard: if data is missing, exit pending state.
        if (mounted) setState(() => _isSubmissionPending = false);
        return;
      }

      final submissionData = jsonDecode(dataString);
      final originalSelections = (submissionData['selectedOptions'] as List)
          .map<int?>((e) => e)
          .toList();
      final testDataForResults = submissionData['testData'] as Map<String, dynamic>;
      final bool showResults = testDataForResults['showResults'] ?? true;


      // Perform the actual submission
      await widget.onSubmit(originalSelections);

      // Update student stats in Firestore
      try {
        final userId = FirebaseAuth.instance.currentUser!.uid;
        await FirebaseFirestore.instance.collection('students').doc(userId).set({
          'numberTestAttempted': FieldValue.increment(1),
          'lastTestAttempt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        print('Could not update student test attempt count: $e');
      }

      // ** SUCCESS! **
      await _clearPendingSubmission();
      await _clearProgress(); // Also clear the regular progress saves

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TestResultScreen(
            testData: testDataForResults,
            selectedOptions: originalSelections,
            showAnswers: showResults,
          ),
        ),
      );
    } catch (e) {
      print("Submission attempt failed: $e. Will retry later.");
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final testId = widget.testId;
    if (mounted) {
      final savedOptions = prefs.getStringList('selectedOptions_$testId');
      setState(() {
        if (savedOptions != null && savedOptions.length == selectedOptions.length) {
          selectedOptions = savedOptions
              .map((e) => e == 'null' ? null : int.tryParse(e))
              .toList();
        }
        remainingSeconds = prefs.getInt('remainingSeconds_$testId') ?? remainingSeconds;
        _focusLossCount = prefs.getInt('focusLossCount_$testId') ?? 0;
      });
    }
  }

  Future<void> _saveProgress() async {
    if (_isSubmissionPending) return;
    final prefs = await SharedPreferences.getInstance();
    final testId = widget.testId;
    await prefs.setStringList('selectedOptions_$testId', selectedOptions.map((e) => e?.toString() ?? 'null').toList());
    await prefs.setInt('remainingSeconds_$testId', remainingSeconds);
    await prefs.setInt('focusLossCount_$testId', _focusLossCount);
  }

  Future<void> _clearProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final testId = widget.testId;
    await prefs.remove('selectedOptions_$testId');
    await prefs.remove('remainingSeconds_$testId');
    await prefs.remove('focusLossCount_$testId');
  }

  Future<void> _clearPendingSubmission() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('submissionPending_${widget.testId}');
    await prefs.remove('pendingSubmissionData_${widget.testId}');
    _connectivitySubscription?.cancel();
  }

  int _getOriginalOptionIndex(int questionIndex, int randomizedOptionIndex) =>
      _optionOrders[questionIndex][randomizedOptionIndex];
  void nextQuestion() =>
      setState(() {
        if (currentIndex < selectedOptions.length - 1) currentIndex++;
      });
  void previousQuestion() =>
      setState(() {
        if (currentIndex > 0) currentIndex--;
      });
  String formatTime(int seconds) =>
      "${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}";
  double get progressValue => selectedOptions.isEmpty
      ? 0.0
      : selectedOptions.where((opt) => opt != null).length /
      selectedOptions.length;

  @override
  Widget build(BuildContext context) {
    if (_isSubmissionPending) {
      return _buildSubmittingScreen();
    }

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final theme = Theme.of(context);
    return WillPopScope(
      onWillPop: () async {
        _showExitConfirmationDialog(context);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Question ${currentIndex + 1}/${_randomizedQuestions.length}"),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                  value: progressValue,
                  backgroundColor: theme.dividerColor.withOpacity(0.5),
                  minHeight: 4),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: remainingSeconds < 60
                    ? theme.colorScheme.errorContainer
                    : theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer,
                      color: remainingSeconds < 60
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(formatTime(remainingSeconds),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: remainingSeconds < 60
                              ? theme.colorScheme.error
                              : theme.colorScheme.primary)),
                ],
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  if (_focusLossCount > 0 && !_isAppInBackground)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      color: _focusLossCount >= _maxFocusLossAllowed
                          ? Colors.red.shade700
                          : Colors.amber.shade700,
                      child: Row(children: [
                        const Icon(Icons.warning, color: Colors.white),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(
                                _focusLossCount >= _maxFocusLossAllowed
                                    ? "Max focus losses reached. Test will submit."
                                    : "Warning: $_focusLossCount/$_maxFocusLossAllowed focus losses detected.",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold))),
                      ]),
                    ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                    color: theme.shadowColor.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5))
                              ],
                            ),
                            child: Text(
                                _randomizedQuestions[currentIndex]['question'] ??
                                    'No question text',
                                style: const TextStyle(
                                    fontSize: 16, height: 1.5)),
                          ),
                          const SizedBox(height: 30),
                          ...List.generate(
                            _randomizedOptions[currentIndex].length,
                                (i) => Container(
                              margin: const EdgeInsets.only(bottom: 15),
                              decoration: BoxDecoration(
                                color: selectedOptions[currentIndex] == i
                                    ? theme.primaryColor.withOpacity(0.1)
                                    : theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                    color: selectedOptions[currentIndex] == i
                                        ? theme.primaryColor
                                        : theme.dividerColor,
                                    width: 1.5),
                              ),
                              child: RadioListTile<int>(
                                value: i,
                                groupValue: selectedOptions[currentIndex],
                                title:
                                Text(_randomizedOptions[currentIndex][i]),
                                onChanged: (val) {
                                  setState(() => selectedOptions[currentIndex] = val);
                                  _saveProgress();
                                },
                                activeColor: theme.primaryColor,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        border: Border(
                            top: BorderSide(
                                color: theme.dividerColor, width: 1))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (currentIndex > 0)
                          OutlinedButton.icon(
                              onPressed: previousQuestion,
                              icon: const Icon(Icons.arrow_back),
                              label: const Text("Previous"),
                              style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 14)))
                        else
                          const SizedBox(width: 100),
                        ElevatedButton.icon(
                          onPressed: currentIndex == selectedOptions.length - 1
                              ? () => setState(() => _showConfirmDialog = true)
                              : nextQuestion,
                          icon: Icon(currentIndex == selectedOptions.length - 1
                              ? Icons.flag
                              : Icons.arrow_forward),
                          label: Text(currentIndex == selectedOptions.length - 1
                              ? "Submit"
                              : "Next"),
                          style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 14)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_isAppInBackground) ...[
              BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                  child: Container(color: Colors.black.withOpacity(0.1))),
              Container(
                color: Colors.black54,
                alignment: Alignment.center,
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.visibility_off, size: 50, color: Colors.white),
                  const SizedBox(height: 20),
                  const Text("App Not in Focus",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 10),
                  Text("Focus losses: $_focusLossCount/$_maxFocusLossAllowed",
                      style: const TextStyle(fontSize: 16, color: Colors.white)),
                ]),
              ),
            ],
            if (_showConfirmDialog)
              _buildConfirmationDialog(context, theme, _randomizedQuestions.length),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmittingScreen() {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSubmitting)
                const CircularProgressIndicator()
              else
                Icon(Icons.cloud_upload_outlined,
                    size: 60, color: theme.primaryColor),
              const SizedBox(height: 24),
              Text(
                isSubmitting ? "Submitting..." : "Submission Pending",
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "Your test is saved and will be submitted automatically once an internet connection is available. You can safely close this screen.",
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.hintColor),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExitConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Exit Test?"),
          content: const Text(
              "Are you sure you want to exit? Your progress will be saved."),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Cancel")),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text("Exit"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildConfirmationDialog(
      BuildContext context, ThemeData theme, int totalQuestions) {
    final answered = selectedOptions.where((opt) => opt != null).length;
    final unanswered = totalQuestions - answered;
    return Container(
      color: Colors.black54,
      alignment: Alignment.center,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Submit Test?", style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              Text("Please review your attempt:",
                  style: theme.textTheme.bodyMedium),
              const SizedBox(height: 20),
              _buildDialogStat("Total Questions", totalQuestions.toString()),
              _buildDialogStat("Answered", answered.toString()),
              _buildDialogStat("Unanswered", unanswered.toString()),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: () => setState(() => _showConfirmDialog = false),
                      child: const Text("REVIEW")),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _initiateSubmissionProcess(),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary),
                    child: const Text("SUBMIT NOW"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("$label:",
              style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}



class TestResultScreen extends StatelessWidget {
  final Map<String, dynamic> testData;
  final List<int?> selectedOptions;

  const TestResultScreen({
    super.key,
    required this.testData,
    required this.selectedOptions, required bool showAnswers,
  });

  /// Read showAnswers directly from testData
  bool get showAnswers => testData['showAnswers'] as bool? ?? false;

  int calculateScore() {
    final questions = testData['questions'] as List<dynamic>? ?? [];
    int score = 0;
    for (int i = 0; i < questions.length; i++) {
      final correctAnswer = questions[i]['correctIndex'] as int?;
      if (correctAnswer != null && selectedOptions[i] == correctAnswer) {
        score++;
      }
    }
    return score;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final questions = testData['questions'] as List<dynamic>? ?? [];
    final total = questions.length;
    final score = calculateScore();
    final percentage = (total > 0) ? (score / total * 100) : 0;
    final isPassed = percentage >= 70;

    return Scaffold(
      appBar: AppBar(title: const Text("Test Results"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Score card container
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text("Your Score",
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 180,
                        height: 180,
                        child: CircularProgressIndicator(
                          value: total > 0 ? (score / total) : 0,
                          strokeWidth: 12,
                          backgroundColor: theme.dividerColor,
                          color: isPassed ? Colors.green : Colors.orange,
                        ),
                      ),
                      Column(
                        children: [
                          Text("$score/$total",
                              style: theme.textTheme.displaySmall
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          Text("${percentage.toStringAsFixed(1)}%",
                              style: theme.textTheme.headlineSmall
                                  ?.copyWith(color: theme.hintColor)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: isPassed
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      isPassed ? "Congratulations!" : "Keep Practicing",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isPassed ? Colors.green : Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // Correct / Incorrect score cards
            Row(
              children: [
                Expanded(
                    child: _buildScoreCard(
                        title: "Correct",
                        value: score,
                        color: Colors.green,
                        icon: Icons.check_circle_outline)),
                const SizedBox(width: 16),
                Expanded(
                    child: _buildScoreCard(
                        title: "Incorrect",
                        value: total - score,
                        color: Colors.red,
                        icon: Icons.highlight_off)),
              ],
            ),
            const SizedBox(height: 30),
            // Question review section
            Align(
              alignment: Alignment.centerLeft,
              child: Text("Question Review:",
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: total,
              itemBuilder: (context, index) {
                final question = questions[index] as Map<String, dynamic>;
                final correctIndex = question['correctIndex'] as int;
                final options =
                (question['options'] as List<dynamic>).cast<String>();
                final userAnswerIndex = selectedOptions[index];
                final isCorrect = userAnswerIndex == correctIndex;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                        color: isCorrect
                            ? Colors.green.withOpacity(0.5)
                            : Colors.red.withOpacity(0.5),
                        width: 1.5),
                  ),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: isCorrect
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      child: Text("${index + 1}",
                          style: TextStyle(
                              color: isCorrect ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold)),
                    ),
                    title: Text(question['question'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(isCorrect ? "Correct" : "Incorrect",
                        style: TextStyle(
                            color: isCorrect ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(height: 20),
                            Text(
                                "Your Answer: ${userAnswerIndex != null ? options[userAnswerIndex] : 'Not answered'}",
                                style: TextStyle(
                                    color:
                                    isCorrect ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            if (showAnswers)
                              Text("Correct Answer: ${options[correctIndex]}",
                                  style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
            // Back button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15))),
                child: const Text("BACK TO TEST LIST",
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard({
    required String title,
    required int value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3))),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              Text(value.toString(),
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ],
      ),
    );
  }
}
