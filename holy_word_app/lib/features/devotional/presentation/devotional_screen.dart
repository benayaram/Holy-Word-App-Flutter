import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../services/audio_player_service.dart';
import '../services/prayer_reminder_service.dart';
import '../services/streak_service.dart';
import '../../../core/providers/language_provider.dart';
import 'package:holy_word_app/l10n/app_localizations.dart';
import '../../bible/presentation/share_verse_screen.dart'; // Import Share Screen

class DevotionalScreen extends ConsumerStatefulWidget {
  const DevotionalScreen({super.key});

  @override
  ConsumerState<DevotionalScreen> createState() => _DevotionalScreenState();
}

class _DevotionalScreenState extends ConsumerState<DevotionalScreen> {
  int _streakCount = 0;
  Map<String, dynamic>? _dailyVerseData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStreak();
    _fetchDailyVerse();
  }

  Future<void> _loadStreak() async {
    final streakService = ref.read(streakServiceProvider);
    await streakService.updateStreak();
    final streak = await streakService.getStreak();
    if (mounted) {
      setState(() {
        _streakCount = streak;
      });
    }
  }

  Future<void> _fetchDailyVerse() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http
          .get(Uri.parse('https://holyword.vercel.app/api/daily-verse'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _dailyVerseData = data;
            _isLoading = false;
          });
        }
      } else {
        debugPrint('Failed to load daily verse: ${response.statusCode}');
        _useFallbackVerse();
      }
    } catch (e) {
      debugPrint('Error fetching daily verse: $e');
      _useFallbackVerse();
    }
  }

  void _useFallbackVerse() {
    if (mounted) {
      setState(() {
        _dailyVerseData = {
          "english":
              "For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life.",
          "englishReference": "John 3:16",
          "telugu":
              "దేవుడు లోకాన్ని ఎంతో ప్రేమించాడు. అందుకే తన ఏకైక కుమారుడిని ఇచ్చాడు. అతనిలో నమ్మకముంచే ప్రతి వ్యక్తి నశించకుండా నిత్యజీవాన్ని పొందును.",
          "teluguReference": "యోహాను 3:16"
        };
        _isLoading = false;
      });
    }
  }

  Future<void> _setPrayerReminder() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      final reminderService = ref.read(prayerReminderServiceProvider);
      await reminderService.scheduleReminder(
        id: 1,
        title: AppLocalizations.of(context)!.prayerTime,
        body: AppLocalizations.of(context)!.prayerTimeBody,
        hour: picked.hour,
        minute: picked.minute,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .reminderSet(picked.format(context)))),
        );
      }
    }
  }

  void _showAudioDialog() {
    showDialog(
      context: context,
      builder: (context) => const AudioPlayerDialog(),
    );
  }

  void _showLanguageDialog() {
    final currentLanguage = ref.read(languageProvider);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.selectLanguage),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(AppLocalizations.of(context)!.english),
                leading: Radio<String>(
                  value: 'english',
                  groupValue: currentLanguage,
                  onChanged: (value) {
                    ref.read(languageProvider.notifier).setLanguage(value!);
                    Navigator.pop(context);
                  },
                ),
                onTap: () {
                  ref.read(languageProvider.notifier).setLanguage('english');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.telugu),
                leading: Radio<String>(
                  value: 'telugu',
                  groupValue: currentLanguage,
                  onChanged: (value) {
                    ref.read(languageProvider.notifier).setLanguage(value!);
                    Navigator.pop(context);
                  },
                ),
                onTap: () {
                  ref.read(languageProvider.notifier).setLanguage('telugu');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _shareDailyVerse() {
    if (_dailyVerseData == null) return;
    final isTelugu = ref.read(languageProvider) == 'telugu';

    final text = isTelugu
        ? (_dailyVerseData?['telugu'] ?? '')
        : (_dailyVerseData?['english'] ?? '');
    final reference = isTelugu
        ? (_dailyVerseData?['teluguReference'] ?? '')
        : (_dailyVerseData?['englishReference'] ?? '');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShareVerseScreen(
          verseText: text,
          verseReference: reference,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = ref.watch(languageProvider);
    final isTelugu = languageCode == 'telugu';

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.dailyDevotional),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department, color: Colors.orange),
                const SizedBox(width: 4),
                Text(
                  '$_streakCount',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(width: 12),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.settings),
                  onSelected: (value) {
                    if (value == 'language') {
                      _showLanguageDialog();
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return [
                      PopupMenuItem<String>(
                        value: 'language',
                        child: Row(
                          children: [
                            const Icon(Icons.language, color: Colors.grey),
                            const SizedBox(width: 12),
                            Text(AppLocalizations.of(context)!.language),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Header
                  Text(
                    DateFormat('MMMM dd, yyyy').format(DateTime.now()),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.todaysWord,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // Language Toggle Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            ref
                                .read(languageProvider.notifier)
                                .setLanguage('english');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: !isTelugu
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.surfaceVariant,
                            foregroundColor: !isTelugu
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                          ),
                          child: Text(AppLocalizations.of(context)!.english),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            ref
                                .read(languageProvider.notifier)
                                .setLanguage('telugu');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isTelugu
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.surfaceVariant,
                            foregroundColor: isTelugu
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                          ),
                          child: Text(AppLocalizations.of(context)!.telugu),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Daily Verse Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Text(
                            isTelugu
                                ? (_dailyVerseData?['telugu'] ?? '')
                                : (_dailyVerseData?['english'] ?? ''),
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontStyle: FontStyle.italic,
                                      fontSize: 18,
                                      height: 1.5,
                                    ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isTelugu
                                ? (_dailyVerseData?['teluguReference'] ?? '')
                                : (_dailyVerseData?['englishReference'] ?? ''),
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      _buildActionCard(
                        icon: Icons.headset,
                        title: AppLocalizations.of(context)!.audioDevotional,
                        color: Colors.purple.shade100,
                        iconColor: Colors.purple,
                        onTap: _showAudioDialog,
                      ),
                      _buildActionCard(
                        icon: Icons.notifications_active,
                        title: AppLocalizations.of(context)!.prayerReminder,
                        color: Colors.orange.shade100,
                        iconColor: Colors.orange,
                        onTap: _setPrayerReminder,
                      ),
                      _buildActionCard(
                        icon: Icons.share,
                        title: "Share Verse",
                        color: Colors.blue.shade100,
                        iconColor: Colors.blue,
                        onTap: _shareDailyVerse,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildActionCard({
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
            Icon(icon, size: 32, color: iconColor),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
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

class AudioPlayerDialog extends ConsumerStatefulWidget {
  const AudioPlayerDialog({super.key});

  @override
  ConsumerState<AudioPlayerDialog> createState() => _AudioPlayerDialogState();
}

class _AudioPlayerDialogState extends ConsumerState<AudioPlayerDialog> {
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    final audioService = ref.read(audioPlayerServiceProvider);

    // Generate URL based on date (simplified logic for now)
    // In production, this should match the Android logic exactly
    // Using the static URL from Android code for reliability as per user request
    const url =
        "http://www.onlinetelugubible.net/Daily%20Devotions/Audio/10October/October-27-Website.mp3";

    try {
      await audioService.init(url);

      audioService.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
            if (state.processingState == ProcessingState.ready) {
              _isLoading = false;
            }
          });
        }
      });

      audioService.positionStream.listen((p) {
        if (mounted) {
          setState(() {
            _position = p;
          });
        }
      });

      audioService.durationStream.listen((d) {
        if (mounted) {
          setState(() {
            _duration = d ?? Duration.zero;
          });
        }
      });
    } catch (e) {
      debugPrint("Error loading audio: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioService = ref.read(audioPlayerServiceProvider);

    return AlertDialog(
      contentPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.audioDevotional,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            const CircularProgressIndicator()
          else
            Column(
              children: [
                Icon(Icons.audiotrack,
                    size: 48, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  DateFormat('MMMM dd, yyyy').format(DateTime.now()),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 24),
                Slider(
                  value: _position.inSeconds.toDouble(),
                  min: 0,
                  max: _duration.inSeconds.toDouble() > 0
                      ? _duration.inSeconds.toDouble()
                      : 1.0,
                  onChanged: (value) {
                    audioService.seek(Duration(seconds: value.toInt()));
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(_position)),
                      Text(_formatDuration(_duration)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.replay_10),
                      onPressed: () {
                        final newPos = _position - const Duration(seconds: 10);
                        audioService.seek(
                            newPos < Duration.zero ? Duration.zero : newPos);
                      },
                    ),
                    const SizedBox(width: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                        color: Colors.white,
                        iconSize: 32,
                        onPressed: () {
                          if (_isPlaying) {
                            audioService.pause();
                          } else {
                            audioService.play();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.forward_10),
                      onPressed: () {
                        final newPos = _position + const Duration(seconds: 10);
                        audioService
                            .seek(newPos > _duration ? _duration : newPos);
                      },
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}
