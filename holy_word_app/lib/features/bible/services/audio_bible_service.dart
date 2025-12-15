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
      "http://audio4.wordfree.net/bibles/app/audio/29";
  static const String _englishBaseUrl =
      "http://kjv.wordfree.net/bibles/app/audio/1";

  // Stream getters for UI
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;

  AudioPlayer get player => _audioPlayer;

  Future<void> playChapter(int bookId, int chapter, bool isTelugu) async {
    final baseUrl = isTelugu ? _teluguBaseUrl : _englishBaseUrl;
    final url = "$baseUrl/$bookId/$chapter.mp3";

    try {
      if (_audioPlayer.playing) {
        await _audioPlayer.stop();
      }

      await _audioPlayer.setUrl(url);
      await _audioPlayer.play();

      debugPrint("Playing Audio: $url");
    } catch (e) {
      debugPrint("Error playing audio: $e");
      throw Exception("Could not play audio chapter: $e");
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

  void dispose() {
    _audioPlayer.dispose();
  }
}
