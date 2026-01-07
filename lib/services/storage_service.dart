import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/place_model.dart';

class StorageService {
  static const String _keySelectedPlace = 'selected_place';
  static const String _keyCachedTimes = 'cached_times';
  static const String _keyCacheDate = 'cache_date';

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
        
        // Önbellek bugüne aitse kullan
        if (cached.year == now.year &&
            cached.month == now.month &&
            cached.day == now.day) {
          final jsonString = prefs.getString(_keyCachedTimes);
          if (jsonString != null) {
            return Map<String, String>.from(json.decode(jsonString));
          }
        }
      }
    } catch (e) {
      debugPrint('Önbellek yükleme hatası: $e');
    }
    return null;
  }

  /// Tüm verileri temizle
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
