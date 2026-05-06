import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'quiz_play_screen.dart';

class QuizHomeScreen extends ConsumerWidget {
  const QuizHomeScreen({super.key});

  static const _categories = [
    {'name': 'old_testament', 'label': 'Old Testament', 'labelTe': 'పాత నిబంధన',
      'icon': Icons.auto_stories, 'color': Color(0xFF8b5cf6)},
    {'name': 'new_testament', 'label': 'New Testament', 'labelTe': 'క్రొత్త నిబంధన',
      'icon': Icons.menu_book_rounded, 'color': Color(0xFF3b82f6)},
    {'name': 'life_of_jesus', 'label': 'Life of Jesus', 'labelTe': 'యేసు జీవితం',
      'icon': Icons.brightness_7, 'color': Color(0xFFf59e0b)},
    {'name': 'psalms_proverbs', 'label': 'Psalms & Proverbs', 'labelTe': 'కీర్తనలు & సామెతలు',
      'icon': Icons.music_note_rounded, 'color': Color(0xFF10b981)},
    {'name': 'pauls_letters', 'label': 'Paul\'s Letters', 'labelTe': 'పౌలు పత్రికలు',
      'icon': Icons.mail_rounded, 'color': Color(0xFFe94560)},
    {'name': 'children', 'label': 'Children\'s Pack', 'labelTe': 'పిల్లల ప్యాక్',
      'icon': Icons.child_care_rounded, 'color': Color(0xFFf97316)},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        title: const Text('Bible Quiz', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Quick Play
          _buildQuickPlayCard(context, ref),
          const SizedBox(height: 24),

          // Category Title
          Text(
            'Choose a Category',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 18, fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),

          // Category Grid
          ...List.generate((_categories.length / 2).ceil(), (rowIdx) {
            final idx1 = rowIdx * 2;
            final idx2 = idx1 + 1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(child: _buildCategoryCard(context, ref, _categories[idx1])),
                  const SizedBox(width: 12),
                  if (idx2 < _categories.length)
                    Expanded(child: _buildCategoryCard(context, ref, _categories[idx2]))
                  else
                    const Expanded(child: SizedBox()),
                ],
              ),
            );
          }),

          const SizedBox(height: 16),
          // Difficulty selector shown as chips
          Text(
            'Difficulty affects question complexity and XP earned',
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPlayCard(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _startQuiz(context, ref, null, 'normal'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFFe94560), Color(0xFFf97316)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFe94560).withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Play',
                    style: TextStyle(
                      color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '10 random questions • All categories',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, WidgetRef ref, Map<String, dynamic> cat) {
    final color = cat['color'] as Color;
    return GestureDetector(
      onTap: () => _showDifficultyPicker(context, ref, cat['name'] as String),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withOpacity(0.06),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(cat['icon'] as IconData, color: color, size: 28),
            const SizedBox(height: 10),
            Text(
              cat['label'] as String,
              style: const TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            Text(
              cat['labelTe'] as String,
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  void _showDifficultyPicker(BuildContext context, WidgetRef ref, String category) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16213e),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select Difficulty',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _difficultyTile(ctx, ref, category, 'beginner', 'Beginner',
                'Sunday school level', Icons.child_care, const Color(0xFF10b981)),
            _difficultyTile(ctx, ref, category, 'normal', 'Normal',
                'Regular believer', Icons.person, const Color(0xFF3b82f6)),
            _difficultyTile(ctx, ref, category, 'expert', 'Expert',
                'Seminary level', Icons.school, const Color(0xFFe94560)),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _difficultyTile(BuildContext ctx, WidgetRef ref, String category,
      String difficulty, String label, String desc, IconData icon, Color color) {
    return ListTile(
      onTap: () {
        Navigator.pop(ctx);
        _startQuiz(ctx, ref, category, difficulty);
      },
      leading: CircleAvatar(backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color, size: 22)),
      title: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      subtitle: Text(desc, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  void _startQuiz(BuildContext context, WidgetRef ref, String? category, String difficulty) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizPlayScreen(category: category, difficulty: difficulty),
      ),
    );
  }
}
