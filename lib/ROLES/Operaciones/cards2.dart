import 'package:flutter/material.dart';
import 'package:login_app/ROLES/Operaciones/cronogrma/cronograma.dart';
import 'package:login_app/ROLES/Operaciones/op.dart';
import 'package:login_app/ROLES/Operaciones/panel/panel_graficas.dart';
import 'package:login_app/ROLES/Operaciones/tabla/home_screen.dart';

import 'package:login_app/super%20usario/home_page.dart';

import 'package:intl/intl.dart';
import 'package:login_app/models/tarjeta.dart';
import 'package:login_app/models/lista_datos.dart';
import 'package:login_app/services/api_service.dart';
import 'package:login_app/models/process.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:flutter/gestures.dart'; // Añade esta importación

import 'dart:io';
import 'package:excel/excel.dart' as excel;  // Alias para Excel
import 'package:flutter/material.dart' as material;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'dart:html' as html;

class TableroScreen22 extends StatefulWidget {
  final String? processName;

  const TableroScreen22({super.key, this.processName,});

  @override
  State<TableroScreen22> createState() => _TableroScreenState();
}

class _TableroScreenState extends State<TableroScreen22> {
  // Esta función debe estar en tu clase _TableroScreenState, al mismo nivel que otros métodos
Future<void> _exportToExcel() async {
  // Validar que exista información del proceso
  if (_currentProcessDetails == null) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay información del proceso para exportar'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return;
  }

  // Crear archivo Excel
  final excelFile = excel.Excel.createExcel();
  final sheet = excelFile['Sheet1']; // Usamos Sheet1 como nombre base

  // 1. Agregar encabezado con información del proceso
  sheet.appendRow(['INFORMACIÓN DEL PROCESO']);
  sheet.merge(excel.CellIndex.indexByString('A1'), excel.CellIndex.indexByString('H1'));
  
  // Estilo para el título
  sheet.cell(excel.CellIndex.indexByString('A1')).cellStyle = excel.CellStyle(
    bold: true,
    fontSize: 16,
    fontColorHex: "FF0000FF", // Azul
    horizontalAlign: excel.HorizontalAlign.Center,
  );
  final status = _currentProcessDetails!.estado;
  // 2. Detalles del proceso
  sheet.appendRow(['Nombre del Proceso:', _currentProcessDetails!.nombre_proceso]);
  sheet.appendRow(['Fecha de Inicio:', DateFormat('dd/MM/yyyy').format(_currentProcessDetails!.startDate)]);
  sheet.appendRow(['Fecha de Fin:', DateFormat('dd/MM/yyyy').format(_currentProcessDetails!.endDate)]);
  sheet.appendRow(['Estado:', _traducirEstado(status!)]);
  sheet.appendRow([]); // Fila vacía como separador

  // 3. Encabezados de las tareas
  sheet.appendRow([
    'LISTA DE TAREAS',
    '', '', '', '', '', '', '' // Celdas vacías para el merge
  ]);
  sheet.merge(excel.CellIndex.indexByString('A7'), excel.CellIndex.indexByString('H6'));
  sheet.cell(excel.CellIndex.indexByString('A7')).cellStyle = excel.CellStyle(
    bold: true,
    fontSize: 14,
    fontColorHex: "FF008000", // Verde
  );

  // 4. Encabezados de columnas
  sheet.appendRow([
    'Lista', 'Tarea', 'Estado', 'Miembro', 
    'Descripción', 'Fecha Inicio', 'Fecha Vencimiento', 'Fecha Completado'
  ]);

