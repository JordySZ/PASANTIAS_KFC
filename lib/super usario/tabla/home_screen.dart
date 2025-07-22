import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:login_app/super%20usario/cards/cards.dart';
import 'package:login_app/super%20usario/cronogrma/cronograma.dart';
import 'package:login_app/super%20usario/panel/panel_graficas.dart';

class KanbanTaskManager extends StatefulWidget {
  final String? processName;

  const KanbanTaskManager({super.key, this.processName});

  @override
  State<KanbanTaskManager> createState() => _KanbanTaskManagerState();
}

class _KanbanTaskManagerState extends State<KanbanTaskManager> {
  List<Map<String, dynamic>> tasks = [];

  final TextEditingController titleController = TextEditingController();
  final TextEditingController statusController = TextEditingController();
  final String baseUrl = 'http://localhost:3000';

  bool showAddForm = false;
  String? estadoFiltro;

  @override
  void initState() {
    super.initState();
    fetchTasks();
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

  Color _estadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'hecho':
        return Colors.green;
      case 'en_progreso':
        return Colors.orange;
      case 'pendiente':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showTaskDetailsDialog(Map<String, dynamic> card) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2D2F3A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            card['titulo'] ?? 'Sin título',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((card['descripcion'] ?? '').isNotEmpty) ...[
                  _buildDetailRow(
                    Icons.description,
                    "Descripción",
                    card['descripcion'],
                  ),
                  const Divider(color: Colors.white24),
                ],
                _buildDetailRow(
                  Icons.person,
                  "Asignado a",
                  card['miembro'] ?? "N/A",
                ),
                const Divider(color: Colors.white24),
                _buildDetailRow(
                  Icons.flag,
                  "Estado",
                  (card['estado'] ?? 'N/A').toString().replaceAll('', ' '),
                ),
                const Divider(color: Colors.white24),
                if (card['fechaInicio'] != null)
                  _buildDetailRow(
                    Icons.play_arrow,
                    "Fecha de Inicio",
                    DateFormat.yMMMMd(
                      'es_ES',
                    ).format(DateTime.parse(card['fechaInicio']).toLocal()),
                  ),
                if (card['fechaVencimiento'] != null)
                  _buildDetailRow(
                    Icons.event_busy,
                    "Fecha de Vencimiento",
                    DateFormat.yMMMMd('es_ES').format(
                      DateTime.parse(card['fechaVencimiento']).toLocal(),
                    ),
                  ),
                if (card['fechaCompletado'] != null)
                  _buildDetailRow(
                    Icons.check_circle,
                    "Fecha de Finalización",
                    DateFormat.yMMMMd(
                      'es_ES',
                    ).format(DateTime.parse(card['fechaCompletado']).toLocal()),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                "Cerrar",
                style: TextStyle(color: Colors.white),
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
          Icon(icon, color: Colors.tealAccent, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(content, style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks =
        estadoFiltro == null
            ? tasks
            : tasks
                .where((task) => task['estado']?.toLowerCase() == estadoFiltro)
                .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2D),
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Redirige al tablero del proceso actual usando el processName correcto
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => TableroScreen(processName: widget.processName),
              ),
            );
          },
        ),
        title: Text(("Tablas"), style: TextStyle(color: Colors.white)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            onSelected: (String value) {
              if (value == 'cronograma') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            PlannerScreen(processName: widget.processName),
                  ),
                );
              } else if (value == 'panel') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            PanelTrello(processName: widget.processName),
                  ),
                );
              } else if (value == 'tablas') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) =>
                            KanbanTaskManager(processName: widget.processName),
                  ),
                );
              }
            },
            itemBuilder:
                (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'cronograma',
                    child: Text('Cronograma'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'tablas',
                    child: Text('Tablas'),
                  ),
                  const PopupMenuItem<String>(
                    value: 'panel',
                    child: Text('Panel'),
                  ),
                ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                DropdownButton<String?>(
                  value: estadoFiltro,
                  dropdownColor: const Color(0xFF2C2C3E),
                  hint: const Text(
                    'Filtrar por estado',
                    style: TextStyle(color: Colors.white70),
                  ),
                  items: const [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(
                        'Todos',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'pendiente',
                      child: Text(
                        'Pendiente',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'en_progreso',
                      child: Text(
                        'En Progreso',
                        style: TextStyle(color: Colors.orangeAccent),
                      ),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'hecho',
                      child: Text(
                        'Hecho',
                        style: TextStyle(color: Colors.greenAccent),
                      ),
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
              color: const Color(0xFF2C2C3E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: const [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Tarjeta',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Lista eliminada
                Expanded(
                  flex: 2,
                  child: Text(
                    'Miembro',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Etiqueta',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Fecha Inicio → Fecha Entrega',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Acciones',
                    style: TextStyle(
                      color: Colors.white70,
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
                  final inicio =
                      fechaInicioRaw != null
                          ? DateTime.tryParse(fechaInicioRaw)?.toLocal()
                          : null;
                  final fin =
                      fechaFinRaw != null
                          ? DateTime.tryParse(fechaFinRaw)?.toLocal()
                          : null;

                  final formato =
                      (DateTime dt) =>
                          '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

                  final inicioStr = inicio != null ? formato(inicio) : '¿?';
                  final finStr = fin != null ? formato(fin) : '¿?';

                  fechas = '$inicioStr → $finStr';
                }

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C3E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: GestureDetector(
                          onTap: () => _showTaskDetailsDialog(t),
                          child: Text(
                            titulo,
                            style: const TextStyle(
                              color: Colors.lightBlueAccent,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      // Lista eliminada
                      Expanded(
                        flex: 2,
                        child: Text(
                          miembro,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: () {
                            final current = estado.toLowerCase();
                            String nuevo = 'pendiente';
                            if (current == 'pendiente')
                              nuevo = 'en_progreso';
                            else if (current == 'en_progreso')
                              nuevo = 'hecho';
                            updateTask(t['_id'], nuevo);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
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
                        child: Text(
                          fechas,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.redAccent,
                              ),
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
          if (showAddForm)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Título de la tarea',
                      labelStyle: TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Color(0xFF2C2C3E),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: statusController,
                    decoration: const InputDecoration(
                      labelText:
                          'Estado inicial (pendiente, en_progreso, hecho)',
                      labelStyle: TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Color(0xFF2C2C3E),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      final titulo = titleController.text.trim();
                      final estado = statusController.text.trim();
                      const idLista =
                          '64f9aa8f8a8a8a8a8a8a8a8a'; // cambia por ID real
                      if (titulo.isNotEmpty && estado.isNotEmpty) {
                        addTask(titulo, estado, idLista);
                        titleController.clear();
                        statusController.clear();
                        setState(() => showAddForm = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                    ),
                    child: const Text('Agregar tarea'),
                  ),
                ],
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
              icon: const Icon(Icons.post_add),
              label: const Text('Tarjeta'),
              backgroundColor: Colors.teal,
              onPressed: () {
                widget.onAddTarjeta();
                setState(() => _open = false);
              },
            ),
          ),
        FloatingActionButton(
          heroTag: 'main',
          child: Icon(_open ? Icons.close : Icons.add),
          backgroundColor: Colors.teal.shade700,
          onPressed: () => setState(() => _open = !_open),
        ),
      ],
    );
  }
}
