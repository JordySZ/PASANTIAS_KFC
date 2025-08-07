import 'package:flutter/material.dart';
import 'package:login_app/ROLES/Operaciones/op.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Modular',
      debugShowCheckedModeBanner: false,
      home: DashboardPage22(), //LoginScreen DashboardPage DashboardPage22
    );
  }
}
