/// Veritabanı için namaz vakitleri modeli
class PrayerTimeDB {
  final int? id;
  final String date; // YYYY-MM-DD formatında
  final int year;
  final int month;
  final int day;
  final String fajr;
  final String sunrise;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;
  final String placeId;
  final String placeName;
  final double latitude;
  final double longitude;
  final DateTime createdAt;

  PrayerTimeDB({
    this.id,
    required this.date,
    required this.year,
    required this.month,
    required this.day,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.placeId,
    required this.placeName,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
  });

  /// Veritabanından map'e dönüştür
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'year': year,
      'month': month,
      'day': day,
      'fajr': fajr,
      'sunrise': sunrise,
      'dhuhr': dhuhr,
      'asr': asr,
      'maghrib': maghrib,
      'isha': isha,
      'place_id': placeId,
      'place_name': placeName,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Map'ten veritabanı modeli oluştur
  factory PrayerTimeDB.fromMap(Map<String, dynamic> map) {
    return PrayerTimeDB(
      id: map['id'] as int?,
      date: map['date'] as String,
      year: map['year'] as int,
      month: map['month'] as int,
      day: map['day'] as int,
      fajr: map['fajr'] as String,
      sunrise: map['sunrise'] as String,
      dhuhr: map['dhuhr'] as String,
      asr: map['asr'] as String,
      maghrib: map['maghrib'] as String,
      isha: map['isha'] as String,
      placeId: map['place_id'] as String,
      placeName: map['place_name'] as String,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Türkçe vakit adlarıyla map döndür
  Map<String, String> toTurkishMap() {
    return {
      'Fecr': fajr,
      'Güneş': sunrise,
      'Öğle': dhuhr,
      'İkindi': asr,
      'Akşam': maghrib,
      'Yatsı': isha,
    };
  }

  @override
  String toString() {
    return 'PrayerTimeDB{date: $date, dhuhr: $dhuhr, placeName: $placeName}';
  }
}
