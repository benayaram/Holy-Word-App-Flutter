import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holy_word_app/l10n/app_localizations.dart';
import '../features/devotional/presentation/devotional_screen.dart';
import '../features/bible/presentation/bible_tools_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DevotionalScreen(),
    const BibleToolsScreen(),
    const Center(child: Text('Worship & Music')), // Placeholder
    const Center(child: Text('Sermons')), // Placeholder
    const Center(child: Text('Community')), // Placeholder
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Devotion',
          ),
          NavigationDestination(
            icon: const Icon(Icons.book_outlined),
            selectedIcon: const Icon(Icons.book),
            label: AppLocalizations.of(context)!.bible,
          ),
          const NavigationDestination(
            icon: Icon(Icons.music_note_outlined),
            selectedIcon: Icon(Icons.music_note),
            label: 'Worship',
          ),
          const NavigationDestination(
            icon: Icon(Icons.mic_none_outlined),
            selectedIcon: Icon(Icons.mic),
            label: 'Sermons',
          ),
          const NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Community',
          ),
        ],
      ),
    );
  }
}
