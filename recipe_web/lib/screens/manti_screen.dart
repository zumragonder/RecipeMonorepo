import 'package:flutter/material.dart';

class MantiScreen extends StatelessWidget {
  const MantiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mantı")),
      body: const Center(
        child: Text(
          "Mantı Tarifi Burada Gözükecek",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}