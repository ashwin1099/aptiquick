import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'dart:ui';




class PracticeQuestionsScreen extends StatefulWidget {
  const PracticeQuestionsScreen({super.key});

  @override
  State<PracticeQuestionsScreen> createState() => _PracticeQuestionsScreenState();
}






class _PracticeQuestionsScreenState extends State<PracticeQuestionsScreen>
    with TickerProviderStateMixin {
  final Map<String, bool> expandedSections = {
    'Numerical Ability': false,
    'Verbal Ability': false,
    'Reasoning Ability': false,
    'Programming Logic': false,
  };

  late AnimationController _staggerController;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<Offset>> _slideAnimations;

  final Map<String, IconData> sectionIcons = {
    'Numerical Ability': Icons.calculate_rounded,
    'Verbal Ability': Icons.menu_book_rounded,
    'Reasoning Ability': Icons.psychology_rounded,
    'Programming Logic': Icons.code_rounded,
  };

  final Map<String, List<Color>> sectionGradients = {
    'Numerical Ability': [const Color(0xFF667eea), const Color(0xFF764ba2)],
    'Verbal Ability': [const Color(0xFFf093fb), const Color(0xFFf5576c)],
    'Reasoning Ability': [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
    'Programming Logic': [const Color(0xFF43e97b), const Color(0xFF38f9d7)],
  };

  final Map<String, List<String>> sectionTopics = {
    'Numerical Ability': [
      'Number System',
      'HCF & LCM',
      'Time and Work',
      'Percentages',
      'Time, Speed and Distance',
      'Profit & Loss',
      'Averages',
      'Simple & Compound Interest',
      'Ratio and Proportion',
      'Permutations and Combinations',
      'Probability',
      'Simplification & Approximation',
      'Geometry & Mensuration',
      'Boats and Streams',
      'Data Interpretation',
      'Progressions (AP, GP)',
      'Unit Digit & Last Digit',
    ],
    'Verbal Ability': [
      'Reading Comprehension',
'Grammar Rules',
'Cloze Test',
'Para Jumbles',
'Sentence Completion',
'Error Spotting',
'Sentence Correction',
'Vocabulary',
'Synonyms & Antonyms',
'Idioms and Phrases',
    ],
    'Reasoning Ability': [
      'Seating Arrangement',
'Blood Relations',
'Syllogisms',
'Puzzles',
'Number Series',
'Coding-Decoding',
'Directions',
'Statement & Conclusions',
'Statement & Assumptions',
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
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimations = List.generate(
      sectionTopics.length,
      (index) => Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(
            index * 0.1,
            0.6 + (index * 0.1),
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    );

    _slideAnimations = List.generate(
      sectionTopics.length,
      (index) => Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(
            index * 0.1,
            0.6 + (index * 0.1),
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    );

    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0a0a0a) : const Color(0xFFfafbff),
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverAppBar(
  expandedHeight: 140,
  floating: false,
  pinned: true,
  elevation: 0,
  backgroundColor: Colors.transparent,
  leading: ClipRRect( // clip for rounded corners on blur effect
    borderRadius: BorderRadius.circular(12),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    ),
  ),
  flexibleSpace: FlexibleSpaceBar(
    titlePadding: const EdgeInsets.only(left: 20, bottom: 16, right: 20),
    title: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Practice Topics',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    ),
    background: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF1a1a2e),
                  const Color(0xFF16213e),
                ]
              : [
                  const Color(0xFF667eea),
                  const Color(0xFF764ba2),
                ],
        ),
      ),
    ),
  ),
),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final sections = sectionTopics.entries.toList();
                  final entry = sections[index];
                  final section = entry.key;
                  final topics = entry.value;

                  return FadeTransition(
                    opacity: _fadeAnimations[index],
                    child: SlideTransition(
                      position: _slideAnimations[index],
                      child: ModernSectionCard(
                        section: section,
                        topics: topics,
                        icon: sectionIcons[section]!,
                        gradient: sectionGradients[section]!,
                        isExpanded: expandedSections[section] ?? false,
                        onExpansionChanged: (expanded) {
                          setState(() {
                            expandedSections[section] = expanded;
                          });
                        },
                        onTopicTap: (topic) {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) =>
                                  QuestionScreen(section: section, topic: topic),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(1.0, 0.0),
                                      end: Offset.zero,
                                    ).animate(CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeOutCubic,
                                    )),
                                    child: child,
                                  ),
                                );
                              },
                              transitionDuration: const Duration(milliseconds: 400),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
                childCount: sectionTopics.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ModernSectionCard extends StatefulWidget {
  final String section;
  final List<String> topics;
  final IconData icon;
  final List<Color> gradient;
  final bool isExpanded;
  final Function(bool) onExpansionChanged;
  final Function(String) onTopicTap;

  const ModernSectionCard({
    super.key,
    required this.section,
    required this.topics,
    required this.icon,
    required this.gradient,
    required this.isExpanded,
    required this.onExpansionChanged,
    required this.onTopicTap,
  });

  @override
  State<ModernSectionCard> createState() => _ModernSectionCardState();
}

