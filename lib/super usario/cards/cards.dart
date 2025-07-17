import 'package:flutter/material.dart';
import 'package:login_app/scrum%20user/scrum_user.dart';
import 'package:login_app/super%20usario/cronogrma/cronograma.dart';
import 'package:login_app/super%20usario/home_page.dart';
import 'package:login_app/super%20usario/panel/panel_graficas.dart';
import 'package:login_app/super%20usario/tabla/home_screen.dart';
import 'package:intl/intl.dart';
import 'package:login_app/models/tarjeta.dart';
import 'package:login_app/models/lista_datos.dart';
import 'package:login_app/services/api_service.dart';
import 'package:login_app/models/process.dart';

import 'package:shared_preferences/shared_preferences.dart';
class TableroScreen extends StatefulWidget {
  final String? processName;

  const TableroScreen({super.key, this.processName});

  @override
  State<TableroScreen> createState() => _TableroScreenState();
}

class _TableroScreenState extends State<TableroScreen> {
  List<ListaDatos> listas = [];
  List<List<Tarjeta>> tarjetasPorLista = [];
  List<GlobalKey> keysAgregarTarjeta = [];
  int? indiceListaEditandoTarjeta;

  String? _currentProcessCollectionName;
  final ApiService _apiService = ApiService();

  Map<String, int> _listIdToIndexMap = {};
  final TextEditingController _processNameController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  String? _selectedEstado; // Para almacenar el estado seleccionado

  // Agrega una variable para almacenar el objeto Process del proceso actual
  Process? _currentProcessDetails;

  @override
  void initState() {
    super.initState();
    print(
        'FLUTTER DEBUG TABLERO: initState - widget.processName: ${widget.processName}');

    if (widget.processName != null) {
      _currentProcessCollectionName = widget.processName;
      _loadProcessDetails().then((_) {
        _loadListsFromBackend().then((_) {
          _loadCardsFromBackend();
        });
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mostrarDialogoNombreProceso(context);
      });
    }
  }

  @override
  void dispose() {
    _processNameController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

Future<void> _mostrarDialogoEditarProceso(BuildContext context) async {
  if (_currentProcessDetails == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No hay un proceso cargado para editar.'),
      ),
    );
    return;
  }

