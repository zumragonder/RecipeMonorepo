import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'recipe_detail_screen.dart';

/// Backend RecipeCategory enum (sekme isimleri)
const kRecipeCategories = [
  "HEPSI",    
  "TATLI",
  "HAMUR_ISI", 
  "ANA_YEMEK", 
  "CORBA",     
  "ICECEK",
  "VEGAN",
  "DIGER",
];

/// UI için Türkçe etiketler
const kRecipeCategoryLabels = {
  "HEPSI": "Hepsi",
  "TATLI": "Tatlılar",
  "HAMUR_ISI": "Hamur İşleri",
  "ANA_YEMEK": "Ana Yemekler", 
  "CORBA": "Çorbalar",        
  "ICECEK": "İçecekler",
  "VEGAN": "Vegan",
  "DIGER": "Diğer",
};

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _recipes = [];
  bool _loading = true;
  String _selectedCategory = "HEPSI";

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: kRecipeCategories.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      final cat = kRecipeCategories[_tabController.index];
      _fetchRecipes(cat);
    });
    _fetchRecipes("HEPSI");
  }

  Future<void> _fetchRecipes(String category) async {
    setState(() {
      _loading = true;
      _recipes = [];
      _selectedCategory = category;
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
      });
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.deepOrange),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Tarifler",
          style: TextStyle(
            color: Colors.deepOrange,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.deepOrange,
          labelColor: Colors.deepOrange,
          unselectedLabelColor: theme.brightness == Brightness.light
              ? Colors.black87   // açık temada siyah
              : Colors.white70,  // koyu temada gri
          tabs: kRecipeCategories
              .map((c) => Tab(text: kRecipeCategoryLabels[c] ?? c))
              .toList(),
        ),
      ),
      body: _loading
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
                            : const Icon(Icons.image_not_supported, size: 40),
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
                              builder: (_) =>
                                  RecipeDetailScreen(recipe: recipe),
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