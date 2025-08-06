import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:login_app/super usario/tabla/home_screen.dart';
import 'package:login_app/super usario/cards/cards.dart';
import 'package:login_app/services/api_service.dart';
import 'package:login_app/models/tarjeta.dart';
import 'package:login_app/models/lista_datos.dart';
import 'package:intl/intl.dart';
import 'package:login_app/super%20usario/cronogrma/cronograma.dart';
import 'package:flutter/foundation.dart';

class PanelTrello extends StatefulWidget {
  final String? processName;
  const PanelTrello({Key? key, this.processName}) : super(key: key);

  @override
  _PanelTrelloState createState() => _PanelTrelloState();
}

class _PanelTrelloState extends State<PanelTrello> {
  
  List<GraficaConfiguracion> graficas = [];
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();

  // Cache optimizada
  final _chartDataCache = <String, Map<String, int>>{};
  final _chartWidgetCache = <String, Widget>{};
  final int _maxCacheSize = 5;
  DateTime? _lastDataUpdate;

  // Datos
  List<ListaDatos> listas = [];
  List<Tarjeta> tarjetas = [];
  String? _currentProcessCollectionName;
bool _needsRefresh = true;
Timer? _refreshTimer;
final Duration _refreshInterval = const Duration(seconds: 5);
bool _autoRefreshEnabled = true;
  // Configuraciones visuales
  final _filtroIconos = const {
    "lista": Icons.list_alt,
    "miembro": Icons.person,
    "vencimiento": Icons.calendar_today,
    "estado": Icons.flag,
  };

  final _listaColores = const [
    Colors.blue,
    Colors.purple,
    Colors.yellow,
    Colors.pink,
    Colors.cyan,
    Colors.teal,
    Colors.lime,
    Colors.indigo,
  ];

  final _coloresFijosVencimiento = const {
    'Completado (a tiempo)': Colors.green,
    'Completado (con retraso)': Colors.red,
    'Completado (sin fecha)': Colors.lightGreen,
    'Vencido': Colors.red,
    'Por vencer (próximos 2 días)': Colors.orange,
    'Por vencer (más de 2 días)': Colors.blue,
    'Sin fecha': Colors.grey,
  };

