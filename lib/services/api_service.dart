// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:login_app/models/tarjeta.dart';
import 'package:login_app/models/lista_datos.dart';
import 'package:login_app/models/process.dart'; // ¡Asegúrate de importar tu modelo Process!

// Esta clase GraficaConfiguracion está bien como está, no necesita cambios.
class GraficaConfiguracion {
  String? id;
  String tipoGrafica;
  String filtro;
  String periodo;

  GraficaConfiguracion({
    this.id,
    required this.tipoGrafica,
    required this.filtro,
    this.periodo = "Semana pasada",
  });

  factory GraficaConfiguracion.fromMap(Map<String, dynamic> map) {
    return GraficaConfiguracion(
      id: map['_id'],
      tipoGrafica: map['tipoGrafica'],
      filtro: map['filtro'],
      periodo: map['periodo'] ?? "Semana pasada",
    );
  }

  Map<String, dynamic> toMap() {
    return {'tipoGrafica': tipoGrafica, 'filtro': filtro, 'periodo': periodo};
  }
}

class ApiService {
  // **IMPORTANTE**: Cambia 'http://localhost:3000' por la URL real de tu backend.
  // Si estás emulando Android en tu PC, usa 'http://10.0.2.2:3000'.
  // Si estás usando un dispositivo físico, usa la IP de tu PC en la red local.
  final String _baseUrl = 'http://localhost:3000'; // O tu IP/URL del backend

