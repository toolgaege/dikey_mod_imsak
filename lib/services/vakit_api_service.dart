import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/prayer_times_model.dart';
import '../models/place_model.dart';

class VakitApiService {
  static const String baseUrl = 'https://vakit.vercel.app/api';

  /// Şehir/yer arama
  Future<List<PlaceModel>> searchPlaces(String query, {String lang = 'tr'}) async {
    try {
      final url = Uri.parse('$baseUrl/searchPlaces?q=$query&lang=$lang');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => PlaceModel.fromJson(json)).toList();
      } else {
        throw Exception('Yerler yüklenemedi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Arama hatası: $e');
    }
  }

  /// GPS koordinatlarına yakın yerleri ara
  Future<List<PlaceModel>> nearByPlaces(
    double lat,
    double lng, {
    String lang = 'tr',
  }) async {
    try {
      final url = Uri.parse('$baseUrl/nearByPlaces?lat=$lat&lng=$lng&lang=$lang');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => PlaceModel.fromJson(json)).toList();
      } else {
        throw Exception('Yakın yerler yüklenemedi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Yakın yer arama hatası: $e');
    }
  }

  /// ID'den yer bilgileri
  Future<PlaceModel> getPlaceById(String id) async {
    try {
      final url = Uri.parse('$baseUrl/placeById?id=$id');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PlaceModel.fromJson(data);
      } else {
        throw Exception('Yer bilgisi yüklenemedi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Yer bilgisi hatası: $e');
    }
  }

  /// Koordinatlardan namaz vakitleri
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
      final dateParam = date ?? _getTodayDate();
      final url = Uri.parse(
        '$baseUrl/timesForGPS?lat=$lat&lng=$lng&date=$dateParam&days=$days&timezoneOffset=$timezoneOffset&calculationMethod=$calculationMethod&lang=$lang',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PrayerTimesResponse.fromJson(data);
      } else {
        throw Exception('Vakitler yüklenemedi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Vakit yükleme hatası: $e');
    }
  }

  /// Yerden namaz vakitleri (place ID ile)
  Future<PrayerTimesResponse> getTimesFromPlace({
    required String placeId,
    String? date,
    int days = 1,
    int timezoneOffset = 180,
    String calculationMethod = 'Turkey',
  }) async {
    try {
      final dateParam = date ?? _getTodayDate();
      final url = Uri.parse(
        '$baseUrl/timesFromPlace?id=$placeId&date=$dateParam&days=$days&timezoneOffset=$timezoneOffset&calculationMethod=$calculationMethod',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PrayerTimesResponse.fromJson(data);
      } else {
        throw Exception('Vakitler yüklenemedi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Vakit yükleme hatası: $e');
    }
  }

  /// Ülkelerin listesi
  Future<List<String>> getCountries() async {
    try {
      final url = Uri.parse('$baseUrl/countries');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<String>();
      } else {
        throw Exception('Ülkeler yüklenemedi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Ülke listesi hatası: $e');
    }
  }

  /// Bölgelerin listesi
  Future<List<String>> getRegions(String country) async {
    try {
      final url = Uri.parse('$baseUrl/regions?country=$country');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<String>();
      } else {
        throw Exception('Bölgeler yüklenemedi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Bölge listesi hatası: $e');
    }
  }

  /// Şehirlerin listesi
  Future<List<String>> getCities(String country, String region) async {
    try {
      final url = Uri.parse('$baseUrl/cities?country=$country&region=$region');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<String>();
      } else {
        throw Exception('Şehirler yüklenemedi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Şehir listesi hatası: $e');
    }
  }

  /// Bugünün tarihi (YYYY-MM-DD formatında)
  String _getTodayDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
