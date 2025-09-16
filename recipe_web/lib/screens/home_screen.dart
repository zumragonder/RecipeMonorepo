import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'welcome_screen.dart';
import 'recipes_screen.dart';
import 'ingredients_screen.dart';
import 'chefs_screen.dart';
import 'settings_screen.dart';
import 'add_recipe_screen.dart';
import 'recipe_detail_screen.dart'; // ✔️ tarif detayına gitmek için

// 🔹 Anasayfa ekranı
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isCollapsed = false; // 🔹 Sidebar açık/kapalı durumunu takip eder

  List<dynamic> _recipes = []; // ✔️ backend’den gelecek tarif listesi

  @override
  void initState() {
    super.initState();
    _fetchRecipes();
  }

  Future<void> _fetchRecipes() async {
    final res = await http.get(
      Uri.parse("http://localhost:8080/api/recipes?page=0&size=4"), // ilk 4 tarif
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        _recipes = data["content"]; // Page<RecipeDto> JSON’undaki content
      });
    }
  }

  // 🔹 Çıkış yapma fonksiyonu
  void _signOut() async {
    await FirebaseAuth.instance.signOut(); // Firebase'den çıkış
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()), // WelcomeScreen’e dön
    );
  }

  Widget _buildMenuButton(String text, IconData icon, Widget page) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 10),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => page),
            );
          },
          borderRadius: BorderRadius.circular(8),
          splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          highlightColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _isCollapsed
                ? Center(
                    child: Icon(icon, color: Theme.of(context).iconTheme.color, size: 22),
                  )
                : Row(
                    children: [
                      Icon(icon, color: Theme.of(context).iconTheme.color, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        text,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // 🔹 Tarif kartlarını oluşturan fonksiyon
  Widget _buildRecipeCard(
      String title, String? imageBase64, int likes, Map<String, dynamic> recipe) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: recipe)),
        );
      },
      child: AspectRatio(
        aspectRatio: 2 / 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // 🔹 Arka plan resmi
              Positioned.fill(
                child: imageBase64 != null
                    ? Image.memory(
                        base64Decode(imageBase64),
                        fit: BoxFit.cover,
                      )
                    : Image.asset(
                        "assets/images/placeholder.png", // yedek resim
                        fit: BoxFit.cover,
                      ),
              ),

              // 🔹 Alt kısım: gradient efekt + yemek adı + beğeni sayısı
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: const [
                                Shadow(
                                  blurRadius: 4,
                                  color: Colors.black,
                                  offset: Offset(1, 1),
                                ),
                              ],
                            ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.favorite, color: Colors.red, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            "$likes",
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 Ekranın ana yapısı
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 🔹 Sol Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _isCollapsed ? 60 : 200,
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      _buildMenuButton("Tarifler", Icons.restaurant, const RecipesScreen()),
                      _buildMenuButton("Malzemeler", Icons.shopping_basket, const IngredientsScreen()),
                      _buildMenuButton("Şefler", Icons.person, const ChefsScreen()),
                      _buildMenuButton("Ayarlar", Icons.settings, const SettingsScreen()),

                      if (FirebaseAuth.instance.currentUser != null &&
                          FirebaseAuth.instance.currentUser!.providerData.isNotEmpty &&
                          (FirebaseAuth.instance.currentUser!.providerData[0].providerId == "google.com" ||
                              FirebaseAuth.instance.currentUser!.providerData[0].providerId == "facebook.com"))
                        _buildMenuButton("Tarif Ekle", Icons.add, const AddRecipeScreen()),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isCollapsed ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  onPressed: () {
                    setState(() {
                      _isCollapsed = !_isCollapsed;
                    });
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: _signOut,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.redAccent, width: 1.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: _isCollapsed
                          ? const Icon(Icons.logout, color: Colors.redAccent, size: 20)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.logout, color: Colors.redAccent, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  "Çıkış",
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 🔹 Sağ içerik alanı
          Expanded(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ListView(
                  children: [
                    Text(
                      "Haftanın Favorileri",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                    ),
                    const SizedBox(height: 20),

                    GridView.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 300, // her kart max 300px genişlik
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 2 / 1, // mevcut oranınızı koruyor
                      ),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _recipes.length,
                      itemBuilder: (context, index) {
                        final recipe = _recipes[index];
                        return _buildRecipeCard(
                          recipe["title"] ?? "Tarif",
                          recipe["imageBase64"], // varsa görsel
                          recipe["likeCount"] ?? 0,
                          recipe,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}