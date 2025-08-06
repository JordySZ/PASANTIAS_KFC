import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:login_app/ROLES/A.R/cronogrma/cronograma.dart';
import 'package:login_app/ROLES/A.R/panel/panel_graficas.dart';
import 'package:login_app/ROLES/A.R/tabla/home_screen.dart';
import 'package:login_app/ROLES/CONT/cronogrma/cronograma.dart';
import 'package:login_app/ROLES/CONT/panel/panel_graficas.dart';
import 'package:login_app/ROLES/CONT/tabla/home_screen.dart';
import 'package:login_app/ROLES/Operaciones/panel/panel_graficas.dart';
import 'package:login_app/models/tarjeta.dart';
import 'package:login_app/models/lista_datos.dart';
import 'package:login_app/models/process.dart';
import 'package:login_app/services/api_service.dart';
import 'package:login_app/super%20usario/cronogrma/cronograma.dart';
import 'package:login_app/super%20usario/panel/panel_graficas.dart';
import 'package:login_app/super%20usario/tabla/home_screen.dart';

import 'dart:async';

class DSIScreen extends StatefulWidget {
  final String? processName;

  const DSIScreen({super.key, this.processName});

  @override
  State<DSIScreen> createState() => _ARTScreenState();
}

class _ARTScreenState extends State<DSIScreen> with WidgetsBindingObserver {
  

