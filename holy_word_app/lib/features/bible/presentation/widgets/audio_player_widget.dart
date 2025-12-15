import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/audio_bible_service.dart';
import 'package:just_audio/just_audio.dart';

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
    // Auto-play on mount if this widget is shown
    _playAudio();
  }

  void _playAudio() {
    ref
        .read(audioBibleServiceProvider)
        .playChapter(widget.bookId, widget.chapter, widget.isTelugu);
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return "00:00";
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final audioService = ref.watch(audioBibleServiceProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Title + Close
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.bookName} ${widget.chapter}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              GestureDetector(
                onTap: () {
                  audioService.stop();
                  widget.onClose();
                },
                child: const Icon(Icons.close, size: 20, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Controls Row
          Row(
            children: [
              // Play/Pause Button
              StreamBuilder<PlayerState>(
                stream: audioService.playerStateStream,
                builder: (context, snapshot) {
                  final playerState = snapshot.data;
                  final processingState = playerState?.processingState;
                  final playing = playerState?.playing;

                  if (processingState == ProcessingState.loading ||
                      processingState == ProcessingState.buffering) {
                    return Container(
                      margin: const EdgeInsets.all(8.0),
                      width: 32.0,
                      height: 32.0,
                      child: const CircularProgressIndicator(),
                    );
                  } else if (playing != true) {
                    return IconButton(
                      icon: const Icon(Icons.play_circle_fill),
                      iconSize: 48,
                      color: Theme.of(context).colorScheme.primary,
                      onPressed: audioService.resume,
                    );
                  } else {
                    return IconButton(
                      icon: const Icon(Icons.pause_circle_filled),
                      iconSize: 48,
                      color: Theme.of(context).colorScheme.primary,
                      onPressed: audioService.pause,
                    );
                  }
                },
              ),

              // Progress Bar
              Expanded(
                child: StreamBuilder<Duration>(
                  stream: audioService.positionStream,
                  builder: (context, snapshotPosition) {
                    final position = snapshotPosition.data ?? Duration.zero;
                    return StreamBuilder<Duration?>(
                      stream: audioService.durationStream,
                      builder: (context, snapshotDuration) {
                        final duration = snapshotDuration.data ?? Duration.zero;

                        return Column(
                          children: [
                            Slider(
                              value: position.inMilliseconds
                                  .toDouble()
                                  .clamp(0, duration.inMilliseconds.toDouble()),
                              max: duration.inMilliseconds.toDouble(),
                              onChanged: (value) {
                                audioService.seek(
                                    Duration(milliseconds: value.toInt()));
                              },
                              activeColor:
                                  Theme.of(context).colorScheme.primary,
                              inactiveColor: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.2),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_formatDuration(position),
                                      style: const TextStyle(
                                          fontSize: 10, color: Colors.grey)),
                                  Text(_formatDuration(duration),
                                      style: const TextStyle(
                                          fontSize: 10, color: Colors.grey)),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
