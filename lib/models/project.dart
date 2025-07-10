class Project {
  final String name;
  final String client;
  final String status;
  final String startDate;
  final String endDate;
  final double progress;

  Project({
    required this.name,
    this.client = 'N/A',
    this.status = 'Activo',
    this.startDate = 'N/A',
    this.endDate = 'N/A',
    this.progress = 0.0,
  });

  // Factory constructor para crear un Project desde un mapa JSON
  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      name: json['nombre'] as String, // Ajusta 'nombre' si tu API usa otra clave
      client: json['cliente'] as String? ?? 'N/A', // Ajusta 'cliente'
      status: json['estado'] as String? ?? 'Activo', // Ajusta 'estado'
      startDate: json['fechaInicio'] as String? ?? 'N/A', // Ajusta 'fechaInicio'
      endDate: json['fechaFin'] as String? ?? 'N/A', // Ajusta 'fechaFin'
      progress: (json['progreso'] as num?)?.toDouble() ?? 0.0, // Ajusta 'progreso'
    );
  }
}