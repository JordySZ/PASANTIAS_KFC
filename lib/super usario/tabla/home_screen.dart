import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:login_app/super%20usario/cards/cards.dart';
import 'package:login_app/super%20usario/cronogrma/cronograma.dart';
import 'package:login_app/super%20usario/panel/panel_graficas.dart';

// Colores modificados según solicitud
final Color primaryColor = const Color.fromARGB(255, 183, 28, 28); // Rojo del primer código
final Color secondaryColor = Colors.white; // Fondo de tarjetas blanco
final Color backgroundColor = const Color(0xFFf5f5f5); // Fondo gris claro
final Color textColor = Colors.black; // Textos en negro
final Color lightGrey = const Color(0xFFe0e0e0); // Gris claro
final Color mediumGrey = const Color(0xFF9e9e9e); // Gris medio
final Color darkGrey = const Color(0xFF616161); // Gris oscuro

class KanbanTaskManager extends StatefulWidget {
  final String? processName;

  const KanbanTaskManager({super.key, this.processName});

  @override
  State<KanbanTaskManager> createState() => _KanbanTaskManagerState();
}

class _KanbanTaskManagerState extends State<KanbanTaskManager> {
  List<Map<String, dynamic>> tasks = [];
  List<Map<String, dynamic>> listas = [];

  final TextEditingController titleController = TextEditingController();
  final TextEditingController statusController = TextEditingController();
  final String baseUrl = 'http://localhost:3000';

  bool showAddForm = false;
  String? estadoFiltro;

  @override
  void initState() {
    super.initState();
    fetchTasks();
    fetchLists();
  }

  Future<void> fetchTasks() async {
    final url = Uri.parse('$baseUrl/procesos/${widget.processName}/cards');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final raw = response.body;
      print('🔹 RAW TASK DATA: $raw');
      setState(() {
        tasks = List<Map<String, dynamic>>.from(json.decode(raw));
      });
    } else {
      print('Error al obtener tareas: ${response.body}');
    }
  }

  Future<void> addTask(String title, String estado, String idLista) async {
    final url = Uri.parse('$baseUrl/procesos/${widget.processName}/cards');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'titulo': title,
        'estado': estado,
        'idLista': idLista,
      }),
    );

    if (response.statusCode == 201) {
      fetchTasks();
    } else {
      print('Error al agregar tarea: ${response.body}');
    }
  }

  Future<void> updateTask(String id, String nuevoEstado) async {
    final url = Uri.parse('$baseUrl/procesos/${widget.processName}/cards/$id');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'estado': nuevoEstado}),
    );

    if (response.statusCode == 200) {
      fetchTasks();
    } else {
      print('Error al actualizar tarea: ${response.body}');
    }
  }

  Future<void> deleteTask(String id) async {
    final url = Uri.parse('$baseUrl/procesos/${widget.processName}/cards/$id');
    final response = await http.delete(url);

    if (response.statusCode == 200) {
      fetchTasks();
    } else {
      print('Error al eliminar tarea: ${response.body}');
    }
  }

  Future<void> fetchLists() async {
  final url = Uri.parse('$baseUrl/procesos/${widget.processName}/lists');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final raw = response.body;
    print('🔹 RAW LIST DATA: $raw');
    setState(() {
      listas = List<Map<String, dynamic>>.from(json.decode(raw));
    });
  } else {
    print('Error al obtener listas: ${response.body}');
  }
}

