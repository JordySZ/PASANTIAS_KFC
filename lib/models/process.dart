// lib/models/process.dart
import 'package:flutter/material.dart'; // Puede que no sea estrictamente necesario si no usas widgets de Material directamente en el modelo, pero es común.

class Process {
  final String? id;
  final String nombre_proceso;
  final DateTime startDate;
  final DateTime endDate;
  final String? estado;
  final double? progress;

  Process({
    this.id,
    required this.nombre_proceso,
    required this.startDate,
    required this.endDate,
    this.estado = 'pendiente', // Valor por defecto para el estado si no se proporciona
    this.progress,
  });

  /// Crea una instancia de Process desde un mapa JSON recibido del backend.
  ///
  /// **¡IMPORTANTE!** Asegúrate de que las claves (`'id'`, `'name'`, `'startDate'`, etc.)
  /// coincidan con los nombres de los campos que tu backend envía en las respuestas GET.
  factory Process.fromJson(Map<String, dynamic> json) {
    print('FLUTTER DEBUG: Process.fromJson received JSON: $json');

    return Process(
      // Mapea el ID. Tu backend puede usar '_id' o 'id'. Ajusta según sea necesario.
      id: json['id'] as String? ?? json['_id'] as String?,
      // Mapea el nombre del proceso. Puede que tu backend use 'name', 'nombre', o 'titulo'.
      // Utiliza una cascada para intentar varias claves, o sé específico si solo usa una.
      nombre_proceso: json['name'] as String,
      // Mapea la fecha de inicio. Tu backend puede usar 'startDate' o 'fechaInicio'.
      startDate: DateTime.parse(json['startDate'] as String? ?? json['fechaInicio'] as String),
      // Mapea la fecha de fin. Tu backend puede usar 'endDate' o 'fechaFin'.
      endDate: DateTime.parse(json['endDate'] as String? ?? json['fechaFin'] as String),
      // Mapea el estado. Tu backend puede usar 'estado' o 'status'. Ajusta si es diferente.
      estado: json['estado'] as String? ?? json['status'] as String? ?? 'Desconocido',
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Convierte la instancia de Process a un mapa JSON para enviar al backend (ej. para PUT/actualizaciones).
  ///
  /// **¡IMPORTANTE!** Las claves en este mapa deben coincidir exactamente con
  /// los nombres de los campos que tu backend espera para una operación de ACTUALIZACIÓN.
  /// Tu backend podría usar 'titulo' para el nombre y 'status' para el estado.
  Map<String, dynamic> toMap() {
    return {
      // Si tu backend espera el ID en el cuerpo para la actualización (raro si va en URL), descomenta o ajusta:
      // '_id': id,

      // Usa la clave que tu backend espera para el nombre en las ACTUALIZACIONES.
      // Ej: 'name': name, o 'nombre': name, o como tenías: 'titulo': name,
      'titulo': nombre_proceso, // <--- Ajusta 'titulo' si tu backend espera otro nombre (ej. 'name' o 'nombre')
      'startDate': startDate.toIso8601String(), // <--- Ajusta 'startDate' si tu backend espera otro nombre (ej. 'fechaInicio')
      'endDate': endDate.toIso8601String(),     // <--- Ajusta 'endDate' si tu backend espera otro nombre (ej. 'fechaFin')

      // Usa la clave que tu backend espera para el estado en las ACTUALIZACIONES.
      // Ej: 'estado': estado, o 'status': estado,
      'estado': estado, // <--- Ajusta 'estado' si tu backend espera otro nombre (ej. 'status')
      'progress': progress,
    };
  }

  /// Convierte la instancia de Process a un mapa JSON para enviar al backend (ej. para POST/creación).
  ///
  /// **¡IMPORTANTE!** Las claves en este mapa deben coincidir exactamente con
  /// los nombres de los campos que tu backend espera para una operación de CREACIÓN.
  /// Tu backend podría usar 'nombre' para el nombre y 'estado' para el estado.
  Map<String, dynamic> toCreateJson() {
    return {
      // Usa la clave que tu backend espera para el nombre en las CREACIONES.
      'nombre': nombre_proceso, // <--- Ajusta 'nombre' si tu backend espera otro nombre (ej. 'name' o 'titulo')
      'fechaInicio': startDate.toIso8601String(), // <--- Ajusta 'fechaInicio' si tu backend espera otro nombre (ej. 'startDate')
      'fechaFin': endDate.toIso8601String(),     // <--- Ajusta 'fechaFin' si tu backend espera otro nombre (ej. 'endDate')

      // Usa la clave que tu backend espera para el estado en las CREACIONES.
      'estado': estado, // <--- Ajusta 'estado' si tu backend espera otro nombre (ej. 'status')
    };
  }

  /// Crea una nueva instancia de Process con valores modificados.
  /// Permite actualizar selectivamente propiedades del objeto sin mutar el original.
  Process copyWith({
    String? id,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    String? estado,
    double? progress,
  }) {
    return Process(
      id: id ?? this.id,
      nombre_proceso: name ?? this.nombre_proceso,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      estado: estado ?? this.estado,
      progress: progress ?? this.progress,
    );
  }
}