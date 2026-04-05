import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'utils/colors.dart';
import 'screens/vertical_clock_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr', null);
  await initializeDateFormatting('tr_TR', null);
  Intl.defaultLocale = 'tr';

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.primaryBlue,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const DikeySaatApp());
}

class DikeySaatApp extends StatelessWidget {
  const DikeySaatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sultan Mescidi Dikey Saat',
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
      ),
      home: const VerticalClockPage(),
    );
  }
}
