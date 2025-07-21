import 'package:flutter/material.dart';

class Task {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final double progress; // <--- AÑADE ESTA LÍNEA
  final Color color;

  Task({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.progress, // <--- AÑADE ESTA LÍNEA AL CONSTRUCTOR
    required this.color,
  });

  // Este método de ejemplos lo puedes mantener o eliminar, ya no afecta el error.
  static List<Task> getExampleTasks() {
    return [
      // ... tus tareas de ejemplo ...
    ];
  }
}