  // Formato para encabezados
  for (var i = 0; i < 8; i++) {
    sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 7))
      .cellStyle = excel.CellStyle(
        bold: true,
        backgroundColorHex: "FFE0E0E0", // Gris claro
    
      );
  }

  // 5. Llenar con datos de tareas
  int rowIndex = 8; // Comenzar después de los encabezados
  for (int i = 0; i < listas.length; i++) {
    final lista = listas[i];
    for (final tarjeta in tarjetasPorLista[i]) {
      sheet.appendRow([
        lista.titulo,
        tarjeta.titulo,
        _traducirEstado(tarjeta.estado.toString().split('.').last),
        tarjeta.miembro,
        tarjeta.descripcion,
        tarjeta.fechaInicio != null 
          ? DateFormat('dd/MM/yyyy HH:mm').format(tarjeta.fechaInicio!) 
          : 'Sin fecha',
        tarjeta.fechaVencimiento != null 
          ? DateFormat('dd/MM/yyyy HH:mm').format(tarjeta.fechaVencimiento!) 
          : 'Sin fecha',
        tarjeta.fechaCompletado != null 
          ? DateFormat('dd/MM/yyyy HH:mm').format(tarjeta.fechaCompletado!) 
          : 'No completado',
      ]);

      // Alternar colores de fila para mejor legibilidad
      if (rowIndex % 2 == 0) {
        for (var col = 0; col < 8; col++) {
          sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex))
            .cellStyle = excel.CellStyle(
              backgroundColorHex: "FFF5F5F5", // Gris muy claro
            );
        }
      }
      rowIndex++;
    }
  }

  // Autoajustar columnas
  for (var i = 0; i < 8; i++) {
    sheet.setColWidth(i, 20);
  }

  // Guardar el archivo

  final excelBytes = excelFile.encode(); // ✅ Solo genera los bytes sin guardar automáticamente

  if (excelBytes == null) return;

  final fileName = '${_currentProcessDetails!.nombre_proceso.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx';

  if (kIsWeb) {
    final blob = html.Blob([excelBytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  } else {
    final directory = await getDownloadsDirectory();
    final filePath = '${directory?.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(excelBytes);
    await OpenFile.open(filePath);
  }

  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Excel exportado: $fileName'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
  String _traducirEstado(String estado) {
    switch (estado) {
      case 'echo':
        return 'Completado';
      case 'pending':
        return 'Pendiente';
      case 'in_progress':
        return 'En progreso';
      case 'cancelled':
        return 'Cancelado';
      default:
        return estado;
    }
  }
  Timer? _estadoTimer;
  List<ListaDatos> listas = [];
  List<List<Tarjeta>> tarjetasPorLista = [];
  List<GlobalKey> keysAgregarTarjeta = [];
  int? indiceListaEditandoTarjeta;

  String? _currentProcessCollectionName;
  final ApiService _apiService = ApiService();
final ValueNotifier<String?> processStatusNotifier = ValueNotifier<String?>(null);
  Map<String, int> _listIdToIndexMap = {};
  final TextEditingController _processNameController = TextEditingController();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
 TimeOfDay? _selectedEndTime;
final TextEditingController _endTimeController = TextEditingController();
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  String? _selectedEstado;

  Process? _currentProcessDetails;

  @override
  void initState() {
    super.initState();
   _estadoTimer = Timer.periodic(Duration(seconds: 10), (timer) {
    if (!mounted || _currentProcessDetails == null) return;

    // Si el estado ya es "echo", cancelamos el Timer
    if (_currentProcessDetails!.estado == 'echo') {
      timer.cancel();
      return;
    }

    _verificarEstadoAutomatico();
  });
    print(
      'FLUTTER DEBUG TABLERO: initState - widget.processName: ${widget.processName}',
    );

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

  
 Future<void> _actualizarEstadoProceso(String nuevoEstado) async {
  print('Intentando actualizar estado a: $nuevoEstado');
  if (_currentProcessCollectionName == null || !mounted) {
    print('No se puede actualizar - proceso no seleccionado o widget no montado');
    return;
  }
  
  try {
    final procesoActualizado = _currentProcessDetails!.copyWith(estado: nuevoEstado);
    
    final success = await _apiService.updateProcess(
      _currentProcessCollectionName!,
      procesoActualizado,
    );

    if (success != null && mounted) {
      setState(() {
        _currentProcessDetails = procesoActualizado;
      });

      // Notificar al Dashboard del cambio de estado
      processStatusNotifier.value = nuevoEstado;

      // Mostrar diálogo de confirmación
      if (nuevoEstado == 'echo' || _currentProcessDetails!.estado != nuevoEstado) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Estado actualizado'),
              content: Text('El proceso ahora está: ${_traducirEstado(nuevoEstado)}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Aceptar'),
                ),
              ],
            ),
          );
        });
      }
    }
    
    if (nuevoEstado == 'echo' && _estadoTimer != null) {
      _estadoTimer?.cancel();
    }
  } catch (e) {
    print('Error al actualizar el estado: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar el estado')),
      );
    }
  }
}




