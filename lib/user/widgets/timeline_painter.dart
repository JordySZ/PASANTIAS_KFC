import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:login_app/user/models/task.dart';
import 'dart:ui' as ui;

class TimelinePainter extends CustomPainter {
  final List<Task> tasks;
  final DateTime minDate;
  final int totalDays;
  final double pixelsPerDay;
  final double rowHeight;

  TimelinePainter({
    required this.tasks,
    required this.minDate,
    required this.totalDays,
    required this.pixelsPerDay,
    required this.rowHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint gridLinePaint = Paint() // Cuadrícula más suave
      ..color = Colors.grey.shade100
      ..strokeWidth = 1.0;

    final Paint todayHighlightPaint =
        Paint() // Pintura para el sombreado de hoy
          ..color =
              Colors.red.shade50.withOpacity(0.5); // Sombreado pastel para hoy

    final TextPainter textPainter = TextPainter(
      textDirection: ui.TextDirection.ltr,
    );

    // Dibuja el sombreado para el día de hoy
    final double todayX =
        DateTime.now().difference(minDate).inDays * pixelsPerDay;
    canvas.drawRect(Rect.fromLTWH(todayX, 0, pixelsPerDay, size.height),
        todayHighlightPaint);

    // --- Las líneas de la cuadrícula horizontal para las filas de tareas ---
    for (int i = 0; i <= tasks.length; i++) {
      final double y = i * rowHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridLinePaint);
    }

    // --- Las líneas de la cuadrícula vertical para los días ---
    for (int i = 0; i <= totalDays; i++) {
      final double x = i * pixelsPerDay;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridLinePaint);
    }

    // --- Dibujar las barras de tareas ---
    for (int i = 0; i < tasks.length; i++) {
      final task = tasks[i];

      final double y = (i * rowHeight) + (rowHeight / 4);
      final int startDayOffset = task.startDate.difference(minDate).inDays;
      final double startX = startDayOffset * pixelsPerDay;
      final int durationDays =
          task.endDate.difference(task.startDate).inDays + 1;
      final double barWidth = durationDays * pixelsPerDay;

      // Dibujar la sombra de la barra (un poco más grande y desplazada)
      final RRect shadowRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(startX + 2, y + 2, barWidth, rowHeight / 2), // Desplazado
        const Radius.circular(6), // Bordes más redondeados
      );
      final Paint shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.1); // Sombra suave
      canvas.drawRRect(shadowRRect, shadowPaint);

      // Dibujar la barra de la tarea
      final Paint taskPaint = Paint()..color = task.color;
      final RRect taskRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(startX, y, barWidth, rowHeight / 2),
        const Radius.circular(6), // Bordes más redondeados
      );
      canvas.drawRRect(taskRRect, taskPaint);

      // Dibujar el texto de la tarea
      textPainter.text = TextSpan(
        text: task.name,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          shadows: [
            // Sombra de texto suave
            Shadow(
              blurRadius: 2.0,
              color: Colors.black38,
              offset: Offset(0.5, 0.5),
            ),
          ],
        ),
      );
      textPainter.layout(maxWidth: barWidth - 10);
      textPainter.paint(canvas,
          Offset(startX + 5, y + (rowHeight / 2 - textPainter.height) / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
