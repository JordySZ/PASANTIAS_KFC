import 'package:flutter/material.dart';

class GerenciaScreen extends StatelessWidget {
  const GerenciaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Gerencia'),
        backgroundColor: Colors.teal,
      ),
      body: const Center(
        child: Text(
          'Bienvenido al panel de Gerencia',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