  // Precargar los controladores con los datos actuales del proceso
  _processNameController.text = _currentProcessDetails!.nombre_proceso;
  _selectedStartDate = _currentProcessDetails!.startDate;
  _startDateController.text = _selectedStartDate != null
      ? DateFormat('dd/MM/yyyy').format(_selectedStartDate!)
      : '';
  _selectedEndDate = _currentProcessDetails!.endDate;
  _endDateController.text = _selectedEndDate != null
      ? DateFormat('dd/MM/yyyy').format(_selectedEndDate!)
      : '';
  _selectedEstado = _currentProcessDetails!.estado;

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Editar Proceso'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _processNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del Proceso',
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: dialogContext,
                        initialDate: _selectedStartDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedStartDate = picked;
                          _startDateController.text =
                              DateFormat('dd/MM/yyyy').format(picked);
                        });
                      }
                    },
                    child: AbsorbPointer(
                      child: TextField(
                        controller: _startDateController,
                        decoration: const InputDecoration(
                          labelText: 'Fecha de Inicio',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: dialogContext,
                        initialDate: _selectedEndDate ??
                            _selectedStartDate ??
                            DateTime.now(),
                        firstDate:
                            _selectedStartDate ?? DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedEndDate = picked;
                          _endDateController.text =
                              DateFormat('dd/MM/yyyy').format(picked);
                        });
                      }
                    },
                    child: AbsorbPointer(
                      child: TextField(
                        controller: _endDateController,
                        decoration: const InputDecoration(
                          labelText: 'Fecha de Fin',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedEstado,
                    decoration: const InputDecoration(
                      labelText: 'Estado del Proceso',
                      border: OutlineInputBorder(),
                    ),
                    items: <String>['echo', 'en proceso', 'pendiente']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedEstado = newValue;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, selecciona un estado.';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancelar'),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
              ),
             TextButton(
  child: const Text('Guardar Cambios'),
  onPressed: () async {
     Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) =>  DashboardPage()),
              );
    final String name = _processNameController.text.trim();

    // --- Validaciones ---
    if (name.isEmpty) {
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        const SnackBar(
          content: Text('Por favor, ingresa un nombre para el proceso.'),
        ),
      );
      return;
    }
    if (_selectedStartDate == null) {
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona una fecha de inicio.'),
        ),
      );
      return;
    }
    if (_selectedEndDate == null) {
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona una fecha de fin.'),
        ),
      );
      return;
    }
    if (_selectedEndDate!.isBefore(_selectedStartDate!)) {
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        const SnackBar(
          content: Text('La fecha de fin no puede ser anterior a la fecha de inicio.'),
        ),
      );
      return;
    }
    if (_selectedEstado == null || _selectedEstado!.isEmpty) {
      ScaffoldMessenger.of(dialogContext).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecciona un estado para el proceso.'),
        ),
      );
      return;
    }

                  await _updateProcessInBackend(
                    name,
                    _selectedStartDate!,
                    _selectedEndDate!,
                    _selectedEstado!,
                  );
                  Navigator.of(dialogContext).pop();
                },
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> _updateProcessInBackend(
  String nombre_proceso, // <-- Este es el nuevo nombre que el usuario ingresó
  DateTime startDate,
  DateTime endDate,
  String estado,
) async {
  print(
      'FLUTTER DEBUG TABLERO: _updateProcessInBackend llamado con nombre: $nombre_proceso, inicio: $startDate, fin: $endDate, estado: $estado');
  if (_currentProcessDetails == null || _currentProcessCollectionName == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No hay un proceso válido para actualizar.'),
      ),
    );
    return;
  }

  // Captura el nombre original del proceso antes de crear el nuevo objeto Process
  // Este es el nombre que tu backend necesita en la URL para encontrar el proceso actual
  final String originalProcessName = _currentProcessDetails!.nombre_proceso; // Correcto, este es el nombre ANTERIOR

  try {
    final Process processDataToSend = _currentProcessDetails!.copyWith(
      nombre_proceso: nombre_proceso, // Este es el nuevo nombre
      startDate: startDate,
      endDate: endDate,
      estado: estado,
    );

    // ¡¡¡EL CAMBIO CRÍTICO ESTÁ AQUÍ!!!
    // Ahora la llamada a _apiService.updateProcess debe coincidir con la nueva firma:
    // Future<Process?> updateProcess(String originalProcessName, Process updatedProcessData)
    final Process? updatedProcess = await _apiService.updateProcess(
      originalProcessName, // <-- ¡Pasa el nombre original como primer argumento!
      processDataToSend,   // <-- ¡Pasa el objeto Process actualizado como segundo argumento!
    );

    if (updatedProcess != null) {
      setState(() {
        _currentProcessDetails = updatedProcess; // Actualiza el estado local con el objeto devuelto por el backend
        // También actualiza _currentProcessCollectionName si lo usas para el AppBar
        _currentProcessCollectionName = updatedProcess.nombre_proceso;
      });
      print(
          'FLUTTER DEBUG TABLERO: Proceso "${updatedProcess.nombre_proceso}" actualizado exitosamente en backend.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Proceso "${updatedProcess.nombre_proceso}" actualizado exitosamente.'),
        ),
      );
    } else {
      print(
          'FLUTTER ERROR TABLERO: _updateProcessInBackend - _apiService.updateProcess devolvió null.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('actualizado exitosamente'),
        ),
      );
    }
  } catch (e) {
    print(
        'FLUTTER ERROR TABLERO: _updateProcessInBackend - Excepción al actualizar proceso: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error de conexión al actualizar el proceso: ${e.toString()}'),
      ),
    );
  }
}
  // Nueva función para cargar los detalles del proceso (incluido el estado)
  Future<void> _loadProcessDetails() async {
    if (_currentProcessCollectionName == null) return;
    try {
      final Process? process =
          await _apiService.getProcessByName(_currentProcessCollectionName!);
      setState(() {
        _currentProcessDetails = process;
      });
      print(
          'FLUTTER DEBUG TABLERO: Detalles del proceso cargados: ${_currentProcessDetails?.nombre_proceso}, Estado: ${_currentProcessDetails?.estado}');
    } catch (e) {
      print(
          'FLUTTER ERROR TABLERO: Error al cargar detalles del proceso: $e');
    }
  }

  Future<void> _loadListsFromBackend() async {
    print(
        'FLUTTER DEBUG TABLERO: _loadListsFromBackend llamado. _currentProcessCollectionName: $_currentProcessCollectionName');
    if (_currentProcessCollectionName == null) {
      print(
          'FLUTTER DEBUG TABLERO: _loadListsFromBackend - No hay proceso seleccionado/creado. No se cargan listas.');
      setState(() {
        listas = [];
        tarjetasPorLista = [];
        keysAgregarTarjeta = [];
        _listIdToIndexMap = {};
      });
      return;
    }
    try {
      final List<ListaDatos> loadedLists = await _apiService.getLists(
        _currentProcessCollectionName!,
      );

      setState(() {
        listas.clear();
        tarjetasPorLista.clear();
        keysAgregarTarjeta.clear();
        _listIdToIndexMap.clear();

        for (int i = 0; i < loadedLists.length; i++) {
          listas.add(loadedLists[i]);
          tarjetasPorLista.add(
              []); // Inicializa una lista vacía de tarjetas para cada nueva lista
          keysAgregarTarjeta.add(GlobalKey());
          _listIdToIndexMap[loadedLists[i].id] =
              i; // Mapea el ID de la lista a su índice
        }
      });

      if (listas.isEmpty) {
        await _createDefaultListIfEmpty();
      }

      print(
          'FLUTTER DEBUG TABLERO: Listas cargadas exitosamente del backend para el proceso: $_currentProcessCollectionName. Cantidad: ${listas.length}');
    } catch (e) {
      print(
          'FLUTTER ERROR TABLERO: _loadListsFromBackend - Error al cargar listas del backend para $_currentProcessCollectionName: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar las listas: ${e.toString()}')),
      );
    }
  }

  Future<void> _createDefaultListIfEmpty() async {
    print(
        'FLUTTER DEBUG TABLERO: _createDefaultListIfEmpty - Intentando crear lista por defecto.');
    final ListaDatos defaultListTemp = ListaDatos(
      id: '',
      titulo: 'Lista de tareas',
    );
    try {
      final ListaDatos? createdList = await _apiService.createList(
        _currentProcessCollectionName!,
        defaultListTemp,
      );
      if (createdList != null) {
        setState(() {
          listas.add(createdList);
          tarjetasPorLista.add([]);
          keysAgregarTarjeta.add(GlobalKey());
          _listIdToIndexMap[createdList.id] = listas.length - 1;
        });
        print(
            'FLUTTER DEBUG TABLERO: _createDefaultListIfEmpty - Lista por defecto creada en backend con ID: ${createdList.id}');
      } else {
        print(
            'FLUTTER ERROR TABLERO: _createDefaultListIfEmpty - Falló la creación de la lista por defecto.');
      }
    } catch (e) {
      print(
          'FLUTTER ERROR TABLERO: _createDefaultListIfEmpty - Excepción al crear lista por defecto: $e');
    }
  }

  Future<void> _loadCardsFromBackend() async {
    print(
        'FLUTTER DEBUG TABLERO: _loadCardsFromBackend llamado. _currentProcessCollectionName: $_currentProcessCollectionName');
    if (_currentProcessCollectionName == null) {
      print(
          'FLUTTER DEBUG TABLERO: _loadCardsFromBackend - No hay proceso seleccionado/creado. No se cargan tarjetas.');
      setState(() {
        tarjetasPorLista = List.generate(listas.length, (_) => []);
      });
      return;
    }
    try {
      final List<Tarjeta> loadedCards = await _apiService.getCards(
        _currentProcessCollectionName!,
      );
      setState(() {
        tarjetasPorLista = List.generate(
          listas.length,
          (_) => [],
        );

        for (var card in loadedCards) {
          final int? listIndex = _listIdToIndexMap[card.idLista];
          if (listIndex != null && listIndex < tarjetasPorLista.length) {
            tarjetasPorLista[listIndex].add(card);
          } else {
            print(
                'FLUTTER WARNING TABLERO: Tarjeta "${card.titulo}" con idLista "${card.idLista}" no tiene una lista correspondiente en el frontend. Asignando a la primera lista si existe.');
            if (tarjetasPorLista.isNotEmpty) {
              tarjetasPorLista[0].add(
                  card);
            } else {
              print(
                  'FLUTTER WARNING TABLERO: No hay listas disponibles para asignar la tarjeta huérfana.');
            }
          }
        }
      });
      print(
          'FLUTTER DEBUG TABLERO: Tarjetas cargadas exitosamente del backend para el proceso: $_currentProcessCollectionName. Cantidad: ${loadedCards.length}');
    } catch (e) {
      print(
          'FLUTTER ERROR TABLERO: _loadCardsFromBackend - Error al cargar tarjetas del backend para $_currentProcessCollectionName: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar las tarjetas: ${e.toString()}'),
        ),
      );
    }
  }

  Future<void> _mostrarDialogoNombreProceso(BuildContext context) async {
    _processNameController.clear();
    _startDateController.clear();
    _endDateController.clear();
    _selectedStartDate = null;
    _selectedEndDate = null;
    _selectedEstado = 'pendiente'; // Establece un valor inicial para el estado

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Crear Nuevo Proceso'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _processNameController,
                      decoration: const InputDecoration(
                        hintText: "Nombre del Proceso (Ej. Proyecto X)",
                        labelText: 'Nombre del Proceso',
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: dialogContext,
                          initialDate: _selectedStartDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedStartDate = picked;
                            _startDateController.text =
                                DateFormat('dd/MM/yyyy').format(picked);
                          });
                        }
                      },
                      child: AbsorbPointer(
                        child: TextField(
                          controller: _startDateController,
                          decoration: const InputDecoration(
                            labelText: 'Fecha de Inicio',
                            hintText: 'Selecciona la fecha de inicio',
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: dialogContext,
                          initialDate: _selectedEndDate ??
                              _selectedStartDate ??
                              DateTime.now(),
                          firstDate:
                              _selectedStartDate ?? DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedEndDate = picked;
                            _endDateController.text =
                                DateFormat('dd/MM/yyyy').format(picked);
                          });
                        }
                      },
                      child: AbsorbPointer(
                        child: TextField(
                          controller: _endDateController,
                          decoration: const InputDecoration(
                            labelText: 'Fecha de Fin',
                            hintText: 'Selecciona la fecha de fin',
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedEstado,
                      decoration: const InputDecoration(
                        labelText: 'Estado del Proceso',
                        border: OutlineInputBorder(),
                      ),
                      items: <String>['echo', 'en proceso', 'pendiente']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedEstado = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, selecciona un estado.';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => DashboardPage()),
                    );
                  },
                ),
                TextButton(
                  child: const Text('Guardar'),
                  onPressed: () async {
                    final String name = _processNameController.text.trim();

                    if (name.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Por favor, ingresa un nombre para el proceso.',
                          ),
                        ),
                      );
                      return;
                    }
                    if (_selectedStartDate == null) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Por favor, selecciona una fecha de inicio.',
                          ),
                        ),
                      );
                      return;
                    }
                    if (_selectedEndDate == null) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Por favor, selecciona una fecha de fin.',
                          ),
                        ),
                      );
                      return;
                    }
                    if (_selectedEndDate!.isBefore(_selectedStartDate!)) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'La fecha de fin no puede ser anterior a la fecha de inicio.',
                          ),
                        ),
                      );
                      return;
                    }
                    if (_selectedEstado == null || _selectedEstado!.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Por favor, selecciona un estado para el proceso.',
                          ),
                        ),
                      );
                      return;
                    }

                    await _saveProcessCollectionToBackend(
                      name,
                      _selectedStartDate!,
                      _selectedEndDate!,
                      _selectedEstado!,
                    );
                    if (_currentProcessCollectionName != null) {
                      Navigator.of(dialogContext).pop();
                      await _loadListsFromBackend();
                      await _loadCardsFromBackend();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  
  Future<void> _saveProcessCollectionToBackend(
  String nombre_proceso,
  DateTime startDate,
  DateTime endDate,
  String estado,
) async {
  print(
      'FLUTTER DEBUG TABLERO: _saveProcessCollectionToBackend llamado con nombre: $nombre_proceso, inicio: $startDate, fin: $endDate, estado: $estado');
  try {
    final Process newProcessData = Process(
      nombre_proceso: nombre_proceso,
      startDate: startDate,
      endDate: endDate,
      estado: estado,
    );

    final String? createdCollectionName = await _apiService.createProcess(
      newProcessData,
    );

    if (createdCollectionName != null) {
      setState(() {
        _currentProcessCollectionName = createdCollectionName;
        // Asigna el objeto Process completo a _currentProcessDetails.
        // Asegúrate de que `copyWith` mantenga el ID si tu modelo `Process` lo tiene
        // y tu backend lo retorna, para futuras actualizaciones.
        _currentProcessDetails = newProcessData.copyWith(nombre_proceso: createdCollectionName);
      });

      // *** AÑADIDO: Guardar el nombre del proceso en SharedPreferences ***
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastProcessName', createdCollectionName); // Guarda el nombre de la colección

      print(
          'FLUTTER DEBUG TABLERO: _saveProcessCollectionToBackend - Colección creada/existente y _currentProcessCollectionName actualizado a: $_currentProcessCollectionName');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Proceso "$nombre_proceso" creado o seleccionado exitosamente.',
          ),
        ),
      );
    } else {
      print(
          'FLUTTER ERROR TABLERO: _saveProcessCollectionToBackend - _apiService.createProcess devolvió null. El proceso NO se guardó o hubo un error inesperado.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Error al guardar o seleccionar el proceso. Hubo un problema inesperado.',
          ),
        ),
      );
    }
  } catch (e) {
    print(
        'FLUTTER ERROR TABLERO: _saveProcessCollectionToBackend - Excepción al guardar colección de proceso: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Error de conexión al guardar el proceso: ${e.toString()}',
        ),
      ),
    );
  }
}
  void agregarListaNueva() async {
    if (_currentProcessCollectionName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, crea o selecciona un proceso primero para añadir listas.',
          ),
        ),
      );
      return;
    }
    String newTitle = 'Nueva lista';
    TextEditingController controller = TextEditingController(text: newTitle);

    String? chosenTitle = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Título de la Nueva Lista'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Ej. Pendientes'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Crear'),
            ),
          ],
        );
      },
    );

    if (chosenTitle != null && chosenTitle.isNotEmpty) {
      newTitle = chosenTitle;
    } else {
      return;
    }

    String tempId = 'temp-list-${DateTime.now().millisecondsSinceEpoch}';
    ListaDatos nuevaListaTemp = ListaDatos(id: tempId, titulo: newTitle);

    setState(() {
      listas.add(nuevaListaTemp);
      tarjetasPorLista.add([]);
      keysAgregarTarjeta.add(GlobalKey());
      _listIdToIndexMap[nuevaListaTemp.id] = listas.length - 1;
    });

    try {
      final ListaDatos? createdList = await _apiService.createList(
        _currentProcessCollectionName!,
        nuevaListaTemp,
      );
      if (createdList != null) {
        setState(() {
          int index = listas.indexWhere((list) => list.id == tempId);
          if (index != -1) {
            listas[index] = createdList;
            _listIdToIndexMap.remove(tempId);
            _listIdToIndexMap[createdList.id] = index;
          }
        });
        print(
            'FLUTTER DEBUG TABLERO: Lista "${createdList.titulo}" creada exitosamente en backend con ID: ${createdList.id}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lista "$newTitle" creada exitosamente.')),
        );
      } else {
        print(
            'FLUTTER ERROR TABLERO: agregarListaNueva - _apiService.createList devolvió null.');
        setState(() {
          listas.removeLast();
          tarjetasPorLista.removeLast();
          keysAgregarTarjeta.removeLast();
          _listIdToIndexMap.remove(tempId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al crear la nueva lista.')),
        );
      }
    } catch (e) {
      print(
          'FLUTTER ERROR TABLERO: agregarListaNueva - Excepción al crear lista: $e');
      setState(() {
        listas.removeLast();
        tarjetasPorLista.removeLast();
        keysAgregarTarjeta.removeLast();
        _listIdToIndexMap.remove(tempId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de conexión al crear la lista: ${e.toString()}'),
        ),
      );
    }
    print(
        'FLUTTER DEBUG TABLERO: Lista nueva añadida localmente. Cantidad de listas: ${listas.length}');
  }

  // Función para editar el título de una lista
  void editarTituloLista(int index, String nuevoTitulo) async {
    if (_currentProcessCollectionName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, crea o selecciona un proceso primero para editar listas.',
          ),
        ),
      );
      return;
    }
    ListaDatos listaToUpdate = listas[index].copyWith(titulo: nuevoTitulo);

    try {
      final ListaDatos? updatedList = await _apiService.updateList(
        _currentProcessCollectionName!,
        listaToUpdate,
      );
      if (updatedList != null) {
        setState(() {
          listas[index] = updatedList;
        });
        print(
            'FLUTTER DEBUG TABLERO: Título de lista editado exitosamente en backend. Lista ${updatedList.id}: ${updatedList.titulo}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Título de la lista actualizado a "$nuevoTitulo".'),
          ),
        );
      } else {
        print(
            'FLUTTER ERROR TABLERO: editarTituloLista - _apiService.updateList devolvió null.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al actualizar el título de la lista.'),
          ),
        );
      }
    } catch (e) {
      print(
          'FLUTTER ERROR TABLERO: editarTituloLista - Excepción al actualizar título de lista: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Error de conexión al actualizar el título de la lista: ${e.toString()}'),
        ),
      );
    }
  }

  /// **Nueva función para eliminar una lista del backend y del frontend.**
  void _eliminarListaDelBackend(int indexLista, String listaId) async {
    print(
        'FLUTTER DEBUG TABLERO: _eliminarListaDelBackend llamado. _currentProcessCollectionName: $_currentProcessCollectionName, ID de lista a eliminar: $listaId');
    if (_currentProcessCollectionName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, crea o selecciona un proceso primero para eliminar listas.',
          ),
        ),
      );
      return;
    }

    String? listTitleToDelete;
    if (indexLista < listas.length) {
      listTitleToDelete = listas[indexLista].titulo;
    }

    // Muestra un diálogo de confirmación
    bool confirmDelete = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirmar Eliminación'),
              content: Text(
                  '¿Estás seguro de que quieres eliminar la lista "$listTitleToDelete"? Esto también eliminará todas las tarjetas dentro de ella.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                TextButton(
                  child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            );
          },
        ) ??
        false; // Si el diálogo se cierra sin seleccionar, asume false

    if (!confirmDelete) {
      print('FLUTTER DEBUG TABLERO: Eliminación de lista cancelada.');
      return;
    }

    try {
      final bool success = await _apiService.deleteList(
        _currentProcessCollectionName!,
        listaId,
      );
      if (success) {
        setState(() {
          listas.removeAt(indexLista);
          tarjetasPorLista.removeAt(indexLista);
          keysAgregarTarjeta.removeAt(indexLista);
          // Reconstruir el mapa de IDs a índices después de la eliminación
          _listIdToIndexMap.clear();
          for (int i = 0; i < listas.length; i++) {
            _listIdToIndexMap[listas[i].id] = i;
          }
        });
        print(
            'FLUTTER DEBUG TABLERO: Lista eliminada exitosamente de "$_currentProcessCollectionName": $listaId');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Lista "${listTitleToDelete ?? "desconocida"}" eliminada exitosamente.',
            ),
          ),
        );
      } else {
        print(
            'FLUTTER ERROR API: _eliminarListaDelBackend - _apiService.deleteList devolvió false.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al eliminar la lista.')),
        );
      }
    } catch (e) {
      print(
          'FLUTTER ERROR API: _eliminarListaDelBackend - Excepción al eliminar lista: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Error de conexión al eliminar la lista: ${e.toString()}'),
        ),
      );
    }
  }

  // Función para agregar una nueva tarjeta a una lista específica
  void agregarTarjeta(int indexLista, Tarjeta tarjeta) async {
    print(
        'FLUTTER DEBUG TABLERO: agregarTarjeta llamado. _currentProcessCollectionName: $_currentProcessCollectionName');
    if (_currentProcessCollectionName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, crea o selecciona un proceso primero para añadir tarjetas.',
          ),
        ),
      );
      print(
          'FLUTTER DEBUG TABLERO: agregarTarjeta - No hay proceso seleccionado, no se añade tarjeta.');
      return;
    }

    final String targetListId = listas[indexLista].id;
    print(
        'FLUTTER DEBUG TABLERO: Intentando crear tarjeta con idLista: $targetListId (que debería ser el ID real de MongoDB)');

    final Tarjeta tarjetaConListId = tarjeta.copyWith(idLista: targetListId);

    try {
      final Tarjeta? createdCard = await _apiService.createCard(
        _currentProcessCollectionName!,
        tarjetaConListId,
      );
      if (createdCard != null) {
        setState(() {
          tarjetasPorLista[indexLista].add(createdCard);
          indiceListaEditandoTarjeta = null;
        });
        print(
            'FLUTTER DEBUG TABLERO: Tarjeta creada exitosamente en "$_currentProcessCollectionName" para lista ${createdCard.idLista}: ${createdCard.titulo}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tarjeta "${createdCard.titulo}" creada exitosamente.',
            ),
          ),
        );
      } else {
        print(
            'FLUTTER ERROR TABLERO: agregarTarjeta - _apiService.createCard devolvió null.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al crear la tarjeta.')),
        );
      }
    } catch (e) {
      print(
          'FLUTTER ERROR TABLERO: agregarTarjeta - Excepción al crear tarjeta: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Error de conexión al crear la tarjeta: ${e.toString()}'),
        ),
      );
    }
  }

  // Muestra el campo de texto para agregar una nueva tarjeta
  void mostrarCampoNuevaTarjeta(int indexLista) {
    setState(() {
      indiceListaEditandoTarjeta = indexLista;
    });
    print(
        'FLUTTER DEBUG TABLERO: Mostrando campo de nueva tarjeta para lista $indexLista.');
  }

  // Oculta el campo de edición/creación de tarjeta
  void ocultarEdicion() {
    if (indiceListaEditandoTarjeta != null) {
      setState(() {
        indiceListaEditandoTarjeta = null;
      });
      print('FLUTTER DEBUG TABLERO: Ocultando campo de edición de tarjeta.');
    }
  }

  // Actualiza una tarjeta en el backend
  void _actualizarTarjetaEnBackend(
    int indexLista,
    int indexTarjeta,
    Tarjeta tarjetaActualizada,
  ) async {
    print(
        'FLUTTER DEBUG TABLERO: _actualizarTarjetaEnBackend llamado. _currentProcessCollectionName: $_currentProcessCollectionName');
    if (_currentProcessCollectionName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, crea o selecciona un proceso primero para actualizar tarjetas.',
          ),
        ),
      );
      return;
    }
    try {
      final Tarjeta? updatedCard = await _apiService.updateCard(
        _currentProcessCollectionName!,
        tarjetaActualizada,
      );
      if (updatedCard != null) {
        setState(() {
          tarjetasPorLista[indexLista][indexTarjeta] = updatedCard;
        });
        print(
            'FLUTTER DEBUG TABLERO: Tarjeta actualizada exitosamente en "$_currentProcessCollectionName": ${updatedCard.titulo}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tarjeta "${updatedCard.titulo}" actualizada exitosamente.',
            ),
          ),
        );
      } else {
        print(
            'FLUTTER ERROR TABLERO: _actualizarTarjetaEnBackend - _apiService.updateCard devolvió null.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al actualizar la tarjeta.')),
        );
      }
    } catch (e) {
      print(
          'FLUTTER ERROR TABLERO: _actualizarTarjetaEnBackend - Excepción al actualizar tarjeta: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Error de conexión al actualizar la tarjeta: ${e.toString()}'),
        ),
      );
    }
  }

  // Cambia el estado de una tarjeta y la actualiza en el backend
  void _cambiarEstadoTarjeta(
    int indexLista,
    int indexTarjeta,
    EstadoTarjeta newEstado,
  ) async {
    print(
        'FLUTTER DEBUG TABLERO: _cambiarEstadoTarjeta llamado. _currentProcessCollectionName: $_currentProcessCollectionName');
    if (_currentProcessCollectionName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, crea o selecciona un proceso primero para cambiar el estado de las tarjetas.',
          ),
        ),
      );
      return;
    }
    Tarjeta tarjetaToUpdate = tarjetasPorLista[indexLista][indexTarjeta];

    DateTime? newFechaCompletado;
    if (newEstado == EstadoTarjeta.hecho) {
      newFechaCompletado = DateTime.now();
    } else {
      newFechaCompletado = null;
    }

    tarjetaToUpdate = tarjetaToUpdate.copyWith(
      estado: newEstado,
      fechaCompletado: newFechaCompletado,
    );

    try {
      final Tarjeta? updatedCard = await _apiService.updateCard(
        _currentProcessCollectionName!,
        tarjetaToUpdate,
      );
      if (updatedCard != null) {
        setState(() {
          tarjetasPorLista[indexLista][indexTarjeta] = updatedCard;
        });
        print(
            'FLUTTER DEBUG TABLERO: Estado de tarjeta actualizado exitosamente en "$_currentProcessCollectionName": ${updatedCard.titulo}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Estado de la tarjeta "${updatedCard.titulo}" actualizado a "${newEstado.toString().split('.').last}".',
            ),
          ),
        );
      } else {
        print(
            'FLUTTER ERROR TABLERO: _cambiarEstadoTarjeta - _apiService.updateCard devolvió null.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cambiar el estado de la tarjeta.'),
          ),
        );
      }
    } catch (e) {
      print(
          'FLUTTER ERROR TABLERO: _cambiarEstadoTarjeta - Excepción al cambiar estado de tarjeta: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Error de conexión al cambiar el estado de la tarjeta: ${e.toString()}'),
        ),
      );
    }
  }

  // Elimina una tarjeta del backend
  void _eliminarTarjetaDelBackend(
    int indexLista,
    int indexTarjeta,
    String tarjetaId,
  ) async {
    print(
        'FLUTTER DEBUG TABLERO: _eliminarTarjetaDelBackend llamado. _currentProcessCollectionName: $_currentProcessCollectionName');
    if (_currentProcessCollectionName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, crea o selecciona un proceso primero para eliminar tarjetas.',
          ),
        ),
      );
      return;
    }
    String? cardTitleToDelete;
    if (indexLista < tarjetasPorLista.length &&
        indexTarjeta < tarjetasPorLista[indexLista].length) {
      cardTitleToDelete = tarjetasPorLista[indexLista][indexTarjeta].titulo;
    }

    try {
      final bool success = await _apiService.deleteCard(
        _currentProcessCollectionName!,
        tarjetaId,
      );
      if (success) {
        setState(() {
          tarjetasPorLista[indexLista].removeAt(indexTarjeta);
        });
        print(
            'FLUTTER DEBUG TABLERO: Tarjeta eliminada exitosamente de "$_currentProcessCollectionName": $tarjetaId');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tarjeta "${cardTitleToDelete ?? "desconocida"}" eliminada exitosamente.',
            ),
          ),
        );
      } else {
        print(
            'FLUTTER ERROR API: _eliminarTarjetaDelBackend - _apiService.deleteCard devolvió false.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al eliminar la tarjeta.')),
        );
      }
    } catch (e) {
      print(
          'FLUTTER ERROR API: _eliminarTarjetaDelBackend - Excepción al eliminar tarjeta: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Error de conexión al eliminar la tarjeta: ${e.toString()}'),
        ),
      );
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFF003C6C),
    appBar: AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => DashboardPage()),
          );
        },
      ),
      title: GestureDetector(
        onTap: () {
          // Asegúrate de que _currentProcessDetails esté cargado antes de intentar editar
          if (_currentProcessDetails != null) {
            _mostrarDialogoEditarProceso(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Por favor, crea o selecciona un proceso primero para editar.',
                ),
              ),
            );
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              // **¡EL CAMBIO CLAVE AQUÍ!**
              // Prioriza _currentProcessCollectionName que es la variable de estado.
              // widget.processName solo se usaría si _currentProcessCollectionName es nulo (ej. al inicio)
              _currentProcessCollectionName ?? widget.processName ?? 'Mi Tablero de Trello',
              style: const TextStyle(color: Colors.black),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.edit, size: 20, color: Colors.black54),
          ],
        ),
      ),
      backgroundColor: const Color.fromARGB(221, 255, 255, 255),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.menu),
          onSelected: (String value) {
            if (_currentProcessCollectionName == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Por favor, crea o selecciona un proceso antes de navegar.',
                  ),
                ),
              );
              return;
            }
            if (value == 'cronograma') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => TimelineScreen(
                    processName: _currentProcessCollectionName,
                  ),
                ),
              );
            } else if (value == 'panel') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => PanelTrello(
                    processName: _currentProcessCollectionName,
                  ),
                ),
              );
            } else if (value == 'tablas') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => KanbanTaskManager(
                    processName: _currentProcessCollectionName,
                  ),
                ),
              );
            }
          },
          itemBuilder: (BuildContext context) => [
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
      body: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (indiceListaEditandoTarjeta != null) {
                ocultarEdicion();
              }
            },
            child: Container(color: Colors.transparent),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < listas.length; i++)
                  ListaTrello(
                    key: ValueKey(listas[i].id),
                    id: listas[i].id,
                    titulo: listas[i].titulo,
                    tarjetas: tarjetasPorLista[i],
                    onTituloEditado: (nuevoTitulo) =>
                        editarTituloLista(i, nuevoTitulo),
                    onAgregarTarjeta: (tarjeta) => agregarTarjeta(i, tarjeta),
                    agregandoTarjeta: indiceListaEditandoTarjeta == i,
                    mostrarCampoNuevaTarjeta: () => mostrarCampoNuevaTarjeta(i),
                    keyAgregarTarjeta: keysAgregarTarjeta[i],
                    onEstadoChanged: (indexTarjeta, newEstado) {
                      _cambiarEstadoTarjeta(i, indexTarjeta, newEstado);
                    },
                    onTarjetaActualizada: (indexTarjeta, tarjetaActualizada) {
                      _actualizarTarjetaEnBackend(
                        i,
                        indexTarjeta,
                        tarjetaActualizada,
                      );
                    },
                    onEliminarTarjeta: (indexTarjeta, tarjetaId) {
                      _eliminarTarjetaDelBackend(i, indexTarjeta, tarjetaId);
                    },
                    onEliminarLista: (listId) =>
                        _eliminarListaDelBackend(i, listId),
                    ocultarEdicion: ocultarEdicion,
                  ),
                BotonAgregarLista(onAgregar: agregarListaNueva),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
}