void _verificarEstadoAutomatico() {
  if (_currentProcessDetails == null) return;
  
  final ahora = DateTime.now();
  final fechaInicio = _currentProcessDetails!.startDate;
  final fechaFin = _currentProcessDetails!.endDate;
  
  final nuevoEstado = _calcularEstadoProceso(fechaInicio, fechaFin);
  
  if (nuevoEstado != _currentProcessDetails!.estado) {
    _actualizarEstadoProceso(nuevoEstado);
  }
}
  @override
  void dispose() {
      _estadoTimer?.cancel();
    _processNameController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
      _endTimeController.dispose(); // Añade esta línea
    super.dispose();
  }

  Future<void> _loadProcessDetails() async {
  if (_currentProcessCollectionName == null) return;
  try {
    final Process? process = await _apiService.getProcessByName(
      _currentProcessCollectionName!,
    );
    setState(() {
      _currentProcessDetails = process;
    });
    // Añade esta línea para verificar el estado al cargar los detalles
    _verificarEstadoAutomatico();
    print(
      'FLUTTER DEBUG TABLERO: Detalles del proceso cargados: ${_currentProcessDetails?.nombre_proceso}, Estado: ${_currentProcessDetails?.estado}',
    );
  } catch (e) {
    print('FLUTTER ERROR TABLERO: Error al cargar detalles del proceso: $e');
  }
}

  Future<void> _loadListsFromBackend() async {
    print(
      'FLUTTER DEBUG TABLERO: _loadListsFromBackend llamado. _currentProcessCollectionName: $_currentProcessCollectionName',
    );
    if (_currentProcessCollectionName == null) {
      print(
        'FLUTTER DEBUG TABLERO: _loadListsFromBackend - No hay proceso seleccionado/creado. No se cargan listas.',
      );
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
          tarjetasPorLista.add([]);
          keysAgregarTarjeta.add(GlobalKey());
          _listIdToIndexMap[loadedLists[i].id] = i;
        }
      });

      if (listas.isEmpty) {
        await _createDefaultListIfEmpty();
      }

      print(
        'FLUTTER DEBUG TABLERO: Listas cargadas exitosamente del backend para el proceso: $_currentProcessCollectionName. Cantidad: ${listas.length}',
      );
    } catch (e) {
      print(
        'FLUTTER ERROR TABLERO: _loadListsFromBackend - Error al cargar listas del backend para $_currentProcessCollectionName: $e',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar las listas: ${e.toString()}')),
      );
    }
  }

  Future<void> _createDefaultListIfEmpty() async {
    print(
      'FLUTTER DEBUG TABLERO: _createDefaultListIfEmpty - Intentando crear lista por defecto.',
    );
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
          'FLUTTER DEBUG TABLERO: _createDefaultListIfEmpty - Lista por defecto creada en backend con ID: ${createdList.id}',
        );
      } else {
        print(
          'FLUTTER ERROR TABLERO: _createDefaultListIfEmpty - Falló la creación de la lista por defecto.',
        );
      }
    } catch (e) {
      print(
        'FLUTTER ERROR TABLERO: _createDefaultListIfEmpty - Excepción al crear lista por defecto: $e',
      );
    }
  }

  Future<void> _loadCardsFromBackend() async {
    print(
      'FLUTTER DEBUG TABLERO: _loadCardsFromBackend llamado. _currentProcessCollectionName: $_currentProcessCollectionName',
    );
    if (_currentProcessCollectionName == null) {
      print(
        'FLUTTER DEBUG TABLERO: _loadCardsFromBackend - No hay proceso seleccionado/creado. No se cargan tarjetas.',
      );
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
        tarjetasPorLista = List.generate(listas.length, (_) => []);

        for (var card in loadedCards) {
          final int? listIndex = _listIdToIndexMap[card.idLista];
          if (listIndex != null && listIndex < tarjetasPorLista.length) {
            tarjetasPorLista[listIndex].add(card);
          } else {
            print(
              'FLUTTER WARNING TABLERO: Tarjeta "${card.titulo}" con idLista "${card.idLista}" no tiene una lista correspondiente en el frontend. Asignando a la primera lista si existe.',
            );
            if (tarjetasPorLista.isNotEmpty) {
              tarjetasPorLista[0].add(card);
            } else {
              print(
                'FLUTTER WARNING TABLERO: No hay listas disponibles para asignar la tarjeta huérfana.',
              );
            }
          }
        }
      });
      print(
        'FLUTTER DEBUG TABLERO: Tarjetas cargadas exitosamente del backend para el proceso: $_currentProcessCollectionName. Cantidad: ${loadedCards.length}',
      );
    } catch (e) {
      print(
        'FLUTTER ERROR TABLERO: _loadCardsFromBackend - Error al cargar tarjetas del backend para $_currentProcessCollectionName: $e',
      );
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
  _endTimeController.clear();
  _selectedStartDate = null;
  _selectedEndDate = null;
  _selectedEndTime = null;

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: Colors.grey[100],
            title: const Text('Crear Nuevo Proceso', style: TextStyle(color: Colors.black)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _processNameController,
                    decoration: const InputDecoration(
                      hintText: "Nombre del Proceso (Ej. Proyecto X)",
                      labelText: 'Nombre del Proceso',
                      labelStyle: TextStyle(color: Colors.black),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.red),
                      ),
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
                          _startDateController.text = DateFormat('dd/MM/yyyy').format(picked);
                        });
                      }
                    },
                    child: AbsorbPointer(
                      child: TextField(
                        controller: _startDateController,
                        decoration: const InputDecoration(
                          labelText: 'Fecha de Inicio',
                          labelStyle: TextStyle(color: Colors.black),
                          hintText: 'Selecciona la fecha de inicio',
                          suffixIcon: Icon(Icons.calendar_today, color: Colors.black),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final DateTime? pickedDate = await showDatePicker(
                        context: dialogContext,
                        initialDate: _selectedEndDate ?? _selectedStartDate ?? DateTime.now(),
                        firstDate: _selectedStartDate ?? DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          _selectedEndDate = pickedDate;
                          _endDateController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
                        });
                      }
                    },
                    child: AbsorbPointer(
                      child: TextField(
                        controller: _endDateController,
                        decoration: const InputDecoration(
                          labelText: 'Fecha de Fin',
                          labelStyle: TextStyle(color: Colors.black),
                          hintText: 'Selecciona la fecha de fin',
                          suffixIcon: Icon(Icons.calendar_today, color: Colors.black),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final TimeOfDay? pickedTime = await showTimePicker(
                        context: dialogContext,
                        initialTime: _selectedEndTime ?? TimeOfDay.now(),
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.light().copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Colors.red,
                                onPrimary: Colors.white,
                                surface: Colors.white,
                                onSurface: Colors.black,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (pickedTime != null) {
                        setState(() {
                          _selectedEndTime = pickedTime;
                          _endTimeController.text = pickedTime.format(context);
                        });
                      }
                    },
                    child: AbsorbPointer(
                      child: TextField(
                        controller: _endTimeController,
                        decoration: const InputDecoration(
                          labelText: 'Hora de Fin',
                          labelStyle: TextStyle(color: Colors.black),
                          hintText: 'Selecciona la hora de fin',
                          suffixIcon: Icon(Icons.access_time, color: Colors.black),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancelar', style: TextStyle(color: Colors.black)),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => DashboardPage()),
                  );
                },
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Guardar', style: TextStyle(color: Colors.white)),
                onPressed: () async {
                  final String name = _processNameController.text.trim();

                  if (name.isEmpty) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text('Por favor, ingresa un nombre para el proceso.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  if (_selectedStartDate == null) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text('Por favor, selecciona una fecha de inicio.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  if (_selectedEndDate == null) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text('Por favor, selecciona una fecha de fin.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  if (_selectedEndTime == null) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text('Por favor, selecciona una hora de fin.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Combinar fecha y hora de fin
                  final DateTime endDateTime = DateTime(
                    _selectedEndDate!.year,
                    _selectedEndDate!.month,
                    _selectedEndDate!.day,
                    _selectedEndTime!.hour,
                    _selectedEndTime!.minute,
                  );

                  if (endDateTime.isBefore(_selectedStartDate!)) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text('La fecha y hora de fin no puede ser anterior a la fecha de inicio.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Mostrar diálogo de confirmación antes de guardar
                  final bool confirm = await showDialog(
                    context: dialogContext,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        backgroundColor: Colors.grey[100],
                        title: const Text('Confirmar creación', style: TextStyle(color: Colors.black)),
                        content: const Text(
                          '¿Estás seguro de crear este proceso?\n\nUna vez creado, las fechas establecidas no podrán ser modificadas.',
                          style: TextStyle(color: Colors.black),
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancelar', style: TextStyle(color: Colors.black)),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Confirmar', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirm == true) {
                    await _saveProcessCollectionToBackend(
                      name,
                      _selectedStartDate!,
                      endDateTime,
                    );
                    if (_currentProcessCollectionName != null) {
                      Navigator.of(dialogContext).pop();
                      await _loadListsFromBackend();
                      await _loadCardsFromBackend();
                    }
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

String _calcularEstadoProceso(DateTime startDate, DateTime endDate) {
   final now = DateTime.now().toLocal();
  startDate = startDate.toLocal();
  endDate = endDate.toLocal();
 
  print('Verificando estado: Ahora: $now, Inicio: $startDate, Fin: $endDate');
  
  if (now.isBefore(startDate)) {
    return 'pendiente';
  } 
  else if ((now.isAfter(startDate) || now.isAtSameMomentAs(startDate)) && 
           (now.isBefore(endDate) || now.isAtSameMomentAs(endDate))) {
    return 'en proceso';
  } 
  else {
    return 'echo';
  }
}
  Future<void> _saveProcessCollectionToBackend(
  String nombre_proceso,
  DateTime startDate,
  DateTime endDate,
) async {
  // Calcular el estado automáticamente
  final String estado = _calcularEstadoProceso(startDate, endDate);
  
  print('FLUTTER DEBUG TABLERO: _saveProcessCollectionToBackend llamado con nombre: $nombre_proceso, inicio: $startDate, fin: $endDate, estado calculado: $estado');
  
  try {
    final Process newProcessData = Process(
      nombre_proceso: nombre_proceso,
      startDate: startDate,
      endDate: endDate,
      estado: estado, // Usamos el estado calculado
    );

    final String? createdCollectionName = await _apiService.createProcess(
      newProcessData,
    );

    if (createdCollectionName != null) {
      setState(() {
        _currentProcessCollectionName = createdCollectionName;
        _currentProcessDetails = newProcessData.copyWith(
          nombre_proceso: createdCollectionName,
        );
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastProcessName', createdCollectionName);

      print('FLUTTER DEBUG TABLERO: Proceso creado con estado automático: $estado');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Proceso "$nombre_proceso" creado con estado: $estado'),
          backgroundColor: const Color.fromARGB(255, 20, 170, 6),
        ),
      );
    } else {
      print('FLUTTER ERROR TABLERO: Error al crear proceso');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al guardar el proceso'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    print('FLUTTER ERROR TABLERO: Excepción al guardar proceso: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error de conexión: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

 
 
  

  
  void mostrarCampoNuevaTarjeta(int indexLista) {
    setState(() {
      indiceListaEditandoTarjeta = indexLista;
    });
    print(
      'FLUTTER DEBUG TABLERO: Mostrando campo de nueva tarjeta para lista $indexLista.',
    );
  }

  void ocultarEdicion() {
    if (indiceListaEditandoTarjeta != null) {
      setState(() {
        indiceListaEditandoTarjeta = null;
      });
      print('FLUTTER DEBUG TABLERO: Ocultando campo de edición de tarjeta.');
    }
  }

  

  void _actualizarTarjetaEnBackend(
    int indexLista,
    int indexTarjeta,
    Tarjeta tarjetaActualizada,
  ) async {
    print(
      'FLUTTER DEBUG TABLERO: _actualizarTarjetaEnBackend llamado. _currentProcessCollectionName: $_currentProcessCollectionName',
    );
    if (_currentProcessCollectionName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, crea o selecciona un proceso primero para actualizar tarjetas.'),
          backgroundColor: Colors.red,
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
          'FLUTTER DEBUG TABLERO: Tarjeta actualizada exitosamente en "$_currentProcessCollectionName": ${updatedCard.titulo}',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tarjeta "${updatedCard.titulo}" actualizada exitosamente.'),
            backgroundColor: const Color.fromARGB(255, 20, 170, 6),
          ),
        );
      } else {
        print(
          'FLUTTER ERROR TABLERO: _actualizarTarjetaEnBackend - _apiService.updateCard devolvió null.',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al actualizar la tarjeta.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print(
        'FLUTTER ERROR TABLERO: _actualizarTarjetaEnBackend - Excepción al actualizar tarjeta: $e',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de conexión al actualizar la tarjeta: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _cambiarEstadoTarjeta(
    int indexLista,
    int indexTarjeta,
    EstadoTarjeta newEstado,
  ) async {
    print(
      'FLUTTER DEBUG TABLERO: _cambiarEstadoTarjeta llamado. _currentProcessCollectionName: $_currentProcessCollectionName',
    );
    if (_currentProcessCollectionName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, crea o selecciona un proceso primero para cambiar el estado de las tarjetas.'),
          backgroundColor: Colors.red,
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
          'FLUTTER DEBUG TABLERO: Estado de tarjeta actualizado exitosamente en "$_currentProcessCollectionName": ${updatedCard.titulo}',
        );
       
      } else {
        print(
          'FLUTTER ERROR TABLERO: _cambiarEstadoTarjeta - _apiService.updateCard devolvió null.',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al cambiar el estado de la tarjeta.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print(
        'FLUTTER ERROR TABLERO: _cambiarEstadoTarjeta - Excepción al cambiar estado de tarjeta: $e',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de conexión al cambiar el estado de la tarjeta: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _mostrarDialogoTienda(Tarjeta tarjeta, int listaIndex, int tarjetaIndex) {
  final TextEditingController descripcionController = 
    TextEditingController(text: tarjeta.descripcionTienda);
  
  // Lista de opciones válidas
  final opcionesValidas = ['Pick', 'Canales Propios', 'Agregadores', 'Kioscos'];
  
  // Verificar que el valor actual exista en las opciones válidas
  String? tiendaSeleccionada = opcionesValidas.contains(tarjeta.tiendaAsignada) 
    ? tarjeta.tiendaAsignada 
    : null;

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Asignación de código de tienda'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: tiendaSeleccionada,
              items: opcionesValidas
                  .map((tienda) => DropdownMenuItem(
                        value: tienda,
                        child: Text(tienda),
                      ))
                  .toList(),
              onChanged: (value) {
                tiendaSeleccionada = value;
              },
              decoration: const InputDecoration(
                labelText: 'Seleccione un canal',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descripcionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final tarjetaActualizada = tarjeta.copyWith(
                tiendaAsignada: tiendaSeleccionada ?? '',
                descripcionTienda: descripcionController.text,
              );
              _actualizarTarjetaEnBackend(
                  listaIndex, tarjetaIndex, tarjetaActualizada);
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      );
    },
  );
}
 @override
Widget build(BuildContext context) {
  // Verificar el estado cada vez que se construye la pantalla
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _verificarEstadoAutomatico();
  });
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
    appBar: AppBar(
  leading: IconButton(
    icon: const Icon(Icons.arrow_back, color: Colors.white),
    onPressed: () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DashboardPage22()),
      );
    },
  ),
  title: GestureDetector(
    onTap: () {},
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _currentProcessCollectionName ?? widget.processName ?? 'Mi Tablero de Trello',
          style: const TextStyle(color: Colors.white),
        ),
      ],
    ),
  ),
  backgroundColor: Colors.black,
  actions: [
    IconButton(
      icon: const Icon(Icons.download, color: Colors.white),
      onPressed: _exportToExcel,
      tooltip: 'Exportar a Excel',
    ),
    PopupMenuButton<String>(
            icon: const Icon(Icons.menu, color: Colors.white),
            onSelected: (String value) {
              if (_currentProcessCollectionName == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Por favor, crea o selecciona un proceso antes de navegar.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              if (value == 'cronograma') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlannerScreenOP(
                      processName: _currentProcessCollectionName,
                    ),
                  ),
                );
              } else if (value == 'panel') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PanelTrelloOp(
                      processName: _currentProcessCollectionName,
                    ),
                  ),
                );
              } else if (value == 'tablas') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => KanbanTaskManagerOp(
                      processName: _currentProcessCollectionName,
                    ),
                  ),
                );
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'cronograma',
                child: Text('Cronograma', style: TextStyle(color: Colors.black)),
              ),
              const PopupMenuItem<String>(
                value: 'tablas',
                child: Text('Tablas', style: TextStyle(color: Colors.black)),
              ),
              const PopupMenuItem<String>(
                value: 'panel',
                child: Text('Panel', style: TextStyle(color: Colors.black)),
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
        if (indiceListaEditandoTarjeta != null) ocultarEdicion();
      },
      child: Container(color: Colors.transparent),
    ),
    
    // Scrollbar POSICIONADO ABAJO
    Positioned.fill(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 4), // Espacio para la barra
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: { 
              PointerDeviceKind.touch, 
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
            },
          ),
          child: Scrollbar(
            controller: ScrollController(), // Controlador explícito
            thumbVisibility: true,
            trackVisibility: true,
            thickness: 10,
            radius: const Radius.circular(10),
            notificationPredicate: (notification) => notification.depth == 0,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Container(
                padding: const EdgeInsets.only(bottom: 12), // Espacio extra
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < listas.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ListaTrello(
                           key: ValueKey(listas[i].id),
                      id: listas[i].id,
                      titulo: listas[i].titulo,
                      tarjetas: tarjetasPorLista[i],
          
                      agregandoTarjeta: indiceListaEditandoTarjeta == i,
                      mostrarCampoNuevaTarjeta: () => mostrarCampoNuevaTarjeta(i),
                      keyAgregarTarjeta: keysAgregarTarjeta[i],
                      onEstadoChanged: (indexTarjeta, newEstado) {
                        _cambiarEstadoTarjeta(i, indexTarjeta, newEstado);
                      },
    onTiendaSelected: (indexTarjeta) {
      _mostrarDialogoTienda(
        tarjetasPorLista[i][indexTarjeta], 
        i,  // índice de la lista
        indexTarjeta  // índice de la tarjeta
      );
    },
    ocultarEdicion: ocultarEdicion,
  ),
)
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  ],
),
    );
  }
}
class ListaTrello extends StatefulWidget {
  final String id;
  final String titulo;
  final List<Tarjeta> tarjetas;
  final bool agregandoTarjeta;
  final GlobalKey? keyAgregarTarjeta;


  final VoidCallback mostrarCampoNuevaTarjeta;
  final VoidCallback ocultarEdicion;


  final Function(int index, EstadoTarjeta nuevoEstado) onEstadoChanged;
final Function(int index) onTiendaSelected; 

  const ListaTrello({
    super.key,
    required this.id,
    required this.titulo,
    required this.tarjetas,
    required this.agregandoTarjeta,
    this.keyAgregarTarjeta,


    required this.mostrarCampoNuevaTarjeta,
    required this.ocultarEdicion,


    required this.onEstadoChanged,
 required this.onTiendaSelected, // <-- Añade este parámetro
  });

  @override
  State<ListaTrello> createState() => _ListaTrelloState();
}

class _ListaTrelloState extends State<ListaTrello> {
  Set<int> tarjetasEnHover = {};
  late bool editandoTituloLista;
  late TextEditingController _controllerTituloLista;
    final ApiService _apiService = ApiService();
      List<List<Tarjeta>> tarjetasPorLista = [];
  late FocusNode _focusNodeTituloLista;
    String? _currentProcessCollectionName;
  final TextEditingController _controllerNuevaTarjeta = TextEditingController();
  final FocusNode _focusNodeNuevaTarjeta = FocusNode();
 
  @override
  void initState() {
    super.initState();
    editandoTituloLista = false;
    _controllerTituloLista = TextEditingController(text: widget.titulo);
    _focusNodeTituloLista = FocusNode();
    _focusNodeTituloLista.addListener(() {
     
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

  
 void mostrarModalTarjeta(int indexTarjeta) {
  Tarjeta tarjeta = widget.tarjetas[indexTarjeta];
  
  final Map<String, dynamic> tiempoInfo = tarjeta.tiempoRestanteCalculado;
  final String diasHorasRestantesTexto = tiempoInfo['text'];
  final Color diasHorasRestantesColor = tiempoInfo['color'] as Color;

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          tarjeta.titulo,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (tarjeta.estado == EstadoTarjeta.hecho)
                const Text("✅ Cumplido", style: TextStyle(color: Colors.green)),
              const SizedBox(height: 8),
              Text(
                diasHorasRestantesTexto,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              if (tarjeta.miembro.isNotEmpty)
                buildInfoRow("👤 Miembro", tarjeta.miembro),
              if (tarjeta.descripcion.isNotEmpty)
                buildInfoRow("📝 Descripción", tarjeta.descripcion),
              buildInfoRow("📝 Estado", _getEstadoText(tarjeta.estado)),
              if (tarjeta.fechaInicio != null)
                buildInfoRow(
                  "📅 Fecha de inicio", 
                  DateFormat('dd/MM/yyyy').format(tarjeta.fechaInicio!)
                ),
              if (tarjeta.fechaVencimiento != null)
                buildInfoRow(
                  "⏳ Fecha de vencimiento", 
                  DateFormat('dd/MM/yyyy HH:mm').format(tarjeta.fechaVencimiento!)
                  ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cerrar", style: TextStyle(color: Colors.black)),
          ),
        ],
      );
    },
  );
}

String _getEstadoText(EstadoTarjeta estado) {
  switch (estado) {
    case EstadoTarjeta.hecho:
      return 'Completado';
    case EstadoTarjeta.en_progreso:
      return 'En progreso';
    case EstadoTarjeta.pendiente:
      return 'Pendiente';
  }
}

Widget buildInfoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
          ),
        ),
      ],
    ),
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
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide.none,
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<EstadoTarjeta>(
              value: estadoActual,
              dropdownColor: Colors.white,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
              style: TextStyle(
                color: estadoActual == EstadoTarjeta.hecho ? Colors.green : Colors.black, // Verde para estado "hecho"
              ),
              onChanged: (EstadoTarjeta? newValue) {
                if (newValue != null) {
                  onChanged(newValue);
                }
              },
              items: EstadoTarjeta.values.map<DropdownMenuItem<EstadoTarjeta>>((
                EstadoTarjeta value,
              ) {
                return DropdownMenuItem<EstadoTarjeta>(
                  value: value,
                  child: Text(
                    estadoDisplayNames[value]!,
                    style: TextStyle(
                      color: value == EstadoTarjeta.hecho ? const Color.fromARGB(255, 0, 0, 0) : Colors.black, // Verde para estado "hecho"
                    ),
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
              color: Colors.black,
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
                  data: ThemeData.light().copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Colors.red,
                      onPrimary: Colors.white,
                      surface: Colors.white,
                      onSurface: Colors.black,
                    ),
                    textButtonTheme: TextButtonThemeData(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
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
                initialTime: TimeOfDay.fromDateTime(currentDate ?? DateTime.now()),
                builder: (context, child) {
                  return Theme(
                    data: ThemeData.light().copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Colors.red,
                        onPrimary: Colors.white,
                        surface: Colors.white,
                        onSurface: Colors.black,
                      ),
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
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
              }
            }
            onDatePicked(pickedDate);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
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
                  style: const TextStyle(color: Colors.black), // Texto en negro
                ),
                const Icon(Icons.edit_calendar, color: Colors.black),
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
        return Colors.green; // Cambiado de rojo a verde
      case EstadoTarjeta.en_progreso:
         return Colors.orange.shade600;
      case EstadoTarjeta.pendiente:
         return Colors.grey.shade600; // Gris más oscuro
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
       border: material.Border.all(color: material.Colors.grey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: editandoTituloLista
                        ? TextField(
                            controller: _controllerTituloLista,
                            focusNode: _focusNodeTituloLista,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                         
                          )
                        : Text(
                            widget.titulo,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                  ),
                ),
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

                final Map<String, dynamic> tiempoInfo = tarjeta.tiempoRestanteCalculado;
                final String tiempoTexto = tiempoInfo['text'];
                final Color tiempoColor = tiempoInfo['color'] as Color;

                return MouseRegion(
                  onEnter: (_) => setState(() => tarjetasEnHover.add(index)),
                  onExit: (_) => setState(() => tarjetasEnHover.remove(index)),
                  child: GestureDetector(
    onTap: () {
  if (tarjeta.titulo == 'Asignación de código de tienda') {
    widget.onTiendaSelected(index); // Esto debería llamar a _mostrarDialogoTienda
  } else {
    mostrarModalTarjeta(index);
  }
},
                    child: Card(
                  color: const Color.fromARGB(255, 255, 255, 255), // Fondo blanco para mejor contraste
                   elevation: 7, 
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
                                  Container(
      width: 24,
      height: 24,
      margin: const EdgeInsets.only(right: 8, top: 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
      
        color: tarjeta.estado == EstadoTarjeta.hecho
            ? Colors.green
            : Colors.transparent,
      ),
      child: Center(
        child: tarjeta.estado == EstadoTarjeta.hecho
            ? const Icon(
                Icons.check,
                size: 16,
                color: Colors.white,
              )
            : null,
      ),
    ),
    Expanded(
      child: Text(
        tarjeta.titulo,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),


                                  ],
                                ),
                                if (tarjeta.tiendaAsignada.isNotEmpty)
  Padding(
    padding: const EdgeInsets.only(top: 4.0),
    child: Row(
      children: [
        Icon(Icons.store, size: 14, color: Colors.grey),
        SizedBox(width: 4),
        Text(
          '${tarjeta.tiendaAsignada}',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    ),
  ),
                                if (tarjeta.miembro.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      '👤 ${tarjeta.miembro}',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                if (tarjeta.fechaVencimiento != null || tarjeta.fechaInicio != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      tiempoTexto,
                                      style: const TextStyle( // Texto en negro
                                        color: Colors.black,
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
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Ingrese un título para esta tarjeta...',
                      hintStyle: const TextStyle(color: Color.fromARGB(255, 29, 28, 28)),
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    ),
                    onSubmitted: (_) => (),
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      
                      const SizedBox(width: 8.0),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: widget.ocultarEdicion,
                      ),
                    ],
                  ),
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
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: onAgregar,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Otra lista', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}