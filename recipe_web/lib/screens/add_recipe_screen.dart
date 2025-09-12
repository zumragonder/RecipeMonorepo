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
  "HEPSI",   // özel, tüm tarifler
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

  List<dynamic> _pool = []; // havuzdaki malzemeler
  final List<_SelIng> _selected = []; // seçilen malzemeler

  bool _loadingPool = true;
  String? _msg;

  String _selectedCategory = 'OTHER'; // malzeme kategorisi
  String? _selectedRecipeCategory;    // tarif kategorisi

  /// Çoklu görsel (web + mobil)
  final _picker = ImagePicker();
  final List<Uint8List> _images = [];

  // ---- stil
  late final OutlineInputBorder _whiteBorder =
      OutlineInputBorder(borderSide: const BorderSide(color: Colors.white70), borderRadius: BorderRadius.circular(8));
  InputDecoration _whiteInput(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
        hintStyle: const TextStyle(color: Colors.white70),
        enabledBorder: _whiteBorder,
        focusedBorder: _whiteBorder.copyWith(borderSide: const BorderSide(color: Colors.white)),
        border: _whiteBorder,
      );
  ButtonStyle get _primaryBtnStyle => ElevatedButton.styleFrom(
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      );

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
      // Çoklu seçim (mobil + web destekli)
      final list = await _picker.pickMultiImage();
      if (list.isNotEmpty) {
        final bytesList = await Future.wait(list.map((x) => x.readAsBytes()));
        setState(() => _images.addAll(bytesList));
        return;
      }

      // Eğer cihaz pickMultiImage desteklemiyorsa tekli fallback
      final one = await _picker.pickImage(source: ImageSource.gallery);
      if (one != null) {
        final bytes = await one.readAsBytes();
        setState(() {
          _images.add(bytes);
        });
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
    "authorEmail": email,   // ✅ artık email gönderiyoruz
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
  Future<void> _showAddIngredientDialog() async {
    final nameCtrl = TextEditingController();
    String cat = _selectedCategory;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text("Havuza yeni malzeme ekle", style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                  decoration: _whiteInput("Malzeme adı"),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: cat,
                  dropdownColor: const Color(0xFF2A2A2A),
                  style: const TextStyle(color: Colors.white),
                  iconEnabledColor: Colors.white,
                  decoration: _whiteInput("Kategori"),
                  items: kCategories.map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(kCategoryLabels[c] ?? c, style: const TextStyle(color: Colors.white)),
                  )).toList(),
                  onChanged: (v) => setLocal(() => cat = v ?? 'OTHER'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Vazgeç", style: TextStyle(color: Colors.white)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: _primaryBtnStyle,
                child: const Text("Ekle"),
              ),
            ],
          );
        },
      ),
    );

    final name = nameCtrl.text.trim();
    if (ok == true && name.isNotEmpty) {
      try {
        final res = await http.post(
          Uri.parse("http://localhost:8080/api/ingredients"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"name": name, "category": cat}),
        );

        if (res.statusCode == 200) {
          final ing = jsonDecode(res.body);
          setState(() {
            if (ing["category"] == _selectedCategory) {
              _pool.add(ing);
            }
            _msg = "✅ \"${ing["name"]}\" havuza eklendi";
          });
        } else if (res.statusCode == 409) {
          final body = jsonDecode(res.body);
          final exist = body["data"];
          setState(() {
            _msg = "ℹ️ \"${exist["name"]}\" zaten ${kCategoryLabels[exist["category"]]} kategorisinde mevcut.";
            if (exist["category"] == _selectedCategory && !_pool.any((p) => p["id"] == exist["id"])) {
              _pool.add(exist);
            }
          });
        } else {
          setState(() => _msg = "❌ Malzeme eklenemedi: ${res.body}");
        }
      } catch (e) {
        setState(() => _msg = "❌ Ağ hatası: $e");
      }
    }
  }

  Widget _categoryChips() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: kCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final c = kCategories[i];
          final selected = c == _selectedCategory;
          return ChoiceChip(
            label: Text(
              kCategoryLabels[c] ?? c,
              style: TextStyle(color: selected ? Colors.black : Colors.white),
            ),
            selectedColor: Colors.deepOrange,
            backgroundColor: const Color(0xFF2A2A2A),
            selected: selected,
            onSelected: (_) async {
              setState(() {
                _selectedCategory = c;
                _loadingPool = true;
                _pool = [];
              });
              await _fetchPool();
            },
          );
        },
      ),
    );
  }

  Widget _ingredientPicker() {
    int? pickedId;
    final amountCtrl = TextEditingController(text: "1");
    final unitCtrl = TextEditingController(text: "adet");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _categoryChips(),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          items: _pool.map<DropdownMenuItem<int>>((it) => DropdownMenuItem(
            value: it["id"],
            child: Text(it["name"], style: const TextStyle(color: Colors.white)),
          )).toList(),
          onChanged: (v) => pickedId = v,
          decoration: _whiteInput("Havuzdan malzeme seç"),
          style: const TextStyle(color: Colors.white),
          dropdownColor: Colors.black87,
          iconEnabledColor: Colors.white,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: amountCtrl,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: _whiteInput("Miktar"),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: unitCtrl,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: _whiteInput("Birim"),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                if (pickedId != null) {
                  final ing = _pool.firstWhere(
                    (p) => p["id"] == pickedId,
                    orElse: () => {"id": pickedId, "name": "Malzeme"},
                  );
                  setState(() {
                    _selected.add(_SelIng(
                      pickedId!,
                      amount: amountCtrl.text,
                      unit: unitCtrl.text,
                      name: ing["name"],
                    ));
                    _msg = null;
                  });
                } else {
                  setState(() => _msg = "Lütfen önce havuzdan bir malzeme seçin.");
                }
              },
              style: _primaryBtnStyle,
              child: const Text("Ekle"),
            )
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text("Havuza yeni malzeme ekle", style: TextStyle(color: Colors.white)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.white70),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onPressed: _showAddIngredientDialog,
        ),
        const SizedBox(height: 12),
        if (_selected.isNotEmpty)
          const Text("Seçilenler", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        ..._selected.map((s) {
          return ListTile(
            dense: true,
            title: Text("${s.name}  •  ${s.amount} ${s.unit}", style: const TextStyle(color: Colors.white)),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.white70),
              onPressed: () => setState(() => _selected.remove(s)),
            ),
          );
        }),
      ],
    );
  }

  Widget _imagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_images.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(_images[i], width: 100, height: 100, fit: BoxFit.cover),
                  ),
                  Positioned(
                    right: 0, top: 0,
                    child: InkWell(
                      onTap: () => setState(() => _images.removeAt(i)),
                      child: Container(
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.close, size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _pickImages,
          icon: const Icon(Icons.photo_library),
          label: const Text("Fotoğraf(lar) Seç"),
          style: _primaryBtnStyle,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final canAdd = _isSocialLoggedIn();

    return Scaffold(
      appBar: AppBar(title: const Text("Tarif Ekle"), backgroundColor: Colors.deepOrange),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loadingPool
            ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _title,
                      style: const TextStyle(color: Colors.white),
                      cursorColor: Colors.white,
                      decoration: _whiteInput("Tarif Başlığı"),
                      validator: (v) => (v == null || v.trim().isEmpty) ? "Başlık giriniz" : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _desc,
                      maxLines: 8,
                      style: const TextStyle(color: Colors.white),
                      cursorColor: Colors.white,
                      decoration: _whiteInput("Tarif Açıklaması"),
                      validator: (v) => (v == null || v.trim().isEmpty) ? "Açıklama giriniz" : null,
                    ),
                    const SizedBox(height: 16),

                    // 🍽 Tarif kategorisi dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedRecipeCategory,
                      decoration: _whiteInput("Tarif Kategorisi"),
                      dropdownColor: const Color(0xFF2A2A2A),
                      style: const TextStyle(color: Colors.white),
                      iconEnabledColor: Colors.white,
                      items: kRecipeCategories.map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text(c, style: const TextStyle(color: Colors.white)),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedRecipeCategory = v),
                      validator: (v) => v == null ? "Kategori seçiniz" : null,
                    ),
                    const SizedBox(height: 16),

                    // 📸 Fotoğraflar
                    _imagesSection(),
                    const SizedBox(height: 16),

                    // 🧾 Malzeme seçimi
                    _ingredientPicker(),
                    const SizedBox(height: 20),

                    if (!canAdd)
                      const Text(
                        "Anonim kullanıcılar tarif ekleyemez. Google/Facebook ile giriş yapın.",
                        style: TextStyle(color: Colors.orange),
                      ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: canAdd
                          ? () {
                              if (_formKey.currentState!.validate()) _submitRecipe();
                            }
                          : null,
                      style: _primaryBtnStyle,
                      child: const Text("Kaydet"),
                    ),
                    if (_msg != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _msg!,
                        style: TextStyle(
                          color: _msg!.startsWith("✅") ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
      backgroundColor: const Color(0xFF222020),
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