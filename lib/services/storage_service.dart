import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import '../models/place_model.dart';
import '../models/prayer_time_db_model.dart';
import '../models/prayer_times_model.dart';
import 'database_service.dart';

class StorageService {
  static const String _keySelectedPlace = 'selected_place';
  static const String _keyCachedTimes = 'cached_times';
  static const String _keyCacheDate = 'cache_date';
  static const String _keyLastYearSync = 'last_year_sync';

  final DatabaseService _dbService = DatabaseService();

  /// Seçili yeri kaydet
  Future<void> saveSelectedPlace(PlaceModel place) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(place.toJson());
    await prefs.setString(_keySelectedPlace, jsonString);
  }

  /// Seçili yeri yükle
  Future<PlaceModel?> loadSelectedPlace() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keySelectedPlace);
      if (jsonString != null) {
        final jsonData = json.decode(jsonString);
        return PlaceModel.fromJson(jsonData);
      }
    } catch (e) {
      debugPrint('Yer yükleme hatası: $e');
    }
    return null;
  }

  /// Vakitleri önbelleğe al
  Future<void> cachePrayerTimes(Map<String, String> times) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(times);
    await prefs.setString(_keyCachedTimes, jsonString);
    await prefs.setString(_keyCacheDate, DateTime.now().toIso8601String());
  }

  /// Önbellekteki vakitleri yükle
  Future<Map<String, String>?> loadCachedPrayerTimes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheDate = prefs.getString(_keyCacheDate);

      if (cacheDate != null) {
        final cached = DateTime.parse(cacheDate);
        final now = DateTime.now();

        print('📂 Cache tarihi: ${cached.year}-${cached.month.toString().padLeft(2, '0')}-${cached.day.toString().padLeft(2, '0')}');
        print('📅 Bugünün tarihi: ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}');

        // Önbellek bugüne aitse kullan
        if (cached.year == now.year &&
            cached.month == now.month &&
            cached.day == now.day) {
          final jsonString = prefs.getString(_keyCachedTimes);
          if (jsonString != null) {
            print('✅ Cache güncel, önbellekten yükleniyor');
            return Map<String, String>.from(json.decode(jsonString));
          }
        } else {
          print('⚠️ Cache ESKİ! Yeni vakitler çekilecek.');
        }
      } else {
        print('⚠️ Cache bulunamadı, ilk defa vakitler çekilecek.');
      }
    } catch (e) {
      debugPrint('❌ Önbellek yükleme hatası: $e');
    }
    return null;
  }

  /// Cache tarihini al
  Future<String?> getCacheDate() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCacheDate);
  }

  /// Yıllık verileri veritabanına kaydet
  Future<bool> saveYearlyPrayerTimes(
    PrayerTimesResponse response,
    PlaceModel place,
    int year,
  ) async {
    // Web platformunda veritabanı çalışmaz
    if (kIsWeb) {
      print('⚠️ Web platformunda veritabanı desteklenmez, sadece SharedPreferences kullanılıyor');
      return false;
    }

    try {
      final placeName = place.city.isNotEmpty ? place.city : place.getShortName();

      print('');
      print('💾 ═══════════════════════════════════════════');
      print('💾 YILLIK VERİLER VERİTABANINA KAYDEDİLİYOR...');
      print('💾 Yıl: $year');
      print('💾 Yer: $placeName');
      print('💾 Toplam: ${response.times.length} gün');
      print('💾 ═══════════════════════════════════════════');

      final prayerTimesDB = response.times.map((dailyTime) {
        final dateParts = dailyTime.date.split('-');
        return PrayerTimeDB(
          date: dailyTime.date,
          year: int.parse(dateParts[0]),
          month: int.parse(dateParts[1]),
          day: int.parse(dateParts[2]),
          fajr: dailyTime.fajr,
          sunrise: dailyTime.sunrise,
          dhuhr: dailyTime.dhuhr,
          asr: dailyTime.asr,
          maghrib: dailyTime.maghrib,
          isha: dailyTime.isha,
          placeId: place.id,
          placeName: placeName,
          latitude: place.latitude,
          longitude: place.longitude,
          createdAt: DateTime.now(),
        );
      }).toList();

      final insertedCount = await _dbService.insertPrayerTimes(prayerTimesDB);

      // Son senkronizasyon yılını kaydet
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyLastYearSync, year);

      print('✅ $insertedCount kayıt veritabanına eklendi!');
      print('💾 ═══════════════════════════════════════════');
      print('');

      return insertedCount > 0;
    } catch (e) {
      print('❌ Veritabanı kaydetme hatası: $e');
      return false;
    }
  }

  /// Veritabanından bugünün namaz vakitlerini getir
  Future<Map<String, String>?> getPrayerTimesFromDB(
    String date,
    String placeId,
  ) async {
    // Web platformunda veritabanı çalışmaz
    if (kIsWeb) {
      return null;
    }

    try {
      final prayerTime = await _dbService.getPrayerTimeByDate(date, placeId);
      if (prayerTime != null) {
        print('✅ Veritabanından vakitler yüklendi: $date');
        return prayerTime.toTurkishMap();
      }
      return null;
    } catch (e) {
      print('❌ Veritabanı okuma hatası: $e');
      return null;
    }
  }

  /// Veritabanında bu yıl için veri var mı kontrol et
  Future<bool> hasYearDataInDB(int year, String placeId) async {
    // Web platformunda veritabanı çalışmaz
    if (kIsWeb) {
      return false;
    }

    try {
      return await _dbService.hasDataForYear(year, placeId);
    } catch (e) {
      print('❌ Yıl kontrolü hatası: $e');
      return false;
    }
  }

  /// Son senkronize edilen yılı al
  Future<int?> getLastSyncYear() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyLastYearSync);
  }

  /// Eski yılların verilerini temizle
  Future<void> cleanOldYearData() async {
    // Web platformunda veritabanı çalışmaz
    if (kIsWeb) {
      return;
    }

    try {
      final currentYear = DateTime.now().year;
      await _dbService.deleteOldYearData(currentYear);
    } catch (e) {
      print('❌ Eski veri temizleme hatası: $e');
    }
  }

  /// Veritabanı istatistiklerini göster
  Future<void> printDBStats() async {
    // Web platformunda veritabanı çalışmaz
    if (kIsWeb) {
      print('ℹ️ Web platformunda veritabanı kullanılamaz');
      return;
    }

    await _dbService.printDatabaseStats();
  }

  /// Tüm verileri temizle
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Web platformunda veritabanı yok
    if (!kIsWeb) {
      await _dbService.clearAllData();
    }
  }
}
