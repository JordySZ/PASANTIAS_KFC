import 'package:flutter/material.dart';
import 'package:login_app/user/procesos/procesos.dart';
import 'dart:math';
import 'package:login_app/user/user.dart';
import 'package:login_app/user/crud_user.dart';
import 'package:login_app/user/custom_drawer.dart';
import 'package:login_app/services/api_service.dart';

import 'package:login_app/models/project.dart';

import 'package:intl/date_symbol_data_local.dart'; // <-- AÑADE ESTA IMPORTACIÓN para soporte de idiomas

class Project {
  final String name;
  final String client;
  final String status;
  final String
  startDate; // Las fechas se siguen guardando como String en este modelo
  final String
  endDate; // Las fechas se siguen guardando como String en este modelo
  final double progress;

  Project({
    required this.name,
    this.client = 'N/A',
    this.status = 'Activo',
    this.startDate = 'N/A',
    this.endDate = 'N/A',
    this.progress = 0.0,
  });
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  final ApiService _apiService = ApiService();
  List<Project> _projects = [];
  bool _isLoadingProjects = true;
  String? _projectsErrorMessage;
  String _formatDate(String dateString) {
    try {
      final DateTime dateTime = DateTime.parse(dateString);
      // Formato DD/MM/YYYY
      return '${dateTime.day.toString().padLeft(2, '0')}/'
          '${dateTime.month.toString().padLeft(2, '0')}/'
          '${dateTime.year.toString()}';
    } catch (e) {
      print('Error al parsear o formatear fecha: $dateString - $e');
      return 'Fecha Inválida'; // O el mensaje que prefieras para errores
    }
  }

  double completedPercent = 0.0;
  double inProgressPercent = 0.0;
  double pendingPercent = 0.0;

  int selectedCircleSegment = -1;
  final List<String> months = [
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
  ];
  final List<int> started = List.filled(12, 0);
  final List<int> closed = List.filled(12, 0);

  int? selectedBarGroup;
  bool? selectedBarIsStarted;

