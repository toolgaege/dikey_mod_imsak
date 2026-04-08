import '../models/prayer_times_model.dart';

class DateUtils {
  static const List<String> hijriMonths = [
    'Muharrem',
    'Safer',
    'Rebiülevvel',
    'Rebiülahir',
    'Cemaziyelevvel',
    'Cemaziyelahir',
    'Recep',
    'Şaban',
    'Ramazan',
    'Şevval',
    'Zilkade',
    'Zilhicce'
  ];

  static const List<String> rumiMonths = [
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
    'Ocak',
    'Şubat'
  ];

  /// API'den gelen HijriDate nesnesini Türkçe formatlı stringe çevirir
  static String formatHijriFromApi(HijriDate hijri) {
    final monthName = (hijri.month >= 1 && hijri.month <= 12)
        ? hijriMonths[hijri.month - 1]
        : '?';
    return '${hijri.day} (${hijri.month}) $monthName ${hijri.year}';
  }

  /// Lokal hesaplama ile Hicri tarih (API yokken fallback olarak kullanılır)
  static String calculateHijriDate(DateTime gregorian) {
    final julianDay = _toJulianDay(gregorian);
    final hijriDate = _julianToHijri(julianDay);

    return '${hijriDate['day']} (${hijriDate['month']}) ${hijriMonths[hijriDate['month']! - 1]} ${hijriDate['year']}';
  }

  /// Calculates Rumi date string from Gregorian date
  /// Rumi calendar is approximately 13 days behind Gregorian and starts year in March
  static String calculateRumiDate(DateTime gregorian) {
    // Simple approximation: Subtract 13 days
    final rumiDate = gregorian.subtract(const Duration(days: 13));

    // Rumi year calculation (starts in March)
    int rumiYear = rumiDate.year - 584;

    int monthIndex;
    if (rumiDate.month >= 3) {
      monthIndex = rumiDate.month - 3;
    } else {
      monthIndex = rumiDate.month + 9;
    }

    return '${rumiDate.day} (${rumiDate.month}) ${rumiMonths[monthIndex]} $rumiYear';
  }

  static int _toJulianDay(DateTime date) {
    final a = (14 - date.month) ~/ 12;
    final y = date.year + 4800 - a;
    final m = date.month + 12 * a - 3;

    return date.day +
        (153 * m + 2) ~/ 5 +
        365 * y +
        y ~/ 4 -
        y ~/ 100 +
        y ~/ 400 -
        32045;
  }

  static Map<String, int> _julianToHijri(int julianDay) {
    final l = julianDay - 1948440 + 10632;
    final n = (l - 1) ~/ 10631;
    final l2 = l - 10631 * n + 354;
    final j = ((10985 - l2) ~/ 5316) * ((50 * l2) ~/ 17719) +
        (l2 ~/ 5670) * ((43 * l2) ~/ 15238);
    final l3 = l2 -
        ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) -
        (j ~/ 16) * ((15238 * j) ~/ 43) +
        29;

    final month = ((24 * l3) ~/ 709);
    final day = l3 - ((709 * month) ~/ 24);
    final year = 30 * n + j - 30;

    return {'year': year, 'month': month, 'day': day};
  }
}
