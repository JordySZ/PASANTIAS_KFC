import 'package:flutter/material.dart';

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
    'Usarios',
    'Procesos',
    'Crear nuevo procesos',
  ];

  final List<IconData> _icons = [
    Icons.home,
    Icons.table_chart,
    Icons.settings,
    Icons.add_task,
  ];

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Center(
              child: Text('Menú', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
          ),
          for (int i = 0; i < _titles.length; i++)
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
    );
  }
}
