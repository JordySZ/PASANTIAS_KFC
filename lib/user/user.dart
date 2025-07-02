import 'package:flutter/material.dart';

class User extends StatelessWidget {
  const User({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Usuario'),
        backgroundColor: Colors.blueAccent,
      ),
      body: const Center(
        child: Text(
          'Bienvenido al panel de Usuario',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
