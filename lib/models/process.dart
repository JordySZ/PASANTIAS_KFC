// lib/models/process.dart (MODIFICADO para datos de MongoDB)
class Process {
  final String? id;
  final String name; // Este será 'titulo' de tu DB
  final DateTime startDate;
  final DateTime endDate;
  final String? description;

  final String? client; // Cliente
  final String? status; // Estado
  final double? progress; // Progreso

  Process({
    this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.description,
    this.client,
    this.status,
    this.progress,
  });

 factory Process.fromJson(Map<String, dynamic> json) {
    print('FLUTTER DEBUG: Process.fromJson received JSON: $json'); // PARA DEPURAR

    return Process(
      id: json['id'] as String?, // Postman muestra 'id', no '_id'
      name: json['name'] as String, // Postman muestra 'name'
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      description: json['description'] as String?, // Si tu backend lo envía

      // Estos campos DEBEN venir de tu backend. Si no vienen, serán null.
      // Puedes proporcionar valores por defecto si no están presentes.
      client: json['client'] as String? ?? 'N/A', // Si backend no lo envía
      status: json['status'] as String? ?? 'Desconocido', // Si backend no lo envía
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0, // Si backend no lo envía
    );
  }
  // ... (toJson y toCreateJson se mantienen igual o se ajustan si es necesario enviar estos nuevos campos al backend)
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'titulo': name, // Usar 'titulo' para el backend si es el campo principal
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'description': description,
      'client': client,
      'status': status,
      'progress': progress,
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'nombre': name, // Tu backend espera 'nombre' para la creación
      'fechaInicio': startDate.toIso8601String(),
      'fechaFin': endDate.toIso8601String(),
      'descripcion': description,
      // Si tu backend espera estos campos al crear, descomenta y usa los valores adecuados
      // 'cliente': client,
      // 'estado': status,
      // 'progreso': progress,
    };
  }
}