import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:login_app/super usario/home_page.dart';
import 'package:login_app/super usario/tabla/home_screen.dart';
import 'package:login_app/super usario/cards/cards.dart';
import 'package:login_app/services/api_service.dart';
import 'package:login_app/models/tarjeta.dart';
import 'package:login_app/models/lista_datos.dart';
import 'package:login_app/models/process.dart';
import 'package:login_app/services/api_service.dart' show GraficaConfiguracion;
import 'package:intl/intl.dart';
import 'package:login_app/super%20usario/cronogrma/cronograma.dart';

class PanelTrello extends StatefulWidget {
  final String? processName;
  const PanelTrello({Key? key, this.processName}) : super(key: key);

  @override
  _PanelTrelloState createState() => _PanelTrelloState();
}

class _PanelTrelloState extends State<PanelTrello> {
  List<GraficaConfiguracion> graficas = [];
  final ApiService _apiService = ApiService();

  // Datos reales
  List<ListaDatos> listas = [];
  List<Tarjeta> tarjetas = [];
  String? _currentProcessCollectionName;

  // Iconos para filtros
  final Map<String, IconData> filtroIconos = {
    "lista": Icons.list_alt,
    "miembro": Icons.person,
    "vencimiento": Icons.calendar_today,
    "estado": Icons.flag,
  };
  final List<Color> listaColores = [
    Colors.blue,
    Colors.purple,
    Colors.yellow,
    Colors.pink,
    Colors.cyan,
    Colors.teal,
    Colors.lime,
    Colors.indigo,
  ];

  // Colores fijos para leyendas específicas
  final Map<String, Color> coloresFijos = {
    'Cumplida': Colors.green,
    'Vence pronto': Colors.orange,
    'Sin fecha': Colors.grey,
    'Vencida': Colors.red,
    'Futuro': Colors.blue,
  };
  //COlores para Vencimiento BarChart//
  final Map<String, Color> coloresFijosVencimiento = {
    'Completado (a tiempo)': Colors.green,
    'Completado (con retraso)': Colors.red,
    'Completado (sin fecha)': Colors.green[300]!,
    'Vencido': Colors.red[700]!,
    'Por vencer (próximos 2 días)': Colors.orange,
    'Por vencer (más de 2 días)': Colors.blue,
    'Sin fecha': Colors.grey,
  };

  @override
  void initState() {
    super.initState();
    // Usa el processName recibido por el widget
    _currentProcessCollectionName = widget.processName;
    if (_currentProcessCollectionName != null) {
      _loadListsAndCards(_currentProcessCollectionName!);
      _loadGraficasFromBackend();
    }
  }

