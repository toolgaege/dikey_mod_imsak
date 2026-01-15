import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../utils/colors.dart';
import '../utils/date_utils.dart' as app_date_utils;
import '../widgets/analog_clock.dart';
import '../widgets/drawer_menu.dart';

class VerticalClockPage extends StatefulWidget {
  const VerticalClockPage({super.key});

  @override
  State<VerticalClockPage> createState() => _VerticalClockPageState();
}

class _VerticalClockPageState extends State<VerticalClockPage> {
  late Timer _timer;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _timeString = '';
  String _dateString = '';
  String _hijriDateString = '';
  String _rumiDateString = '';
  String _dayName = '';

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('tr', null);
    _updateTime();
    _timer =
        Timer.periodic(const Duration(seconds: 1), (Timer t) => _updateTime());
  }

  void _updateTime() {
    if (mounted) {
      final now = DateTime.now();
      setState(() {
        _timeString = DateFormat('HH:mm:ss').format(now);
        // CUMA
        _dayName = DateFormat('EEEE', 'tr').format(now).toUpperCase();

        // H: 11 (11) Zilkade 1446
        _hijriDateString = app_date_utils.DateUtils.calculateHijriDate(now);

        // M: 9 (5) Mayıs 2025
        _dateString = DateFormat('d (M) MMMM yyyy', 'tr').format(now);

        // R: 26 (4) Nisan 1441
        _rumiDateString = app_date_utils.DateUtils.calculateRumiDate(now);
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  // Ekran boyutuna göre font scale faktörü hesapla
  double _getFontScaleFactor(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenHeight = size.height;

    // Tüm cihazlar için ortak ölçekleme
    const referenceHeight = 800.0;
    final scale = screenHeight / referenceHeight;

    // Minimum 0.8, maksimum 2.0 (TV'ler için geniş aralık)
    return scale.clamp(0.8, 2.0);
  }

  @override
  Widget build(BuildContext context) {
    final scaleFactor = _getFontScaleFactor(context);
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;

    // Split the screen exactly in two
    final halfHeight = screenHeight / 2;

    // Calculate a safe clock size based on available screen space
    final safeSize = min(screenWidth, halfHeight);
    // Fallback and cap to reasonable values
    final finalClockSize = safeSize.clamp(100.0, 1200.0);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundDark,
      drawer: DrawerMenu(
        isTestMode: false,
        onTestModeChanged: (_) {},
      ),
      drawerEnableOpenDragGesture: true,
      body: Stack(
        children: [
          // Background Color
          Positioned.fill(
            child: Container(color: AppColors.backgroundDark),
          ),
          // Content divided in two halves
          SingleChildScrollView(
            physics:
                const NeverScrollableScrollPhysics(), // Prevent web scroll bounce
            child: Column(
              children: [
                // Top Half: Text Info
                SizedBox(
                  height: halfHeight,
                  width: screenWidth,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: screenWidth,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Digital Clock
                              Text(
                                _timeString,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 110 * scaleFactor,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Roboto',
                                ),
                              ),
                              // Day Name
                              Text(
                                _dayName,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 50 * scaleFactor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Date Info
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: Column(
                                  children: [
                                    _buildDateRow(
                                        'H:', _hijriDateString, scaleFactor),
                                    const SizedBox(height: 10),
                                    _buildDateRow(
                                        'M:', _dateString, scaleFactor),
                                    const SizedBox(height: 10),
                                    _buildDateRow(
                                        'R:', _rumiDateString, scaleFactor),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Bottom Half: Analog Clock
                SizedBox(
                  height: halfHeight,
                  width: screenWidth,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: AnalogClock(
                        size: finalClockSize,
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
          // Web-only menu button
          if (kIsWeb)
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: const Icon(
                  Icons.menu,
                  color: Colors.white,
                  size: 32,
                ),
                onPressed: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateRow(String label, String value, double scaleFactor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80 * scaleFactor, // Increased from 40
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 40 * scaleFactor, // Increased from 24
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
              fontSize: 40 * scaleFactor, // Increased from 24
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
