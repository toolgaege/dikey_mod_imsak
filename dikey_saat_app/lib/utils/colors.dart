import 'package:flutter/material.dart';

class AppColors {
  // Ana renkler - Orijinal APK'dan
  static const Color primaryDarkBlue =
      Color(0xFF0000AA); // Distinct blue from original TV mod
  static const Color secondaryDarkBlue =
      Color(0xFF0000AA); // Koyu lacivert (arka plan alt)
  static const Color accentBlue = Color(0xFF062C47); // Vurgu mavisi

  // Gradient renkler - Arka plan
  static const Color gradientStart = Color(0xFF0000AA);
  static const Color gradientMid = Color(0xFF0000AA);
  static const Color gradientEnd =
      Color(0xFF000088); // Slightly darker for subtle gradient

  // Bir sonraki vakit için koyu yeşil
  static const Color nextPrayerGreen = Color(0xFF005901); // İstenen: #005901
  static const Color nextPrayerGreenLight = Color(0xFF3A7A3C);

  // Namaz vakitleri için renkler (orijinal uygulamadaki gibi)
  static const Color fecr = Color(0xFF002F61); // Fecr - Arka planla uyumlu
  static const Color gunes = Color(0xFF002F61); // Güneş
  static const Color ogle = Color(0xFF005901); // Öğle - Yeşil
  static const Color ikindi = Color(0xFF002F61); // İkindi
  static const Color aksam = Color(0xFF002F61); // Akşam
  static const Color yatsi = Color(0xFF002F61); // Yatsı

  // Saat ikon renkleri
  static const Color clockIconBg =
      Color(0xFFB3D9F2); // Açık mavi (değişmedi, kontrast için iyi)
  static const Color clockIconHand =
      Color(0xFF001220); // İbre rengi (koyu arka planla uyumlu)

  // Yardımcı renkler
  static const Color white = Color(0xFFFFFFFF);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textWhiteSecondary = Color(0xFFE0E0E0);

  // Hava durumu ve bilgi renkleri
  static const Color weatherText = Color(0xFFB3D9F2);

  // Arka plan renkleri
  static const Color backgroundDark = Color(0xFF0000AA);
  static const Color cardBackground = Color(0xFF0000AA);

  // Yardımcı
  static const Color success = Color(0xFF2D5F2E);
  static const Color error = Color(0xFFE74C3C);
  static const Color warning = Color(0xFFF39C12);

  // Added for compatibility
  static const Color primaryBlue = accentBlue;
  static const Color textPrimary = textWhite;
}