// Asegúrate de que BotonAgregarLista también esté definido en este archivo
// o importado correctamente si está en otro lugar.
// class BotonAgregarLista extends StatelessWidget { ... }
// lib/user/lista_trello.dart
// Asegúrate de que este archivo importe tu modelo Tarjeta correctamente

// lib/user/lista_trello.dart
// Asegúrate de que este archivo importe tu modelo Tarjeta correctamente

// lib/user/lista_trello.dart
// Asegúrate de que este archivo importe tu modelo Tarjeta correctamente

// lib/user/lista_trello.dart

// lib/user/lista_trello.dart
// Asegúrate de que este archivo importe tu modelo Tarjeta correctamente

// lib/user/lista_trello.dart
// Asegúrate de que este archivo importe tu modelo Tarjeta correctamente

// lib/user/lista_trello.dart
// Asegúrate de que este archivo importe tu modelo Tarjeta correctamente

// lib/user/lista_trello.dart
// Asegúrate de que este archivo importe tu modelo Tarjeta correctamente

// lib/user/lista_trello.dart

// lib/user/lista_trello.dart
// Asegúrate de que este archivo importe tu modelo Tarjeta correctamente
class ListaTrello extends StatefulWidget {
  final String id; // AÑADIDO: Este es el ID de la lista
  final String titulo;
  final List<Tarjeta> tarjetas;
  final bool agregandoTarjeta;
  final GlobalKey? keyAgregarTarjeta;
  final ValueChanged<String> onTituloEditado;
  final ValueChanged<Tarjeta> onAgregarTarjeta;
  final VoidCallback mostrarCampoNuevaTarjeta;
  final VoidCallback ocultarEdicion;
  final Function(int index, Tarjeta tarjeta) onTarjetaActualizada;
  final Function(int index, String idTarjeta)
      onEliminarTarjeta; // Añadido idTarjeta al eliminar
  final Function(int index, EstadoTarjeta nuevoEstado) onEstadoChanged;
  final ValueChanged<String> onEliminarLista; // <-- ¡ESTO ES LO NUEVO!

