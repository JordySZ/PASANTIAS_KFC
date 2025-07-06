import 'package:flutter/material.dart';
import 'package:login_app/user/crud_user.dart';
import 'package:login_app/user/custom_drawer.dart';
import 'package:login_app/user/home_page.dart';
import 'package:login_app/user/user.dart';
// Asegúrate de importar tu archivo donde está definido CustomDrawer


class ProcesosRud extends StatelessWidget {
  const ProcesosRud({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Procesos'),
        backgroundColor: Colors.teal,
      ),
      drawer: CustomDrawer(
        selectedIndex: 2, // Índice que representa esta pantalla en el menú
        onItemTap: (index) {
          Navigator.pop(context); // Cierra el drawer
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => DashboardPage()),
            );
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => UsuariosScreen()),
            );
          } else if (index == 2) {
            // Ya estás en ProcesosRud, no hagas nada
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => TableroScreen()),
            );
          }
        },
      ),
      body: const Center(
        child: Text(
          'Bienvenido al panel de Procesos',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

