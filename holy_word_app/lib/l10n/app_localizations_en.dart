// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Holy Word App';

  @override
  String get dailyDevotional => 'Daily Devotional';

  @override
  String get todaysWord => 'Today\'s Word';

  @override
  String get audioDevotional => 'Audio Devotional';

  @override
  String get prayerReminder => 'Prayer Reminder';

  @override
  String get dailyPrayer => 'Daily Prayer';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get english => 'English';

  @override
  String get telugu => 'Telugu';

  @override
  String get prayerTime => 'Prayer Time';

  @override
  String get prayerTimeBody => 'It\'s time for your daily prayer.';

  @override
  String reminderSet(Object time) {
    return 'Reminder set for $time';
  }

  @override
  String get prayerContent => 'Lord, thank you for your endless love. Help me to walk in your light today and share your love with others. Amen.';

  @override
  String get bible => 'Bible';
}
