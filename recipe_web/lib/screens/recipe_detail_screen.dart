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
  List<dynamic> _comments = [];
  final _commentCtrl = TextEditingController();

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _fetchLikes();
    _fetchComments();
    _checkIfLiked();
  }

  bool _isLoggedIn() {
    return _currentUser != null &&
        _currentUser!.providerData.isNotEmpty &&
        (_currentUser!.providerData[0].providerId == "google.com" ||
            _currentUser!.providerData[0].providerId == "facebook.com");
  }

  Future<void> _fetchLikes() async {
    final res = await http.get(
      Uri.parse("http://localhost:8080/api/recipes/${widget.recipe["id"]}/likes/count"),
    );
    if (res.statusCode == 200) {
      setState(() => _likeCount = jsonDecode(res.body));
    }
  }

  Future<void> _checkIfLiked() async {
    if (!_isLoggedIn()) return;
    final email = _currentUser!.email;
    final res = await http.get(
      Uri.parse("http://localhost:8080/api/recipes/${widget.recipe["id"]}/likes/check?email=$email"),
    );
    if (res.statusCode == 200) {
      setState(() => _liked = jsonDecode(res.body));
    }
  }

  Future<void> _toggleLike() async {
    if (!_isLoggedIn()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Beğeni için giriş yapmalısınız.")),
      );
      return;
    }

    final email = _currentUser!.email;
    final res = await http.post(
      Uri.parse("http://localhost:8080/api/recipes/${widget.recipe["id"]}/likes/toggle?email=$email"),
    );

    if (res.statusCode == 200) {
      setState(() {
        AlertDialog.adaptive(
          title: const Text("Beğeni durumu değişti"),
          content: Text(_liked ? "Beğeniniz kaldırıldı." : "Tarifi beğendiniz."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Tamam"),
            ),
          ],
        );
        final result = jsonDecode(res.body); 
        _liked =result["liked"] as bool;
        _likeCount = result["likeCount"] as int;
       // _liked = result.contains("liked");
      });
    }


    // final res1 = await http.get(
    //   Uri.parse("http://localhost:8080/api/recipes/${widget.recipe["id"]}/likes/count"),
    // );
    // if (res1.statusCode == 200) {
    //   setState(() => _likeCount = jsonDecode(res1.body));
    // }
  }

  Future<void> _fetchComments() async {
    final res = await http.get(
      Uri.parse("http://localhost:8080/api/recipes/${widget.recipe["id"]}/comments"),
    );
    if (res.statusCode == 200) {
      setState(() => _comments = jsonDecode(res.body));
    }
  }

  Future<void> _addComment() async {
    if (!_isLoggedIn()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Yorum yapmak için giriş yapmalısınız.")),
      );
      return;
    }

    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;

    final email = _currentUser!.email;
    final res = await http.post(
      Uri.parse("http://localhost:8080/api/recipes/${widget.recipe["id"]}/comments?email=$email"),
      headers: {"Content-Type": "text/plain"}, // düz text
      body: text,
    );

    if (res.statusCode == 200) {
      _commentCtrl.clear();
      _fetchComments();
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final ingredients = recipe["ingredients"] as List? ?? [];
    final images = (recipe["imagesBase64"] as List?)?.cast<String>() ?? [];
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

              // 👤 Ekleyen kişi
              if (recipe["authorEmail"] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    "Ekleyen: ${recipe["authorEmail"]}",
                    style: const TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.white70,
                    ),
                  ),
                ),

              // 📖 Tarif açıklaması
              Text(
                recipe["description"] ?? "",
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
              const SizedBox(height: 24),

              // 🥗 Malzemeler
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

              const SizedBox(height: 24),
              const Divider(color: Colors.white30),

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
                  Text("$_likeCount beğeni",
                      style: const TextStyle(color: Colors.white)),
                ],
              ),

              const Divider(color: Colors.white30),

              // 💬 Yorumlar
              const Text("Yorumlar",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 8),
              if (_comments.isEmpty)
                const Text("Henüz yorum yok.",
                    style: TextStyle(color: Colors.white70))
              else
                ..._comments.map((c) => ListTile(
                      title: Text(c["userEmail"] ?? "Anonim",
                          style: const TextStyle(color: Colors.white)),
                      subtitle: Text(c["text"],
                          style: const TextStyle(color: Colors.white70)),
                    )),

              const SizedBox(height: 12),

              // ✍️ Yorum yaz
              if (_isLoggedIn())
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: "Yorum yaz...",
                          hintStyle: TextStyle(color: Colors.white54),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.deepOrange),
                      onPressed: _addComment,
                    )
                  ],
                )
              else
                const Text(
                  "Yorum yapmak için giriş yapın.",
                  style: TextStyle(color: Colors.orange),
                ),
            ],
          ),
        ),
      ),
      backgroundColor: const Color(0xFF222020),
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