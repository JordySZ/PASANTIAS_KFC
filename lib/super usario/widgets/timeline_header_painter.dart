import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'dart:ui' as ui; // Importación con prefijo

class TimelineHeaderPainter extends CustomPainter {
  final DateTime minDate;
  final int totalDays;
  final double pixelsPerDay;
  final double dateHeaderHeight;

  TimelineHeaderPainter({
    required this.minDate,
    required this.totalDays,
    required this.pixelsPerDay,
    required this.dateHeaderHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint linePaint = Paint()
      ..color = Colors.grey.shade200 // Líneas más suaves
      ..strokeWidth = 1.0;
    final Paint todayLinePaint = Paint()
      ..color =
          Colors.deepOrange.shade300 // Línea de hoy más vibrante pero amigable
      ..strokeWidth = 2.5; // Un poco más gruesa para destacar

    final TextPainter textPainter = TextPainter(
      textDirection: ui.TextDirection.ltr,
    );

    // Dibujar líneas verticales para cada día y texto de fecha
    for (int i = 0; i <= totalDays; i++) {
      final double x = i * pixelsPerDay;
      canvas.drawLine(Offset(x, 0), Offset(x, dateHeaderHeight), linePaint);

      final currentDay = minDate.add(Duration(days: i));
      final bool isToday = currentDay.year == DateTime.now().year &&
          currentDay.month == DateTime.now().month &&
          currentDay.day == DateTime.now().day;

      final TextStyle dateStyle = TextStyle(
        color: isToday
            ? Colors.deepPurple
            : Colors.grey.shade700, // Colores de texto más suaves
        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      );

      final String dayOfWeek = DateFormat('EEE').format(currentDay);
      final String dayOfMonth = DateFormat('dd').format(currentDay);

      textPainter.text = TextSpan(
        text: '$dayOfWeek\n$dayOfMonth',
        style: dateStyle,
      );
      textPainter.layout();
      textPainter.paint(
          canvas, Offset(x + (pixelsPerDay / 2) - (textPainter.width / 2), 5));
    }

    // Dibujar línea horizontal en la parte inferior del encabezado
    canvas.drawLine(Offset(0, dateHeaderHeight),
        Offset(size.width, dateHeaderHeight), linePaint);

    // Dibujar línea vertical para "hoy" en el encabezado
    final double todayX =
        DateTime.now().difference(minDate).inDays * pixelsPerDay;
    canvas.drawLine(
        Offset(todayX, 0), Offset(todayX, dateHeaderHeight), todayLinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
