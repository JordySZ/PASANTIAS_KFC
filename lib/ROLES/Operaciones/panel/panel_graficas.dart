import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:login_app/ROLES/Operaciones/cards2.dart';
import 'package:login_app/super usario/tabla/home_screen.dart';
import 'package:login_app/super usario/cards/cards.dart';
import 'package:login_app/services/api_service.dart';
import 'package:login_app/models/tarjeta.dart';
import 'package:login_app/models/lista_datos.dart';
import 'package:intl/intl.dart';
import 'package:login_app/super%20usario/cronogrma/cronograma.dart';

class PanelTrelloOpe extends StatefulWidget {
  final String? processName;
  const PanelTrelloOpe({Key? key, this.processName}) : super(key: key);

  @override
  _PanelTrelloState createState() => _PanelTrelloState();
}

class _PanelTrelloState extends State<PanelTrelloOpe> {
  List<GraficaConfiguracion> graficas = [];
  final ApiService _apiService = ApiService();
  final _scrollController = ScrollController();

  // Cache para memoización
  final _memoizedChartData = <String, Map<String, int>>{};
  final _memoizedCharts = <String, Widget>{};
  DateTime? _lastDataUpdate;
  final _maxCacheSize = 20;

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
  final Map<String, Color> coloresFijosVencimiento = {
    'Completado (a tiempo)': Colors.green,
    'Completado (con retraso)': Colors.red,
    'Completado (sin fecha)': Colors.lightGreen,
    'Vencido': Colors.red[700]!,
    'Por vencer (próximos 2 días)': Colors.orange,
    'Por vencer (más de 2 días)': Colors.blue,
    'Sin fecha': Colors.grey,
  };

