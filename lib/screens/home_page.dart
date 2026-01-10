import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../services/vakit_api_service.dart';
import '../services/storage_service.dart';
import '../models/place_model.dart';
import '../utils/colors.dart';
import '../utils/date_utils.dart' as app_date_utils;
import '../widgets/drawer_menu.dart';
// import 'vertical_clock_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final VakitApiService _apiService = VakitApiService();
  final StorageService _storageService = StorageService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late AnimationController _animationController;
  late Timer _timer;
  Timer? _dailyUpdateTimer;
  String _lastUpdateDate = '';

  String currentTime = '';
  String currentDate = '';
  String hijriDate = '';
  String nextPrayer = '';
  String currentPrayer = '';
  String timeToNextPrayer = '';

  // Test modu için
  bool _isTestMode = false;
  Duration _timeOffset = Duration.zero;
  DateTime get _now =>
      _isTestMode ? DateTime.now().add(_timeOffset) : DateTime.now();

  PlaceModel? selectedPlace;
  Map<String, String> prayerTimes = {};
  bool isLoading = false;
  bool _isLocaleInitialized = false;
  String? errorMessage;

  final Map<String, PrayerTimeInfo> prayerInfo = {
    'Fecr': PrayerTimeInfo('assets/images/fecr.svg', AppColors.fecr),
    'Güneş': PrayerTimeInfo('assets/images/gunes.svg', AppColors.gunes),
    'Öğle': PrayerTimeInfo('assets/images/ogle.svg', AppColors.ogle),
    'İkindi': PrayerTimeInfo('assets/images/ikindi.svg', AppColors.ikindi),
    'Akşam': PrayerTimeInfo('assets/images/aksam.svg', AppColors.aksam),
    'Yatsı': PrayerTimeInfo('assets/images/yatsi.svg', AppColors.yatsi),
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    initializeDateFormatting('tr', null).then((_) {
      if (mounted) {
        setState(() {
          _isLocaleInitialized = true;
        });
        _updateTime();
        _timer =
            Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());

        // Her 1 saatte bir yeni gün kontrolü yap
        _dailyUpdateTimer = Timer.periodic(
          const Duration(hours: 1),
          (_) => _checkAndUpdateIfNewDay(),
        );
      }
    });

    _loadSavedData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _timer.cancel();
    _dailyUpdateTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSavedData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      print('');
      print('🚀 ═══════════════════════════════════════════');
      print('🚀 UYGULAMA BAŞLATILIYOR...');
      print('🚀 ═══════════════════════════════════════════');

      final now = _now;
      final todayDate =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // Önce kayıtlı yeri yükle (offline mod için)
      selectedPlace = await _storageService.loadSelectedPlace();

      // Kayıtlı yer yoksa Denizli'yi ara (internet gerekir)
      if (selectedPlace == null) {
        print('⚠️ Kayıtlı yer yok, Denizli aranıyor...');
        await _searchAndSelectPlace('Denizli');
      } else {
        print('✅ Kayıtlı yer yüklendi: ${selectedPlace!.city}');
      }

      if (selectedPlace != null) {
        if (kIsWeb) {
          // Web platformunda veritabanı yok, her zaman API'den çek
          print('🌐 Web platformu - API\'den vakitler çekiliyor...');
          await _fetchPrayerTimes(selectedPlace!);
        } else {
          // Mobil/Desktop: Önce veritabanından dene
          final dbTimes = await _storageService.getPrayerTimesFromDB(
            todayDate,
            selectedPlace!.id,
          );

          if (dbTimes != null) {
            print('✅ Veritabanından bugünün vakitleri yüklendi (OFFLINE mod)');
            _lastUpdateDate = todayDate;
            setState(() {
              prayerTimes = dbTimes;
            });
          } else {
            print('⚠️ Veritabanında bugün için veri yok');
            _lastUpdateDate = '';
          }

          // Yıllık verileri kontrol et ve gerekirse çek
          await _checkAndSyncYearlyData();

          // Eski yılların verilerini temizle
          await _storageService.cleanOldYearData();

          // DB istatistiklerini göster
          await _storageService.printDBStats();
        }
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Veri yükleme hatası: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Yıllık verileri kontrol et ve gerekirse API'den çek
  Future<void> _checkAndSyncYearlyData() async {
    if (selectedPlace == null) return;

    try {
      final currentYear = _now.year;
      final hasData = await _storageService.hasYearDataInDB(
        currentYear,
        selectedPlace!.id,
      );

      if (!hasData) {
        print('');
        print('⚠️ $currentYear yılı için veritabanında yeterli veri yok!');
        print('📡 İnternetten yıllık veriler çekiliyor...');

        // Yıllık verileri API'den çek
        final response = await _apiService.getYearlyTimes(
          lat: selectedPlace!.latitude,
          lng: selectedPlace!.longitude,
          year: currentYear,
        );

        // Veritabanına kaydet
        final saved = await _storageService.saveYearlyPrayerTimes(
          response,
          selectedPlace!,
          currentYear,
        );

        if (saved) {
          print('✅ Yıllık veriler başarıyla kaydedildi!');
          print('🎉 Artık internet olmadan çalışabilir!');

          // Bugünün vakitlerini tekrar yükle
          final now = _now;
          final todayDate =
              '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
          final dbTimes = await _storageService.getPrayerTimesFromDB(
            todayDate,
            selectedPlace!.id,
          );

          if (dbTimes != null) {
            _lastUpdateDate = todayDate;
            setState(() {
              prayerTimes = dbTimes;
            });
          }
        }
      } else {
        print('✅ $currentYear yılı için veritabanında veri mevcut');
      }
    } catch (e) {
      print('❌ Yıllık veri senkronizasyon hatası: $e');
      print('⚠️ Offline modda çalışılamayabilir');
    }
  }

  Future<void> _searchAndSelectPlace(String query) async {
    try {
      final places = await _apiService.searchPlaces(query);
      if (places.isNotEmpty) {
        selectedPlace = places.first;
        await _storageService.saveSelectedPlace(selectedPlace!);
        await _fetchPrayerTimes(selectedPlace!);
      }
    } catch (e) {
      // İnternet yoksa varsayılan Denizli bilgisini kullan
      print('⚠️ API\'ye ulaşılamadı, varsayılan Denizli bilgisi kullanılıyor');
      selectedPlace = PlaceModel(
        id: '20392',
        country: 'Turkey',
        region: 'Denizli',
        city: 'Denizli',
        latitude: 37.77,
        longitude: 29.09,
      );
      await _storageService.saveSelectedPlace(selectedPlace!);
      print('✅ Varsayılan Denizli konumu ayarlandı (Offline mod)');
    }
  }

  Future<void> _fetchPrayerTimes(PlaceModel place) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final now = _now;
      final todayDate =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      print('');
      print('═══════════════════════════════════════════');
      print('🔄 Namaz Vakitleri Güncelleniyor...');
      print('📅 Bugünün Tarihi: $todayDate');
      print('📍 Konum: ${place.city}');
      print('═══════════════════════════════════════════');

      // Önce veritabanından dene (offline mod)
      final dbTimes = await _storageService.getPrayerTimesFromDB(
        todayDate,
        place.id,
      );

      if (dbTimes != null) {
        print('✅ Veritabanından vakitler yüklendi (OFFLINE)');
        setState(() {
          prayerTimes = dbTimes;
          _lastUpdateDate = todayDate;
          _calculateNextPrayer();
        });
      } else {
        print('⚠️ Veritabanında veri yok, API\'den çekiliyor...');

        final response = await _apiService.getTimesForGPS(
          lat: place.latitude,
          lng: place.longitude,
          days: 1,
          date: todayDate,
        );

        if (response.times.isNotEmpty) {
          final todayTimes = response.times.first.toTurkishMap();
          setState(() {
            prayerTimes = todayTimes;
            _lastUpdateDate = todayDate;
            _calculateNextPrayer();
          });

          await _storageService.cachePrayerTimes(todayTimes);

          print('');
          print('✅ Vakitler Başarıyla Güncellendi!');
          print('═══════════════════════════════════════════');
          print('');
        }
      }
    } catch (e) {
      if (prayerTimes.isEmpty) {
        setState(() {
          errorMessage = 'Vakitler yüklenemedi: $e';
        });
      } else {
        debugPrint('Offline mode: Using cached data. Error: $e');
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Yeni gün başladıysa vakitleri güncelle ve yıl değişimi kontrol et
  Future<void> _checkAndUpdateIfNewDay() async {
    final now = DateTime.now();
    final todayDate =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final currentTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    print('');
    print('🔍 ═══════════════════════════════════════════');
    print('🔍 OTOMATİK TARİH KONTROLÜ YAPILIYOR...');
    print('🔍 ═══════════════════════════════════════════');
    print('🕐 Mevcut Tarih ve Saat: $todayDate $currentTime');
    print(
        '📅 Son Güncelleme Tarihi: ${_lastUpdateDate.isEmpty ? "BOŞ (henüz güncellenmedi)" : _lastUpdateDate}');
    print('🔍 ═══════════════════════════════════════════');

    if (_lastUpdateDate != todayDate && selectedPlace != null) {
      print('');
      print('🌅 ═══════════════════════════════════════════');
      print('🌅 YENİ GÜN TESPİT EDİLDİ!');
      print('🌅 ═══════════════════════════════════════════');
      print(
          '📆 Eski Tarih: ${_lastUpdateDate.isEmpty ? "Yok (ilk çalıştırma)" : _lastUpdateDate}');
      print('📅 Yeni Tarih: $todayDate');
      print('🕐 Kontrol Zamanı: $currentTime');
      print('🔄 Namaz vakitleri otomatik güncelleniyor...');
      print('🌅 ═══════════════════════════════════════════');
      print('');

      // Yıl değişimi kontrolü
      if (_lastUpdateDate.isNotEmpty) {
        final lastYear = int.parse(_lastUpdateDate.split('-')[0]);
        final currentYear = now.year;

        if (lastYear != currentYear) {
          print('');
          print('🎊 ═══════════════════════════════════════════');
          print('🎊 YENİ YIL TESPİT EDİLDİ!');
          print('🎊 Eski Yıl: $lastYear → Yeni Yıl: $currentYear');
          print('🎊 ═══════════════════════════════════════════');
          print('📡 $currentYear yılının verileri çekiliyor...');

          await _checkAndSyncYearlyData();
        }
      }

      await _fetchPrayerTimes(selectedPlace!);
    } else if (_lastUpdateDate == todayDate) {
      print('');
      print('✅ ═══════════════════════════════════════════');
      print('✅ KONTROL SONUCU: Vakitler güncel!');
      print('✅ ═══════════════════════════════════════════');
      print('📌 Bugünün vakitleri zaten yüklü: $todayDate');
      print('⏭️  Sonraki kontrol: 1 saat sonra');
      print('✅ ═══════════════════════════════════════════');
      print('');
    } else if (selectedPlace == null) {
      print('');
      print('⚠️ ═══════════════════════════════════════════');
      print('⚠️ UYARI: Konum bilgisi bulunamadı!');
      print('⚠️ ═══════════════════════════════════════════');
      print('');
    }
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      currentTime = DateFormat('HH:mm:ss').format(now);
      if (_isLocaleInitialized) {
        currentDate = DateFormat('dd MMMM yyyy, EEEE', 'tr').format(now);
      }
      hijriDate = app_date_utils.DateUtils.calculateHijriDate(now);
    });
    _calculateNextPrayer();
  }

  void _calculateNextPrayer() {
    if (prayerTimes.isEmpty) return;

    final now = DateTime.now();
    DateTime? nextPrayerTime;
    String? foundNextPrayer;

    // Find the next prayer for today
    for (var entry in prayerTimes.entries) {
      final parts = entry.value.split(':');
      if (parts.length >= 2) {
        final prayerTime = DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );

        if (prayerTime.isAfter(now)) {
          // If we found a prayer later today, that's the one (since map is ordered)
          // Exception: If we have multiple, we want the *first* one that is after now
          // checks "closest" one. Since iterate in order, the first one we find is the next one.
          if (nextPrayerTime == null || prayerTime.isBefore(nextPrayerTime)) {
            nextPrayerTime = prayerTime;
            foundNextPrayer = entry.key;
          }
        }
      }
    }

    // If no prayer found for today (e.g. after Isha), get the first prayer of tomorrow
    if (foundNextPrayer == null && prayerTimes.isNotEmpty) {
      foundNextPrayer = prayerTimes.keys.first;
      final parts = prayerTimes[foundNextPrayer]!.split(':');
      nextPrayerTime = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      ).add(const Duration(days: 1));
    }

    if (foundNextPrayer != null && nextPrayerTime != null) {
      // Check if prayer interval changed (meaning a prayer time just passed)
      if (nextPrayer.isNotEmpty && nextPrayer != foundNextPrayer) {
        // _playAdhan();
      }

      final diff = nextPrayerTime.difference(now);
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      final seconds = diff.inSeconds % 60;

      final formattedTime =
          '${hours.toString()}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

      setState(() {
        nextPrayer = foundNextPrayer!;

        // Calculate current prayer (the one before next)
        final keys = prayerTimes.keys.toList();
        final nextIndex = keys.indexOf(nextPrayer);
        if (nextIndex > 0) {
          currentPrayer = keys[nextIndex - 1];
        } else {
          // If next is Fajr (0), current is Isha (last)
          currentPrayer = keys.last;
        }

        timeToNextPrayer = formattedTime;
      });
    }
  }

  /* Future<void> _playAdhan() async {
    try {
      final player = AudioPlayer();
      await player.play(AssetSource('audio/ezan.wav'));
    } catch (e) {
      debugPrint('Error playing adhan: $e');
    }
  } */

  // Ekran boyutuna göre font scale faktörü hesapla
  double _getFontScaleFactor(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;

    // Mobil cihaz kontrolü (genişlik < 600px)
    if (screenWidth < 600) {
      // Mobil: Daha küçük fontlar
      const referenceHeight = 800.0;
      final scale = screenHeight / referenceHeight;
      // Mobilde minimum 0.5, maksimum 0.85
      return scale.clamp(0.5, 0.85);
    } else if (screenWidth < 1024) {
      // Tablet: Orta boyut fontlar
      const referenceHeight = 800.0;
      final scale = screenHeight / referenceHeight;
      // Tablette minimum 0.7, maksimum 1.0
      return scale.clamp(0.7, 1.0);
    } else {
      // Desktop/Büyük ekran: Büyük fontlar
      const referenceHeight = 800.0;
      final scale = screenHeight / referenceHeight;
      // Büyük ekranlarda minimum 0.8, maksimum 1.2
      return scale.clamp(0.8, 1.2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: DrawerMenu(
        isTestMode: _isTestMode,
        onTestModeChanged: (value) {
          setState(() {
            _isTestMode = value;
            if (!value) {
              _timeOffset = Duration.zero;
            }
          });
          if (!value && selectedPlace != null) {
            _fetchPrayerTimes(selectedPlace!);
          }
        },
      ),
      drawerEnableOpenDragGesture: true,
      floatingActionButton: _isTestMode ? _buildFloatingActionButton() : null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.gradientStart,
              AppColors.gradientMid,
              AppColors.gradientEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              if (isLoading)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mosque,
                          color: AppColors.weatherText,
                          size: 64,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Vakitler Hazırlanıyor...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                )
              else if (errorMessage != null)
                _buildErrorWidget()
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildCurrentTimeCard(),
                    const SizedBox(height: 6),
                    if (nextPrayer.isNotEmpty) _buildNextPrayerCard(),
                    const SizedBox(height: 6),
                    if (prayerTimes.isEmpty)
                      _buildEmptyTimesCard()
                    else
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 8,
                            right: 8,
                            top: 2,
                            bottom: 8,
                          ),
                          child: Column(
                            children: [
                              ...prayerTimes.entries.map((entry) {
                                final isCurrent = entry.key == currentPrayer;
                                return Expanded(
                                  child: _buildPrayerTimeCard(
                                    entry.key,
                                    entry.value,
                                    isCurrent,
                                  ),
                                );
                              }).toList(),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              // Web-only menu button
              if (kIsWeb)
                Positioned(
                  top: 16,
                  left: 16,
                  child: IconButton(
                    icon: const Icon(
                      Icons.menu,
                      color: AppColors.white,
                      size: 32,
                    ),
                    onPressed: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage ?? 'Bir hata oluştu',
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 16, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadSavedData,
              icon: const Icon(Icons.refresh),
              label: const Text('Yeniden Dene'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTimeCard() {
    final scaleFactor = _getFontScaleFactor(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      child: Column(
        children: [
          Text(
            'Sultan Mescidi',
            style: TextStyle(
              fontSize: 42 * scaleFactor,
              fontWeight: FontWeight.w300,
              color: AppColors.white,
              fontFamily: 'Serif', // Elegant fallback font
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'DENİZLİ',
            style: TextStyle(
              fontSize: 24 * scaleFactor,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currentTime,
            style: TextStyle(
              fontSize: 68 * scaleFactor,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hijriDate,
            style: TextStyle(
              fontSize: 22 * scaleFactor,
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            currentDate,
            style: TextStyle(
              fontSize: 23 * scaleFactor,
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextPrayerCard() {
    final scaleFactor = _getFontScaleFactor(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.primaryDarkBlue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            'Sonraki Vakit: $nextPrayer',
            style: TextStyle(
              fontSize: 26 * scaleFactor,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Kalan Süre: $timeToNextPrayer',
            style: TextStyle(
              fontSize: 26 * scaleFactor,
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTimesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(
              Icons.access_time,
              size: 64,
              color: AppColors.primaryBlue,
            ),
            const SizedBox(height: 16),
            const Text(
              'Henüz namaz vakti yüklenmedi',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerTimeCard(String name, String time, bool isNext) {
    final scaleFactor = _getFontScaleFactor(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: 2,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: isMobile ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: isNext ? AppColors.nextPrayerGreen : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Saat ikonu
          Container(
            width: isMobile ? 36 : 44 * scaleFactor,
            height: isMobile ? 36 : 44 * scaleFactor,
            decoration: const BoxDecoration(
              color: AppColors.clockIconBg,
              shape: BoxShape.circle,
            ),
            child: SvgPicture.asset(
              prayerInfo[name]?.svgPath ?? 'assets/images/logo.svg',
              fit: BoxFit.contain,
              // colorFilter removed to show original SVG colors
            ),
          ),
          SizedBox(width: isMobile ? 10 : 18),
          // Vakit adı
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontSize: isMobile ? 22 : 30 * scaleFactor,
                fontWeight: FontWeight.w900,
                color: AppColors.white,
              ),
            ),
          ),
          // Vakit saati
          Text(
            time,
            style: TextStyle(
              fontSize: isMobile ? 26 : 34 * scaleFactor,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: _now,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppColors.primaryDarkBlue,
                  onPrimary: AppColors.white,
                  surface: AppColors.white,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          final now = DateTime.now();
          final todayStart = DateTime(now.year, now.month, now.day);
          final diff = picked.difference(todayStart);

          setState(() {
            _timeOffset = diff;
          });

          if (selectedPlace != null) {
            await _fetchPrayerTimes(selectedPlace!);
          }
        }
      },
      child: const Icon(Icons.calendar_today),
    );
  }
}

class PrayerTimeInfo {
  final String svgPath;
  final Color color;

  PrayerTimeInfo(this.svgPath, this.color);
}
