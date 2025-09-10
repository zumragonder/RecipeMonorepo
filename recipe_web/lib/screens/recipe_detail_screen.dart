import 'dart:convert';
//import 'dart:nativewrappers/_internal/vm/lib/internal_patch.dart';
import 'package:flutter/material.dart';
import 'dart:developer'; // log için

class RecipeDetailScreen extends StatelessWidget {
  final Map<String, dynamic> recipe;
  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    final ingredients = recipe["ingredients"] as List? ?? [];
    final images = (recipe["imagesBase64"] as List?)?.cast<String>() ?? [];
    // if (images.isEmpty){
    //   images.add(recipe["imageBase64"]); // Tek resim varsa ekle
    // }
    log("image: $images");
    return Scaffold(
      appBar: AppBar(
        title: Text(recipe["title"] ?? "Tarif"),
        backgroundColor: Colors.deepOrange,
      ),
      body: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 📸 Çoklu fotoğraf galerisi
              if (images.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: images.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      return GestureDetector(
                        onTap: () => _openGallery(context, images, i),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            base64Decode(images[i]),
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.image_not_supported,
                        size: 50, color: Colors.white54),
                  ),
                ),

              const SizedBox(height: 16),

              // 📖 Tarif açıklaması
              Text(
                recipe["description"] ?? "",
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
              const SizedBox(height: 24),

              // 🥗 Malzemeler başlığı
              const Text(
                "Malzemeler",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),

              if (ingredients.isNotEmpty)
                ...ingredients.map((ing) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        "- ${ing["amount"]} ${ing["unit"]} ${ing["name"]}",
                        style: const TextStyle(
                            fontSize: 15, color: Colors.white),
                      ),
                    ))
              else
                const Text(
                  "Hiç malzeme eklenmemiş.",
                  style: TextStyle(fontSize: 15, color: Colors.white70),
                ),
            ],
          ),
        ),
      ),
      backgroundColor: const Color(0xFF222020),
    );
  }

  /// 🔍 Tam ekran galeri aç
  void _openGallery(BuildContext context, List<String> images, int startIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _GalleryView(images: images, startIndex: startIndex),
      ),
    );
  }
}

/// 📸 Tam ekran galeri
class _GalleryView extends StatefulWidget {
  final List<String> images;
  final int startIndex;
  const _GalleryView({required this.images, this.startIndex = 0});

  @override
  State<_GalleryView> createState() => _GalleryViewState();
}

class _GalleryViewState extends State<_GalleryView> {
  late PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.startIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.images.length,
        itemBuilder: (_, i) {
          return InteractiveViewer(
            child: Center(
              child: Image.memory(
                base64Decode(widget.images[i]),
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}