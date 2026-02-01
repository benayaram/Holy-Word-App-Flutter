import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../services/audio_bible_service.dart';

class AudioPlayerWidget extends ConsumerStatefulWidget {
  final int bookId;
  final int chapter;
  final String bookName;
  final bool isTelugu;
  final VoidCallback onClose;

  const AudioPlayerWidget({
    super.key,
    required this.bookId,
    required this.chapter,
    required this.bookName,
    required this.isTelugu,
    required this.onClose,
  });

  @override
  ConsumerState<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends ConsumerState<AudioPlayerWidget> {
  double _currentSpeed = 1.0;

  @override
  void didUpdateWidget(covariant AudioPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bookId != widget.bookId ||
        oldWidget.chapter != widget.chapter ||
        oldWidget.isTelugu != widget.isTelugu) {
      _playAudio();
    }
  }

  @override
  void initState() {
    super.initState();
    _playAudio();
  }

  void _playAudio() {
    ref.read(audioBibleServiceProvider).playChapter(
        widget.bookId, widget.chapter, widget.isTelugu, widget.bookName);
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return "00:00";
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  void _changeSpeed() {
    final speeds = [0.75, 1.0, 1.25, 1.5, 2.0];
    final currentIndex = speeds.indexOf(_currentSpeed);
    final nextIndex = (currentIndex + 1) % speeds.length;
    final newSpeed = speeds[nextIndex];

    setState(() {
      _currentSpeed = newSpeed;
    });
    ref.read(audioBibleServiceProvider).setSpeed(newSpeed);
  }

  @override
  Widget build(BuildContext context) {
    final audioService = ref.watch(audioBibleServiceProvider);
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Title Section
          Text(
            widget.bookName,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[900],
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Chapter ${widget.chapter}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 32),

          // Progress Bar
          StreamBuilder<Duration>(
            stream: audioService.positionStream,
            builder: (context, snapshotPosition) {
              final position = snapshotPosition.data ?? Duration.zero;
              return StreamBuilder<Duration?>(
                stream: audioService.durationStream,
                builder: (context, snapshotDuration) {
                  final duration = snapshotDuration.data ?? Duration.zero;
                  final maxDuration = duration.inMilliseconds.toDouble();
                  final currentValue = position.inMilliseconds
                      .toDouble()
                      .clamp(0.0, maxDuration);

                  return Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8),
                          overlayShape:
                              const RoundSliderOverlayShape(overlayRadius: 20),
                          activeTrackColor: primaryColor,
                          inactiveTrackColor: primaryColor.withOpacity(0.2),
                          thumbColor: primaryColor,
                          overlayColor: primaryColor.withOpacity(0.1),
                        ),
                        child: Slider(
                          value: currentValue,
                          max: maxDuration > 0 ? maxDuration : 1.0,
                          onChanged: (value) {
                            audioService
                                .seek(Duration(milliseconds: value.toInt()));
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(position),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _formatDuration(duration),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 32),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Speed Control
              IconButton(
                onPressed: _changeSpeed,
                icon: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${_currentSpeed}x",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ),

              // Skip Backward
              IconButton(
                onPressed: () {
                  // Seek back 15 seconds
                  // We need current position.
                  // Accessing player directly via service provider is cleaner if we expose it,
                  // but service exposes seek. Ideally we read current pos.
                  // The stream builder has position but we are outside it.
                  // Service exposes `player` getter.
                  final currentPos =
                      ref.read(audioBibleServiceProvider).player.position;
                  final newPos = currentPos - const Duration(seconds: 15);
                  ref
                      .read(audioBibleServiceProvider)
                      .seek(newPos < Duration.zero ? Duration.zero : newPos);
                },
                icon: Icon(Icons.replay_10,
                    size: 32,
                    color: Colors.grey[800]), // replay_10 is closest standard
              ),

              // Play/Pause
              StreamBuilder<PlayerState>(
                stream: audioService.playerStateStream,
                builder: (context, snapshot) {
                  final playerState = snapshot.data;
                  final processingState = playerState?.processingState;
                  final playing = playerState?.playing;

                  if (processingState == ProcessingState.loading ||
                      processingState == ProcessingState.buffering) {
                    return Container(
                      width: 64,
                      height: 64,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: CircularProgressIndicator(
                          strokeWidth: 3, color: primaryColor),
                    );
                  }

                  final isPlaying = playing ?? false;

                  return Container(
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: IconButton(
                      iconSize: 32,
                      padding: const EdgeInsets.all(16),
                      icon: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      onPressed:
                          isPlaying ? audioService.pause : audioService.resume,
                    ),
                  );
                },
              ),

              // Skip Forward
              IconButton(
                onPressed: () {
                  final currentPos =
                      ref.read(audioBibleServiceProvider).player.position;
                  final newPos = currentPos + const Duration(seconds: 15);
                  // Duration is not readily available here without stream, but seek handles clipping usually or we trust logic.
                  ref.read(audioBibleServiceProvider).seek(newPos);
                },
                icon: Icon(Icons.forward_10, size: 32, color: Colors.grey[800]),
              ),

              // Close / More Options
              IconButton(
                onPressed: widget.onClose,
                icon: Icon(Icons.keyboard_arrow_down,
                    size: 32, color: Colors.grey[400]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
