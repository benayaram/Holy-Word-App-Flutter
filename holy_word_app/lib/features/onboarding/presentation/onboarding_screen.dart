import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/app_theme.dart';
import '../../../main_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String _selectedLanguage = 'en'; // Default to English

  final List<OnboardingPageModel> _pages = [
    OnboardingPageModel(
      title: 'Welcome',
      description: 'Please select your language.',
      icon: Icons.language,
      type: OnboardingPageType.languageSelection,
    ),
    OnboardingPageModel(
      title: 'Welcome to Holy Word',
      description: 'Your daily source of spiritual inspiration.',
      icon: Icons.favorite,
      type: OnboardingPageType.info,
    ),
    OnboardingPageModel(
      title: 'See How It Works',
      description: 'Watch a quick video to learn about all the features.',
      icon: Icons.play_circle_outline,
      type: OnboardingPageType.video,
    ),
    OnboardingPageModel(
      title: 'Ready to Begin?',
      description: 'Your journey of faith starts now.',
      icon: Icons.check_circle_outline,
      type: OnboardingPageType.info,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_launch', false);
    await prefs.setString('language_code', _selectedLanguage);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _showVideoPopup() {
    showDialog(
      context: context,
      builder: (context) => const VideoPopupDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
              child: LinearProgressIndicator(
                value: (_currentPage + 1) / _pages.length,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),

            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),

            // Bottom Buttons
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  if (_currentPage < _pages.length - 1)
                    Expanded(
                      child: TextButton(
                        onPressed: _completeOnboarding,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Skip'),
                      ),
                    )
                  else
                    const Spacer(),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 2,
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1
                            ? 'Get Started'
                            : 'Continue',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPageModel page) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          // Icon/Image
          Container(
            width: 200,
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 100,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 40),

          // Title
          Text(
            page.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Specific Content based on Page Type
          if (page.type == OnboardingPageType.languageSelection)
            _buildLanguageSelection(),

          if (page.type == OnboardingPageType.video)
            ElevatedButton.icon(
              onPressed: _showVideoPopup,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Play Video'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).colorScheme.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelection() {
    return Column(
      children: [
        _buildLanguageCard(
          languageCode: 'en',
          title: 'English',
          subtitle: 'English',
          isSelected: _selectedLanguage == 'en',
        ),
        const SizedBox(height: 16),
        _buildLanguageCard(
          languageCode: 'te',
          title: 'Telugu',
          subtitle: 'తెలుగు',
          isSelected: _selectedLanguage == 'te',
        ),
      ],
    );
  }

  Widget _buildLanguageCard({
    required String languageCode,
    required String title,
    required String subtitle,
    required bool isSelected,
  }) {
    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? const BorderSide(color: Colors.white, width: 2)
            : BorderSide.none,
      ),
      color: Colors.white,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedLanguage = languageCode;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                Icons.language,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.black54,
                          ),
                    ),
                  ],
                ),
              ),
              Radio<String>(
                value: languageCode,
                groupValue: _selectedLanguage,
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value!;
                  });
                },
                activeColor: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VideoPopupDialog extends StatelessWidget {
  const VideoPopupDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            color: Colors.black,
            width: double.maxFinite,
            height: 200,
            child: const Center(
              child:
                  Icon(Icons.play_circle_filled, color: Colors.white, size: 64),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  'Video Showcase',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                const Text('This is a placeholder for the video player.'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () async {
                    final Uri url = Uri.parse(
                        'https://www.youtube.com/watch?v=dQw4w9WgXcQ');
                    if (!await launchUrl(url)) {
                      throw Exception('Could not launch $url');
                    }
                  },
                  child: const Text('Watch on YouTube'),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

enum OnboardingPageType { languageSelection, info, video }

class OnboardingPageModel {
  final String title;
  final String description;
  final IconData icon;
  final OnboardingPageType type;

  OnboardingPageModel({
    required this.title,
    required this.description,
    required this.icon,
    required this.type,
  });
}
