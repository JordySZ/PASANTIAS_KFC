import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';

import 'dart:html' as html; // Solo para web
import 'package:flutter/foundation.dart' show kIsWeb;

class SolicitudesAdminScreen extends StatefulWidget {
  const SolicitudesAdminScreen({super.key});

  @override
  State<SolicitudesAdminScreen> createState() => _SolicitudesAdminScreenState();
}

class _SolicitudesAdminScreenState extends State<SolicitudesAdminScreen> {
  List<dynamic> _solicitudes = [];
  List<dynamic> _solicitudesFiltradas = [];
  bool _isLoading = true;
  final String _baseUrl = 'http://localhost:3000';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarSolicitudes();
    _searchController.addListener(_filtrarSolicitudes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filtrarSolicitudes() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _solicitudesFiltradas = List.from(_solicitudes);
      });
    } else {
      setState(() {
        _solicitudesFiltradas = _solicitudes.where((solicitud) {
          final nombreTienda = solicitud['nombreTienda']?.toString().toLowerCase() ?? '';
          return nombreTienda.contains(query);
        }).toList();
      });
    }
  }

  Future<void> _eliminarSolicitud(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/solicitudes/$id'),
      );

      if (response.statusCode == 200) {
        _mostrarMensaje('Solicitud eliminada correctamente');
        _cargarSolicitudes(); // Recargar la lista
      } else {
        _mostrarError('Error al eliminar: ${response.statusCode}');
      }
    } catch (e) {
      _mostrarError('Error: ${e.toString()}');
    }
  }

  Future<void> _descargarArchivo(Map<String, dynamic> solicitud) async {
    try {
      if (solicitud['archivo'] == null || solicitud['archivo']['data'] == null) {
        _mostrarError('No hay archivo adjunto para descargar');
        return;
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/solicitudes/${solicitud['_id']}/archivo'),
        headers: {'Accept': 'application/octet-stream'},
      );

      if (response.statusCode == 200) {
        final nombreArchivo = solicitud['archivo']['nombreOriginal'] ?? 
            'documento_${solicitud['_id'].toString().substring(0, 6)}';
        final extension = _obtenerExtension(solicitud['archivo']['contentType']);

        if (kIsWeb) {
          final bytes = response.bodyBytes;
          final blob = html.Blob([bytes]);
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: url)
            ..setAttribute('download', nombreArchivo + extension)
            ..click();
          html.Url.revokeObjectUrl(url);
          _mostrarMensaje('Descarga iniciada: $nombreArchivo$extension');
        } else {
          Directory directory;
          try {
            directory = await getApplicationDocumentsDirectory();
          } catch (e) {
            directory = await getTemporaryDirectory();
          }

          final filePath = '${directory.path}/$nombreArchivo$extension';
          final file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);

          _mostrarMensaje('Archivo descargado en: $filePath');
          
          if (await file.exists()) {
            OpenFile.open(filePath);
          }
        }
      } else {
        _mostrarError('Error al descargar el archivo: ${response.statusCode}');
      }
    } catch (e) {
      _mostrarError('Error al descargar: ${e.toString()}');
    }
  }

  String _obtenerExtension(String contentType) {
    switch (contentType.toLowerCase()) {
      case 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet':
        return '.xlsx';
      case 'application/vnd.ms-excel':
        return '.xls';
      case 'application/pdf':
        return '.pdf';
      case 'application/msword':
        return '.doc';
      case 'application/vnd.openxmlformats-officedocument.wordprocessingml.document':
        return '.docx';
      case 'image/jpeg':
        return '.jpg';
      case 'image/png':
        return '.png';
      default:
        return '.bin';
    }
  }

  Future<void> _cargarSolicitudes() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('$_baseUrl/solicitudes'));
      
      if (response.statusCode == 200) {
        setState(() {
          _solicitudes = jsonDecode(response.body);
          _solicitudesFiltradas = List.from(_solicitudes);
        });
      } else {
        _mostrarError('Error al cargar solicitudes: ${response.statusCode}');
      }
    } catch (e) {
      _mostrarError('Error de conexión: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _actualizarEstado(String id, String nuevoEstado) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/solicitudes/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'estado': nuevoEstado}),
      );

      if (response.statusCode == 200) {
        _mostrarMensaje('Estado actualizado correctamente');
        _cargarSolicitudes(); // Recargar la lista
      } else {
        _mostrarError('Error al actualizar: ${response.statusCode}');
      }
    } catch (e) {
      _mostrarError('Error: ${e.toString()}');
    }
  }

  void _mostrarDetallesSolicitud(Map<String, dynamic> solicitud) {
    String? estadoSeleccionado = solicitud['estado'];
    bool editando = false;
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Solicitud #${solicitud['_id'].toString().substring(0, 6)}'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildInfoRow('Tienda:', solicitud['nombreTienda'] ?? 'No especificado'),
                    const SizedBox(height: 10),
                    _buildInfoRow('Dirección:', solicitud['direccion'] ?? 'No especificado'),
                    const SizedBox(height: 10),
                    _buildInfoRow('Justificación:', solicitud['justificacion'] ?? 'No especificado'),
                    const SizedBox(height: 20),
                    
                    if (solicitud['archivo'] != null) ...[
                      const Text('Archivo adjunto:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ListTile(
                        leading: _buildIconoArchivo(solicitud['archivo']['contentType']),
                        title: Text(
                          solicitud['archivo']['nombreOriginal'] ?? 'Documento adjunto',
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          solicitud['archivo']['contentType'] ?? 'Tipo desconocido',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.download, color: Colors.blue),
                          onPressed: () => _descargarArchivo(solicitud),
                          tooltip: 'Descargar archivo',
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    
                    if (editando) ...[
                      const Text('Estado:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: estadoSeleccionado,
                        items: ['pendiente', 'aprobada', 'rechazada']
                            .map((estado) => DropdownMenuItem(
                                  value: estado,
                                  child: Text(estado.toUpperCase()),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() => estadoSeleccionado = value),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ] else ...[
                      _buildInfoRow('Estado:', ''),
                      const SizedBox(height: 5),
                      _buildEstadoChip(solicitud['estado'] ?? 'pendiente'),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
              actions: [
                if (editando) ...[
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (estadoSeleccionado != null && 
                          estadoSeleccionado != solicitud['estado']) {
                        Navigator.pop(context);
                        await _actualizarEstado(solicitud['_id'], estadoSeleccionado!);
                      } else {
                        Navigator.pop(context);
                        _mostrarMensaje('No se realizaron cambios');
                      }
                    },
                    child: const Text('Guardar cambios'),
                  ),
                ] else ...[
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => setState(() => editando = true),
                    tooltip: 'Editar estado',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      final confirmado = await _mostrarConfirmacionEliminar();
                      if (confirmado == true) {
                        Navigator.pop(context);
                        await _eliminarSolicitud(solicitud['_id']);
                      }
                    },
                    tooltip: 'Eliminar solicitud',
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Future<bool?> _mostrarConfirmacionEliminar() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de que deseas eliminar esta solicitud? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildIconoArchivo(String? contentType) {
    IconData icon;
    Color color;
    
    if (contentType == null) {
      icon = Icons.insert_drive_file;
      color = Colors.grey;
    } else if (contentType.contains('pdf')) {
      icon = Icons.picture_as_pdf;
      color = Colors.red;
    } else if (contentType.contains('word') || contentType.contains('document')) {
      icon = Icons.description;
      color = Colors.blue;
    } else if (contentType.contains('image')) {
      icon = Icons.image;
      color = Colors.green;
    } else {
      icon = Icons.insert_drive_file;
      color = Colors.orange;
    }
    
    return Icon(icon, color: color, size: 40);
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

   Widget _buildEstadoChip(String estado) {
    Color backgroundColor;
    Color textColor;
    
    switch (estado.toLowerCase()) {
      case 'aprobada':
        backgroundColor = Colors.green[800]!;
        textColor = Colors.white;
        break;
      case 'rechazada':
        backgroundColor = Colors.red[800]!;
        textColor = Colors.white;
        break;
      case 'en revisión':
        backgroundColor = Colors.orange[800]!;
        textColor = Colors.white;
        break;
      default: // pendiente
        backgroundColor = Colors.blue[800]!;
        textColor = Colors.white;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        estado.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }


    @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ADMINISTRACIÓN DE SOLICITUDES', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 10,
          backgroundColor: Colors.red, // Cambio principal aquí
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 28),
            onPressed: _cargarSolicitudes,
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Buscar por nombre de tienda',
                    prefixIcon: const Icon(Icons.search, size: 28),
                    border: InputBorder.none,
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 24),
                            onPressed: () {
                              _searchController.clear();
                              _filtrarSolicitudes();
                            },
                          )
                        : null,
                  ),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 3))
                : _solicitudesFiltradas.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No se encontraron solicitudes',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width * 0.95,
                                child: DataTable(
  dividerThickness: 2,
  dataRowHeight: 60,
  headingRowHeight: 60,
  horizontalMargin: 24,
  columnSpacing: 40,
  columns: [
    DataColumn(
      label: _HeaderCell('ID'),
   
    ),
    DataColumn(
      label: _HeaderCell('TIENDA'),
    ),
    DataColumn(
      label: _HeaderCell('DIRECCIÓN'),
    ),
    DataColumn(
      label: _HeaderCell('ESTADO'),
 
    ),
    DataColumn(
      label: _HeaderCell('DETALLES'),
      numeric: true, // Centra los iconos
    ),
    DataColumn(
      label: _HeaderCell('ELIMINAR'),
      numeric: true, // Centra los iconos
    ),
  ],
  rows: _solicitudesFiltradas.map((solicitud) {
    return DataRow(
      cells: [
        DataCell(
          Container(
            width: 100, // Ancho fijo para ID
            alignment: Alignment.centerRight, // Alineación derecha
            child: Text(
              '${solicitud['_id'].toString().substring(0, 6)}...',
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          Container(
            width: 180, // Ancho fijo para Tienda
            alignment: Alignment.centerLeft,
            child: Text(
              solicitud['nombreTienda'] ?? 'Sin nombre',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ),
        DataCell(
          Container(
            width: 250, // Ancho fijo para Dirección
            alignment: Alignment.centerLeft,
            child: Text(
              solicitud['direccion'] ?? 'Sin dirección',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          Container(
            width: 120, // Ancho fijo para Estado
            alignment: Alignment.center,
            child: _buildEstadoChip(solicitud['estado'] ?? 'pendiente'),
          ),
        ),
        DataCell(
          Container(
            width: 80, // Ancho fijo para Detalles
            alignment: Alignment.center,
            child: IconButton(
              icon: const Icon(Icons.remove_red_eye, size: 28),
              color: Colors.blue[600],
              onPressed: () => _mostrarDetallesSolicitud(solicitud),
            ),
          ),
        ),
        DataCell(
          Container(
            width: 80, // Ancho fijo para Eliminar
            alignment: Alignment.center,
            child: IconButton(
              icon: const Icon(Icons.delete_forever, size: 28),
              color: Colors.red[600],
              onPressed: () async {
                final confirmado = await _mostrarConfirmacionEliminar();
                if (confirmado == true) {
                  await _eliminarSolicitud(solicitud['_id']);
                }
              },
            ),
          ),
        ),
      ],
    );
  }).toList(),

                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }


}
class _HeaderCell extends StatelessWidget {
  final String text;
  final bool numeric;
  
  const _HeaderCell(this.text, {this.numeric = false});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: numeric ? 120 : null, // Ancho fijo para encabezados numéricos
      alignment: numeric ? Alignment.center : Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.white 
              : Colors.blue[800],
        ),
      ),
    );
  }
}
  