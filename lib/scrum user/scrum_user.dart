// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class UsuariosScreen extends StatefulWidget {
  @override
  _UsuariosScreenState createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
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

        setState(() {
          usuarios = data.reversed.toList();
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
            return Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Wrap(
                children: [
                  Text('Filtros de búsqueda',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor)),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      minimumSize: Size(double.infinity, 50),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cerrar', style: TextStyle(color: backgroundColor)),
                  )
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

    String? rolSeleccionado;
    String? ciudadSeleccionada;
    String? areaSeleccionada;

    final roles = ['SWT', 'Cont', 'Supervisor','A.R','CX','SIR','SD','Op'];
    final ciudades = ['Quito', 'Calderón', 'Tumbaco', 'Pomasqui', 'Centro Historico'];
    final areas = ['Ventas', 'Marketing', 'TI', 'Recursos Humanos', 'Operaciones'];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: backgroundColor,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Agregar Usuario', 
                            style: TextStyle(
                                fontSize: 20, 
                                fontWeight: FontWeight.bold,
                                color: textColor)),
                        const SizedBox(height: 16),
                        TextField(
                          controller: nombreController,
                          decoration: InputDecoration(
                            labelText: 'Nombre',
                            labelStyle: TextStyle(color: darkGrey),
                            prefixIcon: Icon(Icons.person, color: textColor),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: primaryColor),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: apellidoController,
                          decoration: InputDecoration(
                            labelText: 'Apellido',
                            labelStyle: TextStyle(color: darkGrey),
                            prefixIcon: Icon(Icons.person_outline, color: textColor),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: primaryColor),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: correoController,
                          decoration: InputDecoration(
                            labelText: 'Correo',
                            labelStyle: TextStyle(color: darkGrey),
                            prefixIcon: Icon(Icons.email, color: textColor),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: primaryColor),
                            ),
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
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: primaryColor),
                            ),
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
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: primaryColor),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: rolSeleccionado,
                          decoration: InputDecoration(
                            labelText: 'Rol',
                            labelStyle: TextStyle(color: darkGrey),
                            prefixIcon: Icon(Icons.badge, color: textColor),
                          ),
                          dropdownColor: backgroundColor,
                          style: TextStyle(color: textColor),
                          items: roles.map((rol) => DropdownMenuItem(
                            value: rol,
                            child: Text(rol),
                          )).toList(),
                          onChanged: (val) => setStateDialog(() => rolSeleccionado = val),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: ciudadSeleccionada,
                          decoration: InputDecoration(
                            labelText: 'Ciudad',
                            labelStyle: TextStyle(color: darkGrey),
                            prefixIcon: Icon(Icons.location_city, color: textColor),
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
                                    rolSeleccionado == null || ciudadSeleccionada == null || areaSeleccionada == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Completa todos los campos'),
                                      backgroundColor: primaryColor,
                                    ),
                                  );
                                  return;
                                }

                                if (contrasena != confirmar) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Las contraseñas no coinciden'),
                                      backgroundColor: primaryColor,
                                    ),
                                  );
                                  return;
                                }

                                final emailValido = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(correo);
                                if (!emailValido) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Correo inválido'),
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

                                if (response.statusCode == 200 || response.statusCode == 201) {
                                  Navigator.pop(context);
                                  await fetchUsuarios();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Usuario agregado exitosamente'),
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
                                      content: Text(mensaje),
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

    String? rolSeleccionado = usuario['rol'];
    String? ciudadSeleccionada = usuario['ciudad'];
    String? areaSeleccionada = usuario['area'];

    final roles = ['Gerencia', 'Usuario', 'Supervisor'];
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: backgroundColor,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Actualizar Usuario', 
                            style: TextStyle(
                                fontSize: 20, 
                                fontWeight: FontWeight.bold,
                                color: textColor)),
                        const SizedBox(height: 16),
                        TextField(
                          controller: nombreController,
                          decoration: InputDecoration(
                            labelText: 'Nombre',
                            labelStyle: TextStyle(color: darkGrey),
                            prefixIcon: Icon(Icons.person, color: textColor),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: primaryColor),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: apellidoController,
                          decoration: InputDecoration(
                            labelText: 'Apellido',
                            labelStyle: TextStyle(color: darkGrey),
                            prefixIcon: Icon(Icons.person_outline, color: textColor),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: primaryColor),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: correoController,
                          decoration: InputDecoration(
                            labelText: 'Correo',
                            labelStyle: TextStyle(color: darkGrey),
                            prefixIcon: Icon(Icons.email, color: textColor),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: primaryColor),
                            ),
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
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: primaryColor),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: rolSeleccionado,
                          decoration: InputDecoration(
                            labelText: 'Rol',
                            labelStyle: TextStyle(color: darkGrey),
                            prefixIcon: Icon(Icons.badge, color: textColor),
                          ),
                          dropdownColor: backgroundColor,
                          style: TextStyle(color: textColor),
                          items: roles.map((rol) => DropdownMenuItem(
                            value: rol,
                            child: Text(rol),
                          )).toList(),
                          onChanged: (val) => setStateDialog(() => rolSeleccionado = val),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: ciudadSeleccionada,
                          decoration: InputDecoration(
                            labelText: 'Ciudad',
                            labelStyle: TextStyle(color: darkGrey),
                            prefixIcon: Icon(Icons.location_city, color: textColor),
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
                                    rolSeleccionado == null || ciudadSeleccionada == null || areaSeleccionada == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Completa todos los campos'),
                                      backgroundColor: primaryColor,
                                    ),
                                  );
                                  return;
                                }

                                final emailValido = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(correo);
                                if (!emailValido) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Correo inválido'),
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

                                if (response.statusCode == 200) {
                                  Navigator.pop(context);
                                  await fetchUsuarios();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Usuario actualizado'),
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
                                      content: Text(mensaje),
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
        title: Text('Eliminar usuario', style: TextStyle(color: primaryColor)),
        content: Text('¿Estás seguro de eliminar este usuario?', style: TextStyle(color: textColor)),
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
            content: const Text('Usuario eliminado'),
            backgroundColor: Colors.green[700],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error al eliminar usuario'),
            backgroundColor: primaryColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de conexión: $e'),
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

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: primaryColor,
        child: Text(
          (nombre.isNotEmpty && apellido.isNotEmpty) ? '${nombre[0]}${apellido[0]}'.toUpperCase() : '?',
          style: TextStyle(color: backgroundColor),
        ),
      ),
      title: Text('$nombre $apellido', style: TextStyle(color: textColor)),
      subtitle: Text(correo, style: TextStyle(color: darkGrey)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.edit, color: primaryColor),
            tooltip: 'Actualizar usuario',
            onPressed: () => _mostrarFormularioActualizarUsuario(usuario),
          ),
          IconButton(
            icon: Icon(Icons.delete, color: primaryColor),
            tooltip: 'Eliminar usuario',
            onPressed: () => _confirmarEliminacion(id),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Usuarios', style: TextStyle(color: backgroundColor)),
        backgroundColor: primaryColor,
        iconTheme: IconThemeData(color: backgroundColor),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: backgroundColor),
            onPressed: fetchUsuarios,
          ),
          IconButton(
            icon: Icon(Icons.filter_alt, color: backgroundColor),
            onPressed: _mostrarPanelFiltros,
          ),
        ],
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
                            labelText: 'Buscar',
                            labelStyle: TextStyle(color: darkGrey),
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.search, color: primaryColor),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: primaryColor),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: usuariosFiltrados.isEmpty
                            ? Center(
                                child: Text(
                                  'No hay usuarios registrados que coincidan con la búsqueda.',
                                  style: TextStyle(color: darkGrey),
                                ),
                              )
                            : ListView.separated(
                                itemCount: usuariosFiltrados.length,
                                separatorBuilder: (_, __) => Divider(height: 1, color: lightGrey),
                                itemBuilder: (_, index) => buildUsuarioItem(usuariosFiltrados[index]),
                              ),
                      ),
                    ],
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarFormularioAgregarUsuario,
        backgroundColor: primaryColor,
        child: Icon(Icons.add, color: backgroundColor),
        tooltip: 'Agregar nuevo usuario',
      ),
    );
  }
}