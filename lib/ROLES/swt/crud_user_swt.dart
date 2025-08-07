// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:login_app/ROLES/custom.dart';
import 'package:login_app/ROLES/swt/projectSwt.dart';
import 'package:login_app/ROLES/swt/sw.dart';
import 'package:login_app/models/process.dart';
import 'package:login_app/services/api_service.dart';
import 'dart:convert';
import 'dart:async';


class UsuariosScreenSWT_USERT extends StatefulWidget {
  @override
  _UsuariosScreenState createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreenSWT_USERT> {
  // Colores empresariales
  final Color primaryColor = Colors.red[900]!;
  final Color secondaryColor = Colors.grey[800]!;
  final Color backgroundColor = Colors.white;
  final Color textColor = Colors.black;
  final Color lightGrey = Colors.grey[300]!;
  final Color mediumGrey = Colors.grey[500]!;
  final Color darkGrey = Colors.grey[700]!;

  List<dynamic> usuarios = [];
  List<dynamic> usuariosFiltrados = [];
  bool isLoading = true;
  String? errorMessage;

  final String baseUrl = 'http://localhost:3000';
  final TextEditingController _searchController = TextEditingController();

  bool buscarPorNombre = true;
  bool buscarPorApellido = false;
  bool buscarPorCorreo = false;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    fetchUsuarios();
      _fetchProjectsData(); // Añade esto
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _filtrarUsuarios);
  }

  Future<void> fetchUsuarios() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/usuarios'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        // Filtrar solo usuarios con rol SWT_USER
        final usuariosSWT_USER = data.where((usuario) => usuario['rol'] == 'SWT_USER').toList();

        setState(() {
          usuarios = usuariosSWT_USER.reversed.toList();
          usuariosFiltrados = usuarios.take(5).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Error en el servidor: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error de conexión: $e';
        isLoading = false;
      });
    }
  }

  void _filtrarUsuarios() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        usuariosFiltrados = usuarios.take(5).toList();
      } else {
        usuariosFiltrados = usuarios.where((usuario) {
          final nombre = (usuario['nombre'] ?? '').toString().toLowerCase();
          final apellido = (usuario['apellido'] ?? '').toString().toLowerCase();
          final correo = (usuario['correo'] ?? '').toString().toLowerCase();
          final nombreCompleto = '$nombre $apellido';

          bool coincidencia = false;
          if (!buscarPorNombre && !buscarPorApellido && !buscarPorCorreo) {
            coincidencia = nombre.contains(query);
          } else {
            if (buscarPorNombre && buscarPorApellido) {
              coincidencia = nombreCompleto.contains(query);
            } else {
              if (buscarPorNombre) coincidencia |= nombre.contains(query);
              if (buscarPorApellido) coincidencia |= apellido.contains(query);
            }
            if (buscarPorCorreo) coincidencia |= correo.contains(query);
          }

          return coincidencia;
        }).toList();
      }
    });
  }

  void _mostrarPanelFiltros() {
    showModalBottomSheet(
      context: context,
      backgroundColor: backgroundColor,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Wrap(
                children: [
                  Text(
                    'Filtros de búsqueda',
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold,
                      color: textColor
                    ),
                  ),
                  CheckboxListTile(
                    activeColor: primaryColor,
                    title: Text('Nombre', style: TextStyle(color: textColor)),
                    value: buscarPorNombre,
                    onChanged: (val) {
                      setModalState(() {
                        buscarPorNombre = val ?? false;
                      });
                      _filtrarUsuarios();
                    },
                  ),
                  CheckboxListTile(
                    activeColor: primaryColor,
                    title: Text('Apellido', style: TextStyle(color: textColor)),
                    value: buscarPorApellido,
                    onChanged: (val) {
                      setModalState(() {
                        buscarPorApellido = val ?? false;
                      });
                      _filtrarUsuarios();
                    },
                  ),
                  CheckboxListTile(
                    activeColor: primaryColor,
                    title: Text('Correo', style: TextStyle(color: textColor)),
                    value: buscarPorCorreo,
                    onChanged: (val) {
                      setModalState(() {
                        buscarPorCorreo = val ?? false;
                      });
                      _filtrarUsuarios();
                    },
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      minimumSize: Size(double.infinity, 50),
                    ),
                    child: Text('Cerrar', style: TextStyle(color: backgroundColor)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _mostrarFormularioAgregarUsuario() {
    final nombreController = TextEditingController();
    final apellidoController = TextEditingController();
    final correoController = TextEditingController();
    final contrasenaController = TextEditingController();
    final confirmarContrasenaController = TextEditingController();
    bool verContrasena = false;
    bool verConfirmacion = false;

    // Solo permitir rol SWT_USER
    String rolSeleccionado = 'SWT_USER';
    String? ciudadSeleccionada;
    String? areaSeleccionada;

    // Listas de selección
    final ciudades = ['Quito', 'Calderón', 'Tumbaco', 'Pomasqui', 'Centro Historico'];
    final areas = ['Ventas', 'Marketing', 'TI', 'Recursos Humanos', 'Operaciones'];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: backgroundColor,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Agregar Usuario SWT_USER',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: nombreController,
                          decoration: InputDecoration(
                            labelText: 'Nombre',
                            labelStyle: TextStyle(color: darkGrey),
                            prefixIcon: Icon(Icons.person, color: textColor),
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: primaryColor),
                            ),
                            filled: true,
                            fillColor: backgroundColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: apellidoController,
                          decoration: InputDecoration(
                            labelText: 'Apellido',
                            labelStyle: TextStyle(color: darkGrey),
                            prefixIcon: Icon(Icons.person_outline, color: textColor),
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: primaryColor),
                            ),
                            filled: true,
                            fillColor: backgroundColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: correoController,
                          decoration: InputDecoration(
                            labelText: 'Correo',
                            labelStyle: TextStyle(color: darkGrey),
                            prefixIcon: Icon(Icons.email, color: textColor),
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: primaryColor),
                            ),
                            filled: true,
                            fillColor: backgroundColor,
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: contrasenaController,
                          obscureText: !verContrasena,
                          autofillHints: const [AutofillHints.newPassword],
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            labelStyle: TextStyle(color: darkGrey),
                            prefixIcon: Icon(Icons.lock, color: textColor),
                            suffixIcon: IconButton(
                              icon: Icon(
                                verContrasena ? Icons.visibility : Icons.visibility_off,
                                color: primaryColor,
                              ),
                              onPressed: () => setStateDialog(() => verContrasena = !verContrasena),
                            ),
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: primaryColor),
                            ),
                            filled: true,
                            fillColor: backgroundColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: confirmarContrasenaController,
                          obscureText: !verConfirmacion,
                          autofillHints: const [AutofillHints.newPassword],
                          decoration: InputDecoration(
                            labelText: 'Confirmar contraseña',
                            labelStyle: TextStyle(color: darkGrey),
                            prefixIcon: Icon(Icons.lock_outline, color: textColor),
                            suffixIcon: IconButton(
                              icon: Icon(
                                verConfirmacion ? Icons.visibility : Icons.visibility_off,
                                color: primaryColor,
                              ),
                              onPressed: () => setStateDialog(() => verConfirmacion = !verConfirmacion),
                            ),
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: primaryColor),
                            ),
                            filled: true,
                            fillColor: backgroundColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Mostrar rol SWT_USER como texto fijo (no editable)
                        TextFormField(
                          initialValue: 'SWT_USER',
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Rol',
                            labelStyle: TextStyle(color: darkGrey),
                            prefixIcon: Icon(Icons.badge, color: textColor),
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: primaryColor),
                            ),
                            filled: true,
                            fillColor: lightGrey,
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: ciudadSeleccionada,
                          decoration: InputDecoration(
                            labelText: 'Ciudad',
                            labelStyle: TextStyle(color: darkGrey),
                            prefixIcon: Icon(Icons.location_city, color: textColor),
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: primaryColor),
                            ),
                            filled: true,
                            fillColor: backgroundColor,
                          ),
                          dropdownColor: backgroundColor,
                          style: TextStyle(color: textColor),
                          items: ciudades.map((ciudad) => DropdownMenuItem(
                            value: ciudad,
                            child: Text(ciudad),
                          )).toList(),
                          onChanged: (val) => setStateDialog(() => ciudadSeleccionada = val),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: areaSeleccionada,
                          decoration: InputDecoration(
                            labelText: 'Área',
                            labelStyle: TextStyle(color: darkGrey),
                            prefixIcon: Icon(Icons.work, color: textColor),
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: primaryColor),
                            ),
                            filled: true,
                            fillColor: backgroundColor,
                          ),
                          dropdownColor: backgroundColor,
                          style: TextStyle(color: textColor),
                          items: areas.map((area) => DropdownMenuItem(
                            value: area,
                            child: Text(area),
                          )).toList(),
                          onChanged: (val) => setStateDialog(() => areaSeleccionada = val),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Cancelar', style: TextStyle(color: primaryColor)),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                              ),
                              onPressed: () async {
                                final nombre = nombreController.text.trim();
                                final apellido = apellidoController.text.trim();
                                final correo = correoController.text.trim();
                                final contrasena = contrasenaController.text.trim();
                                final confirmar = confirmarContrasenaController.text.trim();

                                if ([nombre, apellido, correo, contrasena, confirmar].any((e) => e.isEmpty) ||
                                    ciudadSeleccionada == null || areaSeleccionada == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Completa todos los campos', style: TextStyle(color: backgroundColor)),
                                      backgroundColor: primaryColor,
                                    ),
                                  );
                                  return;
                                }

                                if (contrasena != confirmar) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Las contraseñas no coinciden', style: TextStyle(color: backgroundColor)),
                                      backgroundColor: primaryColor,
                                    ),
                                  );
                                  return;
                                }

                                final emailValido = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(correo);
                                if (!emailValido) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Correo inválido', style: TextStyle(color: backgroundColor)),
                                      backgroundColor: primaryColor,
                                    ),
                                  );
                                  return;
                                }

                                final url = Uri.parse('$baseUrl/usuarios/registro');
                                final response = await http.post(
                                  url,
                                  headers: {'Content-Type': 'application/json'},
                                  body: jsonEncode({
                                    'nombre': nombre,
                                    'apellido': apellido,
                                    'correo': correo,
                                    'contraseña': contrasena,
                                    'rol': rolSeleccionado,
                                    'ciudad': ciudadSeleccionada,
                                    'area': areaSeleccionada,
                                  }),
                                );

                                if (!mounted) return; 
                                if (response.statusCode == 200 || response.statusCode == 201) {
                                  Navigator.pop(context);
                                  await fetchUsuarios();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Usuario SWT_USER agregado exitosamente', style: TextStyle(color: backgroundColor)),
                                      backgroundColor: Colors.green[700],
                                    ),
                                  );
                                } else {
                                  String mensaje = 'Error al guardar';
                                  try {
                                    final jsonResp = jsonDecode(response.body);
                                    mensaje = jsonResp['mensaje'] ?? jsonResp['error'] ?? mensaje;
                                  } catch (_) {}
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(mensaje, style: TextStyle(color: backgroundColor)),
                                      backgroundColor: primaryColor,
                                    ),
                                  );
                                }
                              },
                              child: Text('Guardar', style: TextStyle(color: backgroundColor)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _mostrarFormularioActualizarUsuario(dynamic usuario) {
    final nombreController = TextEditingController(text: usuario['nombre']);
    final apellidoController = TextEditingController(text: usuario['apellido']);
    final correoController = TextEditingController(text: usuario['correo']);
    final contrasenaController = TextEditingController();

    // Forzar rol SWT_USER
    String rolSeleccionado = 'SWT_USER';
    String? ciudadSeleccionada = usuario['ciudad'];
    String? areaSeleccionada = usuario['area'];

    // Listas de selección
    final ciudades = ['Quito', 'Calderón', 'Tumbaco', 'Pomasqui', 'Centro Historico'];
    final areas = ['Ventas', 'Marketing', 'TI', 'Recursos Humanos', 'Operaciones'];

    bool verContrasena = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: backgroundColor,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Actualizar Usuario SWT_USER',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: nombreController,
                          decoration: InputDecoration(
                            labelText: 'Nombre',
                            labelStyle: TextStyle(color: darkGrey),
                            prefixIcon: Icon(Icons.person, color: textColor),
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: primaryColor),
                            ),
                            filled: true,
                            fillColor: backgroundColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: apellidoController,
                          decoration: InputDecoration(
                            labelText: 'Apellido',
                            labelStyle: TextStyle(color: darkGrey),
                            prefixIcon: Icon(Icons.person_outline, color: textColor),
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: primaryColor),
                            ),
                            filled: true,
                            fillColor: backgroundColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: correoController,
                          decoration: InputDecoration(
                            labelText: 'Correo',
                            labelStyle: TextStyle(color: darkGrey),
                            prefixIcon: Icon(Icons.email, color: textColor),
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: primaryColor),
                            ),
                            filled: true,
                            fillColor: backgroundColor,
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: contrasenaController,
                          obscureText: !verContrasena,
                          autofillHints: const [AutofillHints.newPassword],
                          decoration: InputDecoration(
                            labelText: 'Nueva Contraseña (opcional)',
                            labelStyle: TextStyle(color: darkGrey),
                            prefixIcon: Icon(Icons.lock, color: textColor),
                            suffixIcon: IconButton(
                              icon: Icon(
                                verContrasena ? Icons.visibility : Icons.visibility_off,
                                color: primaryColor,
                              ),
                              onPressed: () => setStateDialog(() => verContrasena = !verContrasena),
                            ),
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: primaryColor),
                            ),
                            filled: true,
                            fillColor: backgroundColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Mostrar rol SWT_USER como texto fijo (no editable)
                        TextFormField(
                          initialValue: 'SWT_USER',
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Rol',
                            labelStyle: TextStyle(color: darkGrey),
                            prefixIcon: Icon(Icons.badge, color: textColor),
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: primaryColor),
                            ),
                            filled: true,
                            fillColor: lightGrey,
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: ciudadSeleccionada,
                          decoration: InputDecoration(
                            labelText: 'Ciudad',
                            labelStyle: TextStyle(color: darkGrey),
                            prefixIcon: Icon(Icons.location_city, color: textColor),
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: primaryColor),
                            ),
                            filled: true,
                            fillColor: backgroundColor,
                          ),
                          dropdownColor: backgroundColor,
                          style: TextStyle(color: textColor),
                          items: ciudades.map((ciudad) => DropdownMenuItem(
                            value: ciudad,
                            child: Text(ciudad),
                          )).toList(),
                          onChanged: (val) => setStateDialog(() => ciudadSeleccionada = val),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: areaSeleccionada,
                          decoration: InputDecoration(
                            labelText: 'Área',
                            labelStyle: TextStyle(color: darkGrey),
                            prefixIcon: Icon(Icons.work, color: textColor),
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: primaryColor),
                            ),
                            filled: true,
                            fillColor: backgroundColor,
                          ),
                          dropdownColor: backgroundColor,
                          style: TextStyle(color: textColor),
                          items: areas.map((area) => DropdownMenuItem(
                            value: area,
                            child: Text(area),
                          )).toList(),
                          onChanged: (val) => setStateDialog(() => areaSeleccionada = val),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Cancelar', style: TextStyle(color: primaryColor)),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                              ),
                              onPressed: () async {
                                final nombre = nombreController.text.trim();
                                final apellido = apellidoController.text.trim();
                                final correo = correoController.text.trim();
                                final contrasena = contrasenaController.text.trim();

                                if ([nombre, apellido, correo].any((e) => e.isEmpty) ||
                                    ciudadSeleccionada == null || areaSeleccionada == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Completa todos los campos', style: TextStyle(color: backgroundColor)),
                                      backgroundColor: primaryColor,
                                    ),
                                  );
                                  return;
                                }

                                final emailValido = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(correo);
                                if (!emailValido) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Correo inválido', style: TextStyle(color: backgroundColor)),
                                      backgroundColor: primaryColor,
                                    ),
                                  );
                                  return;
                                }

                                Map<String, dynamic> body = {
                                  'nombre': nombre,
                                  'apellido': apellido,
                                  'correo': correo,
                                  'rol': rolSeleccionado,
                                  'ciudad': ciudadSeleccionada,
                                  'area': areaSeleccionada,
                                };
                                if (contrasena.isNotEmpty) {
                                  body['contraseña'] = contrasena;
                                }

                                final url = Uri.parse('$baseUrl/usuarios/${usuario["_id"]}');
                                final response = await http.put(
                                  url,
                                  headers: {'Content-Type': 'application/json'},
                                  body: jsonEncode(body),
                                );

                                if (!mounted) return;
                                if (response.statusCode == 200) {
                                  Navigator.pop(context);
                                  await fetchUsuarios();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Usuario SWT_USER actualizado', style: TextStyle(color: backgroundColor)),
                                      backgroundColor: Colors.green[700],
                                    ),
                                  );
                                } else {
                                  String mensaje = 'Error al actualizar';
                                  try {
                                    final jsonResp = jsonDecode(response.body);
                                    mensaje = jsonResp['mensaje'] ?? jsonResp['error'] ?? mensaje;
                                  } catch (_) {}
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(mensaje, style: TextStyle(color: backgroundColor)),
                                      backgroundColor: primaryColor,
                                    ),
                                  );
                                }
                              },
                              child: Text('Actualizar', style: TextStyle(color: backgroundColor)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmarEliminacion(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor,
        title: Text('Eliminar usuario SWT_USER', style: TextStyle(color: primaryColor)),
        content: Text('¿Estás seguro de eliminar este usuario SWT_USER?', style: TextStyle(color: textColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: TextStyle(color: secondaryColor)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _eliminarUsuario(id);
            },
            child: Text('Eliminar', style: TextStyle(color: primaryColor)),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarUsuario(String id) async {
    final url = Uri.parse('$baseUrl/usuarios/$id');
    try {
      final response = await http.delete(url);
      if (response.statusCode == 200) {
        setState(() {
          usuarios.removeWhere((u) => u['_id'] == id);
          usuariosFiltrados.removeWhere((u) => u['_id'] == id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Usuario SWT_USER eliminado', style: TextStyle(color: backgroundColor)),
            backgroundColor: Colors.green[700],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar usuario SWT_USER', style: TextStyle(color: backgroundColor)),
            backgroundColor: primaryColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de conexión: $e', style: TextStyle(color: backgroundColor)),
          backgroundColor: primaryColor,
        ),
      );
    }
  }

  Widget buildUsuarioItem(dynamic usuario) {
    final nombre = usuario['nombre'] ?? '';
    final apellido = usuario['apellido'] ?? '';
    final correo = usuario['correo'] ?? '';
    final id = usuario['_id'];

    return Container(
      color: backgroundColor,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: primaryColor,
          child: Text(
            (nombre.isNotEmpty && apellido.isNotEmpty)
                ? '${nombre[0]}${apellido[0]}'.toUpperCase()
                : '?',
            style: TextStyle(color: backgroundColor),
          ),
        ),
        title: Text('$nombre $apellido', style: TextStyle(color: textColor)),
        subtitle: Text('$correo (SWT_USER)', style: TextStyle(color: darkGrey)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: primaryColor),
              tooltip: 'Actualizar usuario SWT_USER',
              onPressed: () => _mostrarFormularioActualizarUsuario(usuario),
            ),
            IconButton(
              icon: Icon(Icons.delete, color: primaryColor),
              tooltip: 'Eliminar usuario SWT_USER',
              onPressed: () => _confirmarEliminacion(id),
            ),
          ],
        ),
      ),
    );
  }

  List<Project8> _projectsFiltered = [];
  final ApiService _apiService = ApiService();
  bool _isLoadingProjects = true;
  String? _projectsErrorMessage;
  List<Project8> _projects = [];
  Timer? _completionCheckerTimer;
  List<Project8> _completedProjectsToNotify = [];
  double completedPercent = 0.0;
  double inProgressPercent = 0.0;
  double pendingPercent = 0.0;
  int selectedCircleSegment = -1;
  int totalProyectos = 0;
  final ValueNotifier<String?> processStatusNotifier = ValueNotifier<String?>(null);




