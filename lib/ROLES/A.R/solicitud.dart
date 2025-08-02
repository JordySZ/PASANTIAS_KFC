import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:login_app/ROLES/A.R/ar.dart';


class SolicitudAperturaScreen extends StatefulWidget {
  const SolicitudAperturaScreen({super.key});

  @override
  State<SolicitudAperturaScreen> createState() => _SolicitudAperturaScreenState();
}

class _SolicitudAperturaScreenState extends State<SolicitudAperturaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreTiendaController = TextEditingController();
  final _direccionController = TextEditingController();
  final _justificacionController = TextEditingController();
  bool _isLoading = false;

  List<PlatformFile> _archivosSeleccionados = [];



 Future<void> _enviarSolicitud() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  const String baseUrl = 'http://localhost:3000';
  final url = Uri.parse('$baseUrl/solicitudes');

  try {
    // Validar campos no vacíos antes de enviar
    final nombreTienda = _nombreTiendaController.text.trim();
    final direccion = _direccionController.text.trim();
    final justificacion = _justificacionController.text.trim();

    if (nombreTienda.isEmpty || direccion.isEmpty || justificacion.isEmpty) {
      throw Exception('Todos los campos son obligatorios');
    }

    final solicitudData = {
      'nombreTienda': nombreTienda,
      'direccion': direccion,
      'justificacion': justificacion,
      'estado': 'pendiente',
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode(solicitudData),
    );

    if (response.statusCode == 201) {
      // Mostrar mensaje y limpiar solo si fue exitoso
      _mostrarMensajeExito();
      _limpiarFormulario();
    } else {
      _mostrarError('Error al enviar: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    _mostrarError('Error: ${e.toString()}');
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}

  Future<void> _seleccionarArchivos() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        setState(() {
          _archivosSeleccionados = result.files;
        });
        _mostrarMensaje('${result.files.length} archivo(s) seleccionado(s)');
      }
    } catch (e) {
      _mostrarError('Error al seleccionar archivos: $e');
    }
  }

  void _limpiarFormulario() {
    _nombreTiendaController.clear();
    _direccionController.clear();
    _justificacionController.clear();
    setState(() => _archivosSeleccionados = []);
    _formKey.currentState?.reset();
  }

  void _mostrarMensajeExito() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Text('Solicitud y documentos enviados exitosamente'),
          ],
        ),
        backgroundColor: Colors.green[800],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: Colors.red[800],
        duration: const Duration(seconds: 5),
      ),
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

  @override
  void dispose() {
    _nombreTiendaController.dispose();
    _direccionController.dispose();
    _justificacionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     appBar: AppBar(
  title: const Text('Nueva Solicitud de Apertura'),
  centerTitle: true,
  backgroundColor: Colors.blue[800],
  leading: BackButton(
    onPressed: () {
      Navigator.maybePop(context).then((value) {
        if (!value) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DashboardAr()),
          );
        }
      });
    },
    color: Colors.white, // Color opcional para el ícono
  ),
  actions: [
    IconButton(
      icon: const Icon(Icons.refresh),
      onPressed: _limpiarFormulario,
      tooltip: 'Limpiar formulario',
    ),
  ],
),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.storefront,
                            size: 60,
                            color: Colors.blue[800],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Complete el formulario',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[800],
                                ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Todos los campos son obligatorios',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  _buildTextField(
                    controller: _nombreTiendaController,
                    label: 'Nombre de la tienda',
                    icon: Icons.store,
                    validator: (value) => value?.isEmpty ?? true 
                        ? 'Ingrese el nombre de la tienda' 
                        : null,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _direccionController,
                    label: 'Dirección completa',
                    icon: Icons.location_on,
                    validator: (value) => value?.isEmpty ?? true 
                        ? 'Ingrese la dirección' 
                        : null,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _justificacionController,
                    label: 'Justificación',
                    icon: Icons.description,
                    maxLines: 4,
                    validator: (value) => value?.isEmpty ?? true 
                        ? 'Ingrese una justificación' 
                        : null,
                  ),
                  const SizedBox(height: 20),
                  _buildUploadSection(),
                  const SizedBox(height: 30),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        prefixIcon: Icon(icon, color: Colors.blue[800]),
        filled: true,
        fillColor: Colors.white,
      ),
      maxLines: maxLines,
      validator: validator,
    );
  }

  Widget _buildUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Documentos adjuntos',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (_archivosSeleccionados.isNotEmpty) ...[
          ..._archivosSeleccionados.map((archivo) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: _getFileIcon(archivo.name),
                  title: Text(
                    archivo.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${(archivo.size / 1024).toStringAsFixed(2)} KB',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() {
                      _archivosSeleccionados.remove(archivo);
                    }),
                  ),
                ),
              )),
          const SizedBox(height: 10),
        ],
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _seleccionarArchivos,
          icon: const Icon(Icons.upload),
          label: const Text('SELECCIONAR DOCUMENTOS'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 15),
            backgroundColor: Colors.blue[800],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Formatos permitidos: PDF, DOC, JPG, PNG',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return const Icon(Icons.picture_as_pdf, color: Colors.red);
      case 'doc':
      case 'docx':
        return const Icon(Icons.description, color: Colors.blue);
      case 'jpg':
      case 'jpeg':
      case 'png':
        return const Icon(Icons.image, color: Colors.green);
      default:
        return const Icon(Icons.insert_drive_file);
    }
  }

  Widget _buildSubmitButton() {
    return Material(
      elevation: 5,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            colors: [
              Colors.blue[800]!,
              Colors.blue[600]!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _enviarSolicitud,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 18),
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 25,
                  width: 25,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.save, color: Colors.white),
                    const SizedBox(width: 10),
                    Text(
                      'ENVIAR SOLICITUD',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}