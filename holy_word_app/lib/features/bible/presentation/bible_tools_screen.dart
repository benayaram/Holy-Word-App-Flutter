import 'package:flutter/material.dart';
import 'bible_screen.dart';
import 'notes/notes_screen.dart';
import 'cross_reference_tool_screen.dart';
import 'highlights_screen.dart';
import 'audio_bible_screen.dart';

import 'image_generator_dashboard.dart';

class BibleToolsScreen extends StatelessWidget {
  const BibleToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bible Study Tools'),
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildToolCard(
            context,
            icon: Icons.menu_book,
            title: 'Bible',
            color: Colors.brown.shade100,
            iconColor: Colors.brown,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BibleScreen(),
                ),
              );
            },
          ),
          _buildToolCard(
            context,
            icon: Icons.headset,
            title: 'Audio Bible',
            color: Colors.purple.shade100,
            iconColor: Colors.purple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AudioBibleScreen()),
              );
            },
          ),
          _buildToolCard(
            context,
            icon: Icons.note,
            title: 'My Notes',
            color: Colors.blue.shade100,
            iconColor: Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotesScreen()),
              );
            },
          ),
          _buildToolCard(
            context,
            icon: Icons.search,
            title: 'Search',
            color: Colors.teal.shade100,
            iconColor: Colors.teal,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const BibleScreen(), // Go to BibleScreen which handles search for now
                ),
              );
            },
            // Note: BibleScreen has the search icon. Ideally search should be its own screen or accessible here.
            // For now, let's keep it simple.
          ),
          _buildToolCard(
            context,
            icon: Icons.compare_arrows,
            title: 'Cross References',
            color: Colors.orange.shade100,
            iconColor: Colors.orange,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const CrossReferenceToolScreen()),
              );
            },
          ),
          _buildToolCard(
            context,
            icon: Icons.highlight, // Highlighting icon
            title: 'Highlights',
            color: Colors.yellow.shade100,
            iconColor: Colors.orange, // Slightly darker for visibility
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const HighlightsScreen()),
              );
            },
          ),
          _buildToolCard(
            context,
            icon: Icons.image,
            title: 'Share Image',
            color: Colors.indigo.shade100,
            iconColor: Colors.indigo,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ImageGeneratorDashboard(),
                ),
              );
            },
          ),
          _buildToolCard(
            context,
            icon: Icons.calendar_today,
            title: 'Reading Plans',
            color: Colors.green.shade100,
            iconColor: Colors.green,
            onTap: () => _showComingSoonDialog(context, 'Reading Plans'),
          ),
          _buildToolCard(
            context,
            icon: Icons.child_care,
            title: 'Kids Stories',
            color: Colors.pink.shade100,
            iconColor: Colors.pink,
            onTap: () => _showComingSoonDialog(context, 'Kids Stories'),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$feature Coming Soon'),
        content: const Text('This feature is currently under development.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Card(
      color: color,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: iconColor),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: iconColor.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
