// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';


class MockTestScreen extends StatefulWidget {
  const MockTestScreen({super.key});

  @override
  State<MockTestScreen> createState() => _MockTestScreenState();
}

class _MockTestScreenState extends State<MockTestScreen> {
  String searchQuery = "";
  Map<String, Map<String, dynamic>> completedTests = {}; // testId -> data

  final userId = FirebaseAuth.instance.currentUser?.uid ?? "demoUser";

  @override
  void initState() {
    super.initState();
    _loadCompletedTestsFromFirestore();
  }

  Future<void> _loadCompletedTestsFromFirestore() async {
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
    });
  }

  void _onTestTap(Map<String, dynamic> testData, String testId) {
    if (completedTests.containsKey(testId)) {
      final selectedAnswers = (completedTests[testId]?['answers'] as List<dynamic>?)
          ?.map<int?>((e) => e == null ? null : (e as int))
          .toList() ?? [];

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TestResultScreen(
            testData: testData,
            selectedOptions: selectedAnswers,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TestInstructionsScreen(
            testData: testData,
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
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final testsCollection = FirebaseFirestore.instance.collection('mock_tests');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mock Tests"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search tests...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (val) {
                setState(() {
                  searchQuery = val.trim().toLowerCase();
                });
              },
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: testsCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No tests available."));
          }

          final filteredDocs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final title = (data['title'] ?? '').toString().toLowerCase();
            return title.contains(searchQuery);
          }).toList();

          if (filteredDocs.isEmpty) {
            return const Center(child: Text("No tests match your search."));
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: filteredDocs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final testId = doc.id;
              final isCompleted = completedTests.containsKey(testId);

              final score = completedTests[testId]?['score'];
              final total = completedTests[testId]?['total'];
              final percentage = completedTests[testId]?['percentage'];
              final timestamp = completedTests[testId]?['timestamp'] as Timestamp?;
              final formattedDate = timestamp != null
                  ? DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate())
                  : null;

              return GestureDetector(
                onTap: () => _onTestTap(data, testId),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(data['title'] ?? 'Untitled',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: isCompleted
                        ? Text("Marks: $score / $total\nPercentage: $percentage%\nSubmitted on: $formattedDate")
                        : Text(data['description'] ?? ''),
                    trailing: Icon(
                      isCompleted ? Icons.check_circle : Icons.play_circle,
                      color: isCompleted ? Colors.green : Colors.blue,
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}


class TestInstructionsScreen extends StatelessWidget {
  final Map<String, dynamic> testData;
  final Function(List<int?>) onTestCompleted;

  const TestInstructionsScreen({
    super.key,
    required this.testData,
    required this.onTestCompleted,
  });

  Future<bool> _hasAlreadySubmitted(String uid, String testId) async {
    final docId = '${uid}_$testId';
    final doc = await FirebaseFirestore.instance
        .collection('mock_test_results')
        .doc(docId)
        .get();
    return doc.exists;
  }

  void _startTest(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not logged in")),
      );
      return;
    }

    final uid = user.uid;
    final testId = testData['id'] ?? "";

    final alreadySubmitted = await _hasAlreadySubmitted(uid, testId);

    if (alreadySubmitted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You have already attempted this test."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TestTakingScreen(
          testData: testData,
          onSubmit: onTestCompleted,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Instructions")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Test: ${testData['title'] ?? 'No Title'}",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text("Duration: ${testData['duration']} minutes"),
            const SizedBox(height: 12),
            const Text(
                "Guidelines:\n1. Do not switch tabs.\n2. Select one option only."),
            const Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: () => _startTest(context),
                child: const Text("Start Test"),
              ),
            )
          ],
        ),
      ),
    );
  }
}


class TestTakingScreen extends StatefulWidget {
  final Map<String, dynamic> testData;
  final Function(List<int?>) onSubmit;

  const TestTakingScreen({
    super.key,
    required this.testData,
    required this.onSubmit,
  });

  @override
  State<TestTakingScreen> createState() => _TestTakingScreenState();
}

class _TestTakingScreenState extends State<TestTakingScreen> {
  int currentIndex = 0;
  late List<int?> selectedOptions;
  Timer? _timer;
  int remainingSeconds = 0;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final questions = widget.testData['questions'] as List<dynamic>;
    selectedOptions = List<int?>.filled(questions.length, null);
    remainingSeconds = (widget.testData['duration'] ?? 10) * 60;

