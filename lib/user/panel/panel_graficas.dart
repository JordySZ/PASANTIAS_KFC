import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PanelTrello extends StatefulWidget {
  @override
  _PanelTrelloState createState() => _PanelTrelloState();
}

class GraficaConfiguracion {
  String tipoGrafica; // barras, circular, lineas
  String filtro; // lista, miembro, etiqueta, vencimiento
  String periodo; // Solo para lineas

  GraficaConfiguracion({
    required this.tipoGrafica,
    required this.filtro,
    this.periodo = "Semana pasada",
  });
}

class _PanelTrelloState extends State<PanelTrello> {
  List<GraficaConfiguracion> graficas = [];
  final Map<String, Color> coloresFijos = {
    'Cumplida': Colors.green,
    'Vence pronto': Colors.orange,
    'Sin fecha': Colors.grey,
  };

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF2E2E2E),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          ("Panel de Proyecto"),
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Colors.white),
            onPressed: () => _mostrarDialogoConfiguracion(),
            tooltip: "Añadir gráfica",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child:
            graficas.isEmpty
                ? Center(
                  child: Text(
                    "Añade una gráfica con el botón + arriba",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
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
                    GraficaConfiguracion config = graficas[index];
                    return Card(
                      color: Color(0xFF3A3A3A),
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                Expanded(child: _construirGrafica(config)),
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
                                  icon: Icon(Icons.edit, color: Colors.white),
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
                                  onPressed: () {
                                    setState(() {
                                      graficas.removeAt(index);
                                    });
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
                    onPressed: () {
                      setState(() {
                        if (editar) {
                          graficas[index!] = GraficaConfiguracion(
                            tipoGrafica: tipo,
                            filtro: filtro,
                            periodo: periodo,
                          );
                        } else {
                          graficas.add(
                            GraficaConfiguracion(
                              tipoGrafica: tipo,
                              filtro: filtro,
                              periodo: periodo,
                            ),
                          );
                        }
                      });
                      Navigator.pop(context);
                    },
                  ),
                ],
              );
            },
          ),
    );
  }

  // Datos simulados por filtro para barras
  Map<String, Map<String, int>> datosBarrasPorFiltro = {
    "lista": {"Backlog": 5, "En progreso": 7, "Revisión": 3, "Finalizado": 8},
    "miembro": {"Alex": 4, "Maria": 6, "Juan": 5, "Ana": 3},
    "etiqueta": {"Urgente": 6, "Media": 4, "Baja": 2},
    "vencimiento": {"Hoy": 3, "Esta semana": 7, "Sin fecha": 5},
  };

  // Datos simulados por filtro para pie
  Map<String, Map<String, int>> datosPiePorFiltro = {
    "lista": {"Cumplida": 6, "Vence pronto": 3, "Sin fecha": 1},
    "miembro": {"Alex": 5, "Maria": 3, "Juan": 2},
    "etiqueta": {"Urgente": 4, "Media": 4, "Baja": 2},
    "vencimiento": {"Hoy": 5, "Esta semana": 4, "Sin fecha": 3},
  };

  // Datos simulados para líneas (más simples, solo según periodo)
  Map<String, List<FlSpot>> datosLineasPorPeriodo = {
    "Semana pasada": [
      FlSpot(0, 2),
      FlSpot(1, 4),
      FlSpot(2, 6),
      FlSpot(3, 8),
      FlSpot(4, 6),
    ],
    "Últimas dos semanas": [
      FlSpot(0, 1),
      FlSpot(1, 3),
      FlSpot(2, 5),
      FlSpot(3, 7),
      FlSpot(4, 9),
      FlSpot(5, 6),
      FlSpot(6, 4),
    ],
    "Mes pasado": [
      FlSpot(0, 2),
      FlSpot(1, 3),
      FlSpot(2, 4),
      FlSpot(3, 5),
      FlSpot(4, 6),
      FlSpot(5, 7),
      FlSpot(6, 8),
      FlSpot(7, 7),
      FlSpot(8, 6),
      FlSpot(9, 5),
      FlSpot(10, 4),
      FlSpot(11, 3),
      FlSpot(12, 2),
      FlSpot(13, 1),
      FlSpot(14, 0),
    ],
  };

  Widget _buildBarChart(GraficaConfiguracion config) {
    final datos = datosBarrasPorFiltro[config.filtro] ?? {};

    final labels = datos.keys.toList();
    final valores = datos.values.toList();

    // Aseguramos que la lista de colores tenga al menos la cantidad de datos
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
                  enabled: true,
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
    final datos = datosPiePorFiltro[config.filtro] ?? {"Sin datos": 1};
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
    // Datos simulados con series diferenciadas por filtro, periodo y serie
    Map<String, Map<String, Map<String, List<FlSpot>>>>
    datosLineasPorFiltroYPeriodoYSerie = {
      "lista": {
        "Semana pasada": {
          "Cumplida": [FlSpot(0, 2), FlSpot(1, 4), FlSpot(2, 6)],
          "Vence pronto": [FlSpot(0, 1), FlSpot(1, 3), FlSpot(2, 5)],
          "Sin fecha": [FlSpot(0, 3), FlSpot(1, 2), FlSpot(2, 4)],
        },
        "Últimas dos semanas": {
          "Cumplida": [FlSpot(0, 3), FlSpot(1, 5), FlSpot(2, 7)],
          "Vence pronto": [FlSpot(0, 2), FlSpot(1, 4), FlSpot(2, 6)],
          "Sin fecha": [FlSpot(0, 1), FlSpot(1, 3), FlSpot(2, 5)],
        },
        "Mes pasado": {
          "Cumplida": [FlSpot(0, 1), FlSpot(1, 2), FlSpot(2, 4)],
          "Vence pronto": [FlSpot(0, 2), FlSpot(1, 1), FlSpot(2, 3)],
          "Sin fecha": [FlSpot(0, 3), FlSpot(1, 4), FlSpot(2, 5)],
        },
      },
      "miembro": {
        "Semana pasada": {
          "Alex": [FlSpot(0, 4), FlSpot(1, 5), FlSpot(2, 7)],
          "Maria": [FlSpot(0, 3), FlSpot(1, 4), FlSpot(2, 6)],
          "Juan": [FlSpot(0, 2), FlSpot(1, 3), FlSpot(2, 5)],
        },
        "Últimas dos semanas": {
          "Alex": [FlSpot(0, 5), FlSpot(1, 6), FlSpot(2, 8)],
          "Maria": [FlSpot(0, 4), FlSpot(1, 5), FlSpot(2, 7)],
          "Juan": [FlSpot(0, 3), FlSpot(1, 4), FlSpot(2, 6)],
        },
        "Mes pasado": {
          "Alex": [FlSpot(0, 3), FlSpot(1, 4), FlSpot(2, 5)],
          "Maria": [FlSpot(0, 2), FlSpot(1, 3), FlSpot(2, 4)],
          "Juan": [FlSpot(0, 1), FlSpot(1, 2), FlSpot(2, 3)],
        },
      },
      "etiqueta": {
        "Semana pasada": {
          "Urgente": [FlSpot(0, 3), FlSpot(1, 4), FlSpot(2, 6)],
          "Media": [FlSpot(0, 2), FlSpot(1, 3), FlSpot(2, 5)],
          "Baja": [FlSpot(0, 1), FlSpot(1, 2), FlSpot(2, 4)],
        },
        "Últimas dos semanas": {
          "Urgente": [FlSpot(0, 4), FlSpot(1, 5), FlSpot(2, 7)],
          "Media": [FlSpot(0, 3), FlSpot(1, 4), FlSpot(2, 6)],
          "Baja": [FlSpot(0, 2), FlSpot(1, 3), FlSpot(2, 5)],
        },
        "Mes pasado": {
          "Urgente": [FlSpot(0, 2), FlSpot(1, 3), FlSpot(2, 4)],
          "Media": [FlSpot(0, 1), FlSpot(1, 2), FlSpot(2, 3)],
          "Baja": [FlSpot(0, 0), FlSpot(1, 1), FlSpot(2, 2)],
        },
      },
      "vencimiento": {
        "Semana pasada": {
          "Hoy": [FlSpot(0, 5), FlSpot(1, 6), FlSpot(2, 8)],
          "Esta semana": [FlSpot(0, 3), FlSpot(1, 4), FlSpot(2, 6)],
          "Sin fecha": [FlSpot(0, 2), FlSpot(1, 3), FlSpot(2, 5)],
        },
        "Últimas dos semanas": {
          "Hoy": [FlSpot(0, 4), FlSpot(1, 5), FlSpot(2, 7)],
          "Esta semana": [FlSpot(0, 3), FlSpot(1, 4), FlSpot(2, 6)],
          "Sin fecha": [FlSpot(0, 2), FlSpot(1, 3), FlSpot(2, 5)],
        },
        "Mes pasado": {
          "Hoy": [FlSpot(0, 3), FlSpot(1, 4), FlSpot(2, 5)],
          "Esta semana": [FlSpot(0, 2), FlSpot(1, 3), FlSpot(2, 4)],
          "Sin fecha": [FlSpot(0, 1), FlSpot(1, 2), FlSpot(2, 3)],
        },
      },
    };

    Map<String, List<String>> nombresSeriesPorFiltro = {
      "lista": ["Cumplida", "Vence pronto", "Sin fecha"],
      "miembro": ["Alex", "Maria", "Juan"],
      "etiqueta": ["Urgente", "Media", "Baja"],
      "vencimiento": ["Hoy", "Esta semana", "Sin fecha"],
    };

    Map<String, Color> coloresDinamicos = {};
    int colorIndex = 0;

    Map<String, List<FlSpot>> series = {};

    List<String> nombresSeries = nombresSeriesPorFiltro[config.filtro] ?? [];

    for (var nombre in nombresSeries) {
      series[nombre] =
          datosLineasPorFiltroYPeriodoYSerie[config.filtro]?[config
              .periodo]?[nombre] ??
          [];
    }

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
                        color: coloresDinamicos[entry.key],
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
                        color: coloresDinamicos[key],
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
