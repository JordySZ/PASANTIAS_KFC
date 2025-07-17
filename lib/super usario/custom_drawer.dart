import 'package:flutter/material.dart';
import '../../login/login.dart'; // Importación relativa ajustada a tu estructura

class CustomDrawer extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTap;

  CustomDrawer({
    Key? key,
    required this.selectedIndex,
    required this.onItemTap,
  }) : super(key: key);

  final List<String> _titles = [
    'Inicio',
    'Usuarios',
    'Crear nuevo procesos',
    'Cerrar sesión', // Nuevo ítem
  ];

  final List<IconData> _icons = [
    Icons.home,
    Icons.table_chart,
    Icons.settings,
    Icons.add_task,
    Icons.exit_to_app,
  ];

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Center(
              child: Text('Menú', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (int i = 0; i < _titles.length - 1; i++)
                  ListTile(
                    leading: Icon(
                      _icons[i],
                      color: selectedIndex == i ? Colors.blue : Colors.grey[700],
                    ),
                    title: Text(_titles[i]),
                    selected: selectedIndex == i,
                    selectedTileColor: Colors.blue[50],
                    onTap: () => onItemTap(i),
                  ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.exit_to_app, color: Colors.grey[700]),
            title: Text(_titles.last),
            onTap: () {
              Navigator.pop(context); // Cierra el drawer
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen1()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
