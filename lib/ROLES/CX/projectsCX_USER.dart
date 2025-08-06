import 'package:flutter/material.dart';
import 'package:login_app/ROLES/CX/cx.dart';
import 'package:login_app/ROLES/CX/cx_user.dart';
import 'package:login_app/ROLES/CX/dsi_screen.dart';
import 'package:login_app/ROLES/Operaciones/cards2.dart';
import 'package:login_app/services/api_service.dart';
import 'package:login_app/super%20usario/cards/cards.dart';
import 'package:login_app/super usario/home_page.dart';
import 'package:login_app/models/process.dart';

class ProjectsTableCX_USERT extends StatefulWidget {
  final List<ProjectCX> projects;
  final ApiService apiService;
  
  final VoidCallback refreshData;
  final ValueNotifier<String?> processStatusNotifier;
  final bool isLoading;
  final String? errorMessage;

  const ProjectsTableCX_USERT({
    super.key,
    required this.projects,
    required this.apiService,
    required this.refreshData,
    required this.processStatusNotifier,
    required this.isLoading,
    this.errorMessage,
  });

  @override
  State<ProjectsTableCX_USERT> createState() => _ProjectsTableState();
}
class AppData {
  // Campos estáticos para almacenar los datos
  static List<ProjectCX>? projects;
  static ApiService? apiService;
  static VoidCallback? refreshData;
  static ValueNotifier<String?>? processStatusNotifier;
  static bool isLoading = false;
  static String? errorMessage;

  // Método para limpiar los datos (opcional)
  static void clear() {
    projects = null;
    apiService = null;
    refreshData = null;
    processStatusNotifier = null;
    isLoading = false;
    errorMessage = null;
  }
}
class _ProjectsTableState extends State<ProjectsTableCX_USERT> {
  final TextEditingController _searchController = TextEditingController();
  List<ProjectCX> _projectsFiltered = [];

  @override
  void initState() {
    super.initState();
    _projectsFiltered = widget.projects;
    _searchController.addListener(_filtrarProyectos);
  }

  @override
  void didUpdateWidget(ProjectsTableCX_USERT oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.projects != oldWidget.projects) {
      _filtrarProyectos();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filtrarProyectos() {
    setState(() {
      _projectsFiltered = widget.projects
          .where((p) => p.name.toLowerCase().contains(_searchController.text.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Colors.red[900]!;
    final Color backgroundColor = Colors.white;
    final Color textColor = Colors.black;
    final Color darkGrey = Colors.grey[700]!;
    final Color mediumGrey = Colors.grey[500]!;
    final Color lightGrey = Colors.grey[200]!;

    return Scaffold(
    appBar: AppBar(
  title: const Text('Tabla de Proyectos'),
  backgroundColor: primaryColor,
  leading: IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => DashboardCx_USERT()),
        (Route<dynamic> route) => false,
      );
    },
  ),
  actions: [
    IconButton(
      icon: const Icon(Icons.refresh),
      onPressed: widget.refreshData,
    ),
  ],
),
      body: widget.isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : widget.errorMessage != null
          ? Center(
              child: Text(
                widget.errorMessage!,
                style: TextStyle(color: primaryColor),
              ),
            )
          : Column(
              children: [
     
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    color: backgroundColor,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Buscar Proyecto',
                          labelStyle: TextStyle(color: darkGrey),
                          prefixIcon: Icon(Icons.search, color: primaryColor),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: mediumGrey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: mediumGrey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: primaryColor,
                              width: 2.0),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
               
                
                // Título y tabla
                 Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Tabla de Proyectos',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        Container(
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: Offset(0, 3),
                              )
                            ],
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: MaterialStateProperty.resolveWith<Color>(
                                (Set<MaterialState> states) => lightGrey,
                              ),
                              columnSpacing: 20,
                              dataRowMinHeight: 60,
                              dataRowMaxHeight: 80,
                              columns: [
                                DataColumn(
                                  label: Text(
                                    'Nombre',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Estado',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Inicio',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Fin',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Acciones',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                             
                               
                              ],
                              rows: _projectsFiltered.map((project) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Container(
                                        constraints: BoxConstraints(maxWidth: 150),
                                        child: Text(
                                          project.name,
                                          style: TextStyle(color: textColor),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(project.estado ?? ''),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          _traducirEstado(project.estado ?? 'Sin estado'),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        _formatStartDate(project.startDate),
                                        style: TextStyle(color: textColor),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        _formatEndDate(project.endDate),
                                        style: TextStyle(color: textColor),
                                      ),
                                    ),
                                    DataCell(
                                      _buildActionButton(
                                        context,
                                        icon: Icons.visibility,
                                        label: 'Detalles',
                                        color: darkGrey,
                                        onPressed: () {
AppData.projects = widget.projects;
AppData.apiService = widget.apiService;
AppData.refreshData = widget.refreshData;
AppData.processStatusNotifier = widget.processStatusNotifier;
AppData.isLoading = widget.isLoading;
AppData.errorMessage = widget.errorMessage;

                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => DSIScreen(
                                                processName: project.name,
                                                
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  
                                   
                                  ],
                                );
                              }).toList(),
                            ),
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

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: Colors.white),
      label: Text(label, style: TextStyle(fontSize: 12, color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completado':
      case 'echo':
        return Colors.green;
      case 'en progreso':
      case 'en proceso':
        return Colors.orange;
      case 'pendiente':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // Métodos de ayuda (mantener los mismos que en tu código original)
  String _traducirEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'echo': return 'Completado';
      case 'en proceso': return 'En progreso';
      case 'pendiente': return 'Pendiente';
      default: return estado;
    }
  }

  String _formatStartDate(String dateString) {
    try {
      final DateTime dateTime = DateTime.parse(dateString);
      return '${dateTime.day.toString().padLeft(2, '0')}/'
             '${dateTime.month.toString().padLeft(2, '0')}/'
             '${dateTime.year}';
    } catch (e) {
      return 'Fecha Inválida';
    }
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

  

  Future<void> _deleteProcess(BuildContext context, String processName) async {
    try {
      final success = await widget.apiService.deleteProcess(processName); // Corregido aquí
      if (success) {
        widget.refreshData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Proceso "$processName" eliminado exitosamente.'),
            backgroundColor: Colors.green[700],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar el proceso "$processName".'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de conexión al eliminar el proceso: $e'),
        ),
      );
    }
  }

  void _showEditProjectDialog(BuildContext context, ProjectCX project) {
    final Color backgroundColor = Colors.white;
    final Color textColor = Colors.black;
    final Color darkGrey = Colors.grey[700]!;
    final Color primaryColor = Colors.red[900]!;
    final Color secondaryColor = Colors.grey[800]!;

    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController(text: project.name);
    final _statusController = TextEditingController(text: project.estado);
    
    final _startDateController = TextEditingController(
      text: project.startDate != 'N/A' ? _formatStartDate(project.startDate) : '',
    );
    final _endDateController = TextEditingController(
      text: project.endDate != 'N/A' ? _formatStartDate(project.endDate) : '',
    );

    showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Editar Proyecto'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Nombre del Proceso'),
                validator: (value) => value?.isEmpty ?? true ? 'Requerido' : null,
              ),
          
      
                ],
             
            ),
          ),
           
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
        
        ],
      );
    },
  );
}

  
  String _parseToIsoDateString(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        ).toIso8601String();
      }
      return DateTime.now().toIso8601String();
    } catch (e) {
      return DateTime.now().toIso8601String();
    }
  }
}