String getTituloListaPorId(String? idLista) {
  final lista = listas.firstWhere(
    (l) => l['_id'] == idLista,
    orElse: () => {'titulo': 'Sin lista'},
  );
  return lista['titulo'] ?? 'Sin lista';

}

  Color _estadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'hecho':
        return Colors.green;
      case 'en_progreso':
        return Colors.orange;
      case 'pendiente':
        return primaryColor; // Usamos el rojo principal
      default:
        return mediumGrey;
    }
  }

  void _showTaskDetailsDialog(Map<String, dynamic> card) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: secondaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            card['titulo'] ?? 'Sin título',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((card['descripcion'] ?? '').isNotEmpty) ...[
                  _buildDetailRow(Icons.description, "Descripción", card['descripcion']),
                  Divider(color: lightGrey),
                ],
                _buildDetailRow(Icons.person, "Asignado a", card['miembro'] ?? "N/A"),
                Divider(color: lightGrey),
                _buildDetailRow(Icons.flag, "Estado", (card['estado'] ?? 'N/A').toString().replaceAll('', ' ')),
                Divider(color: lightGrey),
                if (card['fechaInicio'] != null)
                  _buildDetailRow(Icons.play_arrow, "Fecha de Inicio",
                      DateFormat.yMMMMd('es_ES').format(DateTime.parse(card['fechaInicio']).toLocal())),
                if (card['fechaVencimiento'] != null)
                  _buildDetailRow(Icons.event_busy, "Fecha de Vencimiento",
                      DateFormat.yMMMMd('es_ES').format(DateTime.parse(card['fechaVencimiento']).toLocal())),
                if (card['fechaCompletado'] != null)
                  _buildDetailRow(Icons.check_circle, "Fecha de Finalización",
                      DateFormat.yMMMMd('es_ES').format(DateTime.parse(card['fechaCompletado']).toLocal())),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "Cerrar",
                style: TextStyle(color: primaryColor),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: darkGrey, fontWeight: FontWeight.bold)),
                Text(content, style: TextStyle(color: textColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = estadoFiltro == null
        ? tasks
        : tasks.where((task) => task['estado']?.toLowerCase() == estadoFiltro).toList();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => TableroScreen(processName: widget.processName,),
              ),
            );
          },
        ),
        title: Text("Tablas", style: TextStyle(color: Colors.white)),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.menu, color: Colors.white),
            onSelected: (String value) {
              if (value == 'cronograma') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlannerScreen(processName: widget.processName),
                  ),
                );
              } else if (value == 'panel') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PanelTrello(processName: widget.processName),
                  ),
                );
              } else if (value == 'tablas') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => KanbanTaskManager(processName: widget.processName),
                  ),
                );
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'cronograma',
                child: Text('Cronograma', style: TextStyle(color: textColor)),
              ),
              PopupMenuItem<String>(
                value: 'tablas',
                child: Text('Tablas', style: TextStyle(color: textColor)),
              ),
              PopupMenuItem<String>(
                value: 'panel',
                child: Text('Panel', style: TextStyle(color: textColor)),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    DropdownButton<String?>(
                      value: estadoFiltro,
                      dropdownColor: secondaryColor,
                      hint: Text('Filtrar por estado', style: TextStyle(color: darkGrey)),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Todos', style: TextStyle(color: textColor)),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'pendiente',
                          child: Text('Pendiente', style: TextStyle(color: primaryColor)),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'en_progreso',
                          child: Text('En Progreso', style: TextStyle(color: Colors.orange)),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'hecho',
                          child: Text('Hecho', style: TextStyle(color: Colors.green)),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          estadoFiltro = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: secondaryColor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Tarjeta',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Miembro',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Lista',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Etiqueta',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Fecha Inicio → Fecha Entrega',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Acciones',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredTasks.length,
                  itemBuilder: (context, index) {
                    final t = filteredTasks[index];
                    final titulo = t['titulo'] ?? 'Sin título';
                    final estado = t['estado'] ?? 'Ninguno';
                    final miembro = t['miembro'] ?? 'Sin asignar';

                    final fechaInicioRaw = t['fechaInicio'];
                    final fechaFinRaw = t['fechaVencimiento'];

                    String fechas = 'Sin fecha';
                    if (fechaInicioRaw != null || fechaFinRaw != null) {
                      final inicio = fechaInicioRaw != null
                          ? DateTime.tryParse(fechaInicioRaw)?.toLocal()
                          : null;
                      final fin = fechaFinRaw != null
                          ? DateTime.tryParse(fechaFinRaw)?.toLocal()
                          : null;

                      final formato = (DateTime dt) =>
                          '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

                      final inicioStr = inicio != null ? formato(inicio) : '¿?';
                      final finStr = fin != null ? formato(fin) : '¿?';

                      fechas = '$inicioStr → $finStr';
                    }

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: secondaryColor,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: GestureDetector(
                              onTap: () => _showTaskDetailsDialog(t),
                              child: Text(
                                titulo,
                                style: TextStyle(
                                  color: textColor,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(miembro, style: TextStyle(color: textColor)),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              getTituloListaPorId(t['idLista']),
                              style: TextStyle(color: textColor),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: GestureDetector(
                              onTap: () {
                                final current = estado.toLowerCase();
                                String nuevo = 'pendiente';
                                if (current == 'pendiente') nuevo = 'en_progreso';
                                else if (current == 'en_progreso') nuevo = 'hecho';
                                updateTask(t['_id'], nuevo);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _estadoColor(estado).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  estado,
                                  style: TextStyle(
                                    color: _estadoColor(estado),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(fechas, style: TextStyle(color: textColor)),
                          ),
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.delete, color: primaryColor),
                                  onPressed: () => deleteTask(t['_id']),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                    );
                  },
                ),
              ),
            ],
          ),
          // Formulario de agregar tarea
          if (showAddForm)
            Center(
              child: Card(
                color: secondaryColor,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 350,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Nueva Tarjeta',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: titleController,
                          decoration: InputDecoration(
                            labelText: 'Título de la tarea',
                            labelStyle: TextStyle(color: darkGrey),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(),
                          ),
                          style: TextStyle(color: textColor),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: statusController,
                          decoration: InputDecoration(
                            labelText: 'Estado inicial (pendiente, en_progreso, hecho)',
                            labelStyle: TextStyle(color: darkGrey),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(),
                          ),
                          style: TextStyle(color: textColor),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                final titulo = titleController.text.trim();
                                final estado = statusController.text.trim();
                                const idLista = '64f9aa8f8a8a8a8a8a8a8a8a';
                                if (titulo.isNotEmpty && estado.isNotEmpty) {
                                  addTask(titulo, estado, idLista);
                                  titleController.clear();
                                  statusController.clear();
                                  setState(() => showAddForm = false);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Agregar tarea'),
                            ),
                            TextButton(
                              onPressed: () {
                                titleController.clear();
                                statusController.clear();
                                setState(() => showAddForm = false);
                              },
                              child: Text(
                                'Cancelar',
                                style: TextStyle(color: darkGrey),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: ExpandableFab(
        onAddTarjeta: () {
          setState(() {
            showAddForm = true;
          });
        },
        onAddLista: () {},
      ),
    );
  }
}

class ExpandableFab extends StatefulWidget {
  final VoidCallback onAddTarjeta;
  final VoidCallback onAddLista;
  const ExpandableFab({
    super.key,
    required this.onAddTarjeta,
    required this.onAddLista,
  });
  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab>
    with SingleTickerProviderStateMixin {
  bool _open = false;
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_open)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: FloatingActionButton.extended(
              heroTag: 'addTarjeta',
              icon: Icon(Icons.post_add, color: Colors.white),
              label: Text('Tarjeta', style: TextStyle(color: Colors.white)),
              backgroundColor: primaryColor,
              onPressed: () {
                widget.onAddTarjeta();
                setState(() => _open = false);
              },
            ),
          ),
        FloatingActionButton(
          heroTag: 'main',
          child: Icon(_open ? Icons.close : Icons.add, color: Colors.white),
          backgroundColor: primaryColor,
          onPressed: () => setState(() => _open = !_open),
        ),
      ],
    );
  }
}