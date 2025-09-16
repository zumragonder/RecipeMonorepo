import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'recipe_detail_screen.dart';

class IngredientsScreen extends StatefulWidget {
  const IngredientsScreen({super.key});

  @override
  State<IngredientsScreen> createState() => _IngredientsScreenState();
}

class _IngredientsScreenState extends State<IngredientsScreen> {
  String _selectedCategory = "OTHER";
  List<dynamic> _ingredients = [];
  List<dynamic> _selectedIngredients = [];
  List<dynamic> _recipes = [];

  final categories = [
    {"key": "MEAT", "label": "Et"},
    {"key": "SEAFOOD", "label": "Deniz Ürünü"},
    {"key": "DAIRY", "label": "Süt Ürünü"},
    {"key": "VEGETABLE", "label": "Sebze"},
    {"key": "FRUIT", "label": "Meyve"},
    {"key": "GRAIN", "label": "Tahıl"},
    {"key": "LEGUME", "label": "Bakliyat"},
    {"key": "SPICE", "label": "Baharat"},
    {"key": "OIL", "label": "Yağ"},
    {"key": "SAUCE", "label": "Sos"},
    {"key": "OTHER", "label": "Diğer"},
  ];

  @override
  void initState() {
    super.initState();
    _fetchIngredients();
  }

  Future<void> _fetchIngredients() async {
    final res = await http.get(
      Uri.parse("http://localhost:8080/api/ingredients/all?category=$_selectedCategory"),
    );
    if (res.statusCode == 200) {
      setState(() {
        _ingredients = jsonDecode(res.body);
      });
    }
  }

  void _toggleIngredient(dynamic ing, bool select) {
    setState(() {
      if (select) {
        if (_selectedIngredients.length < 10 &&
            !_selectedIngredients.contains(ing)) {
          _selectedIngredients.add(ing);
        }
      } else {
        _selectedIngredients.remove(ing);
      }
    });
  }

  Future<void> _searchRecipes() async {
    final ids = _selectedIngredients.map((i) => i["id"]).toList();
    final res = await http.get(
      Uri.parse("http://localhost:8080/api/recipes/suggestAll?ingredientIds=${ids.join(",")}"),
    );
    if (res.statusCode == 200) {
      setState(() {
        _recipes = jsonDecode(res.body)["content"];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // 👈 Tema bilgisi

    return Scaffold(
      appBar: AppBar(
        title: const Text("Malzemeler"),
        backgroundColor: theme.colorScheme.primary,
      ),
      body: Column(
        children: [
          // 🔹 Kategoriler
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                final isSelected = _selectedCategory == cat["key"];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(
                      cat["label"]!,
                      style: TextStyle(
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: theme.colorScheme.primary,
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = cat["key"]!;
                      });
                      _fetchIngredients();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Divider(color: theme.dividerColor),

          // 🔹 Malzemeler listesi
          Expanded(
            child: ListView.builder(
              itemCount: _ingredients.length,
              itemBuilder: (context, index) {
                final ing = _ingredients[index];
                final isSelected = _selectedIngredients.contains(ing);
                return ListTile(
                  title: Text(
                    ing["name"],
                    style: theme.textTheme.bodyMedium,
                  ),
                  trailing: Checkbox(
                    value: isSelected,
                    onChanged: (val) {
                      _toggleIngredient(ing, val ?? false);
                    },
                  ),
                  onTap: () {
                    _toggleIngredient(ing, !isSelected);
                  },
                );
              },
            ),
          ),

          // 🔹 Seçilenler
          Wrap(
            spacing: 6,
            children: _selectedIngredients
                .map((ing) => Chip(
                      label: Text(ing["name"]),
                      onDeleted: () {
                        setState(() {
                          _selectedIngredients.remove(ing);
                        });
                      },
                      backgroundColor: theme.chipTheme.backgroundColor,
                      labelStyle: theme.textTheme.bodyMedium,
                    ))
                .toList(),
          ),

          // 🔹 Tarifler listesi
          if (_recipes.isNotEmpty) ...[
            Divider(color: theme.dividerColor),
            Expanded(
              child: ListView.builder(
                itemCount: _recipes.length,
                itemBuilder: (context, index) {
                  final recipe = _recipes[index];
                  return ListTile(
                    title: Text(
                      recipe["title"],
                      style: theme.textTheme.bodyMedium,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RecipeDetailScreen(recipe: recipe),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],

          // 🔹 Ara butonu
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text("Tarifleri Ara"),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              onPressed: _searchRecipes,
            ),
          ),
        ],
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
    );
  }
}