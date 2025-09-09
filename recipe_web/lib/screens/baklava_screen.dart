import 'package:flutter/material.dart';

class BaklavaScreen extends StatelessWidget {
  const BaklavaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Baklava")),
      body: const Center(
        child: Text(
          "Baklava Tarifi Burada Gözükecek",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}