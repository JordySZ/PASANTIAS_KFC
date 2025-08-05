import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:login_app/ROLES/A.R/ar.dart';
import 'package:login_app/ROLES/A.R/ar_user.dart';
import 'package:login_app/ROLES/CONT/cont.dart';
import 'package:login_app/ROLES/CX/cx.dart';
import 'package:login_app/ROLES/SD/sd.dart';
import 'package:login_app/ROLES/SD/sd_user.dart';
import 'package:login_app/ROLES/SIR/sir.dart';
import 'dart:convert';


import 'package:login_app/scrum user/scrum_user.dart';
import 'package:login_app/ROLES/Operaciones/op.dart';
import 'package:login_app/super%20usario/home_page.dart';
import 'package:login_app/ROLES/swt/sw.dart';

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
  bool _passwordVisible = false;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final response = await http.post(
          Uri.parse('http://localhost:3000/usuarios/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'correo': _emailController.text.trim(),
            'contraseña': _passwordController.text,
          }),
        );

        setState(() => _isLoading = false);

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = json.decode(response.body);
          final String? userRole = responseData['usuario']['rol'];

          if (userRole == 'Op') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const DashboardPage22(),
              ),
            );
          } else if (userRole == 'Supervisor') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const DashboardPage(),
              ),
            );
          } else if (userRole == 'SWT') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => DashboardSwt(),
              ),
            );
            } else if (userRole == 'Cont') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const DashboardCont(),
              ),
            );
          } else if (userRole == 'A.R') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => DashboardAr(),
              ),
            );
            } else if (userRole == 'CX') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const DashboardCx(),
              ),
            );
          } else if (userRole == 'SIR') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => DashboardSir(),
              ),
            );

             } else if (userRole == 'SD') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => DashboardSD(),
              ),
            );
            } else if (userRole == 'SD_USER') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => DashboardSD_user(),
              ),
            );

                } else if (userRole == 'A.R_USER') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => DashboardAr_user(),
              ),
            );

               } else if (userRole == 'A.R_USER') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => DashboardAr_user(),
              ),
            );
               } else if (userRole == 'A.R_USER') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => DashboardAr_user(),
              ),
            );
               } else if (userRole == 'A.R_USER') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => DashboardAr_user(),
              ),
            );
               } else if (userRole == 'A.R_USER') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => DashboardAr_user(),
              ),
            );
          } else {

            print('Rol desconocido: $userRole. Redirigiendo a Dashboard por defecto.');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const DashboardPage()),
            );
          }
        } else {
          String errorMessage = 'Correo o contraseña incorrectos';
          try {
            final errorBody = jsonDecode(response.body);
            if (errorBody.containsKey('msg')) {
              errorMessage = errorBody['msg'];
            }
          } catch (e) {}

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage, style: const TextStyle(color: Colors.white)),
              backgroundColor: Colors.red[800],
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de conexión: $e', style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.red[800],
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFEEEEEE)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 350,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
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
                    Text(
                      'Iniciar sesión',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Correo',
                        labelStyle: TextStyle(color: Colors.grey[700]),
                        border: const OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[400]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red[800]!),
                        ),
                        prefixIcon: Icon(Icons.email, color: Colors.red[800]),
                      ),
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingrese su correo';
                        }
                        if (!value.contains('@')) {
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
                        labelStyle: TextStyle(color: Colors.grey[700]),
                        border: const OutlineInputBorder(),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[400]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red[800]!),
                        ),
                        prefixIcon: Icon(Icons.lock, color: Colors.red[800]),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _passwordVisible ? Icons.visibility : Icons.visibility_off,
                            color: Colors.red[800],
                          ),
                          onPressed: () {
                            setState(() {
                              _passwordVisible = !_passwordVisible;
                            });
                          },
                        ),
                      ),
                      textAlign: TextAlign.center,
                      validator: (value) => value!.isEmpty ? 'Ingrese su contraseña' : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[800],
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 5,
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              'Ingresar',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
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