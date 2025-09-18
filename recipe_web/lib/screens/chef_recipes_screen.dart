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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.deepOrange),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          "${widget.chefName} Tarifleri",
          style: const TextStyle(
            color: Colors.deepOrange,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _recipes.isEmpty
              ? Center(
                  child: Text(
                    "Bu şefin henüz tarifi yok",
                    style: theme.textTheme.bodyMedium,
                  ),
                )
              : ListView.builder(
                  itemCount: _recipes.length,
                  itemBuilder: (context, index) {
                    final recipe = _recipes[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      color: theme.cardColor,
                      child: ListTile(
                        title: Text(
                          recipe["title"] ?? "Başlıksız",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface, // ✨ koyu temada beyaz, açık temada siyah
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          (recipe["description"] ?? "").length > 50
                              ? recipe["description"].substring(0, 50) + "..."
                              : recipe["description"] ?? "",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7), // ✨ daha açık ton
                          ),
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