    _loadProgress().then((_) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (remainingSeconds == 0) {
          timer.cancel();
          _submitTest(forceSubmit: true);
        } else {
          setState(() {
            remainingSeconds--;
          });
          _saveProgress();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final savedOptions = prefs.getStringList('selectedOptions_${widget.testData['id']}');
    final savedSeconds = prefs.getInt('remainingSeconds_${widget.testData['id']}');

    if (savedOptions != null) {
      selectedOptions = savedOptions.map((e) => e == 'null' ? null : int.tryParse(e)).toList();
    }

    if (savedSeconds != null) {
      remainingSeconds = savedSeconds;
    }
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'selectedOptions_${widget.testData['id']}',
      selectedOptions.map((e) => e?.toString() ?? 'null').toList(),
    );
    await prefs.setInt('remainingSeconds_${widget.testData['id']}', remainingSeconds);
  }

  Future<void> _clearProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selectedOptions_${widget.testData['id']}');
    await prefs.remove('remainingSeconds_${widget.testData['id']}');
  }

  Future<void> _submitTest({bool forceSubmit = false}) async {
    if (isSubmitting) return;

    if (!forceSubmit && selectedOptions.any((option) => option == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please answer all questions before submitting."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      await widget.onSubmit(selectedOptions);

      final userId = FirebaseAuth.instance.currentUser?.uid ?? "demoUser";
      final studentDocRef = FirebaseFirestore.instance.collection('students').doc(userId);

      try {
        await studentDocRef.update({
          'numberTestAttempted': FieldValue.increment(1),
        });
      } catch (e) {
        await studentDocRef.set({'numberTestAttempted': 1}, SetOptions(merge: true));
      }

      await _clearProgress();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TestResultScreen(
            testData: widget.testData,
            selectedOptions: selectedOptions,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }



  void nextQuestion() {
    if (currentIndex < selectedOptions.length - 1) {
      setState(() {
        currentIndex++;
      });
    }
  }

  void previousQuestion() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
      });
    }
  }

  String formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.testData['questions'] as List<dynamic>;
    final question = questions[currentIndex] as Map<String, dynamic>;
    final options = (question['options'] as List<dynamic>).cast<String>();

    return WillPopScope(
      onWillPop: () async => false, // Block back button
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, // Remove back arrow
          title: Text("Question ${currentIndex + 1} of ${questions.length}"),
          actions: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  formatTime(remainingSeconds),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SelectableText(
                          question['question'] ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      ...List.generate(
                        options.length,
                            (i) => RadioListTile<int>(
                          value: i,
                          groupValue: selectedOptions[currentIndex],
                          title: Text(options[i]),
                          onChanged: (val) {
                            setState(() {
                              selectedOptions[currentIndex] = val;
                            });
                            _saveProgress();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (currentIndex > 0)
                      ElevatedButton(
                        onPressed: previousQuestion,
                        child: const Text("Previous"),
                      ),
                    ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : currentIndex == selectedOptions.length - 1
                          ? _submitTest
                          : nextQuestion,
                      child: isSubmitting
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : Text(currentIndex == selectedOptions.length - 1
                          ? "Submit"
                          : "Next"),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),

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
    required this.selectedOptions,
  });

  int calculateScore() {
    final questions = testData['questions'] as List<dynamic>;
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
    final questions = testData['questions'] as List<dynamic>;
    final total = questions.length;
    final score = calculateScore();

    return Scaffold(
      appBar: AppBar(title: const Text("Test Result")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              "Your Score: $score / $total",
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: total,
                itemBuilder: (context, index) {
                  final question = questions[index] as Map<String, dynamic>;
                  final correctIndex = question['correctIndex'] as int;
                  final options = (question['options'] as List<dynamic>).cast<String>();

                  final userAnswerIndex = selectedOptions[index];
                  final userAnswerText = (userAnswerIndex != null && userAnswerIndex >= 0 && userAnswerIndex < options.length)
                      ? options[userAnswerIndex]
                      : "No answer";

                  final correctAnswerText = (correctIndex >= 0 && correctIndex < options.length)
                      ? options[correctIndex]
                      : "N/A";

                  final isCorrect = userAnswerIndex == correctIndex;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(question['question']),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Text("Your answer: $userAnswerText",
                              style: TextStyle(
                                color: isCorrect ? Colors.green[700] : Colors.red[700],
                                fontWeight: FontWeight.bold,
                              )),
                          Text("Correct answer: $correctAnswerText",
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      trailing: Icon(
                        isCorrect ? Icons.check_circle : Icons.cancel,
                        color: isCorrect ? Colors.green : Colors.red,
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
              child: const Text("Back to Tests"),
            )
          ],
        ),
      ),
    );
  }
}
