import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class AnalogClock extends StatefulWidget {
  final double size;
  final Color backgroundColor;
  final Color hourHandColor;
  final Color minuteHandColor;
  final Color secondHandColor;
  final Color numberColor;
  final Color tickColor;

  const AnalogClock({
    super.key,
    this.size = 200,
    this.backgroundColor = const Color(0xFF005901), // Green from image
    this.hourHandColor = Colors.white,
    this.minuteHandColor = Colors.white,
    this.secondHandColor = Colors.white,
    this.numberColor = Colors.white,
    this.tickColor = Colors.white,
  });

  @override
  State<AnalogClock> createState() => _AnalogClockState();
}

class _AnalogClockState extends State<AnalogClock> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        painter: _ClockPainter(
          context,
          DateTime.now(),
          backgroundColor: widget.backgroundColor,
          hourHandColor: widget.hourHandColor,
          minuteHandColor: widget.minuteHandColor,
          secondHandColor: widget.secondHandColor,
          numberColor: widget.numberColor,
          tickColor: widget.tickColor,
        ),
      ),
    );
  }
}

class _ClockPainter extends CustomPainter {
  final BuildContext context;
  final DateTime dateTime;
  final Color hourHandColor;
  final Color minuteHandColor;
  final Color secondHandColor;
  final Color numberColor;
  final Color tickColor;
  final Color backgroundColor;

  _ClockPainter(
    this.context,
    this.dateTime, {
    required this.backgroundColor,
    required this.hourHandColor,
    required this.minuteHandColor,
    required this.secondHandColor,
    required this.numberColor,
    required this.tickColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final center = Offset(centerX, centerY);
    final radius = min(centerX, centerY);

    // 1. Draw Outer Metallic Bezel
    final bezelPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.grey[300]!,
          Colors.grey[800]!,
          Colors.grey[400]!,
          Colors.grey[900]!,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, bezelPaint);

    // Inner Bezel Highlight Ring
    canvas.drawCircle(
      center,
      radius - 3,
      Paint()
        ..color = Colors.white.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // 2. Main Face with Deep Inner Shadow (The "Gömülü" effect)
    final faceRadius = radius * 0.94;
    final facePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          backgroundColor.withOpacity(0.95),
          backgroundColor,
          backgroundColor.withOpacity(0.85),
          Colors.black.withOpacity(0.7), // Deep shadow edge
        ],
        stops: const [0.0, 0.6, 0.9, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: faceRadius));
    canvas.drawCircle(center, faceRadius, facePaint);

    // Glass Reflection (Subtle highlight on top half)
    final reflectionPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(0.12),
          Colors.white.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(centerX - faceRadius, centerY - faceRadius,
          faceRadius * 2, faceRadius));
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(centerX, centerY - faceRadius * 0.45),
            width: faceRadius * 1.5,
            height: faceRadius * 0.9),
        reflectionPaint);

    // 3. Numbers with Depth
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final textStyle = TextStyle(
      color: numberColor,
      fontSize: faceRadius * 0.16,
      fontWeight: FontWeight.w900,
      shadows: [
        Shadow(
          blurRadius: 2,
          color: Colors.black.withOpacity(0.8),
          offset: const Offset(1, 1),
        ),
      ],
    );

    for (int i = 1; i <= 12; i++) {
      final angle = (i * 30 - 90) * pi / 180;
      final x = centerX + (faceRadius * 0.8) * cos(angle);
      final y = centerY + (faceRadius * 0.8) * sin(angle);

      textPainter.text = TextSpan(
        text: i.toString(),
        style: textStyle,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }

    // 4. Ticks
    for (int i = 0; i < 60; i++) {
      final angle = (i * 6 - 90) * pi / 180;
      final outerR = faceRadius * 0.98;
      final innerR = i % 5 == 0 ? faceRadius * 0.88 : faceRadius * 0.94;

      final p1 = Offset(
        centerX + innerR * cos(angle),
        centerY + innerR * sin(angle),
      );
      final p2 = Offset(
        centerX + outerR * cos(angle),
        centerY + outerR * sin(angle),
      );

      final tickPaint = Paint()
        ..color = i % 5 == 0 ? tickColor : tickColor.withOpacity(0.5)
        ..strokeWidth = i % 5 == 0 ? 3 : 1.5
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(p1, p2, tickPaint);
    }

    // 5. Hands with Realistic Shadows
    final hrHandLen = faceRadius * 0.55;
    final minHandLen = faceRadius * 0.8;
    final secHandLen = faceRadius * 0.9;

    final hourPaint = Paint()
      ..color = hourHandColor
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final minutePaint = Paint()
      ..color = minuteHandColor
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    final secondPaint = Paint()
      ..color = secondHandColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    void drawHandWithShadow(Canvas canvas, Offset p1, Offset p2,
        Paint handPaint, double elevation) {
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.4)
        ..strokeWidth = handPaint.strokeWidth
        ..strokeCap = handPaint.strokeCap
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, elevation);

      canvas.drawLine(p1 + Offset(elevation, elevation),
          p2 + Offset(elevation, elevation), shadowPaint);
      canvas.drawLine(p1, p2, handPaint);
    }

    // Hour
    final hourAngle =
        ((dateTime.hour % 12 * 30 + dateTime.minute * 0.5) - 90) * pi / 180;
    drawHandWithShadow(
        canvas,
        center,
        Offset(centerX + hrHandLen * cos(hourAngle),
            centerY + hrHandLen * sin(hourAngle)),
        hourPaint,
        4);

    // Minute
    final minuteAngle =
        ((dateTime.minute * 6 + dateTime.second * 0.1) - 90) * pi / 180;
    drawHandWithShadow(
        canvas,
        center,
        Offset(centerX + minHandLen * cos(minuteAngle),
            centerY + minHandLen * sin(minuteAngle)),
        minutePaint,
        3);

    // Second
    final secondAngle = (dateTime.second * 6 - 90) * pi / 180;
    final secTail = faceRadius * 0.15;
    drawHandWithShadow(
        canvas,
        center - Offset(secTail * cos(secondAngle), secTail * sin(secondAngle)),
        Offset(centerX + secHandLen * cos(secondAngle),
            centerY + secHandLen * sin(secondAngle)),
        secondPaint,
        2);

    // 6. Center Cap with Gloss
    final capPaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.grey[300]!, Colors.grey[900]!],
      ).createShader(Rect.fromCircle(center: center, radius: 10));

    // Cap Shadow
    canvas.drawCircle(
        center + const Offset(2, 2),
        11,
        Paint()
          ..color = Colors.black45
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    canvas.drawCircle(center, 10, capPaint);
    canvas.drawCircle(center, 4, Paint()..color = Colors.black87);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
