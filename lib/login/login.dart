import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Importa tus pantallas de destino
import 'package:login_app/scrum user/scrum_user.dart';
import 'package:login_app/gerente/gerente.dart';
import 'package:login_app/user/home_page.dart';
class LoginScreen1 extends StatefulWidget {
  const LoginScreen1({Key? key}) : super(key: key);

  @override
  State<LoginScreen1> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen1> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _passwordVisible = false; // Controla visibilidad de la contraseña

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final response = await http.post(
          Uri.parse('http://localhost:3000/usuarios/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'correo': _emailController.text.trim(), // ¡Importante: 'correo' coincide con el backend!
            'contraseña': _passwordController.text,
          }),
        );

        setState(() => _isLoading = false);

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = json.decode(response.body);
          final String? userRole = responseData['usuario']['rol']; // Captura el rol del usuario

          // Lógica de redirección basada en el rol
          if (userRole == 'Gerencia') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const GerenciaScreen()), // Redirige a la página de Gerencia
            );
          } else if (userRole == 'Supervisor') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const DashboardPage()), // Redirige a la página de Supervisor
            );
          } else if (userRole == 'Usuario') { // Si el rol es 'Usuario'
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) =>  UsuariosScreen()), // Redirige a la página de usuario estándar
            );
          } else {
            // Manejar un rol desconocido o por defecto (podría ser un error o una página genérica)
            print('Rol desconocido: $userRole. Redirigiendo a Dashboard por defecto.');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const DashboardPage()),
            );
          }
        } else {
          // Si el backend devuelve un mensaje de error específico, puedes mostrarlo
          String errorMessage = 'Correo o contraseña incorrectos';
          try {
            final errorBody = jsonDecode(response.body);
            if (errorBody.containsKey('msg')) {
              errorMessage = errorBody['msg'];
            }
          } catch (e) {
            // No se pudo parsear el error, usar el mensaje genérico
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                errorMessage,
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        // Manejo de errores de conexión (ej. servidor no disponible)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de conexión: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // Fondo para resaltar el cuadro
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 350,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Iniciar sesión',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Correo',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.emailAddress, // Teclado para email
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingrese su correo';
                      }
                      if (!value.contains('@')) { // Validación básica de formato de correo
                        return 'Ingrese un correo válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_passwordVisible,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _passwordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _passwordVisible = !_passwordVisible;
                          });
                        },
                      ),
                    ),
                    textAlign: TextAlign.center,
                    validator: (value) =>
                        value!.isEmpty ? 'Ingrese su contraseña' : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700], // Color de fondo del botón
                      foregroundColor: Colors.white,     // Color del texto y el icono
                      minimumSize: const Size(double.infinity, 50), // Ancho completo, altura 50
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10), // Bordes redondeados
                      ),
                      elevation: 5, // Sombra del botón
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Ingresar',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}