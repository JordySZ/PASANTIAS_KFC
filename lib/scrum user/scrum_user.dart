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
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Wrap(
                children: [
                  const Text('Filtros de búsqueda',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  CheckboxListTile(
                    title: const Text('Nombre'),
                    value: buscarPorNombre,
                    onChanged: (val) {
                      setModalState(() {
                        buscarPorNombre = val ?? false;
                      });
                      _filtrarUsuarios();
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Apellido'),
                    value: buscarPorApellido,
                    onChanged: (val) {
                      setModalState(() {
                        buscarPorApellido = val ?? false;
                      });
                      _filtrarUsuarios();
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Correo'),
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
                    child: const Text('Cerrar'),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Formulario para agregar nuevo usuario con iconos
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

    final roles = ['Gerencia', 'Usuario', 'Supervisor'];
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
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Agregar Usuario', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        TextField(
                          controller: nombreController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre',
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: apellidoController,
                          decoration: const InputDecoration(
                            labelText: 'Apellido',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: correoController,
                          decoration: const InputDecoration(
                            labelText: 'Correo',
                            prefixIcon: Icon(Icons.email),
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
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(verContrasena ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setStateDialog(() => verContrasena = !verContrasena),
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
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(verConfirmacion ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setStateDialog(() => verConfirmacion = !verConfirmacion),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: rolSeleccionado,
                          decoration: const InputDecoration(
                            labelText: 'Rol',
                            prefixIcon: Icon(Icons.badge),
                          ),
                          items: roles.map((rol) => DropdownMenuItem(value: rol, child: Text(rol))).toList(),
                          onChanged: (val) => setStateDialog(() => rolSeleccionado = val),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: ciudadSeleccionada,
                          decoration: const InputDecoration(
                            labelText: 'Ciudad',
                            prefixIcon: Icon(Icons.location_city),
                          ),
                          items: ciudades.map((ciudad) => DropdownMenuItem(value: ciudad, child: Text(ciudad))).toList(),
                          onChanged: (val) => setStateDialog(() => ciudadSeleccionada = val),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: areaSeleccionada,
                          decoration: const InputDecoration(
                            labelText: 'Área',
                            prefixIcon: Icon(Icons.work),
                          ),
                          items: areas.map((area) => DropdownMenuItem(value: area, child: Text(area))).toList(),
                          onChanged: (val) => setStateDialog(() => areaSeleccionada = val),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.save),
                              label: const Text('Guardar'),
                              onPressed: () async {
                                final nombre = nombreController.text.trim();
                                final apellido = apellidoController.text.trim();
                                final correo = correoController.text.trim();
                                final contrasena = contrasenaController.text.trim();
                                final confirmar = confirmarContrasenaController.text.trim();

                                if ([nombre, apellido, correo, contrasena, confirmar].any((e) => e.isEmpty) ||
                                    rolSeleccionado == null || ciudadSeleccionada == null || areaSeleccionada == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Completa todos los campos')));
                                  return;
                                }

                                if (contrasena != confirmar) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Las contraseñas no coinciden')));
                                  return;
                                }

                                final emailValido = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(correo);
                                if (!emailValido) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Correo inválido')));
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
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario agregado exitosamente')));
                                } else {
                                  String mensaje = 'Error al guardar';
                                  try {
                                    final jsonResp = jsonDecode(response.body);
                                    mensaje = jsonResp['mensaje'] ?? jsonResp['error'] ?? mensaje;
                                  } catch (_) {}
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
                                }
                              },
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

  // Formulario para actualizar usuario con iconos
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
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Actualizar Usuario', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        TextField(
                          controller: nombreController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre',
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: apellidoController,
                          decoration: const InputDecoration(
                            labelText: 'Apellido',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: correoController,
                          decoration: const InputDecoration(
                            labelText: 'Correo',
                            prefixIcon: Icon(Icons.email),
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
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(verContrasena ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setStateDialog(() => verContrasena = !verContrasena),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: rolSeleccionado,
                          decoration: const InputDecoration(
                            labelText: 'Rol',
                            prefixIcon: Icon(Icons.badge),
                          ),
                          items: roles.map((rol) => DropdownMenuItem(value: rol, child: Text(rol))).toList(),
                          onChanged: (val) => setStateDialog(() => rolSeleccionado = val),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: ciudadSeleccionada,
                          decoration: const InputDecoration(
                            labelText: 'Ciudad',
                            prefixIcon: Icon(Icons.location_city),
                          ),
                          items: ciudades.map((ciudad) => DropdownMenuItem(value: ciudad, child: Text(ciudad))).toList(),
                          onChanged: (val) => setStateDialog(() => ciudadSeleccionada = val),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: areaSeleccionada,
                          decoration: const InputDecoration(
                            labelText: 'Área',
                            prefixIcon: Icon(Icons.work),
                          ),
                          items: areas.map((area) => DropdownMenuItem(value: area, child: Text(area))).toList(),
                          onChanged: (val) => setStateDialog(() => areaSeleccionada = val),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.save),
                              label: const Text('Actualizar'),
                              onPressed: () async {
                                final nombre = nombreController.text.trim();
                                final apellido = apellidoController.text.trim();
                                final correo = correoController.text.trim();
                                final contrasena = contrasenaController.text.trim();

                                if ([nombre, apellido, correo].any((e) => e.isEmpty) ||
                                    rolSeleccionado == null || ciudadSeleccionada == null || areaSeleccionada == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Completa todos los campos')));
                                  return;
                                }

                                final emailValido = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(correo);
                                if (!emailValido) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Correo inválido')));
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
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario actualizado')));
                                } else {
                                  String mensaje = 'Error al actualizar';
                                  try {
                                    final jsonResp = jsonDecode(response.body);
                                    mensaje = jsonResp['mensaje'] ?? jsonResp['error'] ?? mensaje;
                                  } catch (_) {}
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
                                }
                              },
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
        title: const Text('Eliminar usuario'),
        content: const Text('¿Estás seguro de eliminar este usuario?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(onPressed: () async { Navigator.pop(context); await _eliminarUsuario(id); }, child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuario eliminado')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al eliminar usuario')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error de conexión: $e')));
    }
  }

  Widget buildUsuarioItem(dynamic usuario) {
    final nombre = usuario['nombre'] ?? '';
    final apellido = usuario['apellido'] ?? '';
    final correo = usuario['correo'] ?? '';
    final id = usuario['_id'];

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue,
        child: Text(
          (nombre.isNotEmpty && apellido.isNotEmpty) ? '${nombre[0]}${apellido[0]}'.toUpperCase() : '?',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text('$nombre $apellido'),
      subtitle: Text(correo),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.green),
            tooltip: 'Actualizar usuario',
            onPressed: () => _mostrarFormularioActualizarUsuario(usuario),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
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
        title: const Text('Usuarios'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: fetchUsuarios),
          IconButton(icon: const Icon(Icons.filter_alt), onPressed: _mostrarPanelFiltros),
        ],
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : errorMessage != null
                ? Text(errorMessage!, style: const TextStyle(color: Colors.red))
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            labelText: 'Buscar',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                      ),
                      Expanded(
                        child: usuariosFiltrados.isEmpty
                            ? const Center(child: Text('No hay usuarios registrados que coincidan con la búsqueda.'))
                            : ListView.separated(
                                itemCount: usuariosFiltrados.length,
                                separatorBuilder: (_, __) => const Divider(),
                                itemBuilder: (_, index) => buildUsuarioItem(usuariosFiltrados[index]),
                              ),
                      ),
                    ],
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarFormularioAgregarUsuario,
        child: const Icon(Icons.add),
        tooltip: 'Agregar nuevo usuario',
      ),
    );
  }
}
