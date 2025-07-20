import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';


class PracticeQuestionsScreen extends StatefulWidget {
  const PracticeQuestionsScreen({super.key});

  @override
  State<PracticeQuestionsScreen> createState() => _PracticeQuestionsScreenState();
}

class _PracticeQuestionsScreenState extends State<PracticeQuestionsScreen> {
  final Map<String, bool> expandedSections = {
    'Numerical Ability': false,
    'Verbal Ability': false,
    'Reasoning Ability': false,
    'Programming Logic': false,
  };

  final Map<String, List<String>> sectionTopics = {
    'Numerical Ability': [
  'Number System',
  'HCF & LCM',
  'Simplification & Approximation',
  'Time and Work',
  'Time, Speed and Distance',
  'Averages',
  'Percentages',
  'Profit & Loss',
  'Simple & Compound Interest',
  'Ratio and Proportion',
  'Permutations and Combinations',
  'Probability',
  'Geometry & Mensuration',
  'Boats and Streams',
  'Data Interpretation',
  'Progressions (AP, GP)',
  'Unit Digit & Last Digit',
  'Logarithms',
  'Ages',
],

    'Verbal Ability': [
  'Reading Comprehension',
  'Grammar Rules',
  'Synonyms & Antonyms',
  'Vocabulary',
  'Sentence Completion',
  'Sentence Correction',
  'Para Jumbles',
  'Error Spotting',
  'Cloze Test',
  'Idioms and Phrases',
  'Spelling Errors',
],

    'Reasoning Ability': [
  'Seating Arrangement',
  'Blood Relations',
  'Syllogisms',
  'Puzzles',
  'Number Series',
  'Coding-Decoding',
  'Directions',
  'Statement & Assumptions',
  'Statement & Conclusions',
  'Analogy',
  'Odd One Out',
  'Data Sufficiency',
  'Clock and Calendar',
],

    'Programming Logic': [
  'Loops',
  'Data Types',
  'Arrays & Strings',
  'Functions',
  'Pointers',
  'Recursion',
  'OOP Concepts',
  'Stacks & Queues',
  'Searching & Sorting',
  'Bit Manipulation',
  'Memory Allocation',
  'Operators & Expressions',
  'Control Statements',
],

  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Practice Questions')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: sectionTopics.entries.map((entry) {
          final section = entry.key;
          final topics = entry.value;
          final isExpanded = expandedSections[section] ?? false;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: Text(
                  section,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                trailing: Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                onTap: () {
                  setState(() {
                    expandedSections[section] = !isExpanded;
                  });
                },
              ),
              const SizedBox(height: 8),
              if (isExpanded)
                ...topics.map(
                  (topic) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QuestionScreen(
                                section: section,
                                topic: topic,
                              ),
                            ),
                          );
                        },
                        child: Center(
                          child: Text(
                            topic,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          );
        }).toList(),
      ),
    );
  }
}




class QuestionScreen extends StatefulWidget {
  final String section;
  final String topic;

  const QuestionScreen({
    super.key,
    required this.section,
    required this.topic,
  });

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  int currentPage = 1;
  bool isLoading = true;
  List<dynamic> questions = [];
  Map<int, int> selectedAnswers = {};
  Set<int> revealedExplanation = {};
  final int questionsPerPage = 20;
  final ScrollController scrollController = ScrollController();
  bool hasNextPage = false;

  String get prefsKeyPage => 'page_${widget.section}_${widget.topic}';
  String get prefsKeyAnswers => 'answers_${widget.section}_${widget.topic}_page$currentPage';