  @override
void initState() {
  super.initState();
  _currentProcessCollectionName = widget.processName;
  if (_currentProcessCollectionName != null) {
    _loadInitialData();
  }

  Timer.periodic(const Duration(minutes: 5), (_) => _clearExpiredCache());
  
  // Timer de refresco sin animación
  Timer.periodic(const Duration(seconds: 10), (_) {
    if (_currentProcessCollectionName != null && mounted) {
      _refreshData();
    }
  });
}
Future<void> _refreshData() async {
  try {
    await _loadListsAndCards(_currentProcessCollectionName!);
    await _loadGraficasFromBackend();
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al refrescar datos: ${e.toString()}')),
      );
    }
  }
}
  void _clearExpiredCache() {
    if (_lastDataUpdate == null ||
        DateTime.now().difference(_lastDataUpdate!) >
            const Duration(minutes: 5)) {
      _chartDataCache.clear();
      _chartWidgetCache.clear();
    }
  }

  Future<void> _loadInitialData() async {
    try {
      await _loadListsAndCards(_currentProcessCollectionName!);
      await _loadGraficasFromBackend();
    } catch (e) {
      _showErrorSnackbar('Error al cargar datos: ${e.toString()}');
    }
  }

  Future<void> _loadListsAndCards(String processName) async {
    try {
      final loadedLists = await _apiService.getLists(processName);
      final loadedCards = await _apiService.getCards(processName);

      if (mounted) {
        setState(() {
          listas = loadedLists;
          tarjetas = loadedCards;
          _lastDataUpdate = DateTime.now();
          _chartDataCache.clear();
          _chartWidgetCache.clear();
        });
      }
    } catch (e) {
      _showErrorSnackbar('Error al cargar listas y tarjetas: $e');
    }
  }

  Future<void> _loadGraficasFromBackend() async {
    if (_currentProcessCollectionName == null) return;

    try {
      final loadedGraficas = await _apiService.getGraficas(
        _currentProcessCollectionName!,
      );

      if (mounted) {
        setState(() {
          graficas = loadedGraficas;
        });
      }
    } catch (e) {
      _showErrorSnackbar('Error al cargar gráficas: $e');
    }
  }

  Future<void> _addGraficaToBackend(GraficaConfiguracion config) async {
    if (_currentProcessCollectionName == null) return;

    try {
      final created = await _apiService.createGrafica(
        _currentProcessCollectionName!,
        config,
      );

      if (created != null && mounted) {
        setState(() {
          graficas.add(created);
          _chartWidgetCache.clear();
        });
      }
    } catch (e) {
      _showErrorSnackbar('Error al crear gráfica: $e');
    }
  }

  Future<void> _updateGraficaInBackend(
    int index,
    GraficaConfiguracion config,
  ) async {
    if (_currentProcessCollectionName == null) return;

    try {
      final updated = await _apiService.updateGrafica(
        _currentProcessCollectionName!,
        config,
      );

      if (updated != null && mounted) {
        setState(() {
          graficas[index] = updated;
          _chartWidgetCache.clear();
        });
      }
    } catch (e) {
      _showErrorSnackbar('Error al actualizar gráfica: $e');
    }
  }

  Future<void> _deleteGraficaFromBackend(int index) async {
    if (_currentProcessCollectionName == null) return;
    final grafica = graficas[index];
    if (grafica.id == null) return;

    try {
      final success = await _apiService.deleteGrafica(
        _currentProcessCollectionName!,
        grafica.id!,
      );

      if (success && mounted) {
        setState(() {
          graficas.removeAt(index);
          _chartWidgetCache.clear();
        });
      }
    } catch (e) {
      _showErrorSnackbar('Error al eliminar gráfica: $e');
    }
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<Map<String, int>> _getChartData(String tipo, String filtro) async {
    final cacheKey =
        '$tipo-$filtro-${_lastDataUpdate?.millisecondsSinceEpoch ?? 0}';

    if (_chartDataCache.containsKey(cacheKey)) {
      return _chartDataCache[cacheKey]!;
    }

    try {
      final data = await compute(_calculateChartData, {
        'filtro': filtro,
        'tarjetas': tarjetas,
        'listas': listas,
      });

      if (data.isNotEmpty) {
        _chartDataCache[cacheKey] = data;
        if (_chartDataCache.length > _maxCacheSize) {
          _chartDataCache.remove(_chartDataCache.keys.first);
        }
      }

      return data;
    } catch (e) {
      return {};
    }
  }

  static Map<String, int> _calculateChartData(Map<String, dynamic> params) {
    final String filtro = params['filtro'];
    final List<Tarjeta> tarjetas = params['tarjetas'];
    final List<ListaDatos> listas = params['listas'];
    final hoy = DateTime.now();
    final Map<String, int> data = {};

    if (filtro == "vencimiento") {
      const categoriasVencimiento = [
        'Completado (a tiempo)',
        'Completado (con retraso)',
        'Completado (sin fecha)',
        'Vencido',
        'Por vencer (próximos 2 días)',
        'Por vencer (más de 2 días)',
        'Sin fecha',
      ];

      for (var categoria in categoriasVencimiento) {
        data[categoria] = 0;
      }

      for (var tarjeta in tarjetas) {
        final tiempoInfo = tarjeta.tiempoRestanteCalculado;
        final textoEstado = tiempoInfo['text']?.toString() ?? 'Desconocido';

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

      data.removeWhere(
        (key, value) => value == 0 || !categoriasVencimiento.contains(key),
      );
    } else {
      switch (filtro) {
        case "lista":
          for (var lista in listas) {
            if (lista.titulo.isNotEmpty) {
              final count = tarjetas.where((t) => t.idLista == lista.id).length;
              if (count > 0) {
                data[lista.titulo] = count;
              }
            }
          }
          break;
        case "miembro":
          for (var tarjeta in tarjetas) {
            final miembro =
                tarjeta.miembro.isNotEmpty ? tarjeta.miembro : "Sin asignar";
            data[miembro] = (data[miembro] ?? 0) + 1;
          }
          data.removeWhere((key, value) => value == 0 && key != "Sin asignar");
          break;
        case "estado":
          final estadosValidos =
              EstadoTarjeta.values.map((e) => e.name).toList();
          for (var tarjeta in tarjetas) {
            final estado = tarjeta.estado.name;
            if (estadosValidos.contains(estado)) {
              data[estado] = (data[estado] ?? 0) + 1;
            }
          }
          break;
        default:
          return {};
      }
    }

    return data;
  }

  String _tituloGrafica(GraficaConfiguracion config) {
    final filtroNombre =
        {
          "lista": "Lista",
          "miembro": "Miembro",
          "vencimiento": "Fecha de vencimiento",
          "estado": "Estado",
        }[config.filtro] ??
        config.filtro;

    if (config.tipoGrafica == "lineas") {
      return "Progreso - $filtroNombre (${config.periodo})";
    }

    final tipoNombre =
        {"barras": "Tarjetas por", "circular": "Distribución por"}[config
            .tipoGrafica] ??
        "";

    return "$tipoNombre $filtroNombre";
  }

  Future<Widget> _construirGrafica(GraficaConfiguracion config) async {
    final cacheKey =
        '${config.tipoGrafica}-${config.filtro}-${_lastDataUpdate?.millisecondsSinceEpoch ?? 0}';

    if (_chartWidgetCache.containsKey(cacheKey)) {
      return _chartWidgetCache[cacheKey]!;
    }

    final datos = await _getChartData(config.tipoGrafica, config.filtro);
    Widget chart;

    switch (config.tipoGrafica) {
      case "barras":
        chart = _buildBarChart(config, datos);
        break;
      case "circular":
        chart = _buildPieChart(config, datos);
        break;
      case "lineas":
        chart = _buildLineChart(config, datos);
        break;
      default:
        chart = const SizedBox();
    }

    if (_chartWidgetCache.length >= _maxCacheSize) {
      _chartWidgetCache.remove(_chartWidgetCache.keys.first);
    }
    _chartWidgetCache[cacheKey] = chart;
    return chart;
  }

  Widget _buildBarChart(GraficaConfiguracion config, Map<String, int> datos) {
    if (datos.isEmpty) return _buildEmptyState('No hay datos disponibles');

    final labels = datos.keys.toList();
    final valores = datos.values.toList();

    final effectiveColors = List.generate(
      labels.length,
      (i) =>
          config.filtro == "vencimiento"
              ? _coloresFijosVencimiento[labels[i]] ?? Colors.grey
              : _listaColores[i % _listaColores.length],
    );

    final maxY = valores.reduce((a, b) => a > b ? a : b).toDouble() + 1;

    return Card(
      margin: const EdgeInsets.all(8),
      color: Colors.grey[850],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        height: 300,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 12,
                  right: 12,
                  top: 12,
                  bottom: 4,
                ),
                child: BarChart(
                  BarChartData(
                    maxY: maxY,
                    minY: 0,
                    barGroups: List.generate(labels.length, (i) {
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: valores[i].toDouble(),
                            color: effectiveColors[i],
                            width: 14,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      );
                    }),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchCallback: (
                        FlTouchEvent event,
                        BarTouchResponse? response,
                      ) {
                        if (event is FlTapUpEvent &&
                            response != null &&
                            response.spot != null) {
                          final index = response.spot!.touchedBarGroupIndex;
                          if (index >= 0 &&
                              index < labels.length &&
                              valores[index] > 0) {
                            _mostrarTarjetasDialog(
                              labels[index],
                              config.filtro,
                            );
                          }
                        }
                      },
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${labels[groupIndex]}\n${rod.toY.toInt()} tarjetas',
                            const TextStyle(color: Colors.white),
                          );
                        },
                      ),
                    ),
                    gridData: FlGridData(show: false),
                    titlesData: const FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Leyenda SIN scroll
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children:
                      labels.asMap().entries.map((entry) {
                        final index = entry.key;
                        final label = entry.value;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: effectiveColors[index],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.25,
                                ),
                                child: Text(
                                  label,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(GraficaConfiguracion config, Map<String, int> datos) {
    if (datos.isEmpty) return _buildEmptyState('No hay datos disponibles');

    final labels = datos.keys.toList();
    final valores = datos.values.toList();
    final total = valores.reduce((a, b) => a + b);

    return Card(
      margin: const EdgeInsets.all(8),
      color: Colors.grey[850],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        height: 280,
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 0,
                        centerSpaceRadius: 0,
                        pieTouchData: PieTouchData(
                          enabled: true,
                          touchCallback: (
                            FlTouchEvent event,
                            PieTouchResponse? response,
                          ) {
                            if (event is FlTapUpEvent &&
                                response != null &&
                                response.touchedSection != null) {
                              final index =
                                  response.touchedSection!.touchedSectionIndex;
                              if (index >= 0 &&
                                  index < labels.length &&
                                  valores[index] > 0) {
                                _mostrarTarjetasDialog(
                                  labels[index],
                                  config.filtro,
                                );
                              }
                            }
                          },
                        ),
                        sections: List.generate(labels.length, (i) {
                          final percentage = (valores[i] / total * 100).round();
                          return PieChartSectionData(
                            value: valores[i].toDouble(),
                            color: _listaColores[i % _listaColores.length],
                            radius: 105,
                            title: valores[i] > 0 ? '${percentage}%' : '',
                            titleStyle: TextStyle(
                              fontSize: valores[i] > total * 0.1 ? 14 : 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(labels.length, (i) {
                      return Tooltip(
                        message: labels[i],
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color:
                                      _listaColores[i % _listaColores.length],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  '${labels[i]} (${valores[i]})',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(GraficaConfiguracion config, Map<String, int> datos) {
    if (datos.isEmpty) return _buildEmptyState('No hay datos históricos');

    final labels = datos.keys.toList();
    final valores = datos.values.toList();

    final fechasFormateadas =
        labels.map((fechaStr) {
          try {
            final fecha = DateTime.parse(fechaStr);
            return DateFormat('dd/MM').format(fecha);
          } catch (_) {
            return fechaStr;
          }
        }).toList();

    final spots = List.generate(
      labels.length,
      (i) => FlSpot(i.toDouble(), valores[i].toDouble()),
    );
    final maxY = valores.reduce((a, b) => a > b ? a : b).toDouble() * 1.1;

    return Card(
      margin: const EdgeInsets.all(8),
      color: Colors.grey[850],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        height: 280,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY > 10 ? 2 : 1,
                getDrawingHorizontalLine:
                    (value) => FlLine(
                      color: Colors.white.withOpacity(0.1),
                      strokeWidth: 1,
                    ),
              ),
              lineTouchData: LineTouchData(
                enabled: true,
                touchCallback: (
                  FlTouchEvent event,
                  LineTouchResponse? response,
                ) {
                  if (event is FlTapUpEvent &&
                      response != null &&
                      response.lineBarSpots != null) {
                    final spot = response.lineBarSpots!.first;
                    final index = spot.x.toInt();
                    if (index >= 0 &&
                        index < labels.length &&
                        valores[index] > 0) {
                      _mostrarTarjetasDialog(labels[index], config.filtro);
                    }
                  }
                },
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (List<LineBarSpot> touchedSpots) {
                    return touchedSpots.map((spot) {
                      final index = spot.x.toInt();
                      return LineTooltipItem(
                        '${fechasFormateadas[index]}\n${spot.y.toInt()} tarjetas',
                        const TextStyle(color: Colors.white),
                      );
                    }).toList();
                  },
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    reservedSize: 28, // Más espacio para etiquetas
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < fechasFormateadas.length) {
                        return Padding(
                          padding: const EdgeInsets.only(
                            top: 10.0,
                          ), // Más espacio arriba
                          child: Text(
                            fechasFormateadas[index],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
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
                    interval: maxY > 10 ? 2 : 1,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
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
                  dotData: FlDotData(
                    show: true,
                    getDotPainter:
                        (spot, percent, barData, index) => FlDotCirclePainter(
                          radius: 4,
                          color: Colors.greenAccent,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        Colors.greenAccent.withOpacity(0.3),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarTarjetasDialog(String categoria, String filtro) {
    final tarjetasFiltradas = _filterCardsByCategory(categoria, filtro);
    if (tarjetasFiltradas.isEmpty) {
      _showErrorSnackbar('No hay tarjetas en esta categoría');
      return;
    }

    showDialog(
      context: context,
      builder:
          (_) => _CardsDialog(
            categoria: categoria,
            tarjetas: tarjetasFiltradas,
            listas: listas,
          ),
    );
  }

  List<Tarjeta> _filterCardsByCategory(String categoria, String filtro) {
    final hoy = DateTime.now();
    return tarjetas.where((t) {
      switch (filtro) {
        case "vencimiento":
          return _filterByDueDate(t, categoria, hoy);
        case "lista":
          return listas.any((l) => l.titulo == categoria && t.idLista == l.id);
        case "miembro":
          return t.miembro == categoria ||
              (categoria == "Sin asignar" && t.miembro.isEmpty);
        case "estado":
          return t.estado.name == categoria;
        default:
          return false;
      }
    }).toList();
  }

  bool _filterByDueDate(Tarjeta t, String categoria, DateTime hoy) {
    if (categoria == 'Completado (a tiempo)') {
      return t.estado == EstadoTarjeta.hecho &&
          t.fechaCompletado != null &&
          (t.fechaVencimiento == null ||
              !t.fechaCompletado!.isAfter(t.fechaVencimiento!));
    } else if (categoria == 'Completado (con retraso)') {
      return t.estado == EstadoTarjeta.hecho &&
          t.fechaCompletado != null &&
          t.fechaVencimiento != null &&
          t.fechaCompletado!.isAfter(t.fechaVencimiento!);
    } else if (categoria == 'Completado (sin fecha)') {
      return t.estado == EstadoTarjeta.hecho && t.fechaCompletado == null;
    } else if (categoria == 'Vencido') {
      return t.estado != EstadoTarjeta.hecho &&
          t.fechaVencimiento != null &&
          t.fechaVencimiento!.isBefore(hoy);
    } else if (categoria == 'Por vencer (próximos 2 días)') {
      return t.estado != EstadoTarjeta.hecho &&
          t.fechaVencimiento != null &&
          !t.fechaVencimiento!.isBefore(hoy) &&
          t.fechaVencimiento!.difference(hoy).inDays <= 2;
    } else if (categoria == 'Por vencer (más de 2 días)') {
      return t.estado != EstadoTarjeta.hecho &&
          t.fechaVencimiento != null &&
          t.fechaVencimiento!.difference(hoy).inDays > 2;
    } else if (categoria == 'Sin fecha') {
      return t.fechaVencimiento == null;
    }
    return false;
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
                backgroundColor: const Color(0xFF3A3A3A),
                title: Text(
                  editar ? "Editar gráfica" : "Añadir gráfica",
                  style: const TextStyle(color: Colors.white),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: tipo,
                      dropdownColor: const Color(0xFF3A3A3A),
                      decoration: const InputDecoration(
                        labelText: "Tipo de gráfica",
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                      style: const TextStyle(color: Colors.white),
                      items: const [
                        DropdownMenuItem(
                          value: "barras",
                          child: Row(
                            children: [
                              Icon(Icons.bar_chart, color: Colors.white),
                              SizedBox(width: 8),
                              Text("Barras"),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: "circular",
                          child: Row(
                            children: [
                              Icon(Icons.pie_chart, color: Colors.white),
                              SizedBox(width: 8),
                              Text("Circular"),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: "lineas",
                          child: Row(
                            children: [
                              Icon(Icons.show_chart, color: Colors.white),
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
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: filtro,
                      dropdownColor: const Color(0xFF3A3A3A),
                      decoration: const InputDecoration(
                        labelText: "Filtrar por",
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                      style: const TextStyle(color: Colors.white),
                      items: const [
                        DropdownMenuItem(
                          value: "lista",
                          child: Row(
                            children: [
                              Icon(Icons.list_alt, color: Colors.white),
                              SizedBox(width: 8),
                              Text("Lista"),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: "miembro",
                          child: Row(
                            children: [
                              Icon(Icons.person, color: Colors.white),
                              SizedBox(width: 8),
                              Text("Miembro"),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: "vencimiento",
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, color: Colors.white),
                              SizedBox(width: 8),
                              Text("Fecha de vencimiento"),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: "estado",
                          child: Row(
                            children: [
                              Icon(Icons.flag, color: Colors.white),
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
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: periodo,
                        dropdownColor: const Color(0xFF3A3A3A),
                        decoration: const InputDecoration(
                          labelText: "Periodo de tiempo",
                          labelStyle: TextStyle(color: Colors.white70),
                        ),
                        style: const TextStyle(color: Colors.white),
                        items: const [
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
                    child: const Text("Cancelar"),
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
                        await _updateGraficaInBackend(index, config);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E2E2E),
      appBar: AppBar(
        backgroundColor: Colors.black,
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
        title: const Text(
          "Panel de Proyecto",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu),
            onSelected: (String value) {
              if (_currentProcessCollectionName == null) {
                _showErrorSnackbar('No hay proceso seleccionado');
                return;
              }

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
                (BuildContext context) => const [
                  PopupMenuItem<String>(
                    value: 'cronograma',
                    child: Text('Cronograma'),
                  ),
                  PopupMenuItem<String>(value: 'tablas', child: Text('Tablas')),
                  PopupMenuItem<String>(value: 'panel', child: Text('Panel')),
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
                            const Text(
                              "Añade una gráfica para comenzar +",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () => _mostrarDialogoConfiguracion(),
                              child: const Text('Crear primera gráfica'),
                            ),
                          ],
                        ),
                      )
                      : GridView.builder(
                        controller: _scrollController,
                        itemCount: graficas.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 6,
                              mainAxisSpacing: 6,
                              childAspectRatio: 2.3,
                            ),
                        itemBuilder: (context, index) {
                          final config = graficas[index];
                          return FutureBuilder<Widget>(
                            future: _construirGrafica(config),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState !=
                                  ConnectionState.done) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              return Card(
                                color: const Color(0xFF3A3A3A),
                                child: Stack(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                _filtroIconos[config.filtro] ??
                                                    Icons.bar_chart,
                                                color: Colors.white70,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  _tituloGrafica(config),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Expanded(
                                            child:
                                                snapshot.data ??
                                                _buildEmptyState(
                                                  'Error al cargar',
                                                ),
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
                                            icon: const Icon(
                                              Icons.edit,
                                              color: Colors.white,
                                            ),
                                            onPressed:
                                                () =>
                                                    _mostrarDialogoConfiguracion(
                                                      editar: true,
                                                      index: index,
                                                    ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.redAccent,
                                            ),
                                            onPressed:
                                                () => _deleteGraficaFromBackend(
                                                  index,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0, right: 12.0),
                child: FloatingActionButton(
                  backgroundColor: Colors.white,
                  onPressed: () => _mostrarDialogoConfiguracion(),
                  child: const Icon(Icons.add, color: Colors.black, size: 35),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildEmptyState(String message) {
  return Card(
    margin: const EdgeInsets.all(8),
    color: Colors.grey[850],
    child: SizedBox(
      height: 280,
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ),
    ),
  );
}

class _CardsDialog extends StatelessWidget {
  final String categoria;
  final List<Tarjeta> tarjetas;
  final List<ListaDatos> listas;

  const _CardsDialog({
    required this.categoria,
    required this.tarjetas,
    required this.listas,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: Text(
        'Tarjetas - $categoria (${tarjetas.length})',
        style: const TextStyle(color: Colors.white),
      ),
      content: SizedBox(
        width: 400,
        height: 500,
        child:
            tarjetas.isEmpty
                ? const Center(
                  child: Text(
                    'No hay tarjetas en esta categoría',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
                : ListView.builder(
                  itemCount: tarjetas.length,
                  itemBuilder: (context, index) {
                    final tarjeta = tarjetas[index];
                    final lista = listas.firstWhere(
                      (l) => l.id == tarjeta.idLista,
                      orElse: () => ListaDatos(id: '', titulo: 'Desconocida'),
                    );

                    return Card(
                      color: Colors.grey[800],
                      margin: const EdgeInsets.all(4),
                      child: ListTile(
                        title: Text(
                          tarjeta.titulo,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lista: ${lista.titulo}',
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
                              tarjeta.tiempoRestanteCalculado['text'],
                              style: TextStyle(
                                color: tarjeta.tiempoRestanteCalculado['color'],
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
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