  @override
  void initState() {
    super.initState();
    _currentProcessCollectionName = widget.processName;
    if (_currentProcessCollectionName != null) {
      _loadListsAndCards(_currentProcessCollectionName!);
      _loadGraficasFromBackend();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _memoizedChartData.clear();
    _memoizedCharts.clear();
    super.dispose();
  }

  // Función para añadir al cache con límite de tamaño
  void _addToCache(String key, Map<String, int> data) {
    if (_memoizedChartData.length >= _maxCacheSize) {
      _memoizedChartData.remove(_memoizedChartData.keys.first);
    }
    _memoizedChartData[key] = data;
  }

  //Hasta aqui//
  Future<void> _loadListsAndCards(String processName) async {
    try {
      final loadedLists = await _apiService.getLists(processName);
      final loadedCards = await _apiService.getCards(processName);
      setState(() {
        listas = loadedLists;
        tarjetas = loadedCards;
        _lastDataUpdate = DateTime.now();
        _memoizedChartData.clear();
        _memoizedCharts.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar datos: $e')));
    }
  }

  Future<void> _loadGraficasFromBackend() async {
    if (_currentProcessCollectionName == null) return;
    try {
      final loadedGraficas = await _apiService.getGraficas(
        _currentProcessCollectionName!,
      );
      setState(() {
        graficas = loadedGraficas;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar gráficas: $e')));
    }
  }

  Future<void> _addGraficaToBackend(GraficaConfiguracion config) async {
    if (_currentProcessCollectionName == null) return;
    try {
      final created = await _apiService.createGrafica(
        _currentProcessCollectionName!,
        config,
      );
      if (created != null) {
        setState(() {
          graficas.add(created);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al crear gráfica: $e')));
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
      if (updated != null) {
        setState(() {
          graficas[index] = updated;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar gráfica: $e')),
      );
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
      if (success) {
        setState(() {
          graficas.removeAt(index);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al eliminar gráfica: $e')));
    }
  }

  Map<String, int> _getBarData(String filtro) {
    final cacheKey = '$filtro-${_lastDataUpdate?.millisecondsSinceEpoch ?? 0}';

    if (_memoizedChartData.containsKey(cacheKey)) {
      return _memoizedChartData[cacheKey]!;
    }

    try {
      final Map<String, int> data = {};
      final hoy = DateTime.now();

      if (filtro == "vencimiento") {
        // Inicialización segura de categorías
        const categoriasVencimiento = [
          'Completado (a tiempo)',
          'Completado (con retraso)',
          'Completado (sin fecha)',
          'Vencido',
          'Por vencer (próximos 2 días)',
          'Por vencer (más de 2 días)',
          'Sin fecha',
        ];

        // Inicializar todas las categorías posibles
        for (var categoria in categoriasVencimiento) {
          data[categoria] = 0;
        }

        for (var tarjeta in tarjetas) {
          final tiempoInfo = tarjeta.tiempoRestanteCalculado ?? {};
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

        // Eliminar categorías vacías
        data.removeWhere(
          (key, value) => value == 0 || !categoriasVencimiento.contains(key),
        );
      } else {
        switch (filtro) {
          case "lista":
            for (var lista in listas) {
              if (lista.id != null && lista.titulo.isNotEmpty) {
                final count =
                    tarjetas.where((t) => t.idLista == lista.id).length;
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
            // Eliminar categorías vacías (excepto "Sin asignar")
            data.removeWhere(
              (key, value) => value == 0 && key != "Sin asignar",
            );
            break;
          case "estado":
            final estadosValidos =
                EstadoTarjeta.values.map((e) => e.name).toList();
            for (var tarjeta in tarjetas) {
              final estado = tarjeta.estado?.name ?? "Desconocido";
              if (estadosValidos.contains(estado)) {
                data[estado] = (data[estado] ?? 0) + 1;
              }
            }
            break;
          default:
            throw ArgumentError('Filtro no válido: $filtro');
        }
      }

      // Validación final - asegurar que hay al menos un valor positivo
      if (data.values.every((v) => v == 0)) {
        return {};
      }

      _addToCache(cacheKey, data);
      return data;
    } catch (e) {
      debugPrint('Error en _getBarData: $e');
      return {};
    }
  }

  Map<String, int> _getPieData(String filtro) {
    // Clave única para el cache (incluye filtro y timestamp de última actualización)
    final cacheKey =
        'pie-$filtro-${_lastDataUpdate?.millisecondsSinceEpoch ?? 0}';

    // Verificar si ya tenemos estos datos en caché
    if (_memoizedChartData.containsKey(cacheKey)) {
      return _memoizedChartData[cacheKey]!;
    }

    try {
      final Map<String, int> data = {};
      final hoy = DateTime.now();

      // Validación inicial
      if (listas.isEmpty && tarjetas.isEmpty) {
        _addToCache(cacheKey, {}); // Almacenar resultado vacío en caché
        return {};
      }

      switch (filtro) {
        case "lista":
          for (var lista in listas) {
            if (lista.id != null && lista.titulo.isNotEmpty) {
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
          // Eliminar categorías vacías (excepto "Sin asignar")
          data.removeWhere((key, value) => value == 0 && key != "Sin asignar");
          break;

        case "estado":
          final estadosValidos =
              EstadoTarjeta.values.map((e) => e.name).toList();
          for (var tarjeta in tarjetas) {
            final estado = tarjeta.estado?.name ?? "Desconocido";
            if (estadosValidos.contains(estado)) {
              data[estado] = (data[estado] ?? 0) + 1;
            }
          }
          break;

        case "vencimiento":
          // Inicialización segura de categorías
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
            final tiempoInfo = tarjeta.tiempoRestanteCalculado ?? {};
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

          // Eliminar categorías vacías
          data.removeWhere(
            (key, value) => value == 0 || !categoriasVencimiento.contains(key),
          );
          break;

        default:
          throw ArgumentError('Filtro no válido: $filtro');
      }

      // Validación final - asegurar que hay al menos un valor positivo
      if (data.values.every((v) => v == 0)) {
        _addToCache(cacheKey, {}); // Almacenar resultado vacío en caché
        return {};
      }

      _addToCache(cacheKey, data); // Almacenar en caché antes de retornar
      return data;
    } catch (e) {
      debugPrint('Error en _getPieData: $e');
      _addToCache(
        cacheKey,
        {},
      ); // Almacenar fallo en caché para evitar reintentos
      return {};
    }
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
    final cacheKey =
        '${config.tipoGrafica}-${config.filtro}-${_lastDataUpdate?.millisecondsSinceEpoch ?? 0}';

    if (_memoizedCharts.containsKey(cacheKey)) {
      return _memoizedCharts[cacheKey]!;
    }

    Widget chart;
    switch (config.tipoGrafica) {
      case "barras":
        chart = _buildBarChart(config);
        break;
      case "circular":
        chart = _buildPieChart(config);
        break;
      case "lineas":
        chart = _buildLineChart(config);
        break;
      default:
        chart = const SizedBox();
    }

    if (_memoizedCharts.length >= _maxCacheSize) {
      _memoizedCharts.remove(_memoizedCharts.keys.first);
    }
    _memoizedCharts[cacheKey] = chart;
    return chart;
  }

  Widget _buildBarChart(GraficaConfiguracion config) {
    final datos = _getBarData(config.filtro);

    // Validación de datos vacíos
    if (datos.isEmpty || datos.values.every((v) => v == 0)) {
      return _buildEmptyState('No hay datos disponibles');
    }

    final labels = datos.keys.toList();
    final valores = datos.values.toList();

    final double maxY =
        valores.isNotEmpty
            ? (valores.reduce((a, b) => a > b ? a : b) + 1).toDouble()
            : 5.0;

    return Card(
      margin: EdgeInsets.all(8),
      color: Colors.grey[850],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        height: 280,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
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
                            color:
                                config.filtro == "vencimiento"
                                    ? coloresFijosVencimiento[labels[i]] ??
                                        Colors.grey
                                    : listaColores[i % listaColores.length],
                            width: 14, // Ancho aumentado
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
                        fitInsideVertically: true,
                        fitInsideHorizontally: true,
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine:
                          (value) => FlLine(
                            color: Colors.white.withOpacity(0.1),
                            strokeWidth: 1,
                          ),
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            return (index >= 0 && index < labels.length)
                                ? SideTitleWidget(
                                  meta: meta,
                                  child: Text(
                                    labels[index],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                                : const SizedBox.shrink();
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
                    ),
                  ),
                ),
              ),
            ),
            Container(
              height: 50,
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children:
                      labels.asMap().entries.map((entry) {
                        final index = entry.key;
                        final label = entry.value;
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color:
                                      config.filtro == "vencimiento"
                                          ? coloresFijosVencimiento[label] ??
                                              Colors.grey
                                          : listaColores[index %
                                              listaColores.length],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 6),
                              ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: 120),
                                child: Text(
                                  label,
                                  style: TextStyle(
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

  Widget _buildPieChart(GraficaConfiguracion config) {
    final datos = _getPieData(config.filtro);

    // Verificación crítica para datos vacíos o inválidos
    if (datos.isEmpty || datos.values.every((v) => v == 0)) {
      return SizedBox(
        height: 280,
        child: Center(
          child: Text(
            'No hay datos disponibles',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
      );
    }

    final labels = datos.keys.toList();
    final valores = datos.values.toList();
    final total = valores.reduce((a, b) => a + b);

    return Card(
      margin: EdgeInsets.all(8),
      color: Colors.grey[850],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        height: 280,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 0,
                        centerSpaceRadius: 0, // Centro más pequeño pero visible
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
                            color: listaColores[i % listaColores.length],
                            radius:
                                95, // Radio más grande para mejor visualización
                            title: valores[i] > 0 ? '${percentage}%' : '',
                            titleStyle: TextStyle(
                              fontSize: valores[i] > total * 0.1 ? 14 : 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            showTitle: valores[i] > 0,
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              height: 60,
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(labels.length, (i) {
                    return Tooltip(
                      message: labels[i],
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
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
                            SizedBox(width: 6),
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: 150),
                              child: Text(
                                '${labels[i]} (${valores[i]})',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(GraficaConfiguracion config) {
    final datos = _getBarData(config.filtro);

    // Validación de datos vacíos
    if (datos.isEmpty || datos.values.every((v) => v == 0)) {
      return _buildEmptyState('No hay datos históricos');
    }

    final labels = datos.keys.toList();
    final valores = datos.values.toList();

    // Procesamiento mejorado de fechas
    final fechasFormateadas =
        labels.map((fechaStr) {
          try {
            final fecha = DateTime.parse(fechaStr);
            return DateFormat('dd/MM').format(fecha);
          } catch (_) {
            return fechaStr.length > 7
                ? '${fechaStr.substring(0, 7)}...'
                : fechaStr;
          }
        }).toList();

    final spots = List.generate(
      labels.length,
      (i) => FlSpot(i.toDouble(), valores[i].toDouble()),
    );
    final maxY = valores.reduce((a, b) => a > b ? a : b).toDouble() * 1.1;

    return Card(
      margin: EdgeInsets.all(8),
      color: Colors.grey[850],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        height: 280,
        child: Column(
          children: [
            Expanded(
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
                            _mostrarTarjetasDialog(
                              labels[index],
                              config.filtro,
                            );
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
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            return (index >= 0 && index < labels.length)
                                ? SideTitleWidget(
                                  meta: meta,
                                  child: Text(
                                    labels[index],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                                : const SizedBox.shrink();
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
                              (spot, percent, barData, index) =>
                                  FlDotCirclePainter(
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
          ],
        ),
      ),
    );
  }

  void _mostrarTarjetasDialog(String categoria, String filtro) {
    List<Tarjeta> tarjetasFiltradas = [];

    if (filtro == "vencimiento") {
      final hoy = DateTime.now();
      tarjetasFiltradas =
          tarjetas.where((t) {
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
              return t.estado == EstadoTarjeta.hecho &&
                  t.fechaCompletado == null;
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
          }).toList();
    } else {
      tarjetasFiltradas =
          tarjetas.where((t) {
            if (filtro == "lista") {
              final lista = listas.firstWhere(
                (l) => l.titulo == categoria,
                orElse: () => ListaDatos(id: '', titulo: ''),
              );
              return t.idLista == lista.id;
            } else if (filtro == "miembro") {
              return t.miembro == categoria ||
                  (categoria == "Sin asignar" && t.miembro.isEmpty);
            } else if (filtro == "estado") {
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
            style: const TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: 400,
            height: 500,
            child:
                tarjetasFiltradas.isEmpty
                    ? const Center(
                      child: Text(
                        'No hay tarjetas en esta categoría',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                    : ListView.builder(
                      itemCount: tarjetasFiltradas.length,
                      itemBuilder: (context, index) {
                        final tarjeta = tarjetasFiltradas[index];
                        final tiempoInfo = tarjeta.tiempoRestanteCalculado;
                        final nombreLista =
                            listas
                                .firstWhere(
                                  (l) => l.id == tarjeta.idLista,
                                  orElse:
                                      () => ListaDatos(
                                        id: '',
                                        titulo: 'Desconocida',
                                      ),
                                )
                                .titulo;

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
                                Text(
                                  'Lista: $nombreLista',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                if (tarjeta.miembro.isNotEmpty)
                                  Text(
                                    'Miembro: ${tarjeta.miembro}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                Text(
                                  'Estado: ${tarjeta.estado.name}',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                if (tarjeta.fechaVencimiento != null)
                                  Text(
                                    'Vence: ${DateFormat('dd/MM/yyyy').format(tarjeta.fechaVencimiento!)}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
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
                    ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
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
                      decoration: InputDecoration(
                        labelText: "Tipo de gráfica",
                        labelStyle: const TextStyle(color: Colors.white70),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueAccent),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      items: const [
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
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: filtro,
                      dropdownColor: const Color(0xFF3A3A3A),
                      decoration: InputDecoration(
                        labelText: "Filtrar por",
                        labelStyle: const TextStyle(color: Colors.white70),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white30),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueAccent),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      items: const [
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
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: periodo,
                        dropdownColor: const Color(0xFF3A3A3A),
                        decoration: InputDecoration(
                          labelText: "Periodo de tiempo",
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white30),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.blueAccent),
                          ),
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
                    child: const Text(
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
                    (_) => TableroScreen22(
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No hay proceso seleccionado')),
                );
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
                        (context) => PanelTrelloOpe(
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
                          if (index < 0 || index >= graficas.length) {
                            return const SizedBox();
                          }
                          GraficaConfiguracion config = graficas[index];
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
                                            filtroIconos[config.filtro] ??
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
                                        icon: const Icon(
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
                                        icon: const Icon(
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
                child: FloatingActionButton(
                  backgroundColor: Colors.white,
                  onPressed: () => _mostrarDialogoConfiguracion(),
                  tooltip: "Añadir gráfica",
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
    margin: EdgeInsets.all(8),
    color: Colors.grey[850],
    child: SizedBox(
      height: 280,
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ),
    ),
  );
}