Future<void> _fetchProjectsData() async {
    setState(() {
      _isLoadingProjects = true;
      _projectsErrorMessage = null;
    });
    try {
      final fetchedProcesses = await _apiService.getProcesses();
      setState(() {
        _projects = fetchedProcesses.map((process) => Project8(
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
              _projects[index] = Project8(
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








  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGrey,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text('Usuarios SWT_USER', style: TextStyle(color: backgroundColor)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: backgroundColor), 
            onPressed: fetchUsuarios
          ),
          IconButton(
            icon: Icon(Icons.filter_alt, color: backgroundColor),
            onPressed: _mostrarPanelFiltros,
          ),
        ],
      ),
      drawer: Custom22(
        selectedIndex: 1,
        onItemTap: (index) {
          Navigator.pop(context); // Cierra el drawer
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => DashboardSwt()),
            );
          } else if (index == 1) {
            // Ya estás en UsuariosScreen, no hace falta redirigir
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => ProjectsSwt( 
                    projects: _projectsFiltered,
    apiService: _apiService,
    refreshData: _fetchProjectsData,
    processStatusNotifier: processStatusNotifier,
    isLoading: _isLoadingProjects,
    errorMessage: _projectsErrorMessage,
              )),
            );
          }
        },
      ),
      body: Center(
        child: isLoading
            ? CircularProgressIndicator(color: primaryColor)
            : errorMessage != null
                ? Text(errorMessage!, style: TextStyle(color: primaryColor))
                : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Buscar usuarios SWT_USER',
                          labelStyle: TextStyle(color: textColor),
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: primaryColor),
                          ),
                          prefixIcon: Icon(Icons.search, color: primaryColor),
                          filled: true,
                          fillColor: backgroundColor,
                        ),
                      ),
                    ),
                    Expanded(
                      child: usuariosFiltrados.isEmpty
                          ? Center(
                            child: Text(
                              'No hay usuarios SWT_USER registrados que coincidan con la búsqueda.',
                              style: TextStyle(color: textColor),
                            ),
                          )
                          : ListView.separated(
                            separatorBuilder: (_, __) => Divider(color: mediumGrey),
                            itemCount: usuariosFiltrados.length,
                            itemBuilder: (_, index) => buildUsuarioItem(usuariosFiltrados[index]),
                          ),
                    ),
                  ],
                ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        onPressed: _mostrarFormularioAgregarUsuario,
        child: Icon(Icons.add, color: backgroundColor),
        tooltip: 'Agregar nuevo usuario SWT_USER',
      ),
    );
  }
}