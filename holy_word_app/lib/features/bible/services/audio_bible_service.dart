import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';

final audioBibleServiceProvider = Provider<AudioBibleService>((ref) {
  return AudioBibleService();
});

class AudioBibleService {
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Native URL Patterns
  static const String _teluguBaseUrl =
      "https://audio4.wordfree.net/bibles/app/audio/29";
  static const String _englishBaseUrl =
      "https://kjv.wordfree.net/bibles/app/audio/1";

  // Stream getters for UI
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;

  // State tracking
  int _currentBookId = 1;
  int _currentChapter = 1;
  bool _currentIsTelugu = false;

  AudioPlayer get player => _audioPlayer;
  int get currentBookId => _currentBookId;
  int get currentChapter => _currentChapter;

  Future<void> playChapter(
      int bookId, int chapter, bool isTelugu, String bookName) async {
    final baseUrl = isTelugu ? _teluguBaseUrl : _englishBaseUrl;
    final url = "$baseUrl/$bookId/$chapter.mp3";

    // Construct Media ID securely
    final mediaId = '$bookId-$chapter-${isTelugu ? 'te' : 'en'}';

    // If matches current state, just ensure playing
    if (_currentBookId == bookId &&
        _currentChapter == chapter &&
        _currentIsTelugu == isTelugu) {
      if (!_audioPlayer.playing) {
        // If already loaded, just play.
        // But what if just initialized?
        try {
          await _audioPlayer.play();
        } catch (e) {
          // Might need to reload if error state
          await _loadAndPlay(url, mediaId, bookName, chapter, isTelugu);
        }
      }
      return;
    }

    _currentBookId = bookId;
    _currentChapter = chapter;
    _currentIsTelugu = isTelugu;

    await _loadAndPlay(url, mediaId, bookName, chapter, isTelugu);
  }

  Future<void> _loadAndPlay(String url, String mediaId, String bookName,
      int chapter, bool isTelugu) async {
    try {
      if (_audioPlayer.playing) {
        await _audioPlayer.stop();
      }

      // Check if URL is duplicate of previous call? No, logic above handles state check.

      // Using Test URL temporarily if needed, but for now restoring simple URL play
      // TEST URL: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3"

      // If original URLs are broken, we might need the test URL.
      // Let's use the PASSED url which we updated to https
      await _audioPlayer.setUrl(url);

      await _audioPlayer.play();

      debugPrint("Playing Audio: $url");
    } catch (e) {
      debugPrint("Error playing audio: $e");
      // Don't throw to UI, just log. UI can listen to player state errors if needed.
    }
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> resume() async {
    await _audioPlayer.play();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> setSpeed(double speed) async {
    await _audioPlayer.setSpeed(speed);
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
