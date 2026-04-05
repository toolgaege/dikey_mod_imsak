import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/colors.dart';
import '../utils/date_utils.dart' as app_date_utils;
import '../models/place_model.dart';
import '../services/vakit_api_service.dart';
import '../services/storage_service.dart';
import '../widgets/analog_clock.dart';

class VerticalClockPage extends StatefulWidget {
  const VerticalClockPage({super.key});

  @override
  State<VerticalClockPage> createState() => _VerticalClockPageState();
}

class _VerticalClockPageState extends State<VerticalClockPage> {
  late Timer _timer;
  final VakitApiService _apiService = VakitApiService();
  final StorageService _storageService = StorageService();
  String _timeString = '';
  String _dateString = '';
  String _hijriDateString = '';
  String _rumiDateString = '';
  String _dayName = '';
  String? _cachedApiHijriDate;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('tr', null);
    _fetchHijriDate();
    _updateTime();
    _timer =
        Timer.periodic(const Duration(seconds: 1), (Timer t) => _updateTime());
  }

  /// Varsayılan konum (Denizli)
  static final _defaultPlace = PlaceModel(
    id: '20392',
    country: 'Turkey',
    region: 'Denizli',
    city: 'Denizli',
    latitude: 37.77,
    longitude: 29.09,
  );

  /// Hicri tarihi yükle: DB → API → lokal hesaplama
  Future<void> _fetchHijriDate() async {
    // 1. Cache/DB'den dene (yıllık veri varsa burada bulur)
    final cached = await _storageService.loadCachedHijriDate();
    if (cached != null && mounted) {
      setState(() {
        _cachedApiHijriDate = cached;
        _hijriDateString = cached;
      });
      // Arka planda yıllık veri kontrolü yap
      _checkAndSyncYearlyData();
      return;
    }

    // 2. DB'de yıllık veri yoksa API'den çek
    await _checkAndSyncYearlyData();

    // 3. Yıllık sync sonrası tekrar DB'den dene
    final afterSync = await _storageService.loadCachedHijriDate();
    if (afterSync != null && mounted) {
      setState(() {
        _cachedApiHijriDate = afterSync;
        _hijriDateString = afterSync;
      });
      return;
    }

    // 4. Yıllık da yoksa tek günlük API isteği
    try {
      final now = DateTime.now();
      final hijri = await _apiService.getHijriDate(now);
      if (hijri != null && mounted) {
        final hijriStr = app_date_utils.DateUtils.formatHijriFromApi(hijri);
        final todayStr =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        await _storageService.cacheHijriDate(hijriStr, todayStr);
        setState(() {
          _cachedApiHijriDate = hijriStr;
          _hijriDateString = hijriStr;
        });
      }
    } catch (e) {
      print('⚠️ Hicri tarih API hatası, lokal hesaplama kullanılıyor: $e');
    }
  }

  /// Yıllık verileri kontrol et ve gerekirse API'den çek (Hicri tarihlerle birlikte)
  Future<void> _checkAndSyncYearlyData() async {
    if (kIsWeb) return;

    try {
      final currentYear = DateTime.now().year;
      final hasData = await _storageService.hasYearDataInDB(
        currentYear,
        _defaultPlace.id,
      );

      if (!hasData) {
        print('📡 Yıllık veriler çekiliyor (Hicri tarihlerle birlikte)...');

        final response = await _apiService.getYearlyTimes(
          lat: _defaultPlace.latitude,
          lng: _defaultPlace.longitude,
          year: currentYear,
        );

        await _storageService.saveYearlyPrayerTimes(
          response,
          _defaultPlace,
          currentYear,
        );

        print('✅ Yıllık veriler kaydedildi (${response.times.length} gün + Hicri tarihler)');
      }
    } catch (e) {
      print('⚠️ Yıllık veri senkronizasyon hatası: $e');
    }
  }

  void _updateTime() {
    if (mounted) {
      final now = DateTime.now();
      setState(() {
        _timeString = DateFormat('HH:mm:ss').format(now);
        _dayName = DateFormat('EEEE', 'tr').format(now).toUpperCase();

        // H: API'den gelen Hicri tarih, yoksa lokal hesaplama
        _hijriDateString = _cachedApiHijriDate ??
            app_date_utils.DateUtils.calculateHijriDate(now);

        _dateString = DateFormat('d (M) MMMM yyyy', 'tr').format(now);
        _rumiDateString = app_date_utils.DateUtils.calculateRumiDate(now);
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  double _getFontScaleFactor(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return (screenWidth / 400).clamp(1.0, 3.0);
  }

  @override
  Widget build(BuildContext context) {
    final scaleFactor = _getFontScaleFactor(context);
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;

    final safeClockSize = min(screenWidth * 0.9, screenHeight * 0.45);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Container(
        width: screenWidth,
        height: screenHeight,
        decoration: const BoxDecoration(color: AppColors.backgroundDark),
        child: Column(
          children: [
            // Üst Kısım: Metin Bilgileri
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: FittedBox(
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      // Dijital Saat
                      Text(
                        _timeString,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 100 * scaleFactor,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Roboto',
                          letterSpacing: 2,
                        ),
                      ),
                      // Gün Adı
                      Text(
                        _dayName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 45 * scaleFactor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Tarih Bilgileri
                      SizedBox(
                        width: 400 * scaleFactor,
                        child: Column(
                          children: [
                            _buildDateRow('H:', _hijriDateString, scaleFactor),
                            const SizedBox(height: 12),
                            _buildDateRow('M:', _dateString, scaleFactor),
                            const SizedBox(height: 12),
                            _buildDateRow('R:', _rumiDateString, scaleFactor),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),

            // Alt Kısım: Analog Saat
            Expanded(
              flex: 5,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 30, top: 10),
                  child: AnalogClock(
                    size: safeClockSize,
                    backgroundColor: const Color(0xFF006633),
                    tickColor: Colors.white,
                    numberColor: Colors.white,
                    hourHandColor: Colors.white,
                    minuteHandColor: Colors.white,
                    secondHandColor: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRow(String label, String value, double scaleFactor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60 * scaleFactor,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 32 * scaleFactor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: Colors.white,
              fontSize: 32 * scaleFactor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
