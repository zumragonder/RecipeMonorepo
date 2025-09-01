import 'package:flutter/material.dart';

class IngredientsScreen extends StatelessWidget {
  const IngredientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Malzemeler"),
        backgroundColor: Colors.deepOrange,
      ),
      body: const Center(
        child: Text(
          "Malzemeler Sayfası (içerik sonra eklenecek)",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}