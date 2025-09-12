import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'recipe_detail_screen.dart';

class ChefRecipesScreen extends StatefulWidget {
  final int chefId;
  final String chefName;

  const ChefRecipesScreen({
    super.key,
    required this.chefId,
    required this.chefName,
  });

  @override
  State<ChefRecipesScreen> createState() => _ChefRecipesScreenState();
}

class _ChefRecipesScreenState extends State<ChefRecipesScreen> {
  List<dynamic> _recipes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchRecipes();
  }

  Future<void> _fetchRecipes() async {
    final uri = Uri.parse("http://localhost:8080/api/recipes/author/${widget.chefId}");
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      setState(() {
        _recipes = jsonDecode(response.body);
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.chefName} Tarifleri"),
        backgroundColor: Colors.deepOrange,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _recipes.isEmpty
              ? const Center(child: Text("Bu şefin henüz tarifi yok"))
              : ListView.builder(
                  itemCount: _recipes.length,
                  itemBuilder: (context, index) {
                    final recipe = _recipes[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(recipe["title"] ?? "Başlıksız"),
                        subtitle: Text(
                          (recipe["description"] ?? "").length > 50
                              ? recipe["description"].substring(0, 50) + "..."
                              : recipe["description"] ?? "",
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RecipeDetailScreen(recipe: recipe),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}