  const ListaTrello({
    super.key,
    required this.id, // AÑADIDO: Ahora es un parámetro requerido
    required this.titulo,
    required this.tarjetas,
    required this.agregandoTarjeta,
    this.keyAgregarTarjeta,
    required this.onTituloEditado,
    required this.onAgregarTarjeta,
    required this.mostrarCampoNuevaTarjeta,
    required this.ocultarEdicion,
    required this.onTarjetaActualizada,
    required this.onEliminarTarjeta,
    required this.onEstadoChanged,
    required this.onEliminarLista, // <-- ¡HAZLO REQUERIDO AQUÍ!
    
  });

  @override
  State<ListaTrello> createState() => _ListaTrelloState();
}

class _ListaTrelloState extends State<ListaTrello> {
  Set<int> tarjetasEnHover = {};
  late bool editandoTituloLista;
  late TextEditingController _controllerTituloLista;
  late FocusNode _focusNodeTituloLista;
  final TextEditingController _controllerNuevaTarjeta = TextEditingController();
  final FocusNode _focusNodeNuevaTarjeta = FocusNode();

  @override
  void initState() {
    super.initState();
    editandoTituloLista = false;
    _controllerTituloLista = TextEditingController(text: widget.titulo);
    _focusNodeTituloLista = FocusNode();
    _focusNodeTituloLista.addListener(() {
      if (!_focusNodeTituloLista.hasFocus && editandoTituloLista) {
        guardarTituloLista();
      }
    });
    if (widget.agregandoTarjeta) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNodeNuevaTarjeta.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _controllerTituloLista.dispose();
    _focusNodeTituloLista.dispose();
    _controllerNuevaTarjeta.dispose();
    _focusNodeNuevaTarjeta.dispose();
    super.dispose();
  }

