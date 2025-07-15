import 'package:flutter/material.dart';
import 'package:login_app/login/login.dart';
import 'package:login_app/user/home_page.dart';
import 'package:login_app/user/user.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      
      title: 'App Modular',
      debugShowCheckedModeBanner: false,
      home: LoginScreen1(),  //LoginScreen DashboardPage
    );
  }
}
