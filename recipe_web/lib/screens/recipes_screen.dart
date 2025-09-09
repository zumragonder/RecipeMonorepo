import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  List<dynamic> _recipes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchRecipes();
  }

  Future<void> _fetchRecipes() async {
    final response = await http.get(
      Uri.parse("http://localhost:8080/api/recipes?page=0&size=20"),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        _recipes = data["content"]; // Spring Page objesinin içinde "content" var
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tarifler"),
        backgroundColor: Colors.deepOrange,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _recipes.length,
              itemBuilder: (context, index) {
                final recipe = _recipes[index];
                return Card(
                  child: ListTile(
                    title: Text(recipe["title"] ?? "Başlıksız"),
                    subtitle: Text(recipe["description"] ?? ""),
                  ),
                );
              },
            ),
    );
  }
}