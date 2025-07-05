import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
class Task {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final Color color; // Para diferenciar visualmente las tareas

  Task({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.color,
  });

  // Helper para crear tareas de ejemplo con colores más suaves
  static List<Task> getExampleTasks() {
    final now = DateTime.now();
    return [
      Task(
        id: '1',
        name: 'Diseño UI/UX',
        startDate: DateTime(now.year, now.month, now.day - 2),
        endDate: DateTime(now.year, now.month, now.day + 3),
        color: Colors.lightBlue.shade300, // Color más suave
      ),
      Task(
        id: '2',
        name: 'Desarrollo Backend',
        startDate: DateTime(now.year, now.month, now.day),
        endDate: DateTime(now.year, now.month, now.day + 7),
        color: Colors.lightGreen.shade300, // Color más suave
      ),
      Task(
        id: '3',
        name: 'Pruebas Integración',
        startDate: DateTime(now.year, now.month, now.day + 5),
        endDate: DateTime(now.year, now.month, now.day + 9),
        color: Colors.orange.shade300, // Color más suave
      ),
      Task(
        id: '4',
        name: 'Despliegue Producción',
        startDate: DateTime(now.year, now.month, now.day + 10),
        endDate: DateTime(now.year, now.month, now.day + 12),
        color: Colors.red.shade300, // Color más suave
      ),
      Task(
        id: '5',
        name: 'Marketing',
        startDate: DateTime(now.year, now.month, now.day + 1),
        endDate: DateTime(now.year, now.month, now.day + 15),
        color: Colors.purple.shade300, // Color más suave
      ),
      Task(
        id: '6',
        name: 'Documentación',
        startDate: DateTime(now.year, now.month, now.day + 8),
        endDate: DateTime(now.year, now.month, now.day + 11),
        color: Colors.teal.shade300, // Nuevo color
      ),
    ];
  }
}
