import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:login_app/models/tarjeta.dart';
import 'package:login_app/models/lista_datos.dart';
import 'package:login_app/models/process.dart';
import 'package:login_app/services/api_service.dart';

class CONTScreen extends StatefulWidget {
  final String? processName;

  const CONTScreen({super.key, this.processName});

  @override
  State<CONTScreen> createState() => _CONTScreenState();
}

class _CONTScreenState extends State<CONTScreen> {
  final ApiService _apiService = ApiService();
  List<ListaDatos> listas = [];
  List<List<Tarjeta>> tarjetasPorLista = [];
  Map<String, int> _listIdToIndexMap = {};
  Process? _currentProcessDetails;

  @override
  void initState() {
    super.initState();
    _loadProcessDetails().then((_) {
      _loadListsFromBackend().then((_) {
        _loadCardsFromBackend();
      });
    });
  }

  Future<void> _loadProcessDetails() async {
    if (widget.processName == null) return;
    try {
      final Process? process = await _apiService.getProcessByName(widget.processName!);
      setState(() {
        _currentProcessDetails = process;
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

  // Método para actualizar el estado de una tarjeta
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
        // Actualizar la lista local
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

  // Filtra las tarjetas para mostrar solo las de DSI
  List<List<Tarjeta>> _filterDSICards() {
    return listas.map((lista) {
      final index = _listIdToIndexMap[lista.id]!;
      return tarjetasPorLista[index].where((tarjeta) {
        // Caso 1: Miembro es exactamente "DSI"
        if (tarjeta.miembro.trim().toLowerCase() == 'contabilidad') return true;
        
        // Caso 2: Miembro contiene "DSI" en cualquier parte
        if (tarjeta.miembro.toLowerCase().contains('contabilidad')) return true;
        
        // Caso 3: Miembro es una lista separada por comas que incluye DSI
        final miembros = tarjeta.miembro.split(',').map((m) => m.trim().toLowerCase()).toList();
        return miembros.contains('contabilidad');
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
              if (tarjeta.tiendaAsignada.isNotEmpty) // Nuevo campo
                Text('Tienda asignada: ${tarjeta.tiendaAsignada}'),
              if (tarjeta.descripcionTienda.isNotEmpty) // Nuevo campo
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('Descripción tienda: ${tarjeta.descripcionTienda}'),
                ),
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
  final filteredCards = _filterDSICards();
  
  return Scaffold(
    appBar: AppBar(
      title: Text(
        'Tareas Contabilidad - ${widget.processName ?? ''}',
        style: TextStyle(color: Colors.white), // Texto en color blanco
      ),
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color.fromARGB(255, 255, 255, 255)),
        onPressed: () => Navigator.pop(context),
      ),
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
              final isDSIOnly = tarjeta.miembro.trim().toLowerCase() == 'contabilidad';

              return GestureDetector(
                onTap: () => _mostrarDetallesTarjeta(tarjeta),
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
                                // Checkbox para estado
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
                            // Mostrar tienda asignada si existe
                            if (tarjeta.tiendaAsignada.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Row(
                                  children: [
                                    const Icon(Icons.store, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      tarjeta.tiendaAsignada,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (!isDSIOnly)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'Compartido con: ${tarjeta.miembro.replaceAll('Contabilidad', '').replaceAll(',,', ',').trim()}',
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