class _ModernSectionCardState extends State<ModernSectionCard>
    with TickerProviderStateMixin {
  late AnimationController _expansionController;
  late AnimationController _iconController;
  late Animation<double> _expandAnimation;
  late Animation<double> _iconRotation;

  @override
  void initState() {
    super.initState();
    _expansionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _iconController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _expansionController,
      curve: Curves.easeOutCubic,
    );

    _iconRotation = Tween<double>(
      begin: 0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Curves.easeInOut,
    ));

    if (widget.isExpanded) {
      _expansionController.value = 1.0;
      _iconController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(ModernSectionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _expansionController.forward();
        _iconController.forward();
      } else {
        _expansionController.reverse();
        _iconController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _expansionController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Material(
        borderRadius: BorderRadius.circular(24),
        elevation: 0,
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: isDark ? const Color(0xFF1a1a2e) : Colors.white,
            boxShadow: [
              BoxShadow(
                color: isDark 
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () => widget.onExpansionChanged(!widget.isExpanded),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: widget.gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: widget.gradient.first.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.icon,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.section,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF2d3748),
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.topics.length} topics available',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark 
                                    ? Colors.white.withOpacity(0.6)
                                    : const Color(0xFF718096),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      RotationTransition(
                        turns: _iconRotation,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isDark 
                                ? Colors.white.withOpacity(0.1)
                                : const Color(0xFFf7fafc),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.expand_more_rounded,
                            color: isDark 
                                ? Colors.white.withOpacity(0.8)
                                : const Color(0xFF4a5568),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizeTransition(
                sizeFactor: _expandAnimation,
                child: Container(
                  padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
                  child: Column(
                    children: [
                      Container(
                        height: 1,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              isDark 
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.black.withOpacity(0.1),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: widget.topics.map((topic) {
                          return ModernTopicChip(
                            topic: topic,
                            gradient: widget.gradient,
                            onTap: () => widget.onTopicTap(topic),
                          );
                        }).toList(),
                      ),
                    ],
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

class ModernTopicChip extends StatefulWidget {
  final String topic;
  final List<Color> gradient;
  final VoidCallback onTap;

  const ModernTopicChip({
    super.key,
    required this.topic,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<ModernTopicChip> createState() => _ModernTopicChipState();
}

class _ModernTopicChipState extends State<ModernTopicChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
          _scaleController.forward();
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
          _scaleController.reverse();
          widget.onTap();
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
          _scaleController.reverse();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: _isPressed
                ? LinearGradient(
                    colors: widget.gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: _isPressed
                ? null
                : isDark
                    ? const Color(0xFF2d3748).withOpacity(0.5)
                    : const Color(0xFFf7fafc),
            borderRadius: BorderRadius.circular(16),
            border: _isPressed
                ? null
                : Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.08),
                    width: 1,
                  ),
            boxShadow: _isPressed
                ? [
                    BoxShadow(
                      color: widget.gradient.first.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            widget.topic,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _isPressed
                  ? Colors.white
                  : isDark
                      ? Colors.white.withOpacity(0.9)
                      : const Color(0xFF2d3748),
              letterSpacing: -0.1,
            ),
          ),
        ),
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

  // Cache expiration time (2 hours in milliseconds)
  static const cacheExpiration = 2 * 60 * 60 * 1000;

  String get prefsKeyPage => 'page_${widget.section}_${widget.topic}';
  String get prefsKeyAnswers => 'answers_${widget.section}_${widget.topic}_page$currentPage';
  String get cacheKey => 'cache_${widget.section}_${widget.topic}_page$currentPage';

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
    final stringKeyMap = selectedAnswers.map((key, value) => MapEntry(key.toString(), value));
    await prefs.setString(prefsKeyAnswers, jsonEncode(stringKeyMap));
  }

  Future<void> loadQuestions() async {
    setState(() => isLoading = true);
    final docId = 'questions$currentPage';

    try {
      // Try to load from cache first
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(cacheKey);
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      if (cachedData != null) {
        final cache = jsonDecode(cachedData);
        final cacheTime = cache['timestamp'] as int;
        
        if (currentTime - cacheTime < cacheExpiration) {
          final savedAnswers = prefs.getString(prefsKeyAnswers);
          
          if (!mounted) return;
          
          setState(() {
            questions = List<dynamic>.from(cache['questions']);
            hasNextPage = cache['hasNextPage'] ?? false;
            selectedAnswers = savedAnswers != null
                ? Map<String, dynamic>.from(jsonDecode(savedAnswers))
                    .map((k, v) => MapEntry(int.parse(k), v as int))
                : {};
            revealedExplanation = {};
            isLoading = false;
          });
          return;
        }
      }

      // If no valid cache, load from Firestore
      final collectionRef = FirebaseFirestore.instance
          .collection('practice_questions')
          .doc(widget.section)
          .collection(widget.topic);

      final doc = await collectionRef.doc(docId).get();
      final nextDoc = await collectionRef.doc('questions${currentPage + 1}').get();
      hasNextPage = nextDoc.exists;

      final savedAnswers = prefs.getString(prefsKeyAnswers);

      if (!mounted) return;

      // Update cache with timestamp
      final cacheData = {
        'timestamp': currentTime,
        'questions': doc.exists ? (doc.data()?['questions'] as List?) ?? [] : [],
        'hasNextPage': hasNextPage,
      };
      await prefs.setString(cacheKey, jsonEncode(cacheData));

      setState(() {
        questions = cacheData['questions'] as List<dynamic>;
        selectedAnswers = savedAnswers != null
            ? Map<String, dynamic>.from(jsonDecode(savedAnswers))
                .map((k, v) => MapEntry(int.parse(k), v as int))
            : {};
        revealedExplanation = {};
        isLoading = false;
      });
    } catch (e) {
      // Fallback to cache if available
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(cacheKey);
      
      if (cachedData != null) {
        final cache = jsonDecode(cachedData);
        final savedAnswers = prefs.getString(prefsKeyAnswers);
        
        if (!mounted) return;
        
        setState(() {
          questions = List<dynamic>.from(cache['questions']);
          hasNextPage = cache['hasNextPage'] ?? false;
          selectedAnswers = savedAnswers != null
              ? Map<String, dynamic>.from(jsonDecode(savedAnswers))
                  .map((k, v) => MapEntry(int.parse(k), v as int))
              : {};
          revealedExplanation = {};
          isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          isLoading = false;
          questions = [];
          hasNextPage = false;
        });
      }
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
      SnackBar(
        content: const Text("Progress reset."),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
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
    
    // Scroll to top after page change
    if (scrollController.hasClients) {
      scrollController.jumpTo(0);
    }
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
      
      // Scroll to top after page change
      if (scrollController.hasClients) {
        scrollController.jumpTo(0);
      }
    }
  }

  Widget buildShimmerPlaceholder() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (_, index) => Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 20,
                  width: double.infinity,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                ...List.generate(
                  4,
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
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
        title: Text(
          widget.topic,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.library_books,
              color: Theme.of(context).colorScheme.onBackground,
            ),
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
            icon: Icon(
              Icons.more_vert,
              color: Theme.of(context).colorScheme.onBackground,
            ),
            onSelected: (value) {
              if (value == 'reset') {
                resetProgress();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(
                      Icons.restart_alt,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(width: 12),
                    const Text('Reset Progress'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.05),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Page $currentPage',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  Text(
                    '${questions.length} Questions',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  // Clear cache for current page to force refresh
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove(cacheKey);
                  await loadQuestions();
                },
                child: isLoading
                    ? buildShimmerPlaceholder()
                    : questions.isEmpty
                        ? CustomScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              SliverFillRemaining(
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        size: 48,
                                        color: Theme.of(context).colorScheme.error,
                                      ),
                                      const SizedBox(height: 16),
                                      const Text("Questions Adding Soon"),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            controller: scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: questions.length,
                            itemBuilder: (context, index) {
                              final q = questions[index];
                              final int? selected = selectedAnswers[index];
                              final int correctIndex = (q['correctIndex'] is int)
                                  ? q['correctIndex']
                                  : int.tryParse(q['correctIndex']?.toString() ?? '') ?? -1;
                              final String explanation = q['explanation'] ?? "No explanation.";

                              return QuestionCard(
                                questionNumber: (currentPage - 1) * questionsPerPage + index + 1,
                                question: q['question'],
                                options: List<String>.from(q['options']),
                                selectedIndex: selected,
                                correctIndex: correctIndex,
                                explanation: explanation,
                                isExplanationRevealed: revealedExplanation.contains(index),
                                onOptionSelected: (val) {
                                  setState(() {
                                    selectedAnswers[index] = val;
                                  });
                                  saveAnswers();
                                },
                                onShowExplanation: () {
                                  setState(() {
                                    revealedExplanation.add(index);
                                  });
                                },
                              );
                            },
                          ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -4),
                  )
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FilledButton.tonal(
                      onPressed: currentPage > 1 ? prevPage : null,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.chevron_left),
                          SizedBox(width: 4),
                          Text("Previous"),
                        ],
                      ),
                    ),
                    Text(
                      "Page $currentPage",
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    FilledButton(
                      onPressed: () {
                        if (hasNextPage) {
                          nextPage();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text("You've reached the last page"),
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        }
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Text("Next"),
                          SizedBox(width: 4),
                          Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class QuestionCard extends StatelessWidget {
  final int questionNumber;
  final String question;
  final List<String> options;
  final int? selectedIndex;
  final int correctIndex;
  final String explanation;
  final bool isExplanationRevealed;
  final ValueChanged<int> onOptionSelected;
  final VoidCallback onShowExplanation;

  const QuestionCard({
    super.key,
    required this.questionNumber,
    required this.question,
    required this.options,
    required this.selectedIndex,
    required this.correctIndex,
    required this.explanation,
    required this.isExplanationRevealed,
    required this.onOptionSelected,
    required this.onShowExplanation,
  });

  Future<void> _askAI(BuildContext context, String url, String name) async {
  // Copy question to clipboard
  await Clipboard.setData(ClipboardData(text: question));
  
  // 1. Encode URL parameters properly
  final encodedQuestion = Uri.encodeComponent(question);
  final Uri uri = Uri.parse("$url?q=$encodedQuestion");

  try {
    // 2. Use more reliable launch method
    final result = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication, // Force browser open
      webOnlyWindowName: '_blank', // Ensure new tab
    );

    // 3. Check actual launch result
    if (!result) {
      throw 'Failed to launch $name';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Question copied! Opening $name...")),
    );
  } catch (e) {
    // 4. More helpful error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Couldn't open $name. Please install it first!"),
        action: SnackBarAction(
          label: "Copy Link",
          onPressed: () => Clipboard.setData(ClipboardData(text: url)),
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }
}
  
  
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question number + text
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$questionNumber',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    question,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Options list
            ...List.generate(
              options.length,
              (i) {
                final isSelected = i == selectedIndex;
                final isCorrect = i == correctIndex;
                final showResult = selectedIndex != null;

                Color borderColor = Colors.transparent;
                Color bgColor = Theme.of(context).colorScheme.surface;
                Color textColor = Theme.of(context).colorScheme.onSurface;

                if (showResult) {
                  if (isSelected) {
                    bgColor = isCorrect
                        ? Colors.green.shade50
                        : Colors.red.shade50;
                    borderColor = isCorrect
                        ? Colors.green
                        : Colors.red;
                    textColor = isCorrect ? Colors.green : Colors.red;
                  } else if (isCorrect) {
                    bgColor = Colors.green.shade50;
                    borderColor = Colors.green;
                    textColor = Colors.green;
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => onOptionSelected(i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: borderColor,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: isSelected
                                ? Icon(
                                    Icons.circle,
                                    size: 14,
                                    color: Theme.of(context).colorScheme.primary,
                                  )
                                : null,
                          ),
                          Expanded(
                            child: Text(
                              options[i],
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (showResult && isCorrect && !isSelected)
                            Icon(
                              Icons.check_circle,
                              color: Colors.green.shade600,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Show Explanation button
            if (!isExplanationRevealed)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: FilledButton.tonal(
                  onPressed: onShowExplanation,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lightbulb_outline, size: 18),
                      SizedBox(width: 8),
                      Text('Show Explanation'),
                    ],
                  ),
                ),
              ),

            // AI Assistance Buttons
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Get AI Help:",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: [
    _buildAIAssistButton(
      context,
      'assets/chatgpt.png',
      "ChatGPT",
      "https://chat.openai.com/",
    ),
    _buildAIAssistButton(
      context,
      'assets/gemini.png',
      "Gemini",
      "https://gemini.google.com/", // Fixed URL
    ),
    _buildAIAssistButton(
      context,
      'assets/deepseek.png',
      "DeepSeek",
      "https://chat.deepseek.com/",
    ),
    _buildAIAssistButton(
      context,
      'assets/grok.png',
      "Grok",
      "https://grok.com/", // Updated URL
    ),
  ],
),
                ],
              ),
            ),

            // Explanation box
            if (isExplanationRevealed)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Get Ai help for more clarification",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(explanation),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIAssistButton(BuildContext context, String imagePath, String name, String url) {
    return Tooltip(
      message: "Ask $name",
      child: InkWell(
        borderRadius: BorderRadius.circular(50),
        onTap: () => _askAI(context, url, name),
        child: Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}


class FormulaScreen extends StatefulWidget {
  final String topic;

  const FormulaScreen({super.key, required this.topic});

  @override
  State<FormulaScreen> createState() => _FormulaScreenState();
}

class _FormulaScreenState extends State<FormulaScreen> {
  String? _content;
  bool _isLoading = true;
  static const int cacheDurationMs = 60 * 60 * 1000; // 1 hour

  String get _cacheKey => 'formula_${widget.topic}';
  String get _cacheTimeKey => 'formula_time_${widget.topic}';

  @override
  void initState() {
    super.initState();
    _loadFormula();
  }

  Future<void> _loadFormula({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();

    // Cache check
    if (!forceRefresh) {
      final cached = prefs.getString(_cacheKey);
      final cacheTime = prefs.getInt(_cacheTimeKey) ?? 0;
      if (cached != null &&
          DateTime.now().millisecondsSinceEpoch - cacheTime < cacheDurationMs) {
        setState(() {
          _content = cached;
          _isLoading = false;
        });
        return;
      }
    }

    // Fetch from Firestore
    try {
      final doc = await FirebaseFirestore.instance
          .collection('formula')
          .doc(widget.topic)
          .get();

      if (doc.exists && doc.data() != null && doc['content'] != null) {
        _content = doc['content'];
        await prefs.setString(_cacheKey, _content!);
        await prefs.setInt(
            _cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
      } else {
        _content = "No formulas found for this topic.";
      }
    } catch (e) {
      _content = "Error loading formulas. Please try again.";
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  List<InlineSpan> _parseInline(String text) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*|\*(.*?)\*|_(.*?)_|`(.*?)`');
    
    text.splitMapJoin(
      regex,
      onMatch: (m) {
        if (m[1] != null) {
          spans.add(TextSpan(
            text: m[1],
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ));
        } else if (m[2] != null || m[3] != null) {
          spans.add(TextSpan(
            text: m[2] ?? m[3],
            style: const TextStyle(fontStyle: FontStyle.italic),
          ));
        } else if (m[4] != null) {
          spans.add(WidgetSpan(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              margin: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
              child: Text(
                m[4]!,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ));
        }
        return '';
      },
      onNonMatch: (t) {
        spans.add(TextSpan(text: t));
        return '';
      },
    );
    return spans;
  }

  List<Widget> _parseBlocks(String text) {
    final widgets = <Widget>[];
    final lines = text.split('\n');
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      Widget block;
      EdgeInsetsGeometry padding = const EdgeInsets.only(bottom: 16);

      if (line.startsWith('# ')) {
        block = Text(
          line.substring(2),
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        );
        padding = const EdgeInsets.only(bottom: 16, top: 8);
      } else if (line.startsWith('## ')) {
        block = Text(
          line.substring(3),
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.secondary,
          ),
        );
        padding = const EdgeInsets.only(bottom: 12, top: 8);
      } else if (RegExp(r'^\d+\.\s').hasMatch(line)) {
        final parts = line.split('. ');
        final number = parts.first;
        final content = parts.skip(1).join('. ');
        
        block = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              alignment: Alignment.topRight,
              margin: const EdgeInsets.only(right: 8),
              child: Text('$number.', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: textTheme.bodyLarge,
                  children: _parseInline(content),
                ),
              ),
            ),
          ],
        );
      } else if (line.startsWith('- ')) {
        block = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 4, right: 8),
              child: Icon(Icons.circle, size: 6, color: Colors.grey),
            ),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: textTheme.bodyLarge,
                  children: _parseInline(line.substring(2)),
                ),
              ),
            ),
          ],
        );
      } else {
        block = RichText(
          text: TextSpan(
            style: textTheme.bodyLarge,
            children: _parseInline(line),
          ),
        );
      }

      widgets.add(
        Padding(
          padding: padding,
          child: block,
        )
      );
    }
    
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.topic} Concepts", 
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
        centerTitle: true,
        elevation: 2,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator.adaptive(
              onRefresh: () => _loadFormula(forceRefresh: true),
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        _content != null && _content!.isNotEmpty
                            ? _parseBlocks(_content!)
                            : [
                                Center(
                                  child: Text(
                                    "No formulas found",
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                )
                              ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}