  final ApiService _apiService = ApiService();
  List<ListaDatos> listas = [];
  List<List<Tarjeta>> tarjetasPorLista = [];
  Map<String, int> _listIdToIndexMap = {};
  Process? _currentProcessDetails;
  bool _isScreenVisible = true;
 String? _currentProcessCollectionName;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  void _loadData() {
    _loadProcessDetails().then((_) {
      _loadListsFromBackend().then((_) {
        _loadCardsFromBackend();
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Pantalla vuelve a estar visible
      _isScreenVisible = true;
      _loadData(); // Cargar datos inmediatamente al volver
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Pantalla ya no está visible
      _isScreenVisible = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadProcessDetails() async {
    if (widget.processName == null) return;
    try {
      final Process? process = await _apiService.getProcessByName(widget.processName!);
      setState(() {
        _currentProcessDetails = process;
         _currentProcessCollectionName = widget.processName;  // Añade esta línea
      });
    } catch (e) {
      print('Error al cargar detalles del proceso: $e');
    }
  }

  Future<void> _loadListsFromBackend() async {
    if (widget.processName == null) return;
    try {
      final List<ListaDatos> loadedLists = await _apiService.getLists(widget.processName!);

      setState(() {
        listas.clear();
        tarjetasPorLista.clear();
        _listIdToIndexMap.clear();

        for (int i = 0; i < loadedLists.length; i++) {
          listas.add(loadedLists[i]);
          tarjetasPorLista.add([]);
          _listIdToIndexMap[loadedLists[i].id] = i;
        }
      });
    } catch (e) {
      print('Error al cargar listas: $e');
    }
  }

  Future<void> _loadCardsFromBackend() async {
    if (widget.processName == null) return;
    try {
      final List<Tarjeta> loadedCards = await _apiService.getCards(widget.processName!);
      
      setState(() {
        tarjetasPorLista = List.generate(listas.length, (_) => []);

        for (var card in loadedCards) {
          final int? listIndex = _listIdToIndexMap[card.idLista];
          if (listIndex != null && listIndex < tarjetasPorLista.length) {
            tarjetasPorLista[listIndex].add(card);
          }
        }
      });
    } catch (e) {
      print('Error al cargar tarjetas: $e');
    }
  }

  Future<void> _actualizarEstadoTarjeta(Tarjeta tarjeta, EstadoTarjeta nuevoEstado) async {
    try {
      final tarjetaActualizada = tarjeta.copyWith(
        estado: nuevoEstado,
        fechaCompletado: nuevoEstado == EstadoTarjeta.hecho ? DateTime.now() : null,
      );

      final success = await _apiService.updateCard(
        widget.processName!,
        tarjetaActualizada,
      );

      if (success != null) {
        setState(() {
          final listIndex = _listIdToIndexMap[tarjeta.idLista];
          if (listIndex != null) {
            final cardIndex = tarjetasPorLista[listIndex].indexWhere((t) => t.id == tarjeta.id);
            if (cardIndex != -1) {
              tarjetasPorLista[listIndex][cardIndex] = tarjetaActualizada;
            }
          }
        });
      }
    } catch (e) {
      print('Error al actualizar tarjeta: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al actualizar la tarjeta'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<List<Tarjeta>> _filterdsiCards() {
    return listas.map((lista) {
      final index = _listIdToIndexMap[lista.id]!;
      return tarjetasPorLista[index].where((tarjeta) {
        if (tarjeta.miembro.trim().toLowerCase() == 'dsi') return true;
        if (tarjeta.miembro.toLowerCase().contains('dsi')) return true;
        final miembros = tarjeta.miembro.split(',').map((m) => m.trim().toLowerCase()).toList();
        return miembros.contains('dsi');
      }).toList();
    }).toList();
  }

  Color _getColorForEstado(EstadoTarjeta estado) {
    switch (estado) {
      case EstadoTarjeta.hecho:
        return Colors.green;
      case EstadoTarjeta.en_progreso:
        return Colors.orange;
      case EstadoTarjeta.pendiente:
        return Colors.grey;
    }
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

  void _mostrarDetallesTarjeta(Tarjeta tarjeta) {
    final tiempoInfo = tarjeta.tiempoRestanteCalculado;
    final tiempoTexto = tiempoInfo['text'];
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(tarjeta.titulo),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Estado: ${_getEstadoText(tarjeta.estado)}'),
                Text('Tiempo: $tiempoTexto'),
                if (tarjeta.miembro.isNotEmpty)
                  Text('Responsable: ${tarjeta.miembro}'),
                if (tarjeta.descripcion.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('Descripción: ${tarjeta.descripcion}'),
                  ),
                if (tarjeta.fechaInicio != null)
                  Text('Inicio: ${DateFormat('dd/MM/yyyy').format(tarjeta.fechaInicio!)}'),
                if (tarjeta.fechaVencimiento != null)
                  Text('Vencimiento: ${DateFormat('dd/MM/yyyy').format(tarjeta.fechaVencimiento!)}'),
                if (tarjeta.fechaCompletado != null)
                  Text('Completado: ${DateFormat('dd/MM/yyyy').format(tarjeta.fechaCompletado!)}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
            if (tarjeta.estado != EstadoTarjeta.hecho)
              TextButton(
                onPressed: () {
                  _actualizarEstadoTarjeta(tarjeta, EstadoTarjeta.hecho);
                  Navigator.pop(context);
                },
                child: const Text('Marcar como completado'),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredCards = _filterdsiCards();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tareas dsi - ${widget.processName ?? ''}',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        actions: [
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
                    builder: (context) => PlannerScreenCont(
                     processName: _currentProcessCollectionName,
                    ),
                  ),
                );
              } else if (value == 'panel') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PanelTrelloCont(
                     processName: _currentProcessCollectionName,
                    ),
                  ),
                );
              } else if (value == 'tablas') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => KanbanTaskManagerCont(
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
      body: _buildContent(filteredCards),
    );
  }

  Widget _buildContent(List<List<Tarjeta>> filteredCards) {
    if (listas.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scrollbar(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < listas.length; i++)
                if (filteredCards[i].isNotEmpty)
                  _buildLista(listas[i], filteredCards[i]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLista(ListaDatos lista, List<Tarjeta> tarjetas) {
    return Container(
      width: 300,
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              lista.titulo,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tarjetas.length,
              itemBuilder: (context, index) {
                final tarjeta = tarjetas[index];
                final isdsiOnly = tarjeta.miembro.trim().toLowerCase() == 'dsi';

                return GestureDetector(
                  onTap: () => _mostrarDetallesTarjeta(tarjeta),
                  onLongPress: () {
                    if (tarjeta.estado != EstadoTarjeta.hecho) {
                      _actualizarEstadoTarjeta(tarjeta, EstadoTarjeta.hecho);
                    }
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 5,
                          decoration: BoxDecoration(
                            color: _getColorForEstado(tarjeta.estado),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      final nuevoEstado = tarjeta.estado == EstadoTarjeta.hecho
                                          ? EstadoTarjeta.pendiente
                                          : EstadoTarjeta.hecho;
                                      _actualizarEstadoTarjeta(tarjeta, nuevoEstado);
                                    },
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: tarjeta.estado == EstadoTarjeta.hecho
                                            ? Colors.green
                                            : Colors.grey[300],
                                        border: Border.all(
                                          color: tarjeta.estado == EstadoTarjeta.hecho
                                              ? Colors.green
                                              : Colors.grey,
                                        ),
                                      ),
                                      child: tarjeta.estado == EstadoTarjeta.hecho
                                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                                          : null,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      tarjeta.titulo,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        decoration: tarjeta.estado == EstadoTarjeta.hecho
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (!isdsiOnly)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    'Compartido con: ${tarjeta.miembro.replaceAll('Infraestructura', '').replaceAll(',,', ',').trim()}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              if (tarjeta.fechaVencimiento != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    tarjeta.tiempoRestanteCalculado['text'],
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}