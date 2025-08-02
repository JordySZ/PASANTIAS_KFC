import 'package:flutter/material.dart';

enum EstadoTarjeta { pendiente, en_progreso, hecho }

class Tarjeta {
  final String? id;
  final String titulo;
  final String descripcion;
  final String miembro;
  final String tarea;
  final String tiempo;
  final DateTime? fechaInicio;
  final DateTime? fechaVencimiento;
  final EstadoTarjeta estado;
  final DateTime? fechaCompletado;
  final String idLista;
  final String tiendaAsignada;
  final String descripcionTienda;

  Tarjeta({
    this.id,
    required this.titulo,
    this.descripcion = '',
    this.miembro = '',
    this.tarea = '',
    this.tiempo = '',
    this.fechaInicio,
    this.fechaVencimiento,
    this.estado = EstadoTarjeta.pendiente,
    this.fechaCompletado,
    required this.idLista,
    this.tiendaAsignada = '',
    this.descripcionTienda = '',
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) '_id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'miembro': miembro,
      'tarea': tarea,
      'tiempo': tiempo,
      'fechaInicio': fechaInicio?.toUtc().toIso8601String(),
      'fechaVencimiento': fechaVencimiento?.toUtc().toIso8601String(),
      'estado': estado.name,
      'fechaCompletado': fechaCompletado?.toUtc().toIso8601String(),
      'idLista': idLista,
      'tiendaAsignada': tiendaAsignada,
      'descripcionTienda': descripcionTienda,
    };
  }

  factory Tarjeta.fromMap(Map<String, dynamic> map) {
    return Tarjeta(
      id: map['_id'] as String?,
      titulo: map['titulo'] as String,
      descripcion: map['descripcion'] as String? ?? '',
      miembro: map['miembro'] as String? ?? '',
      tarea: map['tarea'] as String? ?? '',
      tiempo: map['tiempo'] as String? ?? '',
      fechaInicio: map['fechaInicio'] != null
          ? DateTime.tryParse(map['fechaInicio'] as String)?.toLocal()
          : null,
      fechaVencimiento: map['fechaVencimiento'] != null
          ? DateTime.tryParse(map['fechaVencimiento'] as String)?.toLocal()
          : null,
      estado: EstadoTarjeta.values.firstWhere(
        (e) => e.name == (map['estado'] as String? ?? 'pendiente'),
        orElse: () => EstadoTarjeta.pendiente,
      ),
      fechaCompletado: map['fechaCompletado'] != null
          ? DateTime.tryParse(map['fechaCompletado'] as String)?.toLocal()
          : null,
      idLista: map['idLista'] as String,
      tiendaAsignada: map['tiendaAsignada'] as String? ?? '',
      descripcionTienda: map['descripcionTienda'] as String? ?? '',
    );
  }

  Tarjeta copyWith({
    String? id,
    String? titulo,
    String? descripcion,
    String? miembro,
    String? tarea,
    String? tiempo,
    DateTime? fechaInicio,
    DateTime? fechaVencimiento,
    EstadoTarjeta? estado,
    DateTime? fechaCompletado,
    String? idLista,
    String? tiendaAsignada,
    String? descripcionTienda,
  }) {
    return Tarjeta(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      miembro: miembro ?? this.miembro,
      tarea: tarea ?? this.tarea,
      tiempo: tiempo ?? this.tiempo,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      estado: estado ?? this.estado,
      fechaCompletado: fechaCompletado ?? this.fechaCompletado,
      idLista: idLista ?? this.idLista,
      tiendaAsignada: tiendaAsignada ?? this.tiendaAsignada,
      descripcionTienda: descripcionTienda ?? this.descripcionTienda,
    );
  }

  Map<String, dynamic> get tiempoRestanteCalculado {
    if (fechaVencimiento == null) {
      return {'text': '⏳ N/A', 'color': Colors.white70};
    }

    final DateTime vencimientoNoNula = fechaVencimiento!;
    final now = DateTime.now();
    final diff = vencimientoNoNula.difference(now);

    if (estado == EstadoTarjeta.hecho) {
      if (fechaCompletado != null) {
        final DateTime actualFechaCompletado = fechaCompletado!;
        final differenceWhenCompleted = actualFechaCompletado.difference(
          vencimientoNoNula,
        );

        final days = differenceWhenCompleted.abs().inDays;
        final hours = differenceWhenCompleted.abs().inHours.remainder(24);
        final minutes = differenceWhenCompleted.abs().inMinutes.remainder(60);

        String timeString = '';
        if (days > 0) {
          timeString += '$days día${days == 1 ? '' : 's'}';
        }
        if (hours > 0) {
          if (timeString.isNotEmpty) timeString += ', ';
          timeString += '$hours hora${hours == 1 ? '' : 's'}';
        }
        if (minutes > 0) {
          if (timeString.isNotEmpty) timeString += ', ';
          timeString += '$minutes minuto${minutes == 1 ? '' : 's'}';
        }

        if (actualFechaCompletado.isAfter(vencimientoNoNula)) {
          return {
            'text': 'Completado (con $timeString de retraso)',
            'color': const Color.fromARGB(255, 230, 42, 42),
          };
        } else {
          return {
            'text': 'Completado (con $timeString restantes)',
            'color': Colors.green,
          };
        }
      } else {
        return {
          'text': 'Completado (sin fecha de completado)',
          'color': Colors.green,
        };
      }
    }

    if (diff.isNegative) {
      final absDiff = diff.abs();
      final days = absDiff.inDays;
      final hours = absDiff.inHours.remainder(24);
      final minutes = absDiff.inMinutes.remainder(60);

      String expiredTime = '';
      if (days > 0) {
        expiredTime += '$days día${days == 1 ? '' : 's'}';
      }
      if (hours > 0) {
        if (expiredTime.isNotEmpty) expiredTime += ', ';
        expiredTime += '$hours hora${hours == 1 ? '' : 's'}';
      }
      if (minutes > 0) {
        if (expiredTime.isNotEmpty) expiredTime += ', ';
        expiredTime += '$minutes minuto${minutes == 1 ? '' : 's'}';
      }

      return {
        'text': expiredTime.isEmpty
            ? '⚠️ Vencido (hace menos de 1 minuto)'
            : '⚠️ Vencido hace $expiredTime',
        'color': Colors.red,
      };
    }

    final days = diff.inDays;
    final hours = diff.inHours.remainder(24);
    final minutes = diff.inMinutes.remainder(60);

    if (days > 0) {
      return {
        'text': '⏳ Faltan $days día${days == 1 ? '' : 's'}${hours > 0 ? ' y $hours hora${hours == 1 ? '' : 's'}' : ''}',
        'color': Colors.white70,
      };
    } else if (hours > 0) {
      return {
        'text': '⏳ Faltan $hours hora${hours == 1 ? '' : 's'}${minutes > 0 ? ' y $minutes minuto${minutes == 1 ? '' : 's'}' : ''}',
        'color': Colors.white70,
      };
    } else if (minutes > 0) {
      return {
        'text': '⏳ Faltan $minutes minuto${minutes == 1 ? '' : 's'}',
        'color': Colors.white70,
      };
    } else {
      return {'text': '⏳ Vence ahora', 'color': Colors.amber};
    }
  }
}