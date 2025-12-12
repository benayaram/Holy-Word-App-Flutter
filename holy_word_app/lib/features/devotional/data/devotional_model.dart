class Devotional {
  final String id;
  final String date;
  final String verseText;
  final String verseReference;
  final String prayerText;
  final String? audioUrl;

  Devotional({
    required this.id,
    required this.date,
    required this.verseText,
    required this.verseReference,
    required this.prayerText,
    this.audioUrl,
  });

  factory Devotional.fromJson(Map<String, dynamic> json) {
    return Devotional(
      id: json['id'] as String,
      date: json['date'] as String,
      verseText: json['verse_text'] as String,
      verseReference: json['verse_reference'] as String,
      prayerText: json['prayer_text'] as String,
      audioUrl: json['audio_url'] as String?,
    );
  }
}
