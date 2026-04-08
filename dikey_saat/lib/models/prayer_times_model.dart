/// Hicri tarih bilgisi (Aladhan API'den)
class HijriDate {
  final int day;
  final int month;
  final int year;
  final String monthNameAr;
  final String monthNameEn;

  HijriDate({
    required this.day,
    required this.month,
    required this.year,
    this.monthNameAr = '',
    this.monthNameEn = '',
  });

  factory HijriDate.fromAladhanJson(Map<String, dynamic> json) {
    return HijriDate(
      day: int.tryParse(json['day']?.toString() ?? '0') ?? 0,
      month: json['month']?['number'] ?? 0,
      year: int.tryParse(json['year']?.toString() ?? '0') ?? 0,
      monthNameAr: json['month']?['ar'] ?? '',
      monthNameEn: json['month']?['en'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'month': month,
      'year': year,
      'monthNameAr': monthNameAr,
      'monthNameEn': monthNameEn,
    };
  }

  factory HijriDate.fromJson(Map<String, dynamic> json) {
    return HijriDate(
      day: json['day'] ?? 0,
      month: json['month'] ?? 0,
      year: json['year'] ?? 0,
      monthNameAr: json['monthNameAr'] ?? '',
      monthNameEn: json['monthNameEn'] ?? '',
    );
  }
}

class PrayerTimesResponse {
  final List<DailyPrayerTimes> times;
  final PlaceInfo? place;

  PrayerTimesResponse({
    required this.times,
    this.place,
  });

  /// Aladhan tek gün yanıtından oluştur
  factory PrayerTimesResponse.fromAladhanSingle(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final dailyTimes = DailyPrayerTimes.fromAladhan(data);
    return PrayerTimesResponse(times: [dailyTimes]);
  }

  /// Aladhan aylık takvim yanıtından oluştur
  factory PrayerTimesResponse.fromAladhanCalendar(Map<String, dynamic> json) {
    final dataList = json['data'] as List<dynamic>;
    final times = dataList.map((dayData) {
      return DailyPrayerTimes.fromAladhan(dayData as Map<String, dynamic>);
    }).toList();
    return PrayerTimesResponse(times: times);
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
  final HijriDate? hijriDate;

  DailyPrayerTimes({
    required this.date,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    this.hijriDate,
  });

  /// Aladhan API yanıtından oluştur
  factory DailyPrayerTimes.fromAladhan(Map<String, dynamic> json) {
    final timings = json['timings'] as Map<String, dynamic>;
    final dateInfo = json['date'] as Map<String, dynamic>;
    final gregorian = dateInfo['gregorian'] as Map<String, dynamic>;
    final hijri = dateInfo['hijri'] as Map<String, dynamic>?;

    // Aladhan tarih formatı: DD-MM-YYYY → YYYY-MM-DD'ye çevir
    final aladhanDate = gregorian['date'] as String;
    final dateParts = aladhanDate.split('-');
    final isoDate = '${dateParts[2]}-${dateParts[1]}-${dateParts[0]}';

    return DailyPrayerTimes(
      date: isoDate,
      fajr: _cleanTime(timings['Fajr'] ?? ''),
      sunrise: _cleanTime(timings['Sunrise'] ?? ''),
      dhuhr: _cleanTime(timings['Dhuhr'] ?? ''),
      asr: _cleanTime(timings['Asr'] ?? ''),
      maghrib: _cleanTime(timings['Maghrib'] ?? ''),
      isha: _cleanTime(timings['Isha'] ?? ''),
      hijriDate: hijri != null ? HijriDate.fromAladhanJson(hijri) : null,
    );
  }

  /// Saat bilgisinden timezone kısmını temizle (örn: "05:06 (EET)" → "05:06")
  static String _cleanTime(String time) {
    final spaceIndex = time.indexOf(' ');
    return spaceIndex > 0 ? time.substring(0, spaceIndex) : time;
  }

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
