import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../utils/colors.dart';
import '../utils/date_utils.dart' as app_date_utils;
import '../widgets/analog_clock.dart';

class VerticalClockPage extends StatefulWidget {
  const VerticalClockPage({super.key});

  @override
  State<VerticalClockPage> createState() => _VerticalClockPageState();
}

class _VerticalClockPageState extends State<VerticalClockPage> {
  late Timer _timer;
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
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer t) => _updateTime(),
    );
  }

  void _updateTime() {
    if (mounted) {
      final now = DateTime.now();
      setState(() {
        _timeString = DateFormat('HH:mm:ss').format(now);
        _dayName = DateFormat('EEEE', 'tr').format(now).toUpperCase();
        _hijriDateString = app_date_utils.DateUtils.calculateHijriDate(now);
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
    // Geniş moddaki (TV/Büyük ekran) büyük görünümü tüm cihazlarda (mobil dahil) koruyoruz
    // Ekran genişliğine göre dinamik ölçekleme yaparak mobilde de "büyük" görünmesini sağlıyoruz
    final screenWidth = MediaQuery.of(context).size.width;
    return (screenWidth / 400).clamp(1.0, 3.0);
  }

  @override
  Widget build(BuildContext context) {
    final scaleFactor = _getFontScaleFactor(context);
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final screenHeight = size.height;

    // Analog saat boyutu: Ekran genişliğinin %90'ı veya mevcut yüksekliğin yarısı (hangisi küçükse)
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
