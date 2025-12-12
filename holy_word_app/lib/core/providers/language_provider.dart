import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final languageProvider = StateNotifierProvider<LanguageNotifier, String>((ref) {
  return LanguageNotifier();
});

class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier() : super('telugu') {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getString('app_language') ?? 'telugu';
  }

  Future<void> setLanguage(String languageCode) async {
    state = languageCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', languageCode);
  }

  bool get isTelugu => state == 'telugu';
}
