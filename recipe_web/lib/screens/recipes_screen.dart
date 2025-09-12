import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'recipe_detail_screen.dart';

/// Backend RecipeCategory enum (sekme isimleri)
const kRecipeCategories = [
  "HEPSI",   // özel, tüm tarifler
  "TATLI",
  "TUZLU",
  "ICECEK",
  "VEGAN",
  "DIGER",
];

/// UI için Türkçe etiketler
const kRecipeCategoryLabels = {
  "HEPSI": "Hepsi",
  "TATLI": "Tatlılar",
  "TUZLU": "Tuzlular",
  "ICECEK": "İçecekler",
  "VEGAN": "Vegan",
  "DIGER": "Diğer",
};

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  List<dynamic> _recipes = [];
  bool _loading = true;
  String _selectedCategory = "HEPSI";

  @override
  void initState() {
    super.initState();
    _fetchRecipes("HEPSI"); // başlangıçta tüm tarifler
  }

  Future<void> _fetchRecipes(String category) async {
    setState(() {
      _loading = true;
      _recipes = [];
    });

    Uri uri;
    if (category == "HEPSI") {
      uri = Uri.parse("http://localhost:8080/api/recipes?page=0&size=20");
    } else {
      uri = Uri.parse("http://localhost:8080/api/recipes/category/$category");
    }

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        if (category == "HEPSI") {
          _recipes = data["content"]; // Page response
        } else {
          _recipes = data; // List response
        }
        _loading = false;
        _selectedCategory = category;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tarifler"),
        backgroundColor: Colors.deepOrange,
      ),
      body: Row(
        children: [
          // 🔹 Sol tarafta kategoriler
          Container(
            width: 150,
            color: Colors.black,
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: kRecipeCategories.map((cat) {
                final isSelected = cat == _selectedCategory;
                return Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ElevatedButton(
                    onPressed: () => _fetchRecipes(cat),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isSelected ? Colors.deepOrange : Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Colors.white24),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Center(
                      child: Text(
                        kRecipeCategoryLabels[cat] ?? cat,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // 🔹 Sağ tarafta tarifler
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _recipes.isEmpty
                    ? const Center(child: Text("Tarif bulunamadı"))
                    : ListView.builder(
                        itemCount: _recipes.length,
                        itemBuilder: (context, index) {
                          final recipe = _recipes[index];

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: ListTile(
                              leading: recipe["imageBase64"] != null
                                  ? Image.memory(
                                      base64Decode(recipe["imageBase64"]),
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(Icons.image_not_supported,
                                      size: 40),
                              title: Text(recipe["title"] ?? "Başlıksız"),
                              subtitle: Text(
                                (recipe["description"] ?? "").length > 50
                                    ? recipe["description"].substring(0, 50) +
                                        "..."
                                    : recipe["description"] ?? "",
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        RecipeDetailScreen(recipe: recipe),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}