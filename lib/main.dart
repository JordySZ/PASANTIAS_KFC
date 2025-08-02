import 'package:flutter/material.dart';
import 'package:login_app/ROLES/A.R/ar.dart';
import 'package:login_app/ROLES/A.R/solicitud.dart';
import 'package:login_app/ROLES/Operaciones/op.dart';
import 'package:login_app/login/login.dart';
import 'package:login_app/super%20usario/home_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Modular',
      debugShowCheckedModeBanner: false,
      home: LoginScreen1(), //LoginScreen DashboardPage DashboardPage22
    );
  }
}
