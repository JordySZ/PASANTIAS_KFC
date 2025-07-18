import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:login_app/super%20usario/tabla/home_screen.dart';
import 'package:login_app/super%20usario/cronogrma/cronograma.dart';
import 'package:login_app/super%20usario/cards/cards.dart';
import 'package:login_app/services/api_service.dart';
import 'package:login_app/models/tarjeta.dart';
import 'package:login_app/models/lista_datos.dart';
//

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
    "etiqueta": Icons.label,
    "miembro": Icons.person,
    "vencimiento": Icons.calendar_today,
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

  // Elimina el método _loadProcessAndData, ya que no debe cambiar el nombre de la tienda.
  // Si necesitas cargar todos los procesos, hazlo en otra pantalla.

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

  // Procesamiento de datos para las gráficas (adaptado al modelo de user.dart)
  Map<String, int> _getBarData(String filtro) {
    final Map<String, int> data = {};
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
              (tarjeta.miembro != null && tarjeta.miembro.isNotEmpty)
                  ? tarjeta.miembro
                  : "Sin asignar";
          data[miembro] = (data[miembro] ?? 0) + 1;
        }
        break;
      case "etiqueta":
        for (var tarjeta in tarjetas) {
          final etiqueta =
              (tarjeta.tarea != null && tarjeta.tarea.isNotEmpty)
                  ? tarjeta.tarea
                  : "Sin etiqueta";
          data[etiqueta] = (data[etiqueta] ?? 0) + 1;
        }
        break;
      case "vencimiento":
        final hoy = DateTime.now();
        for (var tarjeta in tarjetas) {
          String key;
          if (tarjeta.fechaVencimiento == null) {
            key = "Sin fecha";
          } else if (tarjeta.fechaVencimiento!.isBefore(hoy)) {
            key = "Vencida";
          } else if (tarjeta.fechaVencimiento!.difference(hoy).inDays <= 2) {
            key = "Vence pronto";
          } else {
            key = "Futuro";
          }
          data[key] = (data[key] ?? 0) + 1;
        }
        break;
    }
    return data;
  }

  Map<String, int> _getPieData(String filtro) {
    final Map<String, int> data = {};
    switch (filtro) {
      case "lista":
        for (var lista in listas) {
          data[lista.titulo] =
              tarjetas
                  .where(
                    (t) =>
                        t.idLista == lista.id &&
                        t.estado == EstadoTarjeta.hecho,
                  )
                  .length;
        }
        break;
      case "miembro":
        for (var tarjeta in tarjetas) {
          if (tarjeta.estado == EstadoTarjeta.hecho) {
            final miembro =
                (tarjeta.miembro != null && tarjeta.miembro.isNotEmpty)
                    ? tarjeta.miembro
                    : "Sin asignar";
            data[miembro] = (data[miembro] ?? 0) + 1;
          }
        }
        break;
      case "etiqueta":
        for (var tarjeta in tarjetas) {
          if (tarjeta.estado == EstadoTarjeta.hecho) {
            final etiqueta =
                (tarjeta.tarea != null && tarjeta.tarea.isNotEmpty)
                    ? tarjeta.tarea
                    : "Sin etiqueta";
            data[etiqueta] = (data[etiqueta] ?? 0) + 1;
          }
        }
        break;
      case "vencimiento":
        final hoy = DateTime.now();
        for (var tarjeta in tarjetas) {
          if (tarjeta.estado == EstadoTarjeta.hecho) {
            String key;
            if (tarjeta.fechaVencimiento == null) {
              key = "Sin fecha";
            } else if (tarjeta.fechaVencimiento!.isBefore(hoy)) {
              key = "Vencida";
            } else if (tarjeta.fechaVencimiento!.difference(hoy).inDays <= 2) {
              key = "Vence pronto";
            } else {
              key = "Futuro";
            }
            data[key] = (data[key] ?? 0) + 1;
          }
        }
        break;
    }
    return data;
  }

  Map<String, List<FlSpot>> _getLineData(String filtro, String periodo) {
    final Map<String, List<FlSpot>> series = {};
    final now = DateTime.now();
    int periods = periodo == "Mes pasado" ? 4 : 2;
    int daysPerPeriod = periodo == "Mes pasado" ? 7 : 7;

    List<DateTime> periodStarts = List.generate(
      periods,
      (i) => now.subtract(Duration(days: (periods - i) * daysPerPeriod)),
    );
    Map<String, List<Tarjeta>> tarjetasPorFiltro = {};

    switch (filtro) {
      case "lista":
        for (var lista in listas) {
          tarjetasPorFiltro[lista.titulo] =
              tarjetas
                  .where(
                    (t) =>
                        t.idLista == lista.id &&
                        t.estado == EstadoTarjeta.hecho,
                  )
                  .toList();
        }
        break;
      case "miembro":
        for (var tarjeta in tarjetas) {
          if (tarjeta.estado == EstadoTarjeta.hecho) {
            final miembro =
                (tarjeta.miembro != null && tarjeta.miembro.isNotEmpty)
                    ? tarjeta.miembro
                    : "Sin asignar";
            tarjetasPorFiltro[miembro] =
                (tarjetasPorFiltro[miembro] ?? [])..add(tarjeta);
          }
        }
        break;
      case "etiqueta":
        for (var tarjeta in tarjetas) {
          if (tarjeta.estado == EstadoTarjeta.hecho) {
            final etiqueta =
                (tarjeta.tarea != null && tarjeta.tarea.isNotEmpty)
                    ? tarjeta.tarea
                    : "Sin etiqueta";
            tarjetasPorFiltro[etiqueta] =
                (tarjetasPorFiltro[etiqueta] ?? [])..add(tarjeta);
          }
        }
        break;
      case "vencimiento":
        for (var tarjeta in tarjetas) {
          if (tarjeta.estado == EstadoTarjeta.hecho) {
            String key;
            if (tarjeta.fechaVencimiento == null) {
              key = "Sin fecha";
            } else if (tarjeta.fechaVencimiento!.isBefore(now)) {
              key = "Vencida";
            } else if (tarjeta.fechaVencimiento!.difference(now).inDays <= 2) {
              key = "Vence pronto";
            } else {
              key = "Futuro";
            }
            tarjetasPorFiltro[key] =
                (tarjetasPorFiltro[key] ?? [])..add(tarjeta);
          }
        }
        break;
    }

    tarjetasPorFiltro.forEach((key, listaTarjetas) {
      List<FlSpot> spots = [];
      for (int i = 0; i < periods; i++) {
        final start = periodStarts[i];
        final end = start.add(Duration(days: daysPerPeriod));
        final count =
            listaTarjetas
                .where(
                  (t) =>
                      t.fechaCompletado != null &&
                      t.fechaCompletado!.isAfter(start) &&
                      t.fechaCompletado!.isBefore(end),
                )
                .length;
        spots.add(FlSpot(i.toDouble(), count.toDouble()));
      }
      series[key] = spots;
    });

    return series;
  }

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
      case "etiqueta":
        filtroNombre = "Etiqueta";
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
                          value: "etiqueta",
                          child: Row(
                            children: [
                              Icon(Icons.label, color: Colors.white70),
                              SizedBox(width: 8),
                              Text("Etiqueta"),
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
    final colores = List<Color>.generate(
      valores.length,
      (index) => listaColores[index % listaColores.length],
    );

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: SizedBox(
            height: 410,
            child: BarChart(
              BarChartData(
                barTouchData: BarTouchData(
                  enabled: false,
                ), // Desactivamos touch para evitar errores (Si se desea, se puede activar)
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < labels.length) {
                          return Text(
                            labels[value.toInt()],
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          );
                        }
                        return Text('');
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(
                  valores.length,
                  (index) => BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: valores[index].toDouble(),
                        color: colores[index],
                        width: 30,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 6), // espacio entre gráfico y leyenda
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            labels.length,
            (index) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Container(width: 13, height: 13, color: colores[index]),
                  SizedBox(width: 6),
                  Text(
                    "${labels[index]} (${valores[index]})",
                    style: TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPieChart(GraficaConfiguracion config) {
    final datos = _getPieData(config.filtro);
    Map<String, Color> coloresDinamicos = {};
    int colorIndex = 0;

    datos.keys.forEach((key) {
      if (coloresFijos.containsKey(key)) {
        coloresDinamicos[key] = coloresFijos[key]!;
      } else {
        coloresDinamicos[key] = listaColores[colorIndex % listaColores.length];
        colorIndex++;
      }
    });

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 600,
          height: 700,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 0,
              sectionsSpace: 3,
              sections:
                  datos.entries
                      .map(
                        (e) => PieChartSectionData(
                          value: e.value.toDouble(),
                          color: coloresDinamicos[e.key]!,
                          title: '',
                          radius:
                              120, // Más grande que centerSpaceRadius para borde grueso
                        ),
                      )
                      .toList(),
            ),
          ),
        ),

        SizedBox(width: 8), // espacio entre pie y leyenda

        SizedBox(
          width: 140, // ancho fijo más pequeño para la leyenda
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children:
                datos.entries
                    .map(
                      (e) => Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 2,
                          horizontal: 0,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              color: coloresDinamicos[e.key]!,
                            ),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                "${e.key}: ${e.value}",
                                style: TextStyle(color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLineChart(GraficaConfiguracion config) {
    final series = _getLineData(config.filtro, config.periodo);

    // Generar colores para cada serie (key)
    Map<String, Color> coloresDinamicos = {};
    int colorIndex = 0;
    for (var key in series.keys) {
      if (coloresFijos.containsKey(key)) {
        coloresDinamicos[key] = coloresFijos[key]!;
      } else {
        coloresDinamicos[key] = listaColores[colorIndex % listaColores.length];
        colorIndex++;
      }
    }

    return Row(
      children: [
        Expanded(
          flex: 10,
          child: SizedBox(
            height: 280,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 2,
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
                      getTitlesWidget:
                          (value, meta) => Text(
                            "Sprint ${value.toInt() + 1}",
                            style: TextStyle(color: Colors.white, fontSize: 10),
                          ),
                    ),
                  ),
                ),
                lineBarsData:
                    series.entries.map((entry) {
                      return LineChartBarData(
                        spots: entry.value,
                        isCurved: true,
                        color: coloresDinamicos[entry.key] ?? Colors.blue,
                        barWidth: 2,
                        dotData: FlDotData(show: true),
                      );
                    }).toList(),
                minY: 0,
              ),
            ),
          ),
        ),
        SizedBox(width: 10),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children:
              series.keys.map((key) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 15,
                        height: 15,
                        color: coloresDinamicos[key] ?? Colors.blue,
                      ),
                      SizedBox(width: 6),
                      Text(key, style: TextStyle(color: Colors.white)),
                    ],
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }
}