  @override
  void initState() {
    super.initState();
    // Inicializa los datos de símbolos de fecha para español antes de usar DateFormat con locale 'es'
    initializeDateFormatting('es', null).then((_) {
      //
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
                    name: process.name,
                    client: process.client ?? 'N/A',
                    status: process.status ?? 'Activo',
                    startDate: process.startDate.toIso8601String(),
                    endDate: process.endDate.toIso8601String(),
                    progress: process.progress ?? 0.0,
                  ),
                )
                .toList();

        _isLoadingProjects = false;
        _calculateProjectPercentages();
      });
      print('FLUTTER DEBUG DASHBOARD: Proyectos cargados: ${_projects.length}');
    } catch (e) {
      setState(() {
        _projectsErrorMessage = 'Error al cargar los procesos: $e';
        _isLoadingProjects = false;
      });
      print('FLUTTER ERROR DASHBOARD: Excepción al cargar procesos: $e');
    }
  }

  String _getStatus(int hash) {
    if (hash % 3 == 0) return 'Completado';
    if (hash % 3 == 1) return 'Activo';
    return 'Pendiente';
  }

  void _calculateProjectPercentages() {
    if (_projects.isEmpty) {
      completedPercent = 0.0;
      inProgressPercent = 0.0;
      pendingPercent = 0.0;
      return;
    }
    int completedCount =
        _projects.where((p) => p.status == 'Completado').length;
    int inProgressCount = _projects.where((p) => p.status == 'Activo').length;
    int pendingCount = _projects.where((p) => p.status == 'Pendiente').length;

    int total = _projects.length;

    setState(() {
      completedPercent = completedCount / total;
      inProgressPercent = inProgressCount / total;
      pendingPercent = pendingCount / total;
    });
  }

  void _confirmDeleteProcess(BuildContext context, String processName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: Text(
            '¿Estás seguro de que quieres eliminar el proceso "$processName"? Esta acción es **irreversible** y eliminará todos los datos asociados a este proceso (listas y tarjetas).',
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

  void _onItemTapped(int index) {
    Navigator.of(context).pop();
    switch (index) {
      case 0:
        setState(() => _selectedIndex = 0);
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => UsuariosScreen()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProcesosRud()),
        );
        break;
      case 3:
        // Cambia aquí: redirige a TableroScreen sin processName para crear nuevo proceso/tarjeta
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TableroScreen(processName: null),
          ),
        );
        setState(() => _selectedIndex = 0);
        break;
      case 4:
        // También aquí: redirige a TableroScreen sin processName
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
        return ProcesosRud();
      case 3:
        // Cambia aquí: muestra TableroScreen sin processName
        return TableroScreen(processName: null);
      case 4:
        // También aquí: muestra TableroScreen sin processName
        return TableroScreen(processName: null);
      default:
        return const Center(child: Text('Página no encontrada'));
    }
  }

  Widget _homeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const ProjectFiltersWidget(),
          const SizedBox(height: 30),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: GestureDetector(
                        onTapUp: (details) {
                          final RenderBox box =
                              context.findRenderObject() as RenderBox;
                          final Offset localPos = box.globalToLocal(
                            details.globalPosition,
                          );
                          _handleCircleTap(localPos);
                        },
                        child: CustomPaint(
                          painter: MultiSegmentCirclePainter(
                            completedPercent: completedPercent,
                            inProgressPercent: inProgressPercent,
                            pendingPercent: pendingPercent,
                            colors: [Colors.green, Colors.blue, Colors.red],
                            selectedSegment: selectedCircleSegment,
                          ),
                          child: Center(
                            child: Text(
                              '${((completedPercent + inProgressPercent + pendingPercent) * 100).round()}%',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    CustomLegendItem(
                      color: Colors.green,
                      label: 'Completados',
                      percent: completedPercent,
                      isSelected: selectedCircleSegment == 0,
                    ),
                    CustomLegendItem(
                      color: Colors.blue,
                      label: 'En progreso',
                      percent: inProgressPercent,
                      isSelected: selectedCircleSegment == 1,
                    ),
                    CustomLegendItem(
                      color: Colors.red,
                      label: 'Pendientes',
                      percent: pendingPercent,
                      isSelected: selectedCircleSegment == 2,
                    ),
                  ],
                ),
                const SizedBox(width: 60),
                SizedBox(
                  width: 700,
                  height: 300,
                  child: GestureDetector(
                    onTapUp: (details) {
                      final RenderBox box =
                          context.findRenderObject() as RenderBox;
                      final Offset localPos = box.globalToLocal(
                        details.globalPosition,
                      );
                      _handleBarTap(localPos);
                    },
                    child: BarChartWidget(
                      months: months,
                      started: started,
                      closed: closed,
                      selectedGroup: selectedBarGroup,
                      selectedIsStarted: selectedBarIsStarted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          _tableContent(),
        ],
      ),
    );
  }

  Widget _tableContent() {
    // Define el formateador de fecha aquí, dentro de un método que se construya
    // cuando el widget se renderice (o una vez en initState si no cambia)

    // Si quieres el nombre del mes:
    // final DateFormat formatter = DateFormat('dd MMM yyyy', 'es'); // Ejemplo: 10 jul 2025 (asegúrate de que `initializeDateFormatting('es', null)` se ha llamado)

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
                                'Cliente',
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
                            DataColumn(
                              label: Text(
                                'Progreso',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
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
                              _projects.map((project) {
                                return DataRow(
                                  cells: [
                                    DataCell(Text(project.name)),
                                    DataCell(Text(project.client)),
                                    DataCell(Text(project.status)),
                                    // Aquí ya estás usando la función _formatDate
                                    DataCell(
                                      Text(_formatDate(project.startDate)),
                                    ),
                                    DataCell(
                                      Text(_formatDate(project.endDate)),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 100,
                                        child: LinearProgressIndicator(
                                          value: project.progress,
                                          backgroundColor: Colors.grey[300],
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                project.status == 'Completado'
                                                    ? Colors.green
                                                    : project.status == 'Activo'
                                                    ? Colors.blue
                                                    : Colors.red,
                                              ),
                                        ),
                                      ),
                                    ),
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

  Widget _procesosContent() {
    return Container();
  }

  void _handleCircleTap(Offset localPos) {
    final center = Offset(90, 90);
    final dx = localPos.dx - center.dx;
    final dy = localPos.dy - center.dy;
    final distance = sqrt(dx * dx + dy * dy);

    if (distance < 50 || distance > 90) {
      setState(() => selectedCircleSegment = -1);
      return;
    }

    double angle = atan2(dy, dx);
    if (angle < -pi / 2) angle += 2 * pi;
    angle += pi / 2;

    final segments = [completedPercent, inProgressPercent, pendingPercent];
    double cumulative = 0;
    for (int i = 0; i < segments.length; i++) {
      cumulative += segments[i];
      if (angle <= cumulative * 2 * pi) {
        setState(() => selectedCircleSegment = i);
        return;
      }
    }
    setState(() => selectedCircleSegment = -1);
  }

  void _handleBarTap(Offset localPos) {
    const double leftPadding = 40;
    const double barWidth = 16;
    const double groupSpace = 50;
    const double barSpace = 8;
    const double chartHeight = 240;

    final int maxValue = [started, closed].expand((e) => e).fold(0, max);

    for (int i = 0; i < months.length; i++) {
      double x = leftPadding + i * groupSpace + 12;

      Rect startedRect = Rect.fromLTWH(
        x,
        chartHeight +
            20 -
            (maxValue == 0 ? 0 : started[i] / maxValue * chartHeight),
        barWidth,
        maxValue == 0 ? 0 : started[i] / maxValue * chartHeight,
      );

      Rect closedRect = Rect.fromLTWH(
        x + barWidth + barSpace,
        chartHeight +
            20 -
            (maxValue == 0 ? 0 : closed[i] / maxValue * chartHeight),
        barWidth,
        maxValue == 0 ? 0 : closed[i] / maxValue * chartHeight,
      );

      if (startedRect.contains(localPos)) {
        setState(() {
          selectedBarGroup = i;
          selectedBarIsStarted = true;
        });
        return;
      } else if (closedRect.contains(localPos)) {
        setState(() {
          selectedBarGroup = i;
          selectedBarIsStarted = false;
        });
        return;
      }
    }
    setState(() {
      selectedBarGroup = null;
      selectedBarIsStarted = null;
    });
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: Colors.blue[900],
      ),
      body: const Center(
        child: Text('Pantalla de Login', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}

class ProjectFiltersWidget extends StatefulWidget {
  const ProjectFiltersWidget({super.key});

  @override
  State<ProjectFiltersWidget> createState() => _ProjectFiltersWidgetState();
}

class _ProjectFiltersWidgetState extends State<ProjectFiltersWidget> {
  String client = 'Todos los Clientes';
  String project = 'Todos los Proyectos';
  String manager = 'Todos los Gestores de Proyecto';
  String status = 'Todos';
  final searchController = TextEditingController();

  final clients = ['Todos los Clientes', 'Cliente A', 'Cliente B'];
  final projects = ['Todos los Proyectos', 'Proyecto X', 'Proyecto Y'];
  final managers = ['Todos los Gestores de Proyecto', 'Gestor 1', 'Gestor 2'];
  final statuses = ['Todos', 'Activo', 'Completado', 'Pendiente'];
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            _buildFilterRow(
              'Cliente:',
              DropdownButton<String>(
                value: client,
                isDense: true,
                items:
                    clients
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(
                              e,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (v) => setState(() => client = v!),
              ),
            ),
            _buildFilterRow(
              'Proyecto:',
              DropdownButton<String>(
                value: project,
                isDense: true,
                items:
                    projects
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(
                              e,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (v) => setState(() => project = v!),
              ),
            ),
            _buildFilterRow(
              'Gestor de Proyecto:',
              DropdownButton<String>(
                value: manager,
                isDense: true,
                items:
                    managers
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(
                              e,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (v) => setState(() => manager = v!),
              ),
            ),
            _buildFilterRow(
              'Estado:',
              DropdownButton<String>(
                value: status,
                isDense: true,
                items:
                    statuses
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(
                              e,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (v) => setState(() => status = v!),
              ),
            ),
            _buildFilterRow(
              'Buscar Proyecto',
              TextField(
                controller: searchController,
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[850],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    fontSize: 14,
                  ),
                ),
                onPressed: () {},
                child: const Text('MOSTRAR PROYECTOS'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow(String label, Widget input) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            ),
          ),
          Expanded(child: input),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: () {},
            splashRadius: 16,
          ),
        ],
      ),
    );
  }
}

class CustomLegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final double percent;
  final bool isSelected;

  const CustomLegendItem({
    Key? key,
    required this.color,
    required this.label,
    required this.percent,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
          Text(
            '$label: ${(percent * 100).round()}%',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class BarChartWidget extends StatelessWidget {
  final List<String> months;
  final List<int> started;
  final List<int> closed;
  final int? selectedGroup;
  final bool? selectedIsStarted;

  const BarChartWidget({
    Key? key,
    required this.months,
    required this.started,
    required this.closed,
    this.selectedGroup,
    this.selectedIsStarted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: BarChartPainter(
        months: months,
        started: started,
        closed: closed,
        selectedGroup: selectedGroup,
        selectedIsStarted: selectedIsStarted,
      ),
      child: Container(),
    );
  }
}

class BarChartPainter extends CustomPainter {
  final List<String> months;
  final List<int> started;
  final List<int> closed;
  final int? selectedGroup;
  final bool? selectedIsStarted;

  BarChartPainter({
    required this.months,
    required this.started,
    required this.closed,
    this.selectedGroup,
    this.selectedIsStarted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double chartHeight = size.height - 80;
    final double leftPadding = 40;
    final double barWidth = 16;
    final double groupSpace = 50;
    final double barSpace = 8;

    final int maxValue = [started, closed].expand((e) => e).fold(0, max);

    final axisPaint =
        Paint()
          ..color = Colors.grey[700]!
          ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(leftPadding, 20),
      Offset(leftPadding, chartHeight + 20),
      axisPaint,
    );
    canvas.drawLine(
      Offset(leftPadding, chartHeight + 20),
      Offset(size.width - 10, chartHeight + 20),
      axisPaint,
    );

    final textPainter = TextPainter(
      textAlign: TextAlign.right,
      textDirection: TextDirection.ltr,
    );
    for (int i = 0; i <= maxValue; i += 5) {
      textPainter.text = TextSpan(
        text: '$i',
        style: const TextStyle(color: Colors.black54, fontSize: 12),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          leftPadding - 8 - textPainter.width,
          chartHeight +
              20 -
              (i / maxValue) * chartHeight -
              textPainter.height / 2,
        ),
      );
    }
    for (int i = 0; i < months.length; i++) {
      double x = leftPadding + i * groupSpace + 12;

      double startedBarHeight =
          maxValue == 0 ? 0 : started[i] / maxValue * chartHeight;
      final startedRect = Rect.fromLTWH(
        x,
        chartHeight + 20 - startedBarHeight,
        barWidth,
        startedBarHeight,
      );
      final startedPaint = Paint()..color = Colors.orange;
      if (selectedGroup == i && selectedIsStarted == true) {
        startedPaint.color = Colors.orangeAccent;
      }
      canvas.drawRect(startedRect, startedPaint);

      double closedBarHeight =
          maxValue == 0 ? 0 : closed[i] / maxValue * chartHeight;
      final closedRect = Rect.fromLTWH(
        x + barWidth + barSpace,
        chartHeight + 20 - closedBarHeight,
        barWidth,
        closedBarHeight,
      );
      final closedPaint = Paint()..color = Colors.cyan[600]!;
      if (selectedGroup == i && selectedIsStarted == false) {
        closedPaint.color = Colors.cyanAccent;
      }
      canvas.drawRect(closedRect, closedPaint);

      final monthPainter = TextPainter(
        text: TextSpan(
          text: months[i],
          style: const TextStyle(color: Colors.black87, fontSize: 12),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      monthPainter.layout();
      final double groupWidth = barWidth * 2 + barSpace;
      monthPainter.paint(
        canvas,
        Offset(x + groupWidth / 2 - monthPainter.width / 2, chartHeight + 28),
      );
    }

    final legendTextStyle = const TextStyle(fontSize: 14);
    final startedLegend = TextPainter(
      text: TextSpan(
        text: 'Iniciados',
        style: legendTextStyle.copyWith(color: Colors.orange),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final closedLegend = TextPainter(
      text: TextSpan(
        text: 'Cerrados',
        style: legendTextStyle.copyWith(color: Colors.cyan[600]!),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final double legendY = chartHeight + 55;

    canvas.drawRect(
      Rect.fromLTWH(leftPadding + 10, legendY, 18, 10),
      Paint()..color = Colors.orange,
    );
    startedLegend.paint(canvas, Offset(leftPadding + 32, legendY - 2));

    canvas.drawRect(
      Rect.fromLTWH(leftPadding + 110, legendY, 18, 10),
      Paint()..color = Colors.cyan[600]!,
    );
    closedLegend.paint(canvas, Offset(leftPadding + 132, legendY - 2));

    final titlePainter = TextPainter(
      text: const TextSpan(
        text: 'Rotación de Proyectos (últimos 12 meses)',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);
    titlePainter.paint(
      canvas,
      Offset((size.width - titlePainter.width) / 2, -30),
    );
  }

  @override
  bool shouldRepaint(covariant BarChartPainter oldDelegate) {
    return oldDelegate.started != started ||
        oldDelegate.closed != closed ||
        oldDelegate.selectedGroup != selectedGroup ||
        oldDelegate.selectedIsStarted != selectedIsStarted;
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
    final strokeWidth = 20.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth / 2;

    final backgroundPaint =
        Paint()
          ..color = Colors.grey.shade300
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, backgroundPaint);

    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    double startAngle = -pi / 2;

    final segments = [completedPercent, inProgressPercent, pendingPercent];

    for (int i = 0; i < segments.length; i++) {
      paint.color = colors[i];
      double sweepAngle = 2 * pi * segments[i];
      paint.strokeWidth =
          (i == selectedSegment) ? strokeWidth + 5 : strokeWidth;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
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
