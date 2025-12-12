// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Telugu (`te`).
class AppLocalizationsTe extends AppLocalizations {
  AppLocalizationsTe([String locale = 'te']) : super(locale);

  @override
  String get appTitle => 'పవిత్ర వాక్యం';

  @override
  String get dailyDevotional => 'దిన ధ్యానం';

  @override
  String get todaysWord => 'ఈ రోజు వాక్యం';

  @override
  String get audioDevotional => 'ఆడియో ధ్యానం';

  @override
  String get prayerReminder => 'ప్రార్థన రిమైండర్';

  @override
  String get dailyPrayer => 'దిన ప్రార్థన';

  @override
  String get settings => 'సెట్టింగులు';

  @override
  String get language => 'భాష';

  @override
  String get selectLanguage => 'భాషను ఎంచుకోండి';

  @override
  String get english => 'ఆంగ్లం';

  @override
  String get telugu => 'తెలుగు';

  @override
  String get prayerTime => 'ప్రార్థన సమయం';

  @override
  String get prayerTimeBody => 'ఇది మీ రోజువారీ ప్రార్థన సమయం.';

  @override
  String reminderSet(Object time) {
    return '$time కి రిమైండర్ సెట్ చేయబడింది';
  }

  @override
  String get prayerContent => 'ప్రభువా, మీ అంతులేని ప్రేమకు ధన్యవాదాలు. ఈ రోజు మీ వెలుగులో నడవడానికి మరియు మీ ప్రేమను ఇతరులతో పంచుకోవడానికి నాకు సహాయం చేయండి. ఆమెన్.';

  @override
  String get bible => 'బైబిల్';
}
