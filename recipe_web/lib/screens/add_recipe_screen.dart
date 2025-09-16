import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

/// Backend enum’ları (malzeme kategorileri)
const kCategories = <String>[
  'MEAT','SEAFOOD','DAIRY','VEGETABLE','FRUIT',
  'GRAIN','LEGUME','SPICE','OIL','SAUCE','OTHER',
];

/// UI etiketleri (malzeme kategorileri için)
const kCategoryLabels = {
  'MEAT':'Et',
  'SEAFOOD':'Deniz Ürünü',
  'DAIRY':'Süt Ürünü',
  'VEGETABLE':'Sebze',
  'FRUIT':'Meyve',
  'GRAIN':'Tahıl',
  'LEGUME':'Bakliyat',
  'SPICE':'Baharat',
  'OIL':'Yağ',
  'SAUCE':'Sos',
  'OTHER':'Diğer',
};

/// Tarif kategorileri (backend RecipeCategory enum ile aynı)
const kRecipeCategories = [
  "HEPSI",
  "TATLI",
  "TUZLU",
  "ICECEK",
  "VEGAN",
  "DIGER",
];

class AddRecipeScreen extends StatefulWidget {
  const AddRecipeScreen({super.key});
  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _desc = TextEditingController();

  List<dynamic> _pool = [];
  final List<_SelIng> _selected = [];

  bool _loadingPool = true;
  String? _msg;

  String _selectedCategory = 'OTHER';
  String? _selectedRecipeCategory;

  final _picker = ImagePicker();
  final List<Uint8List> _images = [];

  @override
  void initState() {
    super.initState();
    _fetchPool();
  }

  Future<void> _fetchPool() async {
    try {
      final uri = Uri.parse("http://localhost:8080/api/ingredients/all?category=$_selectedCategory");
      final r = await http.get(uri);
      if (r.statusCode == 200) {
        setState(() {
          _pool = jsonDecode(r.body);
          _loadingPool = false;
        });
      } else {
        setState(() {
          _loadingPool = false;
          _msg = "Malzeme havuzu alınamadı (${r.statusCode})";
        });
      }
    } catch (e) {
      setState(() {
        _loadingPool = false;
        _msg = "Havuz hatası: $e";
      });
    }
  }

  bool _isSocialLoggedIn() {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null || u.providerData.isEmpty) return false;
    final pid = u.providerData[0].providerId;
    return pid == "google.com" || pid == "facebook.com";
  }

  Future<void> _pickImages() async {
    try {
      final list = await _picker.pickMultiImage();
      if (list.isNotEmpty) {
        final bytesList = await Future.wait(list.map((x) => x.readAsBytes()));
        setState(() => _images.addAll(bytesList));
        return;
      }
      final one = await _picker.pickImage(source: ImageSource.gallery);
      if (one != null) {
        final bytes = await one.readAsBytes();
        setState(() => _images.add(bytes));
      }
    } catch (e) {
      setState(() => _msg = "Fotoğraf seçilemedi: $e");
    }
  }

  Future<void> _submitRecipe() async {
    if (!_isSocialLoggedIn()) {
      setState(() => _msg = "❌ Tarif eklemek için Google veya Facebook ile giriş yapın.");
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (email == null) {
      setState(() => _msg = "❌ Kullanıcı email alınamadı.");
      return;
    }

    final imagesBase64 = _images.map((b) => base64Encode(b)).toList();

    final body = {
      "title": _title.text.trim(),
      "description": _desc.text.trim(),
      "authorEmail": email,
      "ingredients": _selected.map((s) => {
        "ingredientId": s.ingredientId,
        "amount": s.amount.trim().isEmpty ? "1" : s.amount.trim(),
        "unit": s.unit.trim().isEmpty ? "adet" : s.unit.trim(),
      }).toList(),
      if (_selectedRecipeCategory != null) "category": _selectedRecipeCategory,
      if (imagesBase64.isNotEmpty) "imagesBase64": imagesBase64,
      if (imagesBase64.isNotEmpty) "imageBase64": imagesBase64.first,
    };

    try {
      final res = await http.post(
        Uri.parse("http://localhost:8080/api/recipes"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        setState(() {
          _msg = "✅ Tarif eklendi";
          _title.clear();
          _desc.clear();
          _selected.clear();
          _images.clear();
          _selectedRecipeCategory = null;
        });
        if (mounted) Navigator.pop(context, true);
      } else {
        setState(() => _msg = "❌ Kayıt hatası: ${res.body}");
      }
    } catch (e) {
      setState(() => _msg = "❌ Ağ hatası: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canAdd = _isSocialLoggedIn();

    InputDecoration _input(String label) => InputDecoration(
      labelText: label,
      labelStyle: theme.textTheme.bodyMedium,
      hintStyle: theme.textTheme.bodySmall,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: theme.colorScheme.primary),
        borderRadius: BorderRadius.circular(8),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text("Tarif Ekle")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loadingPool
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _title,
                      style: theme.textTheme.bodyMedium,
                      cursorColor: theme.colorScheme.primary,
                      decoration: _input("Tarif Başlığı"),
                      validator: (v) => (v == null || v.trim().isEmpty) ? "Başlık giriniz" : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _desc,
                      maxLines: 8,
                      style: theme.textTheme.bodyMedium,
                      cursorColor: theme.colorScheme.primary,
                      decoration: _input("Tarif Açıklaması"),
                      validator: (v) => (v == null || v.trim().isEmpty) ? "Açıklama giriniz" : null,
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _selectedRecipeCategory,
                      decoration: _input("Tarif Kategorisi"),
                      dropdownColor: theme.cardColor,
                      style: theme.textTheme.bodyMedium,
                      items: kRecipeCategories.map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text(c, style: theme.textTheme.bodyMedium),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedRecipeCategory = v),
                      validator: (v) => v == null ? "Kategori seçiniz" : null,
                    ),
                    const SizedBox(height: 16),

                    // 📸 Fotoğraflar
                    if (_images.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _images.map((img) {
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(img, width: 100, height: 100, fit: BoxFit.cover),
                              ),
                              Positioned(
                                right: 0, top: 0,
                                child: IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white),
                                  onPressed: () => setState(() => _images.remove(img)),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ElevatedButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.photo_library),
                      label: const Text("Fotoğraf(lar) Seç"),
                    ),
                    const SizedBox(height: 16),

                    // 🧾 Malzeme seçimi (kısaltılmış, benzer mantıkla theme uyumlu yapılabilir)
                    Text("Malzemeler", style: theme.textTheme.bodyMedium),
                    // ...

                    const SizedBox(height: 20),

                    if (!canAdd)
                      Text(
                        "Anonim kullanıcılar tarif ekleyemez. Google/Facebook ile giriş yapın.",
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: canAdd
                          ? () {
                              if (_formKey.currentState!.validate()) _submitRecipe();
                            }
                          : null,
                      child: const Text("Kaydet"),
                    ),
                    if (_msg != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _msg!,
                        style: TextStyle(
                          color: _msg!.startsWith("✅") ? Colors.green : theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

class _SelIng {
  final int ingredientId;
  final String name;
  String amount;
  String unit;
  _SelIng(this.ingredientId, {required this.name, this.amount = "1", this.unit = "adet"});
}