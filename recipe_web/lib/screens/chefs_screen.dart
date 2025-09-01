import 'package:flutter/material.dart';

class ChefsScreen extends StatelessWidget {
  const ChefsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Şefler"),
        backgroundColor: Colors.deepOrange,
      ),
      body: const Center(
        child: Text(
          "Şefler Sayfası (içerik sonra eklenecek)",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}