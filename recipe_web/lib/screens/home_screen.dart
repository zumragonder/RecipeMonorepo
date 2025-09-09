import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'welcome_screen.dart';
import 'recipes_screen.dart';
import 'ingredients_screen.dart';
import 'chefs_screen.dart';
import 'settings_screen.dart';
import 'add_recipe_screen.dart';

// Yeni ekranlar (özel yemek sayfaları)
import 'manti_screen.dart';
import 'iskender_screen.dart';
import 'lahmacun_screen.dart';
import 'baklava_screen.dart';

// 🔹 Anasayfa ekranı
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isCollapsed = false; // 🔹 Sidebar açık/kapalı durumunu takip eder

  // 🔹 Çıkış yapma fonksiyonu
  void _signOut() async {
    await FirebaseAuth.instance.signOut(); // Firebase'den çıkış
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()), // WelcomeScreen’e dön
    );
  }

  // 🔹 Sol menüdeki butonları oluşturan fonksiyon
  Widget _buildMenuButton(String text, IconData icon, Widget page) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 10),
      child: InkWell(
        onTap: () {
          // Butona tıklanınca ilgili sayfaya git
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => page),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white54,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _isCollapsed
              // Sidebar kapalıysa sadece ikon göster
              ? Center(
                  child: Icon(icon, color: Colors.white, size: 22),
                )
              // Açıkken ikon + yazı göster
              : Row(
                  children: [
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // 🔹 Tarif kartlarını oluşturan fonksiyon
  Widget _buildRecipeCard(
      String title, String imagePath, int likes, Widget page) {
    return InkWell(
      onTap: () {
        // Kart tıklanınca ilgili yemek ekranına git
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        );
      },
      child: AspectRatio(
        aspectRatio: 16 / 9, // Kart oranı sabit (16:9)
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // 🔹 Arka plan resmi (yemek fotoğrafı)
              Positioned.fill(
                child: Image.asset(
                  imagePath,
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
                      // Yemek adı
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              blurRadius: 4,
                              color: Colors.black,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                      // Beğeni sayısı
                      Row(
                        children: [
                          const Icon(Icons.favorite,
                              color: Colors.red, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            "$likes",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
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
            width: _isCollapsed ? 60 : 200, // Açık/kapalı genişlik
            color: Colors.black87,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Orta menü
                Expanded(
                  child: ListView(
                    children: [
                      _buildMenuButton(
                          "Tarifler", Icons.restaurant, const RecipesScreen()),
                      _buildMenuButton("Malzemeler", Icons.shopping_basket,
                          const IngredientsScreen()),
                      _buildMenuButton(
                          "Şefler", Icons.person, const ChefsScreen()),
                      _buildMenuButton("Ayarlar", Icons.settings,
                          const SettingsScreen()),

                      // 🔹 Tarif Ekle butonu sadece Google/Facebook kullanıcıları için
                      if (FirebaseAuth.instance.currentUser != null &&
                          FirebaseAuth.instance.currentUser!.providerData.isNotEmpty &&
                          (FirebaseAuth.instance.currentUser!.providerData[0].providerId == "google.com" ||
                           FirebaseAuth.instance.currentUser!.providerData[0].providerId == "facebook.com"))
                        _buildMenuButton("Tarif Ekle", Icons.add, const AddRecipeScreen()),
                    ],
                  ),
                ),

                // 🔹 Aç/kapa butonu (sidebar genişliğini değiştirir)
                IconButton(
                  icon: Icon(
                    _isCollapsed
                        ? Icons.arrow_forward_ios
                        : Icons.arrow_back_ios,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _isCollapsed = !_isCollapsed; // durum değiştir
                    });
                  },
                ),

                // 🔹 Alt kısım: Çıkış butonu
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: _signOut, // Çıkış yap
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: Colors.redAccent, width: 1.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: _isCollapsed
                          ? const Icon(Icons.logout,
                              color: Colors.redAccent, size: 20)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.logout,
                                    color: Colors.redAccent, size: 16),
                                const SizedBox(width: 6),
                                const Text(
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
              color: const Color.fromARGB(255, 34, 32, 32), // Arka plan rengi
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ListView(
                  children: [
                    // Başlık
                    const Text(
                      "Haftanın Favorileri",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 176, 173, 173),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Favori yemek kartları grid olarak gösterilir
                    GridView.count(
                      crossAxisCount: 2, // 2 sütun
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildRecipeCard("Mantı", "assets/images/mantı.png",
                            152, const MantiScreen()),
                        _buildRecipeCard("İskender",
                            "assets/images/iskender.png", 125, const IskenderScreen()),
                        _buildRecipeCard("Lahmacun",
                            "assets/images/lahmacun.png", 98, const LahmacunScreen()),
                        _buildRecipeCard("Baklava",
                            "assets/images/baklava.png", 97, const BaklavaScreen()),
                      ],
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