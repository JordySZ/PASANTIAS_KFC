// lib/models/lista_datos.dart
class ListaDatos {
  final String id; // El ID único de la lista, asignado por el backend
  String titulo; // El título editable de la lista


  ListaDatos({required this.id, required this.titulo,});

  // Constructor para crear ListaDatos desde un mapa (ej. desde el backend)
  factory ListaDatos.fromMap(Map<String, dynamic> map) {
    return ListaDatos(
      id: map['_id'] as String, // Asume que el backend usa '_id' para las listas
      titulo: map['titulo'] as String,

    );
  }

  // Método para convertir ListaDatos a un mapa (ej. para enviar al backend)
  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'titulo': titulo,

    };
  }

  // Método copyWith para crear una nueva instancia con valores modificados
  ListaDatos copyWith({
    String? id,
    String? titulo,
    int? orden, // **NUEVO: Permitir copiar el orden**
  }) {
    return ListaDatos(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,

    );
  }
}