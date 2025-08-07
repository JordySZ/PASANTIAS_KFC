import 'package:flutter/material.dart';
import 'dart:math';
import 'package:intl/date_symbol_data_local.dart';



import 'package:login_app/ROLES/custom_user.dart';

import 'package:login_app/ROLES/swt/projectSwt_usert.dart';
import 'package:login_app/super%20usario/cards/cards.dart';

import 'package:login_app/services/api_service.dart';
import 'package:login_app/models/process.dart';
import 'dart:async';


 class  ProjectSwt {
  final String name;
  final String status;
  final String startDate;
  final String endDate;
  final double progress;
  final String? estado;

  ProjectSwt({
    required this.name,
    this.status = 'Activo',
    this.startDate = 'N/A',
    this.endDate = 'N/A',
    this.progress = 0.0,
    this.estado,
  });
}

class DashboardSwt_usert extends StatefulWidget {
  const DashboardSwt_usert({super.key});

  @override
  State<DashboardSwt_usert> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardSwt_usert> {
  final ValueNotifier<String?> processStatusNotifier = ValueNotifier<String?>(null);
  Timer? _completionCheckerTimer;
  List<ProjectSwt> _completedProjectsToNotify = [];
  int _selectedIndex = 0;
  final ApiService _apiService = ApiService();
  List<ProjectSwt> _projects = [];
  List<ProjectSwt> _projectsFiltered = [];
  bool _isLoadingProjects = true;
  String? _projectsErrorMessage;


  double completedPercent = 0.0;
  double inProgressPercent = 0.0;
  double pendingPercent = 0.0;
  int selectedCircleSegment = -1;

  int totalProyectos = 0;

  // Colores empresariales
  final Color primaryColor = Colors.red[900]!;
  final Color secondaryColor = Colors.grey[800]!;
  final Color backgroundColor = Colors.white;
  final Color textColor = Colors.black;
  final Color lightGrey = Colors.grey[300]!;
  final Color mediumGrey = Colors.grey[500]!;
  final Color darkGrey = Colors.grey[700]!;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es', null).then((_) {
      _fetchProjectsData();
    });
    
    processStatusNotifier.addListener(_handleProcessStatusChange);
    _startCompletionChecker();
  }

  @override
  void dispose() {
    processStatusNotifier.removeListener(_handleProcessStatusChange);
    _completionCheckerTimer?.cancel();
    super.dispose();
  }

  void _handleProcessStatusChange() {
    if (!mounted) return;
    
    if (processStatusNotifier.value != null) {
      final nuevoEstado = processStatusNotifier.value!;
      
      if (nuevoEstado.toLowerCase() == 'echo') {
        _mostrarAlertaProcesoCompletado();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estado actualizado: ${_traducirEstado(nuevoEstado)}'),
          backgroundColor: Colors.green[700],
          duration: Duration(seconds: 3),
        ),
      );

      _fetchProjectsData();
      processStatusNotifier.value = null;
    }
  }

  void _mostrarAlertaProcesoCompletado() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('¡Proceso Completado!'),
          content: Text('Un proceso ha alcanzado su hora de finalización.'),
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

  void _startCompletionChecker() {
    _completionCheckerTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (!mounted) return;
      
      final now = DateTime.now().toLocal();
      final completedProjects = _projects.where((project) {
        try {
          final endDate = DateTime.parse(project.endDate).toLocal();
          return (now.isAfter(endDate) || now.isAtSameMomentAs(endDate)) && 
                 project.estado?.toLowerCase() != 'echo';
        } catch (e) {
          return false;
        }
      }).toList();

      if (completedProjects.isNotEmpty) {
        setState(() {
          _completedProjectsToNotify = completedProjects;
        });
        _showCompletionAlert();
      }
    });
  }

  Future<void> _updateProjectsStatus() async {
    for (final project in _completedProjectsToNotify) {
      try {
        final updated = await _apiService.updateProcess(
          project.name,
          Process(
            nombre_proceso: project.name,
            startDate: DateTime.parse(project.startDate),
            endDate: DateTime.parse(project.endDate),
            estado: 'echo',
            progress: 1.0,
          ),
        );
        
        if (updated != null) {
          setState(() {
            final index = _projects.indexWhere((p) => p.name == project.name);
            if (index != -1) {
              _projects[index] = ProjectSwt(
                name: project.name,
                startDate: project.startDate,
                endDate: project.endDate,
                estado: 'echo',
                progress: 1.0,
              );
            }
          });
        }
      } catch (e) {
        print('Error al actualizar el estado del proyecto: $e');
      }
    }
    
    setState(() {
      _completedProjectsToNotify = [];
    });
    _fetchProjectsData();
  }

  void _showCompletionAlert() {
    if (_completedProjectsToNotify.isEmpty || !mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text(_completedProjectsToNotify.length == 1 
              ? '¡Proceso completado!'
              : '¡Procesos completados!'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _completedProjectsToNotify.map((project) {
                return ListTile(
                  title: Text(project.name),
                  subtitle: Text('Finalizó: ${_formatEndDate(project.endDate)}'),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _updateProjectsStatus();
                Navigator.pop(context);
              },
              child: Text('Aceptar'),
            ),
          ],
        ),
      );
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
        _projects = fetchedProcesses.map((process) => ProjectSwt(
          name: process.nombre_proceso,
          startDate: process.startDate.toIso8601String(),
          endDate: process.endDate.toIso8601String(),
          progress: process.progress ?? 0.0,
          estado: process.estado,
        )).toList();
        _projectsFiltered = _projects;
        _isLoadingProjects = false;
        _calculateProjectPercentages();
      });
      
      _completionCheckerTimer?.cancel();
      _startCompletionChecker();
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

    int completedCount = _projects.where((p) => (p.estado?.toLowerCase() ?? '') == 'echo').length;
    int inProgressCount = _projects.where((p) => (p.estado?.toLowerCase() ?? '') == 'en proceso').length;
    int pendingCount = _projects.where((p) => (p.estado?.toLowerCase() ?? '') == 'pendiente').length;

    int otherCount = _projects.length - completedCount - inProgressCount - pendingCount;
    pendingCount += otherCount;

    int total = _projects.length;

    setState(() {
      completedPercent = completedCount / total;
      inProgressPercent = inProgressCount / total;
      pendingPercent = pendingCount / total;
      totalProyectos = total;
    });
  }

  

  String _formatEndDate(String dateString) {
    try {
      final DateTime dateTime = DateTime.parse(dateString).toLocal();
      return '${dateTime.day.toString().padLeft(2, '0')}/'
             '${dateTime.month.toString().padLeft(2, '0')}/'
             '${dateTime.year} '
             '(${dateTime.hour.toString().padLeft(2, '0')}:'
             '${dateTime.minute.toString().padLeft(2, '0')})';
    } catch (e) {
      return 'Fecha Inválida';
    }
  }

  void _onItemTapped(int index) {
    Navigator.of(context).pop();
    switch (index) {
      case 0:
        setState(() => _selectedIndex = 0);
        break;
  
     

      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProjectsSwt_usert(
              projects: _projectsFiltered,
              apiService: _apiService,
              refreshData: _fetchProjectsData,
              processStatusNotifier: processStatusNotifier,
              isLoading: _isLoadingProjects,
              errorMessage: _projectsErrorMessage,
            ),
          ),
        );
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TableroScreen(processName: null),
          ),
        );
        break;
      case 5:
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
          backgroundColor: backgroundColor,
          title: Text('Cerrar Sesión', style: TextStyle(color: primaryColor)),
          content: Text('¿Estás seguro de que quieres cerrar sesión?', style: TextStyle(color: darkGrey)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar', style: TextStyle(color: secondaryColor)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: backgroundColor,
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
        title: Text(_getTitle(_selectedIndex), style: TextStyle(color: backgroundColor)),
        backgroundColor: primaryColor,
        foregroundColor: backgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: backgroundColor),
            onPressed: _fetchProjectsData,
          ),
        ],
      ),
      drawer: Custom_user(
        selectedIndex: _selectedIndex,
        onItemTap: _onItemTapped,
      ),
      body: _buildPageContent(_selectedIndex),
    );
  }

  String _getTitle(int index) {
    switch (index) {
      case 0: return 'SWT (USER)';
      case 1: return 'Tablero de Proyectos';
      default: return 'Dashboard';
    }
  }

  Widget _buildPageContent(int index) {
    switch (index) {
      case 0: return _homeContent();
      case 1: return ProjectsSwt_usert(
        projects: _projectsFiltered,
        apiService: _apiService,
        refreshData: _fetchProjectsData,
        processStatusNotifier: processStatusNotifier,
        isLoading: _isLoadingProjects,
        errorMessage: _projectsErrorMessage,
      );



      default: return Center(child: Text('Página no encontrada', style: TextStyle(color: textColor)));
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
              const SizedBox(height: 30),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 800) {
                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPieChart(),
                            const SizedBox(width: 40),
                            _buildBarChart(constraints),
                          ],
                        ),
                        const SizedBox(height: 40),
                        _buildLineChart(constraints),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        _buildPieChart(),
                        const SizedBox(height: 40),
                        _buildBarChart(constraints),
                        const SizedBox(height: 40),
                        _buildLineChart(constraints),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 30),
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
                colors: [Colors.green[700]!, primaryColor, mediumGrey],
                selectedSegment: selectedCircleSegment,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$totalProyectos',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Text(
                      'Proyectos',
                      style: TextStyle(fontSize: 16, color: mediumGrey),
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
          Colors.green[700]!,
          'Completado: ${(completedPercent * 100).toStringAsFixed(1)}%',
          isSelected: selectedCircleSegment == 0,
        ),
        _buildLegendItem(
          primaryColor,
          'En progreso: ${(inProgressPercent * 100).toStringAsFixed(1)}%',
          isSelected: selectedCircleSegment == 1,
        ),
        _buildLegendItem(
          mediumGrey,
          'Pendiente: ${(pendingPercent * 100).toStringAsFixed(1)}%',
          isSelected: selectedCircleSegment == 2,
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String text, {bool isSelected = false}) {
    return Container(
      decoration: isSelected
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
          Text(text, style: TextStyle(fontSize: 16, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildBarChart(BoxConstraints constraints) {
    List<int> started = List.filled(12, 0);
    List<int> closed = List.filled(12, 0);

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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 800,
        height: 370,
        child: Card(
          elevation: 4,
          color: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Actividad Mensual de Proyectos',
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold,
                      color: textColor
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 240,
                    child: CustomPaint(
                      painter: BarChartPainter(
                        months: const [
                          'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
                          'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
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
                      _buildLegendItem(primaryColor, 'Iniciados'),
                      const SizedBox(width: 20),
                      _buildLegendItem(darkGrey, 'Completados'),
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

  Widget _buildLineChart(BoxConstraints constraints) {
    List<int> started = List.filled(12, 0);
    List<int> closed = List.filled(12, 0);

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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 800,
        height: 370,
        child: Card(
          elevation: 4,
          color: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Tendencia Mensual de Proyectos',
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold,
                      color: textColor
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 240,
                    child: CustomPaint(
                      painter: LineChartPainter(
                        months: const [
                          'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
                          'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
                        ],
                        started: started,
                        closed: closed,
                        startedColor: primaryColor,
                        closedColor: darkGrey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem(primaryColor, 'Iniciados'),
                      const SizedBox(width: 20),
                      _buildLegendItem(darkGrey, 'Completados'),
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

  String _traducirEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'echo': return 'Completado';
      case 'en proceso': return 'En progreso';
      case 'pendiente': return 'Pendiente';
      default: return estado;
    }
  }

  void _handleCircleTap(Offset localPos) {
    final double widgetSize = 220;
    final double strokeWidth = 30.0;
    final double innerRadius = (widgetSize / 2) - strokeWidth;
    final double outerRadius = (widgetSize / 2);

    final center = Offset(widgetSize / 2, widgetSize / 2);
    final dx = localPos.dx - center.dx;
    final dy = localPos.dy - center.dy;
    final distance = sqrt(dx * dx + dy * dy);

    if (distance < innerRadius || distance > outerRadius) {
      setState(() => selectedCircleSegment = -1);
      return;
    }

    double angle = atan2(dy, dx);
    if (angle < 0) angle += 2 * pi;
    angle -= pi / 2;
    if (angle < 0) angle += 2 * pi;

    final segments = [completedPercent, inProgressPercent, pendingPercent];
    double cumulativeAngle = 0;

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
    final radius = (size.width / 2) - strokeWidth / 2;

    final backgroundPaint = Paint()
      ..color = Colors.grey[200]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, backgroundPaint);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    double startAngle = -pi / 2;
    final segments = [completedPercent, inProgressPercent, pendingPercent];

    for (int i = 0; i < segments.length; i++) {
      paint.color = colors[i];
      double sweepAngle = 2 * pi * segments[i];
      paint.strokeWidth = (i == selectedSegment) ? strokeWidth + 8 : strokeWidth;

      if (sweepAngle > 0) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sweepAngle,
          false,
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
    final double barSpace = 8;
    final double groupSpace = 20;
    final double topPadding = 20;

    final int monthCount = months.length;
    final int maxValue = [...started, ...closed].reduce((a, b) => max(a, b));
    final int yAxisSteps = maxValue > 0 ? (maxValue / 5).ceil() : 1;
    final double stepValue = maxValue > 0 ? (maxValue / yAxisSteps) : 1;

    final axisPaint = Paint()
      ..color = Colors.grey[600]!
      ..strokeWidth = 1.5;

    canvas.drawLine(
      Offset(leftPadding, topPadding),
      Offset(leftPadding, topPadding + chartHeight),
      axisPaint,
    );

    canvas.drawLine(
      Offset(leftPadding, topPadding + chartHeight),
      Offset(size.width - rightPadding, topPadding + chartHeight),
      axisPaint,
    );

    final textStyle = TextStyle(color: Colors.grey[700], fontSize: 12);
    for (int i = 0; i <= yAxisSteps; i++) {
      final double value = i * stepValue;
      final double y = topPadding + chartHeight - (chartHeight * (value / (yAxisSteps * stepValue)));

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
      );
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

    for (int i = 0; i < monthCount; i++) {
      double groupX = leftPadding + i * ((barWidth * 2) + barSpace + groupSpace);

      double startedHeight = maxValue == 0 ? 0 : chartHeight * (started[i] / (yAxisSteps * stepValue));
      canvas.drawRect(
        Rect.fromLTWH(
          groupX,
          topPadding + chartHeight - startedHeight,
          barWidth,
          startedHeight,
        ),
        Paint()..color = Colors.red[900]!,
      );

      double closedHeight = maxValue == 0 ? 0 : chartHeight * (closed[i] / (yAxisSteps * stepValue));
      canvas.drawRect(
        Rect.fromLTWH(
          groupX + barWidth + barSpace,
          topPadding + chartHeight - closedHeight,
          barWidth,
          closedHeight,
        ),
        Paint()..color = Colors.grey[800]!,
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
    return oldDelegate.started != started || oldDelegate.closed != closed;
  }
}

class LineChartPainter extends CustomPainter {
  final List<String> months;
  final List<int> started;
  final List<int> closed;
  final Color startedColor;
  final Color closedColor;

  LineChartPainter({
    required this.months,
    required this.started,
    required this.closed,
    this.startedColor = Colors.red,
    this.closedColor = Colors.grey,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double chartHeight = size.height - 80;
    final double leftPadding = 60;
    final double rightPadding = 20;
    final double topPadding = 20;

    
    final int maxValue = [...started, ...closed].reduce((a, b) => max(a, b));
    final int yAxisSteps = maxValue > 0 ? (maxValue / 5).ceil() : 1;
    final double stepValue = maxValue > 0 ? (maxValue / yAxisSteps) : 1;

    // Draw axes
    final axisPaint = Paint()
      ..color = Colors.grey[600]!
      ..strokeWidth = 1.5;

    canvas.drawLine(
      Offset(leftPadding, topPadding),
      Offset(leftPadding, topPadding + chartHeight),
      axisPaint,
    );

    canvas.drawLine(
      Offset(leftPadding, topPadding + chartHeight),
      Offset(size.width - rightPadding, topPadding + chartHeight),
      axisPaint,
    );

    // Draw Y-axis labels
    final textStyle = TextStyle(color: Colors.grey[700], fontSize: 12);
    for (int i = 0; i <= yAxisSteps; i++) {
      final double value = i * stepValue;
      final double y = topPadding + chartHeight - (chartHeight * (value / (yAxisSteps * stepValue)));

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
      );
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

    // Calculate x positions for each month
    final double availableWidth = size.width - leftPadding - rightPadding;
    final double monthSpacing = availableWidth / (months.length - 1);
    
    // Draw started projects line
    final startedPoints = <Offset>[];
    for (int i = 0; i < months.length; i++) {
      double x = leftPadding + (i * monthSpacing);
      double y = topPadding + chartHeight - 
          (started[i] / (yAxisSteps * stepValue)) * chartHeight;
      startedPoints.add(Offset(x, y));
    }
    
    final startedPaint = Paint()
      ..color = startedColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    
    // Draw the line
    for (int i = 0; i < startedPoints.length - 1; i++) {
      canvas.drawLine(startedPoints[i], startedPoints[i+1], startedPaint);
    }
    
    // Draw points
    final pointPaint = Paint()
      ..color = startedColor
      ..style = PaintingStyle.fill;
    
    for (final point in startedPoints) {
      canvas.drawCircle(point, 4, pointPaint);
    }
    
    // Draw closed projects line
    final closedPoints = <Offset>[];
    for (int i = 0; i < months.length; i++) {
      double x = leftPadding + (i * monthSpacing);
      double y = topPadding + chartHeight - 
          (closed[i] / (yAxisSteps * stepValue)) * chartHeight;
      closedPoints.add(Offset(x, y));
    }
    
    final closedPaint = Paint()
      ..color = closedColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    
    // Draw the line
    for (int i = 0; i < closedPoints.length - 1; i++) {
      canvas.drawLine(closedPoints[i], closedPoints[i+1], closedPaint);
    }
    
    // Draw points
    for (final point in closedPoints) {
      canvas.drawCircle(point, 4, pointPaint..color = closedColor);
    }

    // Draw month labels
    for (int i = 0; i < months.length; i++) {
      final monthPainter = TextPainter(
        text: TextSpan(text: months[i], style: textStyle),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      monthPainter.paint(
        canvas,
        Offset(
          leftPadding + (i * monthSpacing) - monthPainter.width / 2,
          topPadding + chartHeight + 5,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) {
    return oldDelegate.started != started || oldDelegate.closed != closed;
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red[900],
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Pantalla de Login', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}