  void guardarTituloLista() {
    setState(() {
      editandoTituloLista = false;
      widget.onTituloEditado(_controllerTituloLista.text.trim());
      _focusNodeTituloLista.unfocus();
    });
  }

  void activarEdicionTituloLista() {
    setState(() {
      editandoTituloLista = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodeTituloLista.requestFocus();
      _controllerTituloLista.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controllerTituloLista.text.length,
      );
    });
  }

  void agregarTarjetaLocal() {
    final texto = _controllerNuevaTarjeta.text.trim();
    if (texto.isEmpty) return;

    // CORRECCIÓN APLICADA AQUÍ: Se añade el idLista
    final nuevaTarjeta = Tarjeta(
      titulo: texto,
      estado: EstadoTarjeta.pendiente,
      idLista: widget.id, // Usamos el ID de la lista actual
    );
    print(
      'FLUTTER DEBUG LISTATRELLO: ID de la nueva tarjeta ANTES de enviar al API: ${nuevaTarjeta.id}',
    );

    widget.onAgregarTarjeta(nuevaTarjeta);
    _controllerNuevaTarjeta.clear();
    _focusNodeNuevaTarjeta.unfocus();
    widget.ocultarEdicion();
  }

  void mostrarModalTarjeta(int indexTarjeta) {
    Tarjeta tarjeta = widget.tarjetas[indexTarjeta];
    final tituloController = TextEditingController(text: tarjeta.titulo);
    final descripcionController = TextEditingController(
      text: tarjeta.descripcion,
    );
    final miembroController = TextEditingController(text: tarjeta.miembro);
    DateTime? fechaInicio = tarjeta.fechaInicio;
    DateTime? fechaVencimiento = tarjeta.fechaVencimiento;
    EstadoTarjeta estadoActual = tarjeta.estado;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            // Asegúrate de que Tarjeta.tiempoRestanteCalculado exista y devuelva lo esperado
            final Map<String, dynamic> tiempoInfo =
                tarjeta.tiempoRestanteCalculado;
            final String diasHorasRestantesTexto = tiempoInfo['text'];
            final Color diasHorasRestantesColor = tiempoInfo['color'] as Color;

            final List<Widget> messagesAlert = [];

            if (estadoActual == EstadoTarjeta.hecho) {
              messagesAlert.add(
                const Text("✅ Cumplido", style: TextStyle(color: Colors.green)),
              );
            }

            return AlertDialog(
              backgroundColor: Colors.black87,
              title: TextField(
                controller: tituloController,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                decoration: const InputDecoration(
                  hintText: 'Título de la tarjeta',
                  hintStyle: TextStyle(
                    color: Colors.white54,
                    fontWeight: FontWeight.normal,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                maxLines: null,
                keyboardType: TextInputType.multiline,
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    ...messagesAlert,
                    const SizedBox(height: 8),
                    Text(
                      diasHorasRestantesTexto,
                      style: TextStyle(
                        color: diasHorasRestantesColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    buildTextField("👤 Miembro", miembroController),
                    buildTextField("📝 Descripción", descripcionController),
                    buildEstadoDropdown(estadoActual, (newValue) {
                      setStateModal(() {
                        estadoActual = newValue;
                        tarjeta = tarjeta.copyWith(estado: newValue);
                      });
                    }),
                    buildDatePicker(
                      "📅 Fecha de inicio",
                      (pickedDate) {
                        setStateModal(() {
                          fechaInicio = pickedDate;
                          tarjeta = tarjeta.copyWith(fechaInicio: pickedDate);
                        });
                      },
                      fechaInicio,
                      includeTime: false,
                    ),
                    buildDatePicker(
                      "⏳ Fecha de vencimiento",
                      (pickedDate) {
                        setStateModal(() {
                          fechaVencimiento = pickedDate;
                          tarjeta = tarjeta.copyWith(
                            fechaVencimiento: pickedDate,
                          );
                        });
                      },
                      fechaVencimiento,
                      includeTime: true,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    "Cancelar",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Tarjeta tarjetaActualizada = Tarjeta(
                      id: tarjeta.id,
                      titulo: tituloController.text.trim(),
                      descripcion: descripcionController.text.trim(),
                      miembro: miembroController.text.trim(),
                      tarea: tarjeta.tarea,
                      tiempo: tarjeta.tiempo,
                      fechaInicio: fechaInicio,
                      fechaVencimiento: fechaVencimiento,
                      estado: estadoActual,
                      fechaCompletado: tarjeta.fechaCompletado,
                      idLista: tarjeta.idLista, // Mantener el idLista existente
                    );
                    widget.onTarjetaActualizada(
                      indexTarjeta,
                      tarjetaActualizada,
                    );
                    Navigator.of(context).pop();
                  },
                  child: const Text("Guardar"),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // CORRECCIÓN CLAVE AQUÍ: Afirmar que tarjeta.id no es nulo
                    // Si tarjeta.id puede ser nulo antes de ser guardado, considera cómo manejarlo
                    // por ejemplo, si solo puedes eliminar tarjetas con un ID asignado.
                    widget.onEliminarTarjeta(indexTarjeta, tarjeta.id!);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text(
                    "Eliminar",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white12,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide.none,
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 12,
            ),
          ),
          maxLines: null,
          keyboardType: TextInputType.multiline,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Map<EstadoTarjeta, String> estadoDisplayNames = {
    EstadoTarjeta.hecho: 'HECHO',
    EstadoTarjeta.en_progreso: 'EN PROGRESO',
    EstadoTarjeta.pendiente: 'PENDIENTE',
  };

  Widget buildEstadoDropdown(
    EstadoTarjeta estadoActual,
    ValueChanged<EstadoTarjeta> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8.0),
          child: Text(
            "📝 Estado",
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<EstadoTarjeta>(
              value: estadoActual,
              dropdownColor: Colors.black,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
              style: const TextStyle(color: Colors.white),
              onChanged: (EstadoTarjeta? newValue) {
                if (newValue != null) {
                  onChanged(newValue);
                }
              },
              items:
                  EstadoTarjeta.values.map<DropdownMenuItem<EstadoTarjeta>>((
                    EstadoTarjeta value,
                  ) {
                    return DropdownMenuItem<EstadoTarjeta>(
                      value: value,
                      child: Text(
                        estadoDisplayNames[value]!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget buildDatePicker(
    String label,
    ValueChanged<DateTime?> onDatePicked,
    DateTime? currentDate, {
    bool includeTime = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        GestureDetector(
          onTap: () async {
            DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: currentDate ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
              builder: (context, child) {
                return Theme(
                  data: ThemeData.dark().copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: Color.fromARGB(255, 0, 93, 169),
                      onPrimary: Colors.white,
                      surface: Color.fromARGB(255, 45, 45, 45),
                      onSurface: Colors.white,
                    ),
                    textButtonTheme: TextButtonThemeData(
                      style: TextButton.styleFrom(
                        foregroundColor: const Color.fromARGB(255, 0, 93, 169),
                      ),
                    ),
                  ),
                  child: child!,
                );
              },
            );

            if (pickedDate != null && includeTime) {
              TimeOfDay? pickedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(
                  currentDate ?? DateTime.now(),
                ),
                builder: (context, child) {
                  return Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: Color.fromARGB(255, 0, 93, 169),
                        onPrimary: Colors.white,
                        surface: Color.fromARGB(255, 45, 45, 45),
                        onSurface: Colors.white,
                      ),
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          foregroundColor: const Color.fromARGB(
                            255,
                            0,
                            93,
                            169,
                          ),
                        ),
                      ),
                    ),
                    child: child!,
                  );
                },
              );

              if (pickedTime != null) {
                pickedDate = DateTime(
                  pickedDate.year,
                  pickedDate.month,
                  pickedDate.day,
                  pickedTime.hour,
                  pickedTime.minute,
                );
              } else {
                // Si el usuario selecciona una fecha pero cancela la hora,
                // mantener la hora existente si currentDate no es nulo
                if (currentDate != null) {
                  pickedDate = DateTime(
                    pickedDate.year,
                    pickedDate.month,
                    pickedDate.day,
                    currentDate.hour,
                    currentDate.minute,
                  );
                } else {
                  // Si no hay fecha actual, establecer hora a 00:00
                  pickedDate = DateTime(
                    pickedDate.year,
                    pickedDate.month,
                    pickedDate.day,
                    0,
                    0,
                  );
                }
              }
            }
            onDatePicked(pickedDate);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  currentDate != null
                      ? (includeTime
                          ? '${currentDate.day}/${currentDate.month}/${currentDate.year} ${currentDate.hour.toString().padLeft(2, '0')}:${currentDate.minute.toString().padLeft(2, '0')}'
                          : '${currentDate.day}/${currentDate.month}/${currentDate.year}')
                      : 'Elegir fecha y hora',
                  style: const TextStyle(color: Colors.white),
                ),
                const Icon(Icons.edit_calendar, color: Colors.white70),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Color _getColorForEstado(EstadoTarjeta estado) {
    switch (estado) {
      case EstadoTarjeta.hecho:
        return Colors.green;
      case EstadoTarjeta.en_progreso:
        return Colors.amber;
      case EstadoTarjeta.pendiente:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 27, 27, 27),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row( // Envuelve el GestureDetector y el IconButton en un Row
            children: [
              Expanded( // Permite que el TextField/Text ocupe el espacio restante
                child: GestureDetector(
                  onTap: activarEdicionTituloLista,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    child: editandoTituloLista
                        ? TextField(
                            controller: _controllerTituloLista,
                            focusNode: _focusNodeTituloLista,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onEditingComplete: guardarTituloLista,
                          )
                        : Text(
                            widget.titulo,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                  ),
                ),
              ),
              // ¡NUEVO: Botón para eliminar la lista!
              IconButton(
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                onPressed: () {
                  // Muestra un diálogo de confirmación antes de eliminar
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        backgroundColor: Colors.black87,
                        title: const Text('Eliminar Lista', style: TextStyle(color: Colors.white)),
                        content: Text(
                          '¿Estás seguro de que quieres eliminar la lista "${widget.titulo}"? Esta acción no se puede deshacer.',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // Cierra el diálogo
                            },
                            child: const Text('Cancelar', style: TextStyle(color: Colors.white)),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // Cierra el diálogo
                              widget.onEliminarLista(widget.id); // Llama al callback para eliminar la lista
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemCount: widget.tarjetas.length,
              itemBuilder: (context, index) {
                if (index < 0 || index >= widget.tarjetas.length) {
                  return SizedBox();
                }
                final tarjeta = widget.tarjetas[index];
                final bool isHovered = tarjetasEnHover.contains(index);

                // Asegúrate de que Tarjeta.tiempoRestanteCalculado exista
                final Map<String, dynamic> tiempoInfo =
                    tarjeta.tiempoRestanteCalculado;
                final String tiempoTexto = tiempoInfo['text'];
                final Color tiempoColor = tiempoInfo['color'] as Color;

                return MouseRegion(
                  onEnter: (_) => setState(() => tarjetasEnHover.add(index)),
                  onExit: (_) => setState(() => tarjetasEnHover.remove(index)),
                  child: GestureDetector(
                    onTap: () => mostrarModalTarjeta(index),
                    child: Card(
                      color: const Color.fromARGB(255, 45, 45, 45),
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 5,
                            decoration: BoxDecoration(
                              color: _getColorForEstado(tarjeta.estado),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(6),
                                topRight: Radius.circular(6),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      width: isHovered ? 24 : 0,
                                      height: 24,
                                      margin: const EdgeInsets.only(
                                        right: 8,
                                        top: 2,
                                      ),
                                      child: isHovered
                                          ? GestureDetector(
                                              onTap: () {
                                                EstadoTarjeta nuevoEstado;
                                                if (tarjeta.estado ==
                                                    EstadoTarjeta.hecho) {
                                                  nuevoEstado =
                                                      EstadoTarjeta.pendiente;
                                                } else {
                                                  nuevoEstado =
                                                      EstadoTarjeta.hecho;
                                                }
                                                widget.onEstadoChanged(
                                                  index,
                                                  nuevoEstado,
                                                );
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: _getColorForEstado(
                                                      tarjeta.estado,
                                                    ),
                                                    width: 2,
                                                  ),
                                                  color: tarjeta.estado ==
                                                          EstadoTarjeta.hecho
                                                      ? Colors.green
                                                      : Colors
                                                          .transparent,
                                                ),
                                                child: Center(
                                                  child: tarjeta.estado ==
                                                          EstadoTarjeta.hecho
                                                      ? const Icon(
                                                          Icons.check,
                                                          size: 16,
                                                          color:
                                                              Colors.white,
                                                        )
                                                      : null,
                                                ),
                                              ),
                                            )
                                          : null,
                                    ),
                                    Expanded(
                                      child: Text(
                                        tarjeta.titulo,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (tarjeta.miembro.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      '👤 ${tarjeta.miembro}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                if (tarjeta.fechaVencimiento != null ||
                                    tarjeta.fechaInicio != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      tiempoTexto,
                                      style: TextStyle(
                                        color: tiempoColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (widget.agregandoTarjeta)
            Padding(
              key: widget.keyAgregarTarjeta,
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: [
                  TextField(
                    controller: _controllerNuevaTarjeta,
                    focusNode: _focusNodeNuevaTarjeta,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Ingrese un título para esta tarjeta...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white12,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => agregarTarjetaLocal(),
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: agregarTarjetaLocal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            0,
                            93,
                            169,
                          ),
                        ),
                        child: const Text('Añadir tarjeta'),
                      ),
                      const SizedBox(width: 8.0),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: widget.ocultarEdicion,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          if (!widget.agregandoTarjeta)
            TextButton(
              onPressed: widget.mostrarCampoNuevaTarjeta,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white70,
                minimumSize: const Size(double.infinity, 36),
                alignment: Alignment.centerLeft,
              ),
              child: const Row(
                children: [
                  Icon(Icons.add, color: Colors.white70),
                  SizedBox(width: 8.0),
                  Text('Añadir otra tarjeta'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class BotonAgregarLista extends StatelessWidget {
  final VoidCallback onAgregar;
  const BotonAgregarLista({super.key, required this.onAgregar});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.all(10),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[700],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: onAgregar,
        icon: const Icon(Icons.add),
        label: const Text('Otra lista'),
      ),
    );
  }
}