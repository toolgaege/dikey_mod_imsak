import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/vakit_api_service.dart';
import 'services/storage_service.dart';
import 'models/place_model.dart';
import 'utils/colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr', null);
  await initializeDateFormatting('tr_TR', null);
  Intl.defaultLocale = 'tr';

  // Tüm yönlendirmelere izin ver (iPad tam ekran için)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    // DeviceOrientation.landscapeLeft,
    // DeviceOrientation.landscapeRight,
  ]);

  // Sistem UI ayarları - Koyu mavi tema
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.primaryBlue,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const DikeyModApp());
}

class DikeyModApp extends StatelessWidget {
  const DikeyModApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dikey Mod Sultan Mescidi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primaryDarkBlue,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryDarkBlue,
          primary: AppColors.primaryDarkBlue,
          secondary: AppColors.accentBlue,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: AppColors.backgroundDark,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primaryDarkBlue,
          foregroundColor: AppColors.white,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primaryDarkBlue,
          foregroundColor: AppColors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryDarkBlue,
            foregroundColor: AppColors.white,
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final VakitApiService _apiService = VakitApiService();
  final StorageService _storageService = StorageService();

  late AnimationController _animationController;
  late Timer _timer;

  String currentTime = '';
  String currentDate = '';
  String hijriDate = '';
  String nextPrayer = '';
  String currentPrayer = '';
  String timeToNextPrayer = '';

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
      }
    });

    _loadSavedData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _timer.cancel();
    super.dispose();
  }

  Future<void> _loadSavedData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final cachedTimes = await _storageService.loadCachedPrayerTimes();
      if (cachedTimes != null) {
        setState(() {
          prayerTimes = cachedTimes;
        });
      }

      // Always force Denizli
      await _searchAndSelectPlace('Denizli');
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

  Future<void> _searchAndSelectPlace(String query) async {
    try {
      final places = await _apiService.searchPlaces(query);
      if (places.isNotEmpty) {
        selectedPlace = places.first;
        await _storageService.saveSelectedPlace(selectedPlace!);
        await _fetchPrayerTimes(selectedPlace!);
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Yer arama hatası: $e';
      });
    }
  }

  Future<void> _fetchPrayerTimes(PlaceModel place) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await _apiService.getTimesForGPS(
        lat: place.latitude,
        lng: place.longitude,
        days: 1,
      );

      if (response.times.isNotEmpty) {
        final todayTimes = response.times.first.toTurkishMap();
        setState(() {
          prayerTimes = todayTimes;
          _calculateNextPrayer();
        });

        await _storageService.cachePrayerTimes(todayTimes);
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

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      currentTime = DateFormat('HH:mm:ss').format(now);
      if (_isLocaleInitialized) {
        currentDate = DateFormat('dd MMMM yyyy, EEEE', 'tr').format(now);
      }
      hijriDate = _calculateHijriDate(now);
    });
    _calculateNextPrayer();
  }

  String _calculateHijriDate(DateTime gregorian) {
    // Miladi tarihi Hicri takvime çevir (yaklaşık hesaplama)
    final julianDay = _toJulianDay(gregorian);
    final hijriDate = _julianToHijri(julianDay);

    final hijriMonths = [
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

    return '${hijriDate['day']} ${hijriMonths[hijriDate['month']! - 1]} ${hijriDate['year']}';
  }

  int _toJulianDay(DateTime date) {
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

  Map<String, int> _julianToHijri(int julianDay) {
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

  Future<void> _playAdhan() async {
    try {
      final player = AudioPlayer();
      await player.play(AssetSource('audio/ezan.wav'));
    } catch (e) {
      debugPrint('Error playing adhan: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryBlue,
                  ),
                )
              : errorMessage != null
                  ? _buildErrorWidget()
                  : Column(
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
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              itemCount: prayerTimes.length,
                              itemBuilder: (context, index) {
                                final entry =
                                    prayerTimes.entries.elementAt(index);
                                final isCurrent = entry.key == currentPrayer;
                                return _buildPrayerTimeCard(
                                  entry.key,
                                  entry.value,
                                  isCurrent,
                                );
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      child: Column(
        children: [
          Text(
            'Sultan Mescidi',
            style: GoogleFonts.greatVibes(
              fontSize: 42,
              fontWeight: FontWeight.w500,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'DENİZLİ',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currentTime,
            style: const TextStyle(
              fontSize: 68,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hijriDate,
            style: const TextStyle(
              fontSize: 22,
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            currentDate,
            style: const TextStyle(
              fontSize: 23,
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextPrayerCard() {
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
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Kalan Süre: $timeToNextPrayer',
            style: const TextStyle(
              fontSize: 26,
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isNext ? AppColors.nextPrayerGreen : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Saat ikonu
          Container(
            width: 44,
            height: 44,
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
          const SizedBox(width: 18),
          // Vakit adı
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: AppColors.white,
              ),
            ),
          ),
          // Vakit saati
          Text(
            time,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class PrayerTimeInfo {
  final String svgPath;
  final Color color;

  PrayerTimeInfo(this.svgPath, this.color);
}
