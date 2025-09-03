import 'package:flutter/material.dart';

class RecipesScreen extends StatelessWidget {
  const RecipesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tarifler"),
        backgroundColor: Colors.deepOrange,
      ),
      body: const Center(
        child: Text(
          "Tarifler Sayfası (içerik sonra eklenecek)",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
} 