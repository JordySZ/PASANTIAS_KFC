import 'package:flutter/material.dart';
import 'package:login_app/ROLES/A.R/ar.dart';
import 'package:login_app/ROLES/A.R/ar_user.dart' show DashboardAr_user;
import 'package:login_app/ROLES/A.R/solicitud.dart';
import 'package:login_app/ROLES/CONT/cont.dart';
import 'package:login_app/ROLES/CONT/cont_usert.dart';
import 'package:login_app/ROLES/CONT/tabla_solicitud.dart';
import 'package:login_app/ROLES/CX/cx.dart';
import 'package:login_app/ROLES/CX/cx_user.dart';
import 'package:login_app/ROLES/Operaciones/op.dart';
import 'package:login_app/ROLES/SD/sd.dart';
import 'package:login_app/ROLES/SD/sd_user.dart';
import 'package:login_app/ROLES/SIR/sir.dart';
import 'package:login_app/ROLES/SIR/sir_usert.dart';
import 'package:login_app/ROLES/swt/sw.dart';
import 'package:login_app/ROLES/swt/sw_usert.dart';
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
      home: DashboardAr(), //LoginScreen DashboardPage DashboardPage22
    );
  }
}