  @override
  void initState() {
    super.initState();
    loadSavedPage().then((_) => loadQuestions());
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  Future<void> loadSavedPage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentPage = prefs.getInt(prefsKeyPage) ?? 1;
    });
  }

  Future<void> saveCurrentPage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(prefsKeyPage, currentPage);
  }

  Future<void> saveAnswers() async {
    final prefs = await SharedPreferences.getInstance();
    // Convert Map<int, int> to Map<String, int>
    final stringKeyMap = selectedAnswers.map((key, value) => MapEntry(key.toString(), value));
    await prefs.setString(prefsKeyAnswers, jsonEncode(stringKeyMap));
  }

  Future<void> loadQuestions() async {
    setState(() => isLoading = true);
    final docId = 'questions$currentPage';

    try {
      final collectionRef = FirebaseFirestore.instance
          .collection('practice_questions')
          .doc(widget.section)
          .collection(widget.topic);

      final doc = await collectionRef.doc(docId).get();
      final nextDoc = await collectionRef.doc('questions${currentPage + 1}').get();
      hasNextPage = nextDoc.exists;

      final prefs = await SharedPreferences.getInstance();
      final savedAnswers = prefs.getString(prefsKeyAnswers);

      if (!mounted) return;

      setState(() {
        questions = doc.exists ? (doc.data()?['questions'] as List?) ?? [] : [];
        selectedAnswers = savedAnswers != null
            ? Map<String, dynamic>.from(jsonDecode(savedAnswers))
            .map((k, v) => MapEntry(int.parse(k), v as int))
            : {};
        revealedExplanation = {};
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        questions = [];
        hasNextPage = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You're offline or Firestore is unavailable."),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final allKeys = prefs.getKeys().where((k) =>
    k.contains(widget.section) && k.contains(widget.topic));
    for (final key in allKeys) {
      await prefs.remove(key);
    }
    setState(() {
      currentPage = 1;
      selectedAnswers.clear();
      revealedExplanation.clear();
    });
    await loadQuestions();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Progress reset.")),
    );
  }

  Future<void> nextPage() async {
    await saveAnswers();
    setState(() {
      currentPage++;
      selectedAnswers = {};
      revealedExplanation = {};
    });
    await saveCurrentPage();
    await loadQuestions();
  }

  Future<void> prevPage() async {
    if (currentPage > 1) {
      await saveAnswers();
      setState(() {
        currentPage--;
        selectedAnswers = {};
        revealedExplanation = {};
      });
      await saveCurrentPage();
      await loadQuestions();
    }
  }

  Widget buildShimmerPlaceholder() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: ListTile(
          title: Container(height: 16, color: Colors.white),
          subtitle: Column(
            children: List.generate(
              4,
                  (_) => Container(
                height: 12,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.topic),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book),
            tooltip: 'Formula List',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FormulaScreen(topic: widget.topic),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'reset') {
                resetProgress();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'reset',
                child: Text('Reset Progress'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? buildShimmerPlaceholder()
                : questions.isEmpty
                ? const Center(child: Text("No questions found."))
                : ListView.builder(
              controller: scrollController,
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final q = questions[index];
                final int? selected = selectedAnswers[index];
                final int correctIndex = (q['correctIndex'] is int)
                    ? q['correctIndex']
                    : int.tryParse(q['correctIndex']?.toString() ?? '') ?? -1;
                final String explanation = q['explanation'] ?? "No explanation.";

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Q${(currentPage - 1) * questionsPerPage + index + 1}. ${q['question']}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...List.generate(
                          (q['options'] as List).length,
                              (i) {
                            Color textColor = Colors.black;
                            if (selected != null && i == selected) {
                              textColor = (selected == correctIndex)
                                  ? Colors.green
                                  : Colors.red;
                            }
                            return RadioListTile<int>(
                              title: Text(
                                q['options'][i],
                                style: TextStyle(color: textColor),
                              ),
                              value: i,
                              groupValue: selected,
                              onChanged: (val) {
                                setState(() {
                                  selectedAnswers[index] = val!;
                                });
                                saveAnswers();
                              },
                            );
                          },
                        ),
                        if (!revealedExplanation.contains(index))
                          TextButton(
                            onPressed: () {
                              setState(() {
                                revealedExplanation.add(index);
                              });
                            },
                            child: const Text("Show Explanation"),
                          ),
                        if (revealedExplanation.contains(index))
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: (selected != null &&
                                        selected == correctIndex)
                                        ? "Correct! "
                                        : "Wrong. ",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: (selected != null &&
                                          selected == correctIndex)
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                  const TextSpan(
                                    text: "\nExplanation: ",
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(text: explanation),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: currentPage > 1 ? prevPage : null,
                child: const Text("Previous"),
              ),
              Text("Page $currentPage"),
              TextButton(
                onPressed: hasNextPage ? nextPage : null,
                child: const Text("Next"),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}


class FormulaScreen extends StatelessWidget {
  final String topic;

  const FormulaScreen({super.key, required this.topic});

  String _getImagePathFromTopic(String topic) {
    // Convert to lowercase, replace spaces and "&" with underscores or 'and'
    // Remove special characters except underscore
    final sanitized = topic
        .toLowerCase()
        .replaceAll('&', 'and')
        .replaceAll(' ', '_')
        .replaceAll(RegExp(r'[^\w_]'), ''); // removes special chars like (,),-,etc.

    return 'assets/${sanitized}_formula.jpg';
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = _getImagePathFromTopic(topic);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Formula List"),
        leading: BackButton(),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.asset(
            imagePath,
            errorBuilder: (context, error, stackTrace) {
              return const Text(
                "Formula image not found.",
                style: TextStyle(fontSize: 18, color: Colors.red),
              );
            },
          ),
        ),
      ),
    );
  }
}
