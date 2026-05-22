import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/prayer_times_model.dart';
import '../models/place_model.dart';

class VakitApiService {
  /// Aladhan API - Ücretsiz, uluslararası namaz vakitleri API'si
  static const String baseUrl = 'https://api.aladhan.com/v1';

  /// Diyanet İşleri Başkanlığı hesaplama metodu (method=13)
  static const int methodDiyanet = 13;

  /// 429 ve geçici hatalar için üstel geri çekilmeli GET.
  /// Retry-After header'ı varsa onu, yoksa exponential backoff kullanır.
  Future<http.Response?> _getWithRetry(
    Uri url, {
    int maxAttempts = 4,
  }) async {
    var delayMs = 1000;
    http.Response? lastResponse;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final response = await http.get(url);
        lastResponse = response;
        if (response.statusCode == 200) {
          return response;
        }
        if (response.statusCode == 429 || response.statusCode >= 500) {
          if (attempt == maxAttempts) return response;
          final retryAfter = response.headers['retry-after'];
          var waitMs = delayMs;
          if (retryAfter != null) {
            final seconds = int.tryParse(retryAfter);
            if (seconds != null) waitMs = seconds * 1000;
          }
          print(
              '⏳ ${response.statusCode} alındı, ${waitMs}ms bekleniyor (deneme $attempt/$maxAttempts)');
          await Future.delayed(Duration(milliseconds: waitMs));
          delayMs *= 2;
          continue;
        }
        return response;
      } catch (e) {
        if (attempt == maxAttempts) rethrow;
        print('⚠️ İstek hatası ($attempt/$maxAttempts): $e');
        await Future.delayed(Duration(milliseconds: delayMs));
        delayMs *= 2;
      }
    }
    return lastResponse;
  }

  /// Koordinatlardan namaz vakitleri (tek gün)
  Future<PrayerTimesResponse> getTimesForGPS({
    required double lat,
    required double lng,
    String? date,
    int days = 1,
    int timezoneOffset = 180,
    String calculationMethod = 'Turkey',
    String lang = 'tr',
  }) async {
    try {
      final now = DateTime.now();
      final dateParam = date ??
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // YYYY-MM-DD → DD-MM-YYYY (Aladhan formatı)
      final parts = dateParam.split('-');
      final aladhanDate = '${parts[2]}-${parts[1]}-${parts[0]}';

      final url = Uri.parse(
        '$baseUrl/timings/$aladhanDate?latitude=$lat&longitude=$lng&method=$methodDiyanet',
      );

      print('🕌 Aladhan API İsteği Gönderiliyor...');
      print('📍 URL: $url');
      print('📅 Tarih: $dateParam');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        print('✅ API Yanıtı Başarılı (200)');

        final data = json.decode(response.body);

        if (data['code'] != 200) {
          throw Exception('API hatası: ${data['status']}');
        }

        final result = PrayerTimesResponse.fromAladhanSingle(data);

        if (result.times.isNotEmpty) {
          final todayTimes = result.times.first;
          print('🕐 Fecr: ${todayTimes.fajr}');
          print('☀️ Güneş: ${todayTimes.sunrise}');
          print('🕐 Öğle: ${todayTimes.dhuhr}');
          print('🕐 İkindi: ${todayTimes.asr}');
          print('🌙 Akşam: ${todayTimes.maghrib}');
          print('⭐ Yatsı: ${todayTimes.isha}');

          if (todayTimes.hijriDate != null) {
            final h = todayTimes.hijriDate!;
            print('📿 Hicri: ${h.day} ${h.monthNameEn} ${h.year}');
          }
        }

        return result;
      } else {
        throw Exception('Vakitler yüklenemedi: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ API Hatası: $e');
      throw Exception('Vakit yükleme hatası: $e');
    }
  }

  /// Yıllık vakitleri çek (12 aylık, paralel istekler)
  Future<PrayerTimesResponse> getYearlyTimes({
    required double lat,
    required double lng,
    int? year,
    int timezoneOffset = 180,
    String calculationMethod = 'Turkey',
    String lang = 'tr',
  }) async {
    try {
      final targetYear = year ?? DateTime.now().year;

      print('');
      print('📅 ═══════════════════════════════════════════');
      print('📅 YILLIK VERİLER ÇEKİLİYOR (Aladhan API)...');
      print('📅 Yıl: $targetYear');
      print('📅 12 ay sıralı çekiliyor (rate limit koruması)...');
      print('📅 ═══════════════════════════════════════════');

      final allTimes = <DailyPrayerTimes>[];

      for (int i = 0; i < 12; i++) {
        final month = i + 1;
        final url = Uri.parse(
          '$baseUrl/calendar/$targetYear/$month?latitude=$lat&longitude=$lng&method=$methodDiyanet',
        );

        final response = await _getWithRetry(url);

        if (response != null && response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['code'] == 200) {
            final monthTimes =
                PrayerTimesResponse.fromAladhanCalendar(data);
            allTimes.addAll(monthTimes.times);
            print('✅ $month. ay: ${monthTimes.times.length} gün');
          } else {
            print('❌ $month. ay API hatası: ${data['status']}');
          }
        } else {
          print(
              '❌ $month. ay HTTP hatası: ${response?.statusCode ?? 'no response'}');
        }

        // Ardışık istekler arası küçük gecikme (rate limit nezaketi)
        if (i < 11) {
          await Future.delayed(const Duration(milliseconds: 250));
        }
      }

      print('');
      print('✅ Toplam ${allTimes.length} günlük veri başarıyla çekildi!');
      print('📅 ═══════════════════════════════════════════');
      print('');

      return PrayerTimesResponse(times: allTimes);
    } catch (e) {
      print('❌ Yıllık veri çekme hatası: $e');
      throw Exception('Yıllık vakit yükleme hatası: $e');
    }
  }

  /// Aladhan API'den Hicri tarih çek.
  /// /gToH genel astronomik dönüşümü Türkiye'de 1 gün geride kaldığı için
  /// /timings endpoint'i method=13 (Türkiye/Diyanet hesabı) ile çağrılır;
  /// response.data.date.hijri Türkiye takvimi ile hizalı döner.
  /// Konum gerekmediği için sabit Türkiye koordinatları (Ankara) kullanılır;
  /// Hicri tarih tüm Türkiye için aynı olduğundan koordinat sonucu etkilemez.
  Future<HijriDate?> getHijriDate(DateTime gregorian) async {
    const defaultLat = 39.9334; // Ankara
    const defaultLng = 32.8597;
    try {
      final dateStr =
          '${gregorian.day.toString().padLeft(2, '0')}-${gregorian.month.toString().padLeft(2, '0')}-${gregorian.year}';
      final url = Uri.parse(
        '$baseUrl/timings/$dateStr?latitude=$defaultLat&longitude=$defaultLng&method=$methodDiyanet',
      );

      print('📿 Hicri tarih API isteği: $url');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 200) {
          final hijriData = data['data']?['date']?['hijri'];
          if (hijriData != null) {
            final hijri = HijriDate.fromAladhanJson(hijriData);
            print(
                '✅ Hicri tarih: ${hijri.day} ${hijri.monthNameEn} ${hijri.year}');
            return hijri;
          }
        }
      }
    } catch (e) {
      print('❌ Hicri tarih API hatası: $e');
    }
    return null;
  }

  /// Şehir/yer arama
  /// Aladhan API'de yer arama yoktur, boş liste döner.
  /// Uygulama varsayılan koordinatları kullanacak.
  Future<List<PlaceModel>> searchPlaces(String query,
      {String lang = 'tr'}) async {
    return [];
  }
}
