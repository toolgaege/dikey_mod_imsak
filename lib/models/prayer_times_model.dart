class PrayerTimesResponse {
  final List<DailyPrayerTimes> times;
  final PlaceInfo? place;

  PrayerTimesResponse({
    required this.times,
    this.place,
  });

  factory PrayerTimesResponse.fromJson(Map<String, dynamic> json) {
    final timesMap = json['times'] as Map<String, dynamic>;
    final timesList = timesMap.entries.map((entry) {
      return DailyPrayerTimes.fromList(
          entry.key, List<String>.from(entry.value));
    }).toList();

    return PrayerTimesResponse(
      times: timesList,
      place: json['place'] != null ? PlaceInfo.fromJson(json['place']) : null,
    );
  }
}

class DailyPrayerTimes {
  final String date;
  final String fajr; // Fecr
  final String sunrise; // Güneş
  final String dhuhr; // Öğle
  final String asr; // İkindi
  final String maghrib; // Akşam
  final String isha; // Yatsı

  DailyPrayerTimes({
    required this.date,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
  });

  factory DailyPrayerTimes.fromJson(Map<String, dynamic> json) {
    return DailyPrayerTimes(
      date: json['date'] ?? '',
      fajr: json['fajr'] ?? '',
      sunrise: json['sunrise'] ?? '',
      dhuhr: json['dhuhr'] ?? '',
      asr: json['asr'] ?? '',
      maghrib: json['maghrib'] ?? '',
      isha: json['isha'] ?? '',
    );
  }

  factory DailyPrayerTimes.fromList(String date, List<String> times) {
    return DailyPrayerTimes(
      date: date,
      fajr: times.isNotEmpty ? times[0] : '',
      sunrise: times.length > 1 ? times[1] : '',
      dhuhr: times.length > 2 ? times[2] : '',
      asr: times.length > 3 ? times[3] : '',
      maghrib: times.length > 4 ? times[4] : '',
      isha: times.length > 5 ? times[5] : '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'fajr': fajr,
      'sunrise': sunrise,
      'dhuhr': dhuhr,
      'asr': asr,
      'maghrib': maghrib,
      'isha': isha,
    };
  }

  /// Türkçe vakit adlarıyla map döndürür
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
}

class PlaceInfo {
  final String? country;
  final String? region;
  final String? city;
  final double? latitude;
  final double? longitude;

  PlaceInfo({
    this.country,
    this.region,
    this.city,
    this.latitude,
    this.longitude,
  });

  factory PlaceInfo.fromJson(Map<String, dynamic> json) {
    return PlaceInfo(
      country: json['country'],
      region: json['region'],
      city: json['city'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }

  String getFullName() {
    final parts = <String>[];
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (region != null && region!.isNotEmpty) parts.add(region!);
    if (country != null && country!.isNotEmpty) parts.add(country!);
    return parts.join(', ');
  }
}