  Future<void> _loadListsAndCards(String processName) async {
    try {
      final loadedLists = await _apiService.getLists(processName);
      final loadedCards = await _apiService.getCards(processName);
      setState(() {
        listas = loadedLists;
        tarjetas = loadedCards;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar datos: $e')));
    }
  }

  Future<void> _loadGraficasFromBackend() async {
    if (_currentProcessCollectionName == null) return;
    final loadedGraficas = await _apiService.getGraficas(
      _currentProcessCollectionName!,
    );
    setState(() {
      graficas = loadedGraficas.cast<GraficaConfiguracion>();
    });
  }

  Future<void> _addGraficaToBackend(GraficaConfiguracion config) async {
    if (_currentProcessCollectionName == null) return;
    final created = await _apiService.createGrafica(
      _currentProcessCollectionName!,
      config,
    );
    if (created != null) {
      setState(() {
        graficas.add(created);
      });
    }
  }

  Future<void> _updateGraficaInBackend(
    int index,
    GraficaConfiguracion config,
  ) async {
    if (_currentProcessCollectionName == null) return;
    final updated = await _apiService.updateGrafica(
      _currentProcessCollectionName!,
      config,
    );
    if (updated != null) {
      setState(() {
        graficas[index] = updated as GraficaConfiguracion;
      });
    }
  }

  Future<void> _deleteGraficaFromBackend(int index) async {
    if (_currentProcessCollectionName == null) return;
    final grafica = graficas[index];
    if (grafica.id == null) return;
    final success = await _apiService.deleteGrafica(
      _currentProcessCollectionName!,
      grafica.id!,
    );
    if (success) {
      setState(() {
        graficas.removeAt(index);
      });
    }
  }

  Map<String, int> _getBarData(String filtro) {
    final Map<String, int> data = {};

    if (filtro == "vencimiento") {
      // Inicializamos todas las categorías posibles basadas en tiempoRestanteCalculado
      data['Completado (a tiempo)'] = 0;
      data['Completado (con retraso)'] = 0;
      data['Completado (sin fecha)'] = 0;
      data['Vencido'] = 0;
      data['Por vencer (próximos 2 días)'] = 0;
      data['Por vencer (más de 2 días)'] = 0;
      data['Sin fecha'] = 0;

      final hoy = DateTime.now();

      for (var tarjeta in tarjetas) {
        final tiempoInfo = tarjeta.tiempoRestanteCalculado;
        final textoEstado = tiempoInfo['text'] as String;

        if (textoEstado.contains('Completado (con') &&
            textoEstado.contains('restantes')) {
          data['Completado (a tiempo)'] =
              (data['Completado (a tiempo)'] ?? 0) + 1;
        } else if (textoEstado.contains('Completado (con') &&
            textoEstado.contains('retraso')) {
          data['Completado (con retraso)'] =
              (data['Completado (con retraso)'] ?? 0) + 1;
        } else if (textoEstado == 'Completado (sin fecha de completado)') {
          data['Completado (sin fecha)'] =
              (data['Completado (sin fecha)'] ?? 0) + 1;
        } else if (textoEstado.contains('Vencido')) {
          data['Vencido'] = (data['Vencido'] ?? 0) + 1;
        } else if (textoEstado.contains('Faltan') &&
            tarjeta.fechaVencimiento != null) {
          final diff = tarjeta.fechaVencimiento!.difference(hoy);
          if (diff.inDays <= 2) {
            data['Por vencer (próximos 2 días)'] =
                (data['Por vencer (próximos 2 días)'] ?? 0) + 1;
          } else {
            data['Por vencer (más de 2 días)'] =
                (data['Por vencer (más de 2 días)'] ?? 0) + 1;
          }
        } else if (tarjeta.fechaVencimiento == null) {
          data['Sin fecha'] = (data['Sin fecha'] ?? 0) + 1;
        }
      }

      // Eliminar categorías con 0 elementos
      data.removeWhere((key, value) => value == 0);
    } else {
      // Resto de lógica para otros filtros...
      switch (filtro) {
        case "lista":
          for (var lista in listas) {
            data[lista.titulo] =
                tarjetas.where((t) => t.idLista == lista.id).length;
          }
          break;
        case "miembro":
          for (var tarjeta in tarjetas) {
            final miembro =
                tarjeta.miembro.isNotEmpty ? tarjeta.miembro : "Sin asignar";
            data[miembro] = (data[miembro] ?? 0) + 1;
          }
          break;
        case "estado":
          for (var tarjeta in tarjetas) {
            final estado = tarjeta.estado.name;
            data[estado] = (data[estado] ?? 0) + 1;
          }
          break;
      }
    }

    return data;
  }

  Map<String, int> _getPieData(String filtro) {
    final Map<String, int> data = {};
    final hoy = DateTime.now();

    switch (filtro) {
      case "lista":
        for (var lista in listas) {
          data[lista.titulo] =
              tarjetas.where((t) => t.idLista == lista.id).length;
        }
        break;

      case "miembro":
        for (var tarjeta in tarjetas) {
          final miembro =
              tarjeta.miembro.isNotEmpty ? tarjeta.miembro : "Sin asignar";
          data[miembro] = (data[miembro] ?? 0) + 1;
        }
        break;

      case "estado":
        for (var tarjeta in tarjetas) {
          final estado = tarjeta.estado.name;
          data[estado] = (data[estado] ?? 0) + 1;
        }
        break;

      case "vencimiento":
        // Inicializamos todas las categorías posibles basadas en tiempoRestanteCalculado
        data['Completado (a tiempo)'] = 0;
        data['Completado (con retraso)'] = 0;
        data['Completado (sin fecha)'] = 0;
        data['Vencido'] = 0;
        data['Por vencer (próximos 2 días)'] = 0;
        data['Por vencer (más de 2 días)'] = 0;
        data['Sin fecha'] = 0;

        for (var tarjeta in tarjetas) {
          final tiempoInfo = tarjeta.tiempoRestanteCalculado;
          final textoEstado = tiempoInfo['text'] as String;

          if (textoEstado.contains('Completado (con') &&
              textoEstado.contains('restantes')) {
            data['Completado (a tiempo)'] =
                (data['Completado (a tiempo)'] ?? 0) + 1;
          } else if (textoEstado.contains('Completado (con') &&
              textoEstado.contains('retraso')) {
            data['Completado (con retraso)'] =
                (data['Completado (con retraso)'] ?? 0) + 1;
          } else if (textoEstado == 'Completado (sin fecha de completado)') {
            data['Completado (sin fecha)'] =
                (data['Completado (sin fecha)'] ?? 0) + 1;
          } else if (textoEstado.contains('Vencido')) {
            data['Vencido'] = (data['Vencido'] ?? 0) + 1;
          } else if (textoEstado.contains('Faltan') &&
              tarjeta.fechaVencimiento != null) {
            final diff = tarjeta.fechaVencimiento!.difference(hoy);
            if (diff.inDays <= 2) {
              data['Por vencer (próximos 2 días)'] =
                  (data['Por vencer (próximos 2 días)'] ?? 0) + 1;
            } else {
              data['Por vencer (más de 2 días)'] =
                  (data['Por vencer (más de 2 días)'] ?? 0) + 1;
            }
          } else if (tarjeta.fechaVencimiento == null) {
            data['Sin fecha'] = (data['Sin fecha'] ?? 0) + 1;
          }
        }

        // Eliminar categorías con 0 elementos
        data.removeWhere((key, value) => value == 0);
        break;
    }

    return data;
  }

  // Estados de vencimiento para el eje X de la gráfica lineal
  final List<String> estadosVencimiento = [
    "Cumplida",
    "Vence pronto",
    "Futuro",
    "Vencida",
    "Sin fecha",
  ];

  //--Por si se nesecita hacer algun cambio futuro (_GetLineChart)--//
  /*Map<String, List<FlSpot>> _getLineData(String filtro, String periodo) {
    final Map<String, List<FlSpot>> series = {};

    // Agrupa las tarjetas por filtro (lista, miembro, estado, etc.)
    Map<String, List<Tarjeta>> tarjetasPorFiltro = {};
    switch (filtro) {
      case "lista":
        for (var lista in listas) {
          tarjetasPorFiltro[lista.titulo] =
              tarjetas.where((t) => t.idLista == lista.id).toList();
        }
        break;
      case "miembro":
        for (var tarjeta in tarjetas) {
          final miembro =
              (tarjeta.miembro != null && tarjeta.miembro.isNotEmpty)
                  ? tarjeta.miembro
                  : "Sin asignar";
          tarjetasPorFiltro[miembro] =
              (tarjetasPorFiltro[miembro] ?? [])..add(tarjeta);
        }
        break;
      case "estado":
        for (var tarjeta in tarjetas) {
          final estado = tarjeta.estado.name;
          tarjetasPorFiltro[estado] =
              (tarjetasPorFiltro[estado] ?? [])..add(tarjeta);
        }
        break;
      case "vencimiento":
        // Para vencimiento, todas las tarjetas van en el mismo grupo
        tarjetasPorFiltro["Todas"] = tarjetas;
        break;
    }

    // Para cada filtro, cuenta las tarjetas por estado de vencimiento
    tarjetasPorFiltro.forEach((key, listaTarjetas) {
      List<FlSpot> spots = [];
      for (int i = 0; i < estadosVencimiento.length; i++) {
        final estado = estadosVencimiento[i];
        int count = 0;
        for (var tarjeta in listaTarjetas) {
          final hoy = DateTime.now();
          String estadoTarjeta;
          if (tarjeta.fechaVencimiento == null) {
            estadoTarjeta = "Sin fecha";
          } else if (tarjeta.estado == EstadoTarjeta.hecho) {
            estadoTarjeta = "Cumplida";
          } else if (tarjeta.fechaVencimiento!.isBefore(hoy)) {
            estadoTarjeta = "Vencida";
          } else if (tarjeta.fechaVencimiento!.difference(hoy).inDays <= 2) {
            estadoTarjeta = "Vence pronto";
          } else {
            estadoTarjeta = "Futuro";
          }
          if (estadoTarjeta == estado) count++;
        }
        spots.add(FlSpot(i.toDouble(), count.toDouble()));
      }
      series[key] = spots;
    });

    return series;
  }*/
  // -- //

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF2E2E2E),
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Redirige al tablero del proceso actual usando el processName correcto
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
        title: Text(
          ("Panel de Proyecto"),
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            onSelected: (String value) {
              if (value == 'cronograma') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => PlannerScreen(
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
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Expanded(
              child:
                  graficas.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Añade una gráfica para comenzar +",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                      : GridView.builder(
                        itemCount: graficas.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                          childAspectRatio: 2.3,
                        ),
                        itemBuilder: (context, index) {
                          // Protege el acceso: solo renderiza si el índice es válido
                          if (index < 0 || index >= graficas.length) {
                            return SizedBox(); // No renderiza nada si el índice está fuera de rango
                          }
                          GraficaConfiguracion config = graficas[index];
                          return Card(
                            color: Color(0xFF3A3A3A),
                            child: Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Título con filtro arriba a la izquierda
                                      Row(
                                        children: [
                                          Icon(
                                            filtroIconos[config.filtro] ??
                                                Icons.bar_chart,
                                            color: Colors.white70,
                                            size: 18,
                                          ),
                                          SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              _tituloGrafica(config),
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Expanded(
                                        child: _construirGrafica(config),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  top: 5,
                                  right: 5,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          Icons.edit,
                                          color: Colors.white,
                                        ),
                                        onPressed:
                                            () => _mostrarDialogoConfiguracion(
                                              editar: true,
                                              index: index,
                                            ),
                                        tooltip: "Editar gráfica",
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.delete,
                                          color: Colors.redAccent,
                                        ),
                                        onPressed: () async {
                                          await _deleteGraficaFromBackend(
                                            index,
                                          );
                                        },
                                        tooltip: "Eliminar gráfica",
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
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0, right: 12.0),
                child: IconButton(
                  icon: Icon(
                    Icons.add,
                    color: const Color.fromARGB(255, 0, 0, 0),
                    size: 35,
                  ),
                  onPressed: () => _mostrarDialogoConfiguracion(),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                      const Color.fromARGB(255, 255, 255, 255),
                    ),
                    shape: MaterialStateProperty.all<CircleBorder>(
                      CircleBorder(),
                    ),
                  ),
                  tooltip: "Añadir gráfica",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _tituloGrafica(GraficaConfiguracion config) {
    String filtroNombre = "";
    switch (config.filtro) {
      case "lista":
        filtroNombre = "Lista";
        break;
      case "miembro":
        filtroNombre = "Miembro";
        break;
      case "vencimiento":
        filtroNombre = "Fecha de vencimiento";
        break;
      default:
        filtroNombre = config.filtro;
    }

    if (config.tipoGrafica == "lineas") {
      return "Progreso - $filtroNombre (${config.periodo})";
    }

    String tipoNombre = "";
    switch (config.tipoGrafica) {
      case "barras":
        tipoNombre = "Tarjetas por";
        break;
      case "circular":
        tipoNombre = "Distribución por";
        break;
      default:
        tipoNombre = "";
    }

    return "$tipoNombre $filtroNombre";
  }

  Widget _construirGrafica(GraficaConfiguracion config) {
    switch (config.tipoGrafica) {
      case "barras":
        return _buildBarChart(config);
      case "circular":
        return _buildPieChart(config);
      case "lineas":
        return _buildLineChart(config);
      default:
        return SizedBox();
    }
  }

  void _mostrarDialogoConfiguracion({bool editar = false, int? index}) {
    String tipo = editar ? graficas[index!].tipoGrafica : "barras";
    String filtro = editar ? graficas[index!].filtro : "lista";
    String periodo =
        editar && graficas[index!].tipoGrafica == "lineas"
            ? graficas[index].periodo
            : "Semana pasada";

    showDialog(
      context: context,
      builder:
          (_) => StatefulBuilder(
            builder: (context, setStateDialog) {
              return AlertDialog(
                backgroundColor: Color(0xFF3A3A3A),
                title: Text(
                  editar ? "Editar gráfica" : "Añadir gráfica",
                  style: TextStyle(color: Colors.white),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: tipo,
                      dropdownColor: Color(0xFF3A3A3A),
                      decoration: InputDecoration(
                        labelText: "Tipo de gráfica",
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueAccent),
                        ),
                      ),
                      style: TextStyle(color: Colors.white),
                      items: [
                        DropdownMenuItem(
                          value: "barras",
                          child: Row(
                            children: [
                              Icon(Icons.bar_chart, color: Colors.white70),
                              SizedBox(width: 8),
                              Text("Barras"),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: "circular",
                          child: Row(
                            children: [
                              Icon(Icons.pie_chart, color: Colors.white70),
                              SizedBox(width: 8),
                              Text("Circular"),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: "lineas",
                          child: Row(
                            children: [
                              Icon(Icons.show_chart, color: Colors.white70),
                              SizedBox(width: 8),
                              Text("Líneas"),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setStateDialog(() {
                          tipo = value!;
                          if (tipo != "lineas") periodo = "Semana pasada";
                        });
                      },
                    ),
                    SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: filtro,
                      dropdownColor: Color(0xFF3A3A3A),
                      decoration: InputDecoration(
                        labelText: "Filtrar por",
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueAccent),
                        ),
                      ),
                      style: TextStyle(color: Colors.white),
                      items: [
                        DropdownMenuItem(
                          value: "lista",
                          child: Row(
                            children: [
                              Icon(Icons.list_alt, color: Colors.white70),
                              SizedBox(width: 8),
                              Text("Lista"),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: "miembro",
                          child: Row(
                            children: [
                              Icon(Icons.person, color: Colors.white70),
                              SizedBox(width: 8),
                              Text("Miembro"),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: "vencimiento",
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, color: Colors.white70),
                              SizedBox(width: 8),
                              Text("Fecha de vencimiento"),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: "estado",
                          child: Row(
                            children: [
                              Icon(Icons.flag, color: Colors.white70),
                              SizedBox(width: 8),
                              Text("Estado"),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setStateDialog(() {
                          filtro = value!;
                        });
                      },
                    ),
                    if (tipo == "lineas") ...[
                      SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: periodo,
                        dropdownColor: Color(0xFF3A3A3A),
                        decoration: InputDecoration(
                          labelText: "Periodo de tiempo",
                          labelStyle: TextStyle(color: Colors.white70),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white30),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.blueAccent),
                          ),
                        ),
                        style: TextStyle(color: Colors.white),
                        items: [
                          DropdownMenuItem(
                            value: "Semana pasada",
                            child: Text("Semana pasada"),
                          ),
                          DropdownMenuItem(
                            value: "Últimas dos semanas",
                            child: Text("Últimas dos semanas"),
                          ),
                          DropdownMenuItem(
                            value: "Mes pasado",
                            child: Text("Mes pasado"),
                          ),
                        ],
                        onChanged: (value) {
                          setStateDialog(() {
                            periodo = value!;
                          });
                        },
                      ),
                    ],
                  ],
                ),
                actions: [
                  TextButton(
                    child: Text(
                      "Cancelar",
                      style: TextStyle(color: Colors.white70),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  ElevatedButton(
                    child: Text(editar ? "Guardar" : "Añadir"),
                    onPressed: () async {
                      if (editar) {
                        final config = graficas[index!];
                        config.tipoGrafica = tipo;
                        config.filtro = filtro;
                        config.periodo = periodo;
                        await _updateGraficaInBackend(index!, config);
                      } else {
                        final nuevaGrafica = GraficaConfiguracion(
                          tipoGrafica: tipo,
                          filtro: filtro,
                          periodo: periodo,
                        );
                        await _addGraficaToBackend(nuevaGrafica);
                      }
                      Navigator.pop(context);
                    },
                  ),
                ],
              );
            },
          ),
    );
  }

  Widget _buildBarChart(GraficaConfiguracion config) {
    final datos = _getBarData(config.filtro);
    final labels = datos.keys.toList();
    final valores = datos.values.toList();

    // Colores para todos los filtros
    final Map<String, Color> coloresGrafica = {
      'Completado (a tiempo)': Colors.green,
      'Completado (con retraso)': Colors.red,
      'Completado (sin fecha)': Colors.lightGreen,
      'Vencido': Colors.red[700]!,
      'Por vencer (próximos 2 días)': Colors.orange,
      'Por vencer (más de 2 días)': Colors.blue,
      'Sin fecha': Colors.grey,
    };

    final double maxY =
        valores.isNotEmpty
            ? (valores.reduce((a, b) => a > b ? a : b) + 1).toDouble()
            : 5.0;

    final grupos = List.generate(labels.length, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: valores[i].toDouble(),
            color:
                config.filtro == "vencimiento"
                    ? coloresGrafica[labels[i]] ?? Colors.grey
                    : listaColores[i % listaColores.length],
            width: 12, // Reducido de 18 a 14 para más espacio entre barras
            borderRadius: BorderRadius.circular(4),
          ),
        ],
        barsSpace: 0.2, // Espacio adicional entre grupos de barras
      );
    });
    return Padding(
      padding: const EdgeInsets.only(
        top: 30.0,
      ), // Aumentado de 20 a 30 para bajar más el gráfico
      child: Column(
        children: [
          SizedBox(
            height: 200, // Mantenemos la misma altura
            child: BarChart(
              BarChartData(
                maxY: maxY,
                minY: 0,
                barGroups: grupos,
                barTouchData: BarTouchData(
                  enabled: false,
                  touchCallback: (event, response) {
                    if (response != null &&
                        response.spot != null &&
                        event is FlTapUpEvent) {
                      final touchedIndex = response.spot!.touchedBarGroupIndex;
                      if (touchedIndex >= 0 && touchedIndex < labels.length) {
                        final categoria = labels[touchedIndex];

                        // Filtrado especial para categorías de vencimiento
                        List<Tarjeta> tarjetasFiltradas = [];
                        if (config.filtro == "vencimiento") {
                          final hoy = DateTime.now();
                          tarjetasFiltradas =
                              tarjetas.where((t) {
                                if (categoria == 'Completado (a tiempo)') {
                                  return t.estado == EstadoTarjeta.hecho &&
                                      t.fechaCompletado != null &&
                                      (t.fechaVencimiento == null ||
                                          !t.fechaCompletado!.isAfter(
                                            t.fechaVencimiento!,
                                          ));
                                } else if (categoria ==
                                    'Completado (con retraso)') {
                                  return t.estado == EstadoTarjeta.hecho &&
                                      t.fechaCompletado != null &&
                                      t.fechaVencimiento != null &&
                                      t.fechaCompletado!.isAfter(
                                        t.fechaVencimiento!,
                                      );
                                } else if (categoria ==
                                    'Completado (sin fecha)') {
                                  return t.estado == EstadoTarjeta.hecho &&
                                      t.fechaCompletado == null;
                                } else if (categoria == 'Vencido') {
                                  return t.estado != EstadoTarjeta.hecho &&
                                      t.fechaVencimiento != null &&
                                      t.fechaVencimiento!.isBefore(hoy);
                                } else if (categoria ==
                                    'Por vencer (próximos 2 días)') {
                                  return t.estado != EstadoTarjeta.hecho &&
                                      t.fechaVencimiento != null &&
                                      !t.fechaVencimiento!.isBefore(hoy) &&
                                      t.fechaVencimiento!
                                              .difference(hoy)
                                              .inDays <=
                                          2;
                                } else if (categoria ==
                                    'Por vencer (más de 2 días)') {
                                  return t.estado != EstadoTarjeta.hecho &&
                                      t.fechaVencimiento != null &&
                                      t.fechaVencimiento!
                                              .difference(hoy)
                                              .inDays >
                                          2;
                                } else if (categoria == 'Sin fecha') {
                                  return t.fechaVencimiento == null;
                                }
                                return false;
                              }).toList();
                        } else {
                          // Filtrado normal para otros tipos de gráficos
                          tarjetasFiltradas =
                              tarjetas.where((t) {
                                if (config.filtro == "lista") {
                                  final lista = listas.firstWhere(
                                    (l) => l.titulo == categoria,
                                    orElse:
                                        () => ListaDatos(id: '', titulo: ''),
                                  );
                                  return t.idLista == lista.id;
                                } else if (config.filtro == "miembro") {
                                  return t.miembro == categoria ||
                                      (categoria == "Sin asignar" &&
                                          t.miembro.isEmpty);
                                } else if (config.filtro == "estado") {
                                  return t.estado.name == categoria;
                                }
                                return false;
                              }).toList();
                        }

                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              backgroundColor: Colors.grey[900],
                              title: Text(
                                'Tarjetas - $categoria (${tarjetasFiltradas.length})',
                                style: TextStyle(color: Colors.white),
                              ),
                              content: SizedBox(
                                width: 400,
                                height: 500,
                                child:
                                    tarjetasFiltradas.isEmpty
                                        ? Center(
                                          child: Text(
                                            'No hay tarjetas en esta categoría',
                                            style: TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                        )
                                        : ListView.builder(
                                          itemCount: tarjetasFiltradas.length,
                                          itemBuilder: (context, index) {
                                            final tarjeta =
                                                tarjetasFiltradas[index];
                                            final tiempoInfo =
                                                tarjeta.tiempoRestanteCalculado;
                                            final nombreLista =
                                                listas
                                                    .firstWhere(
                                                      (l) =>
                                                          l.id ==
                                                          tarjeta.idLista,
                                                      orElse:
                                                          () => ListaDatos(
                                                            id: '',
                                                            titulo:
                                                                'Desconocida',
                                                          ),
                                                    )
                                                    .titulo;

                                            return Card(
                                              color: Colors.grey[800],
                                              margin: const EdgeInsets.all(8),
                                              child: ListTile(
                                                title: Text(
                                                  tarjeta.titulo,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                subtitle: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Lista: $nombreLista',
                                                      style: TextStyle(
                                                        color: Colors.white70,
                                                      ),
                                                    ),
                                                    if (tarjeta
                                                        .miembro
                                                        .isNotEmpty)
                                                      Text(
                                                        'Miembro: ${tarjeta.miembro}',
                                                        style: TextStyle(
                                                          color: Colors.white70,
                                                        ),
                                                      ),
                                                    Text(
                                                      'Estado: ${tarjeta.estado.name}',
                                                      style: TextStyle(
                                                        color: Colors.white70,
                                                      ),
                                                    ),
                                                    if (tarjeta
                                                            .fechaVencimiento !=
                                                        null)
                                                      Text(
                                                        'Vence: ${DateFormat('dd/MM/yyyy').format(tarjeta.fechaVencimiento!)}',
                                                        style: TextStyle(
                                                          color: Colors.white70,
                                                        ),
                                                      ),
                                                    Text(
                                                      tiempoInfo['text'],
                                                      style: TextStyle(
                                                        color:
                                                            tiempoInfo['color'],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text('Cerrar'),
                                ),
                              ],
                            );
                          },
                        );
                      }
                    }
                  },
                ),
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 1,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine:
                      (value) => FlLine(
                        color: Colors.white.withOpacity(0.1),
                        strokeWidth: 1,
                      ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < labels.length) {
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              labels[index],
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        );
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
              ),
            ),
          ),
          // Leyenda para el filtro de vencimiento
          const SizedBox(height: 10), // Espacio entre gráfico y leyenda
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children:
                  labels.asMap().entries.map((entry) {
                    final index = entry.key;
                    final label = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color:
                                  config.filtro == "vencimiento"
                                      ? coloresGrafica[label] ?? Colors.grey
                                      : listaColores[index %
                                          listaColores.length],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(GraficaConfiguracion config) {
    final datos = _getPieData(config.filtro);
    final labels = datos.keys.toList();
    final valores = datos.values.toList();

    // Mapa de nombres de lista para mostrar mejor la información
    final Map<String, String> listaNames = {
      for (var lista in listas) lista.id: lista.titulo,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Gráfico
          SizedBox(
            height: 220,
            width: 220,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 0,
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    if (response != null &&
                        response.touchedSection != null &&
                        event is FlTapUpEvent) {
                      final touchedIndex =
                          response.touchedSection!.touchedSectionIndex;
                      final categoria = labels[touchedIndex];

                      // Mostrar diálogo con tarjetas filtradas
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            backgroundColor: Colors.grey[900],
                            title: Text(
                              'Tarjetas - $categoria',
                              style: TextStyle(color: Colors.white),
                            ),
                            content: SizedBox(
                              width: 400,
                              height: 500,
                              child: mostrarTarjetasPorCategoria(
                                categoria,
                                tarjetas,
                                listas,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text('Cerrar'),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  },
                ),
                sections: List.generate(labels.length, (i) {
                  return PieChartSectionData(
                    value: valores[i].toDouble(),
                    color: listaColores[i % listaColores.length],
                    radius: 100,
                    title: '${valores[i]}',
                    titleStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(width: 40),
          // Leyenda
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(labels.length, (i) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: listaColores[i % listaColores.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      labels[i],
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(GraficaConfiguracion config) {
    final datos = _getBarData(config.filtro);
    final labels = datos.keys.toList();
    final valores = datos.values.toList();

    // Convertir fechas a formato legible (ej: "2025-07-19" → "19/07")
    final fechasFormateadas =
        labels.map((fechaStr) {
          try {
            final fecha = DateTime.parse(fechaStr);
            return '${fecha.day}/${fecha.month}';
          } catch (_) {
            return fechaStr; // Fallback si no es una fecha
          }
        }).toList();

    final List<FlSpot> spots = List.generate(
      labels.length,
      (i) => FlSpot(i.toDouble(), valores[i].toDouble()),
    );

    double maxY = 5;
    if (valores.isNotEmpty) {
      final maxValor = valores.reduce((a, b) => a > b ? a : b);
      maxY = (maxValor + 1).toDouble();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: SizedBox(
        height: 280,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 1,
              getDrawingHorizontalLine:
                  (value) => FlLine(
                    color: Colors.white.withOpacity(0.1),
                    strokeWidth: 1,
                  ),
            ),
            lineTouchData: LineTouchData(
              enabled: false,
              touchCallback: (event, response) {
                if (response != null &&
                    response.lineBarSpots != null &&
                    event is FlTapUpEvent) {
                  final touchedIndex = response.lineBarSpots!.first.spotIndex;
                  if (touchedIndex >= 0 && touchedIndex < labels.length) {
                    final categoria = labels[touchedIndex];

                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          backgroundColor: Colors.grey[900],
                          title: Text(
                            'Tarjetas - $categoria',
                            style: TextStyle(color: Colors.white),
                          ),
                          content: SizedBox(
                            width: 400,
                            height: 500,
                            child: mostrarTarjetasPorCategoria(
                              categoria,
                              tarjetas,
                              listas,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text('Cerrar'),
                            ),
                          ],
                        );
                      },
                    );
                  }
                }
              },
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  reservedSize: 30,
                  getTitlesWidget:
                      (value, meta) => Text(
                        value.toInt().toString(),
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    int index = value.toInt();
                    if (index >= 0 && index < fechasFormateadas.length) {
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          fechasFormateadas[index],
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      );
                    } else {
                      return const SizedBox.shrink();
                    }
                  },
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            minY: 0,
            maxY: maxY,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: Colors.greenAccent,
                barWidth: 3,
                dotData: FlDotData(show: true),
                belowBarData: BarAreaData(show: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _getMaxY(Map<String, List<FlSpot>> series) {
    double maxY = 1;
    for (var entry in series.entries) {
      for (var spot in entry.value) {
        if (spot.y > maxY) maxY = spot.y;
      }
    }
    return maxY < 5 ? 5 : maxY + 1;
  }
}

//Metodo para la SubVentana//

class TarjetaDetalleView extends StatelessWidget {
  final String categoria; // será el idLista que filtra
  final List<Tarjeta> tarjetasDisponibles;
  final Map<String, String> nombreListas; // Map idLista -> nombreLista

  const TarjetaDetalleView({
    super.key,
    required this.categoria,
    required this.tarjetasDisponibles,
    required this.nombreListas,
  });

  @override
  Widget build(BuildContext context) {
    // Filtrar tarjetas que pertenezcan a esta lista (idLista)
    List<Tarjeta> tarjetasFiltradas =
        tarjetasDisponibles
            .where(
              (tarjeta) =>
                  tarjeta.idLista.toLowerCase() == categoria.toLowerCase(),
            )
            .toList();

    if (tarjetasFiltradas.isEmpty) {
      return Center(
        child: Text(
          'No hay tarjetas en esta lista',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    final nombreLista = nombreListas[categoria] ?? 'Lista Desconocida';

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text('Tarjetas en "$nombreLista"'),
        backgroundColor: Colors.grey[850],
      ),
      body: ListView.builder(
        itemCount: tarjetasFiltradas.length,
        itemBuilder: (context, index) {
          final tarjeta = tarjetasFiltradas[index];
          final tiempoRestante = tarjeta.tiempoRestanteCalculado;

          return Card(
            color: Colors.grey[800],
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(
                tarjeta.titulo,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (tarjeta.descripcion.isNotEmpty)
                    Text(
                      tarjeta.descripcion,
                      style: TextStyle(color: Colors.white70),
                    ),
                  Text(
                    'Miembro: ${tarjeta.miembro}',
                    style: TextStyle(color: Colors.white70),
                  ),
                  Text(
                    'Tarea: ${tarjeta.tarea}',
                    style: TextStyle(color: Colors.white70),
                  ),
                  Text(
                    'Estado: ${tarjeta.estado.name}',
                    style: TextStyle(color: Colors.white70),
                  ),
                  Text(
                    'Fecha inicio: ${tarjeta.fechaInicio != null ? _formatDate(tarjeta.fechaInicio!) : "N/A"}',
                    style: TextStyle(color: Colors.white70),
                  ),
                  Text(
                    'Fecha vencimiento: ${tarjeta.fechaVencimiento != null ? _formatDate(tarjeta.fechaVencimiento!) : "N/A"}',
                    style: TextStyle(color: Colors.white70),
                  ),
                  Text(
                    tiempoRestante['text'],
                    style: TextStyle(color: tiempoRestante['color']),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

Widget _buildInfoRow(String label, String valor) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(valor, style: const TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

Widget mostrarTarjetasPorCategoria(
  String categoria,
  List<Tarjeta> tarjetas,
  List<ListaDatos> listas,
) {
  // Crear un mapa de ID de lista a nombre de lista para mostrar mejor la información
  final Map<String, String> listaNames = {
    for (var lista in listas) lista.id: lista.titulo,
  };

  List<Tarjeta> tarjetasFiltradas =
      tarjetas.where((t) {
        final tiempoInfo = t.tiempoRestanteCalculado;
        final textoEstado = tiempoInfo['text'] as String;
        final hoy = DateTime.now();

        // Para el filtro de lista, comparamos con el título de la lista
        if (listaNames.containsValue(categoria)) {
          return listaNames[t.idLista] == categoria;
        }

        // Para el filtro de estado
        if (t.estado.name.toLowerCase() == categoria.toLowerCase()) {
          return true;
        }

        // Para el filtro de miembro
        if (t.miembro == categoria ||
            (categoria == "Sin asignar" && t.miembro.isEmpty)) {
          return true;
        }

        // Para el filtro de vencimiento (nuevas categorías)
        if (categoria == 'Completado (a tiempo)' &&
            textoEstado.contains('Completado (con') &&
            textoEstado.contains('restantes')) {
          return true;
        }
        if (categoria == 'Completado (con retraso)' &&
            textoEstado.contains('Completado (con') &&
            textoEstado.contains('retraso')) {
          return true;
        }
        if (categoria == 'Completado (sin fecha)' &&
            textoEstado == 'Completado (sin fecha de completado)') {
          return true;
        }
        if (categoria == 'Vencido' && textoEstado.contains('Vencido')) {
          return true;
        }
        if (categoria == 'Por vencer (próximos 2 días)' &&
            textoEstado.contains('Faltan') &&
            t.fechaVencimiento != null &&
            t.fechaVencimiento!.difference(hoy).inDays <= 2) {
          return true;
        }
        if (categoria == 'Por vencer (más de 2 días)' &&
            textoEstado.contains('Faltan') &&
            t.fechaVencimiento != null &&
            t.fechaVencimiento!.difference(hoy).inDays > 2) {
          return true;
        }
        if (categoria == 'Sin fecha' && t.fechaVencimiento == null) {
          return true;
        }

        return false;
      }).toList();

  return tarjetasFiltradas.isEmpty
      ? const Center(
        child: Text(
          'No hay tarjetas en esta categoría.',
          style: TextStyle(color: Colors.white70),
        ),
      )
      : ListView.builder(
        itemCount: tarjetasFiltradas.length,
        itemBuilder: (context, index) {
          final tarjeta = tarjetasFiltradas[index];
          final tiempoInfo = tarjeta.tiempoRestanteCalculado;
          final nombreLista = listaNames[tarjeta.idLista] ?? 'Desconocida';

          return Card(
            color: Colors.grey[800],
            margin: const EdgeInsets.all(8),
            child: ListTile(
              title: Text(
                tarjeta.titulo,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (listaNames.containsKey(tarjeta.idLista))
                    Text(
                      'Lista: $nombreLista',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  if (tarjeta.miembro.isNotEmpty)
                    Text(
                      'Miembro: ${tarjeta.miembro}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  Text(
                    'Estado: ${tarjeta.estado.name}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  if (tarjeta.fechaVencimiento != null)
                    Text(
                      'Vence: ${DateFormat('dd/MM/yyyy').format(tarjeta.fechaVencimiento!)}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  Text(
                    tiempoInfo['text'],
                    style: TextStyle(color: tiempoInfo['color']),
                  ),
                ],
              ),
            ),
          );
        },
      );
}
