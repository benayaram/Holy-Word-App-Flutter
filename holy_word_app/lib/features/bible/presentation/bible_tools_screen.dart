import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'bible_screen.dart';
import 'notes/notes_screen.dart';
import 'cross_reference_tool_screen.dart';
import 'highlights_screen.dart';
import 'audio_bible_screen.dart';

import 'reading_plans/reading_plans_screen.dart';

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
            icon: Icons.local_library, // Changed from search to library icon
            title: 'Encyclopedias',
            color: Colors.teal.shade100,
            iconColor: Colors.teal,
            onTap: () async {
              final Uri url =
                  Uri.parse('https://www.biblestudytools.com/encyclopedias/');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Could not launch Encyclopedias')),
                  );
                }
              }
            },
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
            icon: Icons.calendar_today,
            title: 'Reading Plans',
            color: Colors.green.shade100,
            iconColor: Colors.green,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ReadingPlansScreen()),
              );
            },
          ),
          _buildToolCard(
            context,
            icon: Icons.child_care,
            title: 'Kids Stories',
            color: Colors.pink.shade100,
            iconColor: Colors.pink,
            onTap: () => _showComingSoonDialog(context, 'Kids Stories'),
          ),
          _buildToolCard(
            context,
            icon: Icons.menu_book_outlined,
            title: 'Bible Dictionary',
            color: Colors.indigo.shade100,
            iconColor: Colors.indigo,
            onTap: () => _showDictionaryDialog(context),
          ),
        ],
      ),
    );
  }

  Future<void> _showDictionaryDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
              title: const Text('English Dictionary'),
              onTap: () {
                Navigator.pop(context);
                _launchUrl(
                    context, 'https://www.biblestudytools.com/dictionaries/');
              },
            ),
            const Divider(),
            ListTile(
              leading: const Text('🇮🇳', style: TextStyle(fontSize: 24)),
              title: const Text('Telugu Dictionary'),
              onTap: () {
                Navigator.pop(context);
                _launchUrl(context,
                    'https://sajeevavahini.com/telugu-bible-dictionary');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch dictionary')),
        );
      }
    }
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
