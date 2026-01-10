import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'utils/colors.dart';
import 'screens/vertical_clock_page.dart';
import 'screens/home_page.dart';
import 'services/storage_service.dart';

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

class DikeyModApp extends StatefulWidget {
  const DikeyModApp({super.key});

  @override
  State<DikeyModApp> createState() => _DikeyModAppState();
}

class _DikeyModAppState extends State<DikeyModApp> {
  final StorageService _storageService = StorageService();
  String _initialPage = 'home';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialPage();
  }

  Future<void> _loadInitialPage() async {
    final page = await _storageService.getDefaultPage();
    if (mounted) {
      setState(() {
        _initialPage = page;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        home: Scaffold(
          backgroundColor: AppColors.backgroundDark,
          body: Center(
              child: CircularProgressIndicator(color: AppColors.accentBlue)),
        ),
      );
    }

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
      home: _initialPage == 'vertical_clock'
          ? const VerticalClockPage()
          : const HomePage(),
    );
  }
}

// HomePage is now moved to screens/home_page.dart
