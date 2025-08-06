import 'package:flutter/material.dart';
import '../../login/login.dart';

class tablasoli extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTap;

  tablasoli({
    Key? key,
    required this.selectedIndex,
    required this.onItemTap,
  }) : super(key: key);

  // Colores empresariales
  final Color primaryColor = Colors.red[900]!;
  final Color secondaryColor = Colors.grey[800]!;
  final Color backgroundColor = Colors.white;
  final Color textColor = Colors.black;
  final Color lightGrey = Colors.grey[300]!;
  final Color mediumGrey = Colors.grey[500]!;
  final Color darkGrey = Colors.grey[700]!;

  final List<String> _titles = [
    'Inicio',
    'Usuarios',
    'Tabla Proceso',
    'Tabla de Solicitud de Proceso',
    'Cerrar sesión',
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
          DrawerHeader(
            decoration: BoxDecoration(color: primaryColor),
            child: Center(
              child: Text(
                'Menú', 
                style: TextStyle(
                  color: backgroundColor, 
                  fontSize: 24,
                  fontWeight: FontWeight.bold
                )
              ),
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
                      color: selectedIndex == i 
                          ? primaryColor 
                          : secondaryColor,
                    ),
                    title: Text(
                      _titles[i],
                      style: TextStyle(
                        color: selectedIndex == i 
                            ? primaryColor 
                            : secondaryColor,
                        fontWeight: selectedIndex == i 
                            ? FontWeight.bold 
                            : FontWeight.normal,
                      ),
                    ),
                    selected: selectedIndex == i,
                    selectedTileColor: lightGrey,
                    onTap: () => onItemTap(i),
                  ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.exit_to_app, 
              color: secondaryColor
            ),
            title: Text(
              _titles.last, 
              style: TextStyle(
                color: secondaryColor,
                fontWeight: FontWeight.w500
              )
            ),
            onTap: () {
              Navigator.pop(context);
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