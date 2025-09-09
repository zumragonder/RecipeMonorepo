import 'package:flutter/material.dart';

class LahmacunScreen extends StatelessWidget {
  const LahmacunScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Lahmacun")),
      body: const Center(
        child: Text(
          "Lahmacun Tarifi Burada Gözükecek",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}