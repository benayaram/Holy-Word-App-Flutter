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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          height: 70,
          elevation: 0,
          backgroundColor: Colors.white,
          indicatorColor:
              Theme.of(context).colorScheme.primary.withOpacity(0.15),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.favorite_outline_rounded),
              selectedIcon: Icon(Icons.favorite_rounded,
                  color: Theme.of(context).colorScheme.primary),
              label: 'Devotion',
            ),
            NavigationDestination(
              icon: const Icon(
                  Icons.menu_book_rounded), // Using generic book icon
              selectedIcon: Icon(Icons.menu_book_rounded,
                  color: Theme.of(context).colorScheme.primary),
              label: AppLocalizations.of(context)!.bible,
            ),
            NavigationDestination(
              icon: const Icon(Icons.library_music_outlined),
              selectedIcon: Icon(Icons.library_music_rounded,
                  color: Theme.of(context).colorScheme.primary),
              label: 'Worship',
            ),
            NavigationDestination(
              icon: const Icon(Icons.mic_none_outlined),
              selectedIcon: Icon(Icons.mic_rounded,
                  color: Theme.of(context).colorScheme.primary),
              label: 'Sermons',
            ),
            NavigationDestination(
              icon: const Icon(Icons.people_outline_rounded),
              selectedIcon: Icon(Icons.people_rounded,
                  color: Theme.of(context).colorScheme.primary),
              label: 'Community',
            ),
          ],
        ),
      ),
    );
  }
}