  /// Obtiene una lista de los nombres de todos los procesos disponibles.
  Future<List<String>> getProcessNames() async {
    print('FLUTTER DEBUG API: getProcessNames - Solicitando nombres de procesos de: $_baseUrl/procesos');
    try {
      final response = await http.get(Uri.parse('$_baseUrl/procesos'));

      print('FLUTTER DEBUG API: getProcessNames - StatusCode: ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic decodedBody = json.decode(response.body);

        if (decodedBody is List) {
          // Si el backend devuelve directamente una lista de strings (nombres)
          return decodedBody.map((name) => name.toString()).toList();
        } else if (decodedBody is Map && decodedBody.containsKey('procesos')) {
          // Si el backend devuelve un objeto con una clave 'procesos' que contiene la lista
          final List<dynamic> processesJson = decodedBody['procesos'];
          return processesJson.map((p) => p['nombre'].toString()).toList();
        } else {
          print('FLUTTER ERROR API: getProcessNames - Formato de respuesta inesperado.');
          return [];
        }
      } else {
        print('FLUTTER ERROR API: getProcessNames - Error al obtener nombres de procesos: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('FLUTTER ERROR API: getProcessNames - Excepción en la solicitud GET de nombres de procesos: $e');
      return [];
    }
  }

  /// Obtiene una lista de todos los objetos Process (con todos sus detalles).
  Future<List<Process>> getProcesses() async {
    final url = Uri.parse('$_baseUrl/procesos');
    print('FLUTTER DEBUG API: getProcesses - Solicitando todos los procesos de: $url');

    try {
      final response = await http.get(url);
      print('FLUTTER DEBUG API: getProcesses - StatusCode: ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic decodedBody = jsonDecode(response.body);
        List<dynamic> data;

        if (decodedBody is Map && decodedBody.containsKey('procesos')) {
          data = decodedBody['procesos'];
        } else if (decodedBody is List) {
          data = decodedBody;
        } else {
          print('API ERROR: Formato de respuesta inesperado para getProcesses. Body: ${response.body}');
          return [];
        }
        return data.map((json) => Process.fromJson(json)).toList();
      } else {
        print('API ERROR getProcesses: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('API EXCEPTION getProcesses: $e');
      return [];
    }
  }


  /// Obtiene los detalles de un proceso específico por su nombre (el nombre de la colección).
  ///
  /// Devuelve un objeto [Process] si se encuentra, o `null` si no existe o hay un error.
  Future<Process?> getProcessByName(String processName) async {
    // Codificamos el nombre del proceso para que sea seguro en la URL
    final url = Uri.parse('$_baseUrl/procesos/${Uri.encodeComponent(processName)}');
    print('FLUTTER DEBUG API: getProcessByName - Solicitando detalles del proceso: $url');
    try {
      final response = await http.get(url);
      print('FLUTTER DEBUG API: getProcessByName - StatusCode: ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> processJson = jsonDecode(response.body);
        return Process.fromJson(processJson);
      } else if (response.statusCode == 404) {
        print('FLUTTER ERROR API: getProcessByName - Proceso no encontrado (404 Not Found): $processName');
        return null;
      } else {
        print('FLUTTER ERROR API: getProcessByName - Error al obtener el proceso: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('FLUTTER ERROR API: getProcessByName - Excepción al obtener proceso por nombre: $e');
      return null;
    }
  }

  /// Obtiene las listas de datos (ListaDatos) para un proceso específico.
  Future<List<ListaDatos>> getLists(String processName) async {
    print('FLUTTER DEBUG API: getLists - Solicitando listas para proceso: $_baseUrl/procesos/$processName/lists');
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/procesos/${Uri.encodeComponent(processName)}/lists'),
      );
      print('FLUTTER DEBUG API: getLists - StatusCode: ${response.statusCode}, Body: ${response.body}');
      if (response.statusCode == 200) {
        List<dynamic> listsJson = json.decode(response.body);
        return listsJson.map((json) => ListaDatos.fromMap(json)).toList();
      } else {
        print('FLUTTER ERROR API: getLists - Error al obtener listas: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('FLUTTER ERROR API: getLists - Excepción en la solicitud GET de listas: $e');
      return [];
    }
  }

  /// Crea una nueva lista para un proceso específico.
  Future<ListaDatos?> createList(String processName, ListaDatos list) async {
    print('FLUTTER DEBUG API: createList - Solicitando crear lista en: $_baseUrl/procesos/$processName/lists con datos: ${json.encode(list.toMap())}');
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/procesos/${Uri.encodeComponent(processName)}/lists'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(list.toMap()),
      );
      print('FLUTTER DEBUG API: createList - StatusCode: ${response.statusCode}, Body: ${response.body}');
      if (response.statusCode == 201) {
        return ListaDatos.fromMap(json.decode(response.body));
      } else {
        print('FLUTTER ERROR API: createList - Error al crear lista: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('FLUTTER ERROR API: createList - Excepción en la solicitud POST de listas: $e');
      return null;
    }
  }

  /// Actualiza una lista existente en un proceso específico.
  Future<ListaDatos?> updateList(String processName, ListaDatos list) async {
    print('FLUTTER DEBUG API: updateList - Solicitando actualizar lista en: $_baseUrl/procesos/$processName/lists/${list.id}');
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/procesos/${Uri.encodeComponent(processName)}/lists/${list.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(list.toMap()),
      );
      print('FLUTTER DEBUG API: updateList - StatusCode: ${response.statusCode}, Body: ${response.body}');
      if (response.statusCode == 200) {
        return ListaDatos.fromMap(json.decode(response.body));
      } else {
        print('FLUTTER ERROR API: updateList - Error al actualizar lista: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('FLUTTER ERROR API: updateList - Excepción en la solicitud PUT de listas: $e');
      return null;
    }
  }

  /// Elimina una lista específica de un proceso dado.
  /// Necesita el nombre del proceso y el ID de la lista a eliminar.
  Future<bool> deleteList(String processName, String listId) async {
    print('FLUTTER DEBUG API: deleteList - Solicitando eliminar lista $listId del proceso $processName: $_baseUrl/procesos/$processName/lists/$listId');
    try {
      final response = await http.delete(
        Uri.parse(
          '$_baseUrl/procesos/${Uri.encodeComponent(processName)}/lists/${Uri.encodeComponent(listId)}',
        ), // ¡Importante: Codificar ambos, processName y listId!
        headers: {'Content-Type': 'application/json'},
      );

      print('FLUTTER DEBUG API: deleteList - StatusCode: ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        // 200 OK o 204 No Content son códigos de éxito comunes para DELETE
        print('Lista $listId eliminada correctamente del proceso $processName.');
        return true;
      } else if (response.statusCode == 404) {
        print('FLUTTER ERROR API: deleteList - Lista $listId o proceso $processName no encontrado (404 Not Found).');
        return false;
      } else {
        print('FLUTTER ERROR API: deleteList - Error al eliminar lista: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('FLUTTER ERROR API: deleteList - Excepción en la solicitud DELETE de lista: $e');
      return false;
    }
  }


  /// Obtiene todas las tarjetas de una colección de proceso específica.
  Future<List<Tarjeta>> getCards(String collectionName) async {
    print('FLUTTER DEBUG API: getCards - Solicitando tarjetas de: $_baseUrl/procesos/$collectionName/cards');
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/procesos/${Uri.encodeComponent(collectionName)}/cards',
        ),
      );
      print('FLUTTER DEBUG API: getCards - StatusCode: ${response.statusCode}, Body: ${response.body}');
      if (response.statusCode == 200) {
        List<dynamic> cardsJson = json.decode(response.body);
        return cardsJson.map((json) => Tarjeta.fromMap(json)).toList();
      } else {
        print('FLUTTER ERROR API: getCards - Error al obtener tarjetas: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('FLUTTER ERROR API: getCards - Excepción en la solicitud GET de tarjetas: $e');
      return [];
    }
  }

  /// Crea una nueva tarjeta en una colección de proceso específica.
  Future<Tarjeta?> createCard(String collectionName, Tarjeta card) async {
    print('FLUTTER DEBUG API: createCard - Solicitando crear tarjeta en: $_baseUrl/procesos/$collectionName/cards');
    try {
      final Map<String, dynamic> body = card.toMap();
      print('FLUTTER DEBUG API: createCard - Cuerpo a enviar: ${json.encode(body)}');

      final response = await http.post(
        Uri.parse(
          '$_baseUrl/procesos/${Uri.encodeComponent(collectionName)}/cards',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      print('FLUTTER DEBUG API: createCard - StatusCode de respuesta: ${response.statusCode}');
      print('FLUTTER DEBUG API: createCard - Cuerpo de respuesta: ${response.body}');

      if (response.statusCode == 201) {
        print('FLUTTER DEBUG API: createCard - Tarjeta creada exitosamente, parseando respuesta.');
        return Tarjeta.fromMap(json.decode(response.body));
      } else {
        print('FLUTTER ERROR API: createCard - El servidor no devolvió 201. Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('FLUTTER ERROR API: createCard - Excepción en la solicitud POST de tarjetas: $e');
      return null;
    }
  }

  /// Actualiza una tarjeta existente en una colección de proceso específica.
  Future<Tarjeta?> updateCard(String collectionName, Tarjeta card) async {
    print('FLUTTER DEBUG API: updateCard - Solicitando actualizar tarjeta en: $_baseUrl/procesos/$collectionName/cards/${card.id}');
    try {
      final Map<String, dynamic> body = card.toMap();
      print('FLUTTER DEBUG API: updateCard - Cuerpo a enviar: ${json.encode(body)}');
      final response = await http.put(
        Uri.parse(
          '$_baseUrl/procesos/${Uri.encodeComponent(collectionName)}/cards/${card.id}',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      print('FLUTTER DEBUG API: updateCard - StatusCode: ${response.statusCode}, Body: ${response.body}');
      if (response.statusCode == 200) {
        return Tarjeta.fromMap(json.decode(response.body));
      } else {
        print('FLUTTER ERROR API: updateCard - Error al actualizar tarjeta: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('FLUTTER ERROR API: updateCard - Excepción en la solicitud PUT de tarjetas: $e');
      return null;
    }
  }

  /// Elimina una tarjeta de una colección de proceso específica.
  Future<bool> deleteCard(String collectionName, String cardId) async {
    print('FLUTTER DEBUG API: deleteCard - Solicitando eliminar tarjeta de: $_baseUrl/procesos/$collectionName/cards/$cardId');
    try {
      final response = await http.delete(
        Uri.parse(
          '$_baseUrl/procesos/${Uri.encodeComponent(collectionName)}/cards/${Uri.encodeComponent(cardId)}', // ¡Codificar también cardId!
        ),
      );
      print('FLUTTER DEBUG API: deleteCard - StatusCode: ${response.statusCode}, Body: ${response.body}');
      if (response.statusCode == 200) {
        return true;
      } else {
        print('FLUTTER ERROR API: deleteCard - Error al eliminar tarjeta: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('FLUTTER ERROR API: deleteCard - Excepción en la solicitud DELETE de tarjetas: $e');
      return false;
    }
  }


  /// Crea un nuevo proceso (colección/documento) en el backend.
  ///
  /// Acepta un objeto [Process] que contiene el nombre, fecha de inicio, fecha de fin y estado.
  /// Devuelve el nombre de la colección creada si es exitoso, o `null` en caso de error.
  Future<String?> createProcess(Process newProcessData) async {
    final url = Uri.parse('$_baseUrl/procesos');
    try {
      // Usamos newProcessData.toCreateJson() para el cuerpo de la solicitud POST.
      // Asegúrate de que este método en tu modelo Process genere el JSON que tu backend espera para la creación.
      print('FLUTTER DEBUG API: createProcess - Enviando datos para nuevo proceso: ${newProcessData.toCreateJson()} a $url');
      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(newProcessData.toCreateJson()),
      );

      print('FLUTTER DEBUG API: createProcess - StatusCode: ${response.statusCode}');
      print('FLUTTER DEBUG API: createProcess - Response Body: ${response.body}');

      if (response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final String? collectionName = responseData['nombreColeccion'] as String?;
        print('FLUTTER DEBUG API: createProcess - nombreColeccion extraído: $collectionName');
        return collectionName;
      } else if (response.statusCode == 409) {
        print('FLUTTER DEBUG API: createProcess - La colección ya existe (409 Conflict).');
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final String? collectionName = responseData['nombreColeccion'] as String?;
        return collectionName;
      } else {
        print('FLUTTER ERROR API: createProcess - El servidor no devolvió 201 ni 409. Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('FLUTTER ERROR API: createProcess - Excepción al crear/seleccionar proceso: $e');
      return null;
    }
  }

 
  /// Actualiza un proceso (colección/documento) existente en el backend.
  ///
  /// Toma un objeto [Process] con los datos actualizados. El nombre del proceso
  /// se usa como identificador en la URL.
  /// Devuelve `true` si la actualización fue exitosa, `false` en caso contrario.
Future<Process?> updateProcess(Process process) async {
    // Usamos el nombre del proceso como identificador en la URL para la actualización.
    // Asegúrate de que tu backend espera el nombre del proceso en la URL para las operaciones PUT.
    final url = Uri.parse('$_baseUrl/procesos/${Uri.encodeComponent(process.nombre_proceso)}'); // <-- ¡Asegúrate que sea process.name, no process.nombre_proceso!
  
  try {
    // Usamos process.toMap() para el cuerpo de la solicitud PUT.
    // Asegúrate de que este método en tu modelo Process genere el JSON que tu backend espera para la actualización.
    final Map<String, dynamic> bodyToSend = process.toMap(); // Captura el body que se envía
    print('FLUTTER DEBUG API: updateProcess - Enviando datos para actualizar proceso: ${jsonEncode(bodyToSend)} a $url');
    
    final response = await http.put(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(bodyToSend), // Asegúrate de que tu modelo Process tenga un toMap() para la actualización
    );

    print('FLUTTER DEBUG API: updateProcess - StatusCode: ${response.statusCode}');
    print('FLUTTER DEBUG API: updateProcess - Response Body: ${response.body}');

    if (response.statusCode == 200) {
      // ¡CRÍTICO! Parsear la respuesta del backend para obtener el objeto actualizado
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      final Process updatedProcess = Process.fromJson(responseData); // <-- ¡Parsear el JSON devuelto!
      
      print('FLUTTER DEBUG API: updateProcess - Proceso "${updatedProcess.nombre_proceso}" actualizado exitosamente.');
      return updatedProcess; // <-- ¡DEVOLVER EL OBJETO ACTUALIZADO DEL BACKEND!
    } else if (response.statusCode == 404) {
      print('FLUTTER ERROR API: updateProcess - Proceso "${process.nombre_proceso}" no encontrado (404 Not Found).');
      return null;
    } else {
      print('FLUTTER ERROR API: updateProcess - Error al actualizar proceso: ${response.statusCode} - ${response.body}');
      return null;
    }
  } catch (e) {
    print('FLUTTER ERROR API: updateProcess - Excepción al actualizar proceso: $e');
    return null;
  }
}
  /// Elimina un proceso (colección/documento) específico del backend.
  /// `processName` es el identificador del proceso a eliminar.
  /// Devuelve `true` si la eliminación fue exitosa, `false` en caso contrario.
  Future<bool> deleteProcess(String processName) async {
    print('FLUTTER DEBUG API: deleteProcess - Solicitando eliminar proceso: $_baseUrl/procesos/$processName');
    try {
      final response = await http.delete(
        Uri.parse(
          '$_baseUrl/procesos/${Uri.encodeComponent(processName)}',
        ),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      print('FLUTTER DEBUG API: deleteProcess - StatusCode: ${response.statusCode}');
      print('FLUTTER DEBUG API: deleteProcess - Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('FLUTTER DEBUG API: deleteProcess - Proceso "$processName" eliminado exitosamente.');
        return true;
      } else if (response.statusCode == 404) {
        print('FLUTTER ERROR API: deleteProcess - Proceso "$processName" no encontrado (404 Not Found).');
        return false;
      } else {
        print('FLUTTER ERROR API: deleteProcess - Error al eliminar proceso: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('FLUTTER ERROR API: deleteProcess - Excepción al eliminar proceso: $e');
      return false;
    }
  }



 
  /// Obtiene las configuraciones de gráficas para un proceso específico.
  Future<List<GraficaConfiguracion>> getGraficas(String processName) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/procesos/${Uri.encodeComponent(processName)}/graficas',
        ),
      );
      if (response.statusCode == 200) {
        List<dynamic> graficasJson = json.decode(response.body);
        return graficasJson.map((json) => GraficaConfiguracion.fromMap(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Crea una nueva configuración de gráfica para un proceso específico.
  Future<GraficaConfiguracion?> createGrafica(
    String processName,
    GraficaConfiguracion grafica,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(
          '$_baseUrl/procesos/${Uri.encodeComponent(processName)}/graficas',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(grafica.toMap()),
      );
      if (response.statusCode == 201) {
        return GraficaConfiguracion.fromMap(json.decode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Actualiza una configuración de gráfica existente para un proceso específico.
  Future<GraficaConfiguracion?> updateGrafica(
    String processName,
    GraficaConfiguracion grafica,
  ) async {
    if (grafica.id == null) return null;
    try {
      final response = await http.put(
        Uri.parse(
          '$_baseUrl/procesos/${Uri.encodeComponent(processName)}/graficas/${grafica.id}',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(grafica.toMap()),
      );
      if (response.statusCode == 200) {
        return GraficaConfiguracion.fromMap(json.decode(response.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Elimina una configuración de gráfica específica de un proceso dado.
  Future<bool> deleteGrafica(String processName, String graficaId) async {
    try {
      final response = await http.delete(
        Uri.parse(
          '$_baseUrl/procesos/${Uri.encodeComponent(processName)}/graficas/$graficaId',
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}