import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../presentation/common/share_card_widget.dart';

/// Service for generating and sharing victory/milestone cards.
class ArenaShareService {
  final ScreenshotController _screenshotCtrl = ScreenshotController();

  /// Generate and share a victory card
  Future<void> shareVictoryCard({
    required BuildContext context,
    required int myScore,
    required int opponentScore,
    required String playerName,
  }) async {
    final widget = ShareCardWidget.victory(
      myScore: myScore,
      opponentScore: opponentScore,
      playerName: playerName,
    );
    await _captureAndShare(context, widget,
        'I won a Bible Trivia Battle! $myScore-$opponentScore 🏆\n'
        'Challenge me in Holy Word Bible Arena!');
  }

  /// Generate and share a quiz result card
  Future<void> shareQuizCard({
    required BuildContext context,
    required int score,
    required int total,
    required String category,
  }) async {
    final widget = ShareCardWidget.quizResult(
      score: score, total: total, category: category);
    await _captureAndShare(context, widget,
        'I scored $score/$total on a $category Bible Quiz! 📖\n'
        'Try it in Holy Word Bible Arena!');
  }

  /// Generate and share a milestone card
  Future<void> shareMilestoneCard({
    required BuildContext context,
    required String milestoneName,
    required String playerName,
    required int count,
    required String unit,
  }) async {
    final widget = ShareCardWidget.milestone(
      milestoneName: milestoneName,
      playerName: playerName,
      count: count,
      unit: unit,
    );
    await _captureAndShare(context, widget,
        '🎉 I just earned "$milestoneName" in Bible Arena!\n'
        '$count $unit achieved. Join me in Holy Word app!');
  }

  /// Internal: capture widget as image and share
  Future<void> _captureAndShare(
    BuildContext context, Widget widget, String text) async {
    try {
      final Uint8List imageBytes = await _screenshotCtrl.captureFromWidget(
        Material(color: Colors.transparent, child: widget),
        delay: const Duration(milliseconds: 200),
        pixelRatio: 3.0,
      );

      // Save to temp file
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/bible_arena_share.png');
      await file.writeAsBytes(imageBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: text,
        subject: 'Bible Arena',
      );
    } catch (e) {
      debugPrint('Share card error: $e');
      _shareTextOnly(text);
    }
  }

  void _shareTextOnly(String text) {
    Share.share(text);
  }
}
