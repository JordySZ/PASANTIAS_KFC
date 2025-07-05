import 'package:flutter/material.dart';
import 'login/login.dart';  // Importa la pantalla de login

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      
      title: 'App Modular',
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}
