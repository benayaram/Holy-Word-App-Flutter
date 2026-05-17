import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/arena_providers.dart';
import '../arena_theme.dart';

class SermonComposerScreen extends ConsumerStatefulWidget {
  const SermonComposerScreen({super.key});

  @override
  ConsumerState<SermonComposerScreen> createState() => _SermonComposerScreenState();
}

class _SermonComposerScreenState extends ConsumerState<SermonComposerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final List<TextEditingController> _keyPointsControllers = [TextEditingController()];
  
  bool _useCustomQuiz = false;
  final List<_CustomQuestionField> _customQuestions = [];

  String? _selectedChurch;
  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Add one default custom question if needed
    _addQuestion();

    // Auto-select first church if available
    final user = ref.read(arenaUserProvider).value;
    if (user != null && user.churchIds.isNotEmpty) {
      _selectedChurch = user.churchIds.first;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    for (var ctrl in _keyPointsControllers) {
      ctrl.dispose();
    }
    for (var q in _customQuestions) {
      q.dispose();
    }
    super.dispose();
  }

  void _addKeyPoint() {
    setState(() {
      _keyPointsControllers.add(TextEditingController());
    });
  }

  void _removeKeyPoint(int index) {
    if (_keyPointsControllers.length > 1) {
      setState(() {
        _keyPointsControllers[index].dispose();
        _keyPointsControllers.removeAt(index);
      });
    }
  }

  void _addQuestion() {
    setState(() {
      _customQuestions.add(_CustomQuestionField());
    });
  }

  void _removeQuestion(int index) {
    if (_customQuestions.length > 1) {
      setState(() {
        _customQuestions[index].dispose();
        _customQuestions.removeAt(index);
      });
    }
  }

  Future<void> _publishSermon() async {
    if (!_formKey.currentState!.validate()) {
      _tabController.animateTo(0); // Switch back to compose tab
      return;
    }

    final user = ref.read(arenaUserProvider).value;
    final church = _selectedChurch ?? user?.churchId ?? '';
    if (church.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or add a church to your profile first.')),
      );
      return;
    }

    setState(() {
      _isPublishing = true;
    });

    try {
      final api = ref.read(arenaApiClientProvider);
      
      final points = _keyPointsControllers
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      List<Map<String, dynamic>>? quizQuestions;
      if (_useCustomQuiz) {
        quizQuestions = _customQuestions.map((q) {
          final options = q.optionsControllers.map((c) => c.text.trim()).toList();
          return {
            'question': q.questionController.text.trim(),
            'questionTe': q.questionController.text.trim(),
            'options': options,
            'optionsTe': options, // Native translation fallback
            'correctAnswer': q.correctAnswerIndex,
          };
        }).toList();
      }

      await api.createSermonQuiz(
        title: _titleController.text.trim(),
        keyPoints: points,
        churchId: church,
        questions: quizQuestions,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sermon Published! Members have been notified. 📖')),
        );
        ref.invalidate(pendingSermonsProvider);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to publish sermon: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPublishing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(arenaUserProvider).value;

    return Scaffold(
      backgroundColor: ArenaTheme.background,
      appBar: AppBar(
        title: const Text('Sermon Composer', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: ArenaTheme.primary,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(icon: Icon(Icons.edit_note_rounded), text: 'Compose Notes'),
            Tab(icon: Icon(Icons.remove_red_eye_rounded), text: 'Layout Preview'),
          ],
        ),
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildComposeTab(user),
                _buildPreviewTab(user),
              ],
            ),
          ),
          if (_isPublishing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: ArenaTheme.primary),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _isPublishing ? null : _publishSermon,
            style: ElevatedButton.styleFrom(
              backgroundColor: ArenaTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 8,
            ),
            icon: const Icon(Icons.send_rounded),
            label: const Text('Publish & Notify Members', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildComposeTab(dynamic user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Church Selector
          if (user != null && user.churchIds.length > 1) ...[
            const Text('Post to Church', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedChurch,
              dropdownColor: ArenaTheme.surface,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDec('Select targeted church...'),
              items: user.churchIds.map<DropdownMenuItem<String>>((c) => DropdownMenuItem(
                value: c,
                child: Text(c),
              )).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedChurch = val;
                });
              },
            ),
            const SizedBox(height: 16),
          ],

          // Title
          const Text('Sermon Title', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _titleController,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDec('e.g. Walking in His Light'),
            validator: (value) => value == null || value.isEmpty ? 'Title is required' : null,
          ),
          const SizedBox(height: 20),

          // Key Points Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Sermon Key Points', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: _addKeyPoint,
                icon: const Icon(Icons.add, size: 16, color: ArenaTheme.success),
                label: const Text('Add Point', style: TextStyle(color: ArenaTheme.success, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Key Points List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _keyPointsControllers.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: ArenaTheme.xpGold.withOpacity(0.1),
                      child: Text('${index + 1}', style: const TextStyle(color: ArenaTheme.xpGold, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _keyPointsControllers[index],
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: _inputDec('Key takeaway point details...'),
                        validator: (value) => value == null || value.isEmpty ? 'Key point cannot be empty' : null,
                      ),
                    ),
                    if (_keyPointsControllers.length > 1) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                        onPressed: () => _removeKeyPoint(index),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          const Divider(color: Colors.white12, height: 32),

          // Custom Quiz Option
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                const Icon(Icons.quiz_rounded, color: ArenaTheme.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Custom Quiz Questions',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        _useCustomQuiz
                            ? 'Define custom questions and wrong options'
                            : 'Gemini AI will automatically generate questions',
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _useCustomQuiz,
                  activeColor: ArenaTheme.primary,
                  onChanged: (val) {
                    setState(() {
                      _useCustomQuiz = val;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Custom Questions Dynamic List
          if (_useCustomQuiz) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Quiz Questions', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _addQuestion,
                  icon: const Icon(Icons.add_circle, size: 16, color: ArenaTheme.accent),
                  label: const Text('Add Question', style: TextStyle(color: ArenaTheme.accent, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _customQuestions.length,
              itemBuilder: (context, index) {
                return _buildQuestionEditor(index);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestionEditor(int index) {
    final q = _customQuestions[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Question #${index + 1}', style: const TextStyle(color: ArenaTheme.accent, fontWeight: FontWeight.bold, fontSize: 14)),
              if (_customQuestions.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                  onPressed: () => _removeQuestion(index),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: q.questionController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: _inputDec('Enter the question text...'),
            validator: (value) => value == null || value.isEmpty ? 'Question text is required' : null,
          ),
          const SizedBox(height: 16),
          const Text('Options (Tap checkbox to set as CORRECT answer)', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...List.generate(4, (oIdx) {
            final isCorrect = q.correctAnswerIndex == oIdx;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Radio<int>(
                    value: oIdx,
                    groupValue: q.correctAnswerIndex,
                    activeColor: ArenaTheme.success,
                    onChanged: (val) {
                      setState(() {
                        q.correctAnswerIndex = val!;
                      });
                    },
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: q.optionsControllers[oIdx],
                      style: TextStyle(
                        color: isCorrect ? ArenaTheme.success : Colors.white,
                        fontSize: 13,
                        fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                      ),
                      decoration: _inputDec(
                        oIdx == 0 ? 'Correct Answer option...' : 'Wrong Answer option #${oIdx}...',
                        borderColor: isCorrect ? ArenaTheme.success.withOpacity(0.4) : null,
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Option cannot be empty' : null,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPreviewTab(dynamic user) {
    final title = _titleController.text.isEmpty ? 'Sermon Title Placeholder' : _titleController.text;
    final points = _keyPointsControllers.map((c) => c.text).where((t) => t.isNotEmpty).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gorgeous elevation container card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Church badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: ArenaTheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.church, color: ArenaTheme.primary, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            _selectedChurch ?? user?.churchId ?? 'My Church',
                            style: const TextStyle(color: ArenaTheme.primary, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'PREVIEW',
                      style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Sermon Title
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person, color: ArenaTheme.xpGold, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Pastor: ${user?.displayName ?? "Lead Pastor"}',
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                    ),
                  ],
                ),
                const Divider(color: Colors.white12, height: 32),

                // Notes body
                const Text(
                  'SERMON NOTES & SUMMARY',
                  style: TextStyle(color: ArenaTheme.xpGold, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
                ),
                const SizedBox(height: 12),
                if (points.isEmpty)
                  const Text(
                    'No key points added yet. Return to Compose Notes tab to add points.',
                    style: TextStyle(color: Colors.white30, fontSize: 13, fontStyle: FontStyle.italic),
                  )
                else
                  ...List.generate(points.length, (idx) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: ArenaTheme.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              points[idx],
                              style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Interactive quiz preview
          if (_useCustomQuiz && _customQuestions.isNotEmpty) ...[
            const Text(
              'SERMON QUIZ PREVIEW',
              style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
            ),
            const SizedBox(height: 12),
            ...List.generate(_customQuestions.length, (qIdx) {
              final q = _customQuestions[qIdx];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.04)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Q${qIdx + 1}: ${q.questionController.text.isEmpty ? "Question Text Placeholder" : q.questionController.text}',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ...List.generate(4, (oIdx) {
                      final isCorrect = q.correctAnswerIndex == oIdx;
                      final text = q.optionsControllers[oIdx].text;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isCorrect ? ArenaTheme.success.withOpacity(0.1) : Colors.black12,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isCorrect ? ArenaTheme.success.withOpacity(0.3) : Colors.transparent),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isCorrect ? Icons.check_circle : Icons.circle_outlined,
                              color: isCorrect ? ArenaTheme.success : Colors.white30,
                              size: 14,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                text.isEmpty ? 'Option ${oIdx + 1}' : text,
                                style: TextStyle(
                                  color: isCorrect ? Colors.white : Colors.white70,
                                  fontSize: 12,
                                  fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ArenaTheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ArenaTheme.primary.withOpacity(0.1)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome, color: ArenaTheme.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Gemini AI will automatically generate custom quiz questions from your key notes upon publishing.',
                      style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _inputDec(String hint, {Color? borderColor}) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
    filled: true,
    fillColor: Colors.white.withOpacity(0.04),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: borderColor ?? Colors.transparent),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: borderColor ?? Colors.transparent),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: borderColor ?? ArenaTheme.primary.withOpacity(0.5)),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
  );
}

class _CustomQuestionField {
  final questionController = TextEditingController();
  final List<TextEditingController> optionsControllers = List.generate(4, (_) => TextEditingController());
  int correctAnswerIndex = 0;

  void dispose() {
    questionController.dispose();
    for (var c in optionsControllers) {
      c.dispose();
    }
  }
}
