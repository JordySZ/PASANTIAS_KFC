import 'package:flutter/material.dart';
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
  late List<Map<String, dynamic>> tasks;

  final List<String> miembrosDisponibles = [
    'Alex',
    'David',
    'Juan',
    'Rocio',
    'Luis',
    'Rebeca',
    'Jose',
  ];

  List<String> listasDisponibles = [
    'Primer Sprint',
    'Segundo Sprint',
    'Tercer Sprint',
    'Cuarto Sprint',
  ];

  String? _currentProcessCollectionName;

  @override
  void initState() {
    super.initState();

    tasks = [
      {
        'titulo': 'Creación - Login',
        'lista': 'Primer Sprint',
        'estado': 'HECHO',
        'miembro': 'Alex',
        'fecha': DateTime(2024, 6, 30),
        'editando': false,
      },
      {
        'titulo': 'Creación CRUD - User',
        'lista': 'Primer Sprint',
        'estado': 'HECHO',
        'miembro': 'David',
        'fecha': DateTime(2024, 6, 30),
        'editando': false,
      },
      {
        'titulo': 'FASE EN PROCESO',
        'lista': 'Segundo Sprint',
        'estado': 'EN PROCESO',
        'miembro': 'Juan',
        'fecha': DateTime(2024, 7, 7),
        'editando': true,
      },
    ];
    _currentProcessCollectionName = widget.processName;
  }

  Color _estadoColor(String estado) {
    switch (estado) {
      case 'HECHO':
        return Colors.green;
      case 'EN PROCESO':
        return Colors.orange;
      case 'INVALIDO':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _cambiarFecha(int index) async {
    DateTime? nuevaFecha = await showDatePicker(
      context: context,
      initialDate: tasks[index]['fecha'],
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );

    if (nuevaFecha != null) {
      setState(() {
        tasks[index]['fecha'] = nuevaFecha;
      });
    }
  }

  void _cambiarEstado(int index) {
    setState(() {
      final estadoActual = tasks[index]['estado'];
      if (estadoActual == 'HECHO') {
        tasks[index]['estado'] = 'INVALIDO';
      } else if (estadoActual == 'INVALIDO') {
        tasks[index]['estado'] = 'EN PROCESO';
      } else {
        tasks[index]['estado'] = 'HECHO';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2D),
      appBar: AppBar(
        backgroundColor: Colors.teal.shade800,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (_) => TableroScreen(
                      processName: _currentProcessCollectionName,
                    ),
              ),
            );
          },
        ),
        title: const Text('Gestión de Tareas'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            onSelected: (String value) {
              if (value == 'cronograma') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => TimelineScreen(
                          processName: _currentProcessCollectionName,
                        ),
                  ),
                );
              } else if (value == 'panel') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => PanelTrello(
                          processName: _currentProcessCollectionName,
                        ),
                  ),
                );
              } else if (value == 'tablas') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => KanbanTaskManager(
                          processName: _currentProcessCollectionName,
                        ),
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
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildHeaderRow(),
          const Divider(color: Colors.white24),
          ...List.generate(tasks.length, (index) => _buildTaskRow(index)),
        ],
      ),
      floatingActionButton: ExpandableFab(
        onAddTarjeta: () {
          setState(() {
            tasks.add({
              'titulo': 'Nueva tarea',
              'lista':
                  listasDisponibles.isNotEmpty
                      ? listasDisponibles.first
                      : 'Nuevo',
              'estado': 'EN PROCESO',
              'miembro': miembrosDisponibles.first,
              'fecha': DateTime.now(),
              'editando': true,
            });
          });
        },
        onAddLista: () {
          showDialog(
            context: context,
            builder: (context) {
              final TextEditingController listaController =
                  TextEditingController();
              return AlertDialog(
                backgroundColor: const Color(0xFF2C2C3E),
                title: const Text(
                  'Nueva Lista',
                  style: TextStyle(color: Colors.white),
                ),
                content: TextField(
                  controller: listaController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Nombre de la lista',
                    hintStyle: TextStyle(color: Colors.white38),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      if (listaController.text.trim().isNotEmpty) {
                        setState(() {
                          listasDisponibles.add(listaController.text.trim());
                        });
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text(
                      'Guardar',
                      style: TextStyle(color: Colors.tealAccent),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeaderRow() {
    return Row(
      children: const [
        _HeaderCell('Tarjeta', flex: 3),
        _HeaderCell('Lista', flex: 2),
        _HeaderCell('Etiqueta', flex: 2),
        _HeaderCell('Miembros', flex: 3),
        _HeaderCell('Fecha', flex: 2),
      ],
    );
  }

  Widget _buildTaskRow(int index) {
    final task = tasks[index];
    final DateTime fecha = task['fecha'];
    final String fechaTexto = '${fecha.day}/${fecha.month}';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white24)),
      ),
      child: Row(
        children: [
          _DataCell(
            Row(
              children: [
                Expanded(
                  child:
                      task['editando'] == true
                          ? TextField(
                            autofocus: true,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(),
                              hintText: 'Nombre',
                              hintStyle: TextStyle(color: Colors.white38),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                            ),
                            controller: TextEditingController(
                              text: task['titulo'],
                            ),
                            onSubmitted: (value) {
                              setState(() {
                                task['titulo'] =
                                    value.trim().isEmpty
                                        ? task['titulo']
                                        : value.trim();
                                task['editando'] = false;
                              });
                            },
                          )
                          : Text(
                            task['titulo'],
                            style: const TextStyle(color: Colors.white),
                          ),
                ),
                IconButton(
                  icon: Icon(
                    task['editando'] == true ? Icons.check : Icons.edit,
                    color: Colors.white70,
                    size: 18,
                  ),
                  onPressed: () {
                    setState(() {
                      task['editando'] = !(task['editando'] == true);
                    });
                  },
                ),
              ],
            ),
            flex: 3,
          ),
          _DataCell(
            DropdownButton<String>(
              value: task['lista'],
              underline: const SizedBox(),
              iconEnabledColor: Colors.white,
              dropdownColor: const Color(0xFF2C2C3E),
              style: const TextStyle(color: Colors.white),
              isExpanded: true,
              onChanged: (String? newValue) {
                setState(() {
                  task['lista'] = newValue!;
                });
              },
              items:
                  listasDisponibles
                      .map(
                        (value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        ),
                      )
                      .toList(),
            ),
            flex: 2,
          ),
          _DataCell(
            GestureDetector(
              onTap: () => _cambiarEstado(index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _estadoColor(task['estado']).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  task['estado'],
                  style: TextStyle(
                    color: _estadoColor(task['estado']),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            flex: 2,
          ),
          _DataCell(
            DropdownButton<String>(
              value: task['miembro'],
              underline: const SizedBox(),
              iconEnabledColor: Colors.white,
              dropdownColor: const Color(0xFF2C2C3E),
              style: const TextStyle(color: Colors.white),
              isExpanded: true,
              onChanged: (String? newValue) {
                setState(() {
                  task['miembro'] = newValue!;
                });
              },
              items:
                  miembrosDisponibles
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
            ),
            flex: 3,
          ),
          _DataCell(
            InkWell(
              onTap: () => _cambiarFecha(index),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.greenAccent,
                  ),
                  const SizedBox(width: 4),
                  Text(fechaTexto, style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
            flex: 2,
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final int flex;
  const _HeaderCell(this.text, {this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white70,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _DataCell extends StatelessWidget {
  final Widget child;
  final int flex;
  const _DataCell(this.child, {this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Align(alignment: Alignment.centerLeft, child: child),
    );
  }
}

// FAB Personalizado
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
              onPressed: () {
                widget.onAddTarjeta();
                setState(() => _open = false);
              },
              label: const Text('Tarjeta'),
              icon: const Icon(Icons.post_add),
              backgroundColor: Colors.teal,
            ),
          ),
        if (_open)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: FloatingActionButton.extended(
              heroTag: 'addLista',
              onPressed: () {
                widget.onAddLista();
                setState(() => _open = false);
              },
              label: const Text('Lista'),
              icon: const Icon(Icons.list),
              backgroundColor: Colors.deepOrange,
            ),
          ),
        FloatingActionButton(
          heroTag: 'main',
          onPressed: () => setState(() => _open = !_open),
          backgroundColor: Colors.teal.shade700,
          child: Icon(_open ? Icons.close : Icons.add),
        ),
      ],
    );
  }
}
