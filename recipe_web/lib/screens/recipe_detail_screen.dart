import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer'; // log için

class RecipeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> recipe;
  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  int _likeCount = 0;
  bool _liked = false;
  bool _liking = false;

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _fetchLikes();
  }

  bool _isLoggedIn() {
    final u = _currentUser;
    if (u == null) return false;
    final providers = u.providerData.map((p) => p.providerId).toSet();
    return providers.contains('google.com') || providers.contains('facebook.com');
  }

  Future<void> _fetchLikes() async {
    final email = _currentUser?.email ?? "";
    final res = await http.get(
      Uri.parse("http://localhost:8080/api/recipes/${widget.recipe["id"]}/likes?email=$email"),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        _likeCount = (data["likeCount"] ?? data["count"] ?? 0) as int;
        _liked = (data["liked"] ?? false) as bool;
      });
    } else {
      log("⚠️ Likes fetch error: ${res.statusCode}");
    }
  }

  Future<void> _toggleLike() async {
    if (!_isLoggedIn()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Beğeni için giriş yapmalısınız.")),
      );
      return;
    }
    if (_liking) return;
    _liking = true;

    try {
      final email = _currentUser!.email;
      final res = await http.post(
        Uri.parse("http://localhost:8080/api/recipes/${widget.recipe["id"]}/likes/toggle?email=$email"),
      );

      if (res.statusCode == 200) {
        final result = jsonDecode(res.body);
        setState(() {
          _liked = (result["liked"] ?? false) as bool;
          _likeCount = (result["likeCount"] ?? result["count"] ?? 0) as int;
        });
      } else if (res.statusCode == 403) {
        final msg = res.body.isNotEmpty ? res.body : "Beğeni reddedildi (403).";
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Beğeni başarısız (${res.statusCode}).")),
        );
      }
    } finally {
      _liking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recipe = widget.recipe;
    final ingredients = recipe["ingredients"] as List? ?? [];
    final images = (recipe["imagesBase64"] as List?)?.cast<String>() ?? [];
    log("image: $images");

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
      recipe["title"] ?? "Tarif Detayı",
      style: const TextStyle(
        color: Colors.deepOrange,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),
  body: Scrollbar(
    thumbVisibility: true,
    child: SingleChildScrollView(
      // ...
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
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.image_not_supported,
                      size: 50, color: theme.iconTheme.color?.withOpacity(0.6)),
                ),

              const SizedBox(height: 16),

              // 👤 Ekleyen kişi
              if (recipe["authorEmail"] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    "Ekleyen: ${recipe["authorEmail"]}",
                    style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                  ),
                ),

              // 📖 Tarif açıklaması
              Text(
                recipe["description"] ?? "",
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              // 🥗 Malzemeler (turuncu)
              Text(
                "Malzemeler",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange, // turuncu
                ),
              ),
              const SizedBox(height: 8),
              if (ingredients.isNotEmpty)
                ...ingredients.map((ing) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        "- ${ing["amount"]} ${ing["unit"]} ${ing["name"]}",
                        style: theme.textTheme.bodyMedium,
                      ),
                    ))
              else
                Text("Hiç malzeme eklenmemiş.",
                    style: theme.textTheme.bodySmall),

              const SizedBox(height: 24),
              Divider(color: theme.dividerColor),

              // ❤️ Beğeni
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _liked ? Icons.favorite : Icons.favorite_border,
                      color: Colors.red,
                    ),
                    onPressed: _isLoggedIn() ? _toggleLike : null,
                  ),
                  Text("$_likeCount beğeni", style: theme.textTheme.bodyMedium),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔍 Tam ekran galeri
  void _openGallery(BuildContext context, List<String> images, int startIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _GalleryView(images: images, startIndex: startIndex),
      ),
    );
  }
}

/// 📸 Galeri ekranı
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