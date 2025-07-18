import 'package:flutter/material.dart';

class Process {
  final String? id;
  final String nombre_proceso; // Propiedad en tu clase Process
  final DateTime startDate; // Propiedad en tu clase Process
  final DateTime endDate; // Propiedad en tu clase Process
  final String? estado;
  final double? progress;

  Process({
    this.id,
    required this.nombre_proceso,
    required this.startDate,
    required this.endDate,
    this.estado = 'pendiente',
    this.progress,
  });

  // TU Process.fromJson (SIN CAMBIOS, como lo pediste):
  factory Process.fromJson(Map<String, dynamic> json) {
    print('FLUTTER DEBUG: Process.fromJson received JSON: $json');

    return Process(
      id: json['id'] as String? ?? json['_id'] as String?,
      nombre_proceso:
          (json['name'] as String?) ??
          (json['nombre_proceso'] as String), // CORREGIDO
      startDate: DateTime.parse(
        json['startDate'] as String? ?? json['fechaInicio'] as String,
      ),
      endDate: DateTime.parse(
        json['endDate'] as String? ?? json['fechaFin'] as String,
      ),
      estado:
          json['estado'] as String? ??
          json['status'] as String? ??
          'Desconocido',
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // toMap (Sin cambios, asumiendo que ya funciona para enviar al backend)
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre_proceso,
      'fechaInicio': startDate.toIso8601String(),
      'fechaFin': endDate.toIso8601String(),
      'estado': estado,
      // 'progress': progress, // Comentado si no lo espera tu backend en el PUT
    };
  }

  // toCreateJson (Sin cambios, asumiendo que ya funciona para crear)
  Map<String, dynamic> toCreateJson() {
    return {
      'nombre': nombre_proceso,
      'fechaInicio': startDate.toIso8601String(),
      'fechaFin': endDate.toIso8601String(),
      'estado': estado,
    };
  }

  // copyWith -- ¡ESTO ES LO QUE NECESITA COINCIDIR CON LOS CAMPOS DE TU CLASE!
  Process copyWith({
    String? id,
    String?
    nombre_proceso, // <-- Debe coincidir con 'nombre_proceso' de tu clase
    DateTime? startDate, // <-- Debe coincidir con 'startDate' de tu clase
    DateTime? endDate, // <-- Debe coincidir con 'endDate' de tu clase
    String? estado,
    double? progress,
  }) {
    return Process(
      id: id ?? this.id,
      nombre_proceso:
          nombre_proceso ??
          this.nombre_proceso, // Usar el parámetro 'nombre_proceso'
      startDate: startDate ?? this.startDate, // Usar el parámetro 'startDate'
      endDate: endDate ?? this.endDate, // Usar el parámetro 'endDate'
      estado: estado ?? this.estado,
      progress: progress ?? this.progress,
    );
  }
}
