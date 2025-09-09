import 'package:flutter/material.dart';

class IskenderScreen extends StatelessWidget {
  const IskenderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("İskender")),
      body: const Center(
        child: Text(
          "İskender Tarifi Burada Gözükecek",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}