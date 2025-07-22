import 'package:flutter/material.dart';
import 'dart:math';
import 'package:intl/date_symbol_data_local.dart';

import 'package:login_app/super%20usario/cards/cards.dart'; // Asumo que TableroScreen está aquí
import 'package:login_app/super%20usario/crud_user.dart'; // Asumo que UsuariosScreen está aquí
import 'package:login_app/super%20usario/custom_drawer.dart';
import 'package:login_app/services/api_service.dart';

// Modelo del proyecto
class Project {
  final String name;
  final String status;
  final String startDate;
  final String endDate;
  final double progress;
  final String? estado;

  Project({
    required this.name,
    this.status = 'Activo',
    this.startDate = 'N/A',
    this.endDate = 'N/A',
    this.progress = 0.0,
    this.estado,
  });
}

// Página principal del dashboard
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  final ApiService _apiService = ApiService();
  List<Project> _projects = [];
  List<Project> _projectsFiltered = [];
  bool _isLoadingProjects = true;
  String? _projectsErrorMessage;
  final TextEditingController _searchController = TextEditingController();

  double completedPercent = 0.0;
  double inProgressPercent = 0.0;
  double pendingPercent = 0.0;
  int selectedCircleSegment = -1;

  int totalProyectos = 0;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es', null).then((_) {
      _fetchProjectsData();
    });
  }

  Future<void> _fetchProjectsData() async {
    setState(() {
      _isLoadingProjects = true;
      _projectsErrorMessage = null;
    });
    try {
      final fetchedProcesses = await _apiService.getProcesses();
      setState(() {
        _projects =
            fetchedProcesses
                .map(
                  (process) => Project(
                    name: process.nombre_proceso,
                    startDate: process.startDate.toIso8601String(),
                    endDate: process.endDate.toIso8601String(),
                    progress: process.progress ?? 0.0,
                    estado: process.estado,
                  ),
                )
                .toList();
        _projectsFiltered = _projects;
        _isLoadingProjects = false;
        _calculateProjectPercentages();
      });
    } catch (e) {
      setState(() {
        _projectsErrorMessage = 'Error al cargar los procesos: $e';
        _isLoadingProjects = false;
      });
    }
  }

  void _calculateProjectPercentages() {
    if (_projects.isEmpty) {
      setState(() {
        completedPercent = 0.0;
        inProgressPercent = 0.0;
        pendingPercent = 0.0;
        totalProyectos = 0;
      });
      return;
    }

    int completedCount =
        _projects
            .where((p) => (p.estado?.toLowerCase() ?? '') == 'echo')
            .length;
    int inProgressCount =
        _projects
            .where((p) => (p.estado?.toLowerCase() ?? '') == 'en proceso')
            .length;
    int pendingCount =
        _projects
            .where((p) => (p.estado?.toLowerCase() ?? '') == 'pendiente')
            .length;

    int otherCount =
        _projects.length - completedCount - inProgressCount - pendingCount;
    pendingCount +=
        otherCount; // Se asume que cualquier otro estado se agrupa en 'Pendiente'

    int total = _projects.length;

    setState(() {
      completedPercent = completedCount / total;
      inProgressPercent = inProgressCount / total;
      pendingPercent = pendingCount / total;
      totalProyectos = total;
    });
  }

  void _filtrarProyectos(String query) {
    setState(() {
      _projectsFiltered =
          _projects
              .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
              .toList();
    });
  }

  void _confirmDeleteProcess(BuildContext context, String processName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: Text(
            '¿Estás seguro de que quieres eliminar el proceso "$processName"? Esta acción es irreversible y eliminará todos los datos asociados a este proceso (listas y tarjetas).',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteProcess(processName);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteProcess(String processName) async {
    setState(() {
      _isLoadingProjects = true;
    });
    try {
      final success = await _apiService.deleteProcess(processName);
      if (success) {
        await _fetchProjectsData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Proceso "$processName" eliminado exitosamente.'),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar el proceso "$processName".'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de conexión al eliminar el proceso: $e'),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingProjects = false;
      });
    }
  }

  String _formatDate(String dateString) {
    try {
      final DateTime dateTime = DateTime.parse(dateString);
      return '${dateTime.day.toString().padLeft(2, '0')}/'
          '${dateTime.month.toString().padLeft(2, '0')}/'
          '${dateTime.year}';
    } catch (e) {
      return 'Fecha Inválida';
    }
  }

  void _onItemTapped(int index) {
    Navigator.of(context).pop(); // Cierra el drawer
    switch (index) {
      case 0: // Inicio (Dashboard)
        setState(() => _selectedIndex = 0);
        break;
      case 1: // Usuarios
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => UsuariosScreen()),
        );
        break;
      case 2: // Gestión de Procesos / Tablero
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TableroScreen(processName: null),
          ),
        );
        break;
      case 3: // Tablero de Proyectos (Redundante con 2 si es lo mismo)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TableroScreen(processName: null),
          ),
        );
        break;
      case 4: // Crear nuevo proceso (Redundante con 2 si es lo mismo)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TableroScreen(processName: null),
          ),
        );
        //
        break;
      case 5: // Cerrar Sesión
        _showLogoutDialog();
        break;
      default:
        break;
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cerrar Sesión'),
            ),
          ],
        );
      },
    );
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle(_selectedIndex)),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchProjectsData,
          ),
        ],
      ),
      drawer: CustomDrawer(
        selectedIndex: _selectedIndex,
        onItemTap: _onItemTapped,
      ),
      body: _buildPageContent(_selectedIndex),
    );
  }

  String _getTitle(int index) {
    switch (index) {
      case 0:
        return 'Inicio';
      case 1:
        return 'Usuarios';
      case 2:
        return 'Gestión de Procesos';
      case 3:
        return 'Tablero de Proyectos';
      case 4:
        return 'Crear nuevo proceso';
      default:
        return 'Dashboard';
    }
  }

  Widget _buildPageContent(int index) {
    switch (index) {
      case 0:
        return _homeContent();
      case 1:
        return UsuariosScreen();
      case 2:
      case 3:
      case 4:
        return TableroScreen(processName: null);
      default:
        return const Center(child: Text('Página no encontrada'));
    }
  }

  Widget _homeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Center(
                child: SizedBox(
                  width: 600,
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          labelText: 'Buscar Proyecto',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                        ),
                        onChanged: _filtrarProyectos,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 800) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPieChart(),
                        const SizedBox(width: 40),
                        _buildBarChart(constraints),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        _buildPieChart(),
                        const SizedBox(height: 40),
                        _buildBarChart(constraints),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 30),
              _tableContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 220,
          height: 220,
          child: GestureDetector(
            onTapUp: (details) {
              final RenderBox box = context.findRenderObject() as RenderBox;
              final Offset localPos = box.globalToLocal(details.globalPosition);
              _handleCircleTap(localPos);
            },
            child: CustomPaint(
              painter: MultiSegmentCirclePainter(
                completedPercent: completedPercent,
                inProgressPercent: inProgressPercent,
                pendingPercent: pendingPercent,
                colors: [Colors.green, Colors.blue, Colors.orange],
                selectedSegment: selectedCircleSegment,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$totalProyectos',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Text(
                      'Proyectos',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildLegend(),
      ],
    );
  }

  Widget _buildLegend() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(
          Colors.green,
          'Completado: ${(completedPercent * 100).toStringAsFixed(1)}%',
          isSelected: selectedCircleSegment == 0,
        ),
        _buildLegendItem(
          Colors.blue,
          'En progreso: ${(inProgressPercent * 100).toStringAsFixed(1)}%',
          isSelected: selectedCircleSegment == 1,
        ),
        _buildLegendItem(
          Colors.orange,
          'Pendiente: ${(pendingPercent * 100).toStringAsFixed(1)}%',
          isSelected: selectedCircleSegment == 2,
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String text, {bool isSelected = false}) {
    return Container(
      decoration:
          isSelected
              ? BoxDecoration(
                border: Border.all(color: color, width: 2),
                borderRadius: BorderRadius.circular(6),
                color: color.withOpacity(0.15),
              )
              : null,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 20, height: 14, color: color),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildBarChart(BoxConstraints constraints) {
    // Inicializamos contadores para cada mes (de enero a diciembre)
    List<int> started = List.filled(12, 0); // Proyectos iniciados por mes
    List<int> closed = List.filled(12, 0); // Proyectos finalizados por mes

    for (var project in _projects) {
      final start = DateTime.tryParse(project.startDate);
      final end = DateTime.tryParse(project.endDate);

      if (start != null) {
        started[start.month - 1]++;
      }

      if (end != null) {
        closed[end.month - 1]++;
      }
    }

    // Calculamos el ancho dinámicamente según barras y espacios para evitar desbordes
    const double barWidth = 20;
    const double barSpace = 8; // Space between started and closed bars
    const double groupSpace = 20; // Space between month groups
    const double leftPadding = 60;
    const double rightPadding = 20;
    const int monthCount = 12;

    double totalContentWidth =
        leftPadding +
        monthCount * ((barWidth * 2) + barSpace + groupSpace) +
        rightPadding;

    // Definimos un ancho mínimo para el container
    double boxWidth = totalContentWidth > 600 ? totalContentWidth : 600;

    // Envolvemos la gráfica en un SingleChildScrollView horizontal para permitir scroll si no cabe
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: boxWidth,
        height: 370,
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Actividad Mensual de Proyectos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 240,
                    child: CustomPaint(
                      painter: BarChartPainter(
                        months: const [
                          'Ene',
                          'Feb',
                          'Mar',
                          'Abr',
                          'May',
                          'Jun',
                          'Jul',
                          'Ago',
                          'Sep',
                          'Oct',
                          'Nov',
                          'Dic',
                        ],
                        started: started,
                        closed: closed,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem(Colors.orange, 'Iniciados'),
                      const SizedBox(width: 20),
                      _buildLegendItem(Colors.cyan, 'Completados'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tableContent() {
    return _isLoadingProjects
        ? const Center(child: CircularProgressIndicator())
        : _projectsErrorMessage != null
        ? Center(
          child: Text(
            _projectsErrorMessage!,
            style: const TextStyle(color: Colors.red),
          ),
        )
        : SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Tabla de Proyectos',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(
                              label: Text(
                                'Nombre',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Estado',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Inicio',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Fin',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            //
                            DataColumn(
                              label: Text(
                                'Acciones',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Eliminar',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                          rows:
                              _projectsFiltered.map((project) {
                                return DataRow(
                                  cells: [
                                    DataCell(Text(project.name)),
                                    DataCell(
                                      Text(project.estado ?? 'Sin estado'),
                                    ),
                                    DataCell(
                                      Text(_formatDate(project.startDate)),
                                    ),
                                    DataCell(
                                      Text(_formatDate(project.endDate)),
                                    ),
                                    //
                                    DataCell(
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) => TableroScreen(
                                                    processName: project.name,
                                                  ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.visibility,
                                          size: 18,
                                        ),
                                        label: const Text(
                                          'Ver Detalles',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue[700],
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 8,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          _confirmDeleteProcess(
                                            context,
                                            project.name,
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.delete,
                                          size: 18,
                                        ),
                                        label: const Text(
                                          'Eliminar',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red[700],
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 8,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
  }

  void _handleCircleTap(Offset localPos) {
    // Estas dimensiones deben coincidir con las del SizedBox en _buildPieChart
    final double widgetSize = 220; // width and height of the SizedBox
    final double strokeWidth = 30.0;
    final double innerRadius =
        (widgetSize / 2) - strokeWidth; // inner boundary of the ring
    final double outerRadius =
        (widgetSize / 2); // outer boundary of the ring (or radius for center)

    final center = Offset(widgetSize / 2, widgetSize / 2);
    final dx = localPos.dx - center.dx;
    final dy = localPos.dy - center.dy;
    final distance = sqrt(dx * dx + dy * dy);

    // Check if the tap is within the drawable ring area
    if (distance < innerRadius || distance > outerRadius) {
      setState(() => selectedCircleSegment = -1);
      return;
    }

    double angle = atan2(dy, dx);
    // Adjust angle to be from 0 to 2*pi, starting from the top (-pi/2)
    // atan2 returns values from -pi to pi. Convert to 0 to 2*pi range.
    if (angle < 0) angle += 2 * pi;
    angle -=
        pi /
        2; // Adjust so 0 is at the top (like CSS/Flutter's 0 angle for arcs)
    if (angle < 0) angle += 2 * pi; // Ensure it stays positive after adjustment

    final segments = [completedPercent, inProgressPercent, pendingPercent];
    double cumulativeAngle = 0; // Cumulative angle for segments

    for (int i = 0; i < segments.length; i++) {
      double segmentSweepAngle = 2 * pi * segments[i];
      if (angle >= cumulativeAngle &&
          angle < (cumulativeAngle + segmentSweepAngle)) {
        setState(() => selectedCircleSegment = i);
        return;
      }
      cumulativeAngle += segmentSweepAngle;
    }
    setState(() => selectedCircleSegment = -1);
  }
}

// --- CLASES CUSTOMPAINTER ---

class MultiSegmentCirclePainter extends CustomPainter {
  final double completedPercent;
  final double inProgressPercent;
  final double pendingPercent;
  final List<Color> colors;
  final int selectedSegment;

  MultiSegmentCirclePainter({
    required this.completedPercent,
    required this.inProgressPercent,
    required this.pendingPercent,
    required this.colors,
    this.selectedSegment = -1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 30.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius =
        (size.width / 2) -
        strokeWidth / 2; // Radius to the center of the stroke

    final backgroundPaint =
        Paint()
          ..color = Colors.grey.shade200
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth;

    // Draw the full background circle
    canvas.drawCircle(center, radius, backgroundPaint);

    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round; // Use round cap for a smoother look

    double startAngle = -pi / 2; // Start from top center (12 o'clock)
    final segments = [completedPercent, inProgressPercent, pendingPercent];

    for (int i = 0; i < segments.length; i++) {
      paint.color = colors[i];
      double sweepAngle = 2 * pi * segments[i];
      paint.strokeWidth =
          (i == selectedSegment) ? strokeWidth + 8 : strokeWidth;

      if (sweepAngle > 0) {
        // Only draw if the segment has a size
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweepAngle,
          false, // Use center is false for an arc (not a pie slice)
          paint,
        );
      }
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant MultiSegmentCirclePainter oldDelegate) {
    return oldDelegate.completedPercent != completedPercent ||
        oldDelegate.inProgressPercent != inProgressPercent ||
        oldDelegate.pendingPercent != pendingPercent ||
        oldDelegate.selectedSegment != selectedSegment;
  }
}

class BarChartPainter extends CustomPainter {
  final List<String> months;
  final List<int> started;
  final List<int> closed;

  BarChartPainter({
    required this.months,
    required this.started,
    required this.closed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double chartHeight = size.height - 80;
    final double leftPadding = 60;
    final double rightPadding = 20;
    final double barWidth = 20;
    final double barSpace = 8; // Space between started and closed bars
    final double groupSpace = 20; // Space between month groups
    final double topPadding = 20;

    final int monthCount = months.length;

    // Calculate max value for Y-axis scaling
    final int maxValue = [...started, ...closed].reduce((a, b) => max(a, b));
    final int yAxisSteps = maxValue > 0 ? (maxValue / 5).ceil() : 1;
    final double stepValue =
        maxValue > 0
            ? (maxValue / yAxisSteps)
            : 1; // Use double for more precise scaling

    final axisPaint =
        Paint()
          ..color = Colors.grey[600]!
          ..strokeWidth = 1.5;

    // Eje Y
    canvas.drawLine(
      Offset(leftPadding, topPadding),
      Offset(leftPadding, topPadding + chartHeight),
      axisPaint,
    );

    // Eje X
    canvas.drawLine(
      Offset(leftPadding, topPadding + chartHeight),
      Offset(size.width - rightPadding, topPadding + chartHeight),
      axisPaint,
    );

    // Líneas guía y etiquetas eje Y
    final textStyle = TextStyle(color: Colors.grey[700], fontSize: 12);
    for (int i = 0; i <= yAxisSteps; i++) {
      final double value = i * stepValue;
      final double y =
          topPadding +
          chartHeight -
          (chartHeight * (value / (yAxisSteps * stepValue)));

      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        Paint()
          ..color = Colors.grey[300]!
          ..strokeWidth = 0.5,
      );

      final textSpan = TextSpan(
        text: value.toInt().toString(),
        style: textStyle,
      ); // Convert to Int for display
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.right,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(leftPadding - 8 - textPainter.width, y - textPainter.height / 2),
      );
    }

    // Dibujar barras
    for (int i = 0; i < monthCount; i++) {
      double groupX =
          leftPadding + i * ((barWidth * 2) + barSpace + groupSpace);

      double startedHeight =
          maxValue == 0
              ? 0
              : chartHeight * (started[i] / (yAxisSteps * stepValue));
      canvas.drawRect(
        Rect.fromLTWH(
          groupX,
          topPadding + chartHeight - startedHeight,
          barWidth,
          startedHeight,
        ),
        Paint()..color = Colors.orange,
      );

      double closedHeight =
          maxValue == 0
              ? 0
              : chartHeight * (closed[i] / (yAxisSteps * stepValue));
      canvas.drawRect(
        Rect.fromLTWH(
          groupX + barWidth + barSpace,
          topPadding + chartHeight - closedHeight,
          barWidth,
          closedHeight,
        ),
        Paint()..color = Colors.cyan[600]!,
      );

      final monthPainter = TextPainter(
        text: TextSpan(text: months[i], style: textStyle),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      monthPainter.paint(
        canvas,
        Offset(
          groupX + barWidth + barSpace / 2 - monthPainter.width / 2,
          topPadding + chartHeight + 5,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant BarChartPainter oldDelegate) {
    // Only repaint if the data lists change (assuming they are new lists when updated)
    return oldDelegate.started != started || oldDelegate.closed != closed;
  }
}

// --- CLASE LOGINSCREEN ---
// Puedes mover esta clase a un archivo separado (e.g., lib/login/login_screen.dart)
// si lo prefieres para una mejor organización.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Pantalla de Login', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
