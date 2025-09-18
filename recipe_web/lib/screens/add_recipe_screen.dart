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

/// UI etiketleri
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

/// Backend RecipeCategory enum
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
  "TATLI": "Tatlı",
  "HAMUR_ISI": "Hamur İşi",
  "ANA_YEMEK": "Ana Yemek",
  "CORBA": "Çorba",
  "ICECEK": "İçecek",
  "VEGAN": "Vegan",
  "DIGER": "Diğer",
};

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

  /// Çoklu görsel
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

    // 🚨 "HEPSI" seçilmişse backend’e göndermiyoruz
    String? categoryToSend;
    if (_selectedRecipeCategory != null && _selectedRecipeCategory != "HEPSI") {
      categoryToSend = _selectedRecipeCategory;
    }

    final body = {
      "title": _title.text.trim(),
      "description": _desc.text.trim(),
      "authorEmail": email,
      "ingredients": _selected.map((s) => {
        "ingredientId": s.ingredientId,
        "amount": s.amount.trim().isEmpty ? "1" : s.amount.trim(),
        "unit": s.unit.trim().isEmpty ? "adet" : s.unit.trim(),
      }).toList(),
      if (categoryToSend != null) "category": categoryToSend,
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

  // ---------- UI helpers (tema uyumlu) ----------
  InputDecoration _input(String label, ThemeData theme) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  ButtonStyle _primaryBtnStyle(ThemeData theme) => ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      );

  Widget _categoryChips(ThemeData theme) {
    final onSurface = theme.colorScheme.onSurface;
    return SizedBox(
      height: 44,
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
              style: TextStyle(
                color: selected ? theme.colorScheme.onPrimary : onSurface,
              ),
            ),
            selectedColor: theme.colorScheme.primary,
            backgroundColor: theme.chipTheme.backgroundColor,
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

  Widget _ingredientPicker(ThemeData theme) {
    int? pickedId;
    final amountCtrl = TextEditingController(text: "1");
    final unitCtrl = TextEditingController(text: "adet");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _categoryChips(theme),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          items: _pool
              .map<DropdownMenuItem<int>>(
                (it) => DropdownMenuItem(
                  value: it["id"],
                  child: Text(it["name"], style: theme.textTheme.bodyMedium),
                ),
              )
              .toList(),
          onChanged: (v) => pickedId = v,
          decoration: _input("Havuzdan malzeme seç", theme),
          style: theme.textTheme.bodyMedium,
          dropdownColor: theme.cardColor,
          iconEnabledColor: theme.iconTheme.color,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: amountCtrl,
                style: theme.textTheme.bodyMedium,
                decoration: _input("Miktar", theme),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: unitCtrl,
                style: theme.textTheme.bodyMedium,
                decoration: _input("Birim", theme),
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
                    _selected.add(
                      _SelIng(
                        pickedId!,
                        amount: amountCtrl.text,
                        unit: unitCtrl.text,
                        name: ing["name"],
                      ),
                    );
                    _msg = null;
                  });
                } else {
                  setState(() => _msg = "Lütfen önce havuzdan bir malzeme seçin.");
                }
              },
              style: _primaryBtnStyle(theme),
              child: const Text("Ekle"),
            )
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: Icon(Icons.add, color: theme.colorScheme.primary),
          label: Text(
            "Havuza yeni malzeme ekle",
            style: theme.textTheme.bodyMedium,
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: theme.dividerColor),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onPressed: _showAddIngredientDialog,
        ),
        const SizedBox(height: 12),
        if (_selected.isNotEmpty)
          Text("Seçilenler",
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        ..._selected.map((s) {
          return ListTile(
            dense: true,
            title: Text(
              "${s.name}  •  ${s.amount} ${s.unit}",
              style: theme.textTheme.bodyMedium,
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: theme.iconTheme.color?.withOpacity(0.7)),
              onPressed: () => setState(() => _selected.remove(s)),
            ),
          );
        }),
      ],
    );
  }

  Widget _imagesSection(ThemeData theme) {
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
                    child: Image.memory(_images[i],
                        width: 100, height: 100, fit: BoxFit.cover),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: InkWell(
                      onTap: () => setState(() => _images.removeAt(i)),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
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
          style: _primaryBtnStyle(theme),
        ),
      ],
    );
  }

  Future<void> _showAddIngredientDialog() async {
    final nameCtrl = TextEditingController();
    String cat = _selectedCategory;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) {
        final theme = Theme.of(context);
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              backgroundColor: theme.dialogBackgroundColor,
              title: Text("Havuza yeni malzeme ekle",
                  style: theme.textTheme.titleMedium),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    style: theme.textTheme.bodyMedium,
                    decoration: _input("Malzeme adı", theme),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: cat,
                    dropdownColor: theme.cardColor,
                    style: theme.textTheme.bodyMedium,
                    decoration: _input("Kategori", theme),
                    items: kCategories
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(kCategoryLabels[c] ?? c,
                                  style: theme.textTheme.bodyMedium),
                            ))
                        .toList(),
                    onChanged: (v) => setLocal(() => cat = v ?? 'OTHER'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text("Vazgeç", style: theme.textTheme.bodyMedium),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: _primaryBtnStyle(theme),
                  child: const Text("Ekle"),
                ),
              ],
            );
          },
        );
      },
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
            _msg =
                "ℹ️ \"${exist["name"]}\" zaten ${kCategoryLabels[exist["category"]]} kategorisinde mevcut.";
            if (exist["category"] == _selectedCategory &&
                !_pool.any((p) => p["id"] == exist["id"])) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canAdd = _isSocialLoggedIn();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.deepOrange),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Tarif Ekle",
          style: TextStyle(
            color: Colors.deepOrange,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loadingPool
            ? Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              )
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _title,
                      style: theme.textTheme.bodyMedium,
                      decoration: _input("Tarif Başlığı", theme),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? "Başlık giriniz" : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _desc,
                      maxLines: 8,
                      style: theme.textTheme.bodyMedium,
                      decoration: _input("Tarif Açıklaması", theme),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? "Açıklama giriniz" : null,
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _selectedRecipeCategory,
                      decoration: _input("Tarif Kategorisi", theme),
                      dropdownColor: theme.cardColor,
                      style: theme.textTheme.bodyMedium,
                      iconEnabledColor: theme.iconTheme.color,
                      items: kRecipeCategories
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c, style: theme.textTheme.bodyMedium),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedRecipeCategory = v),
                      validator: (v) => v == null ? "Kategori seçiniz" : null,
                    ),
                    const SizedBox(height: 16),

                    _imagesSection(theme),
                    const SizedBox(height: 16),

                    _ingredientPicker(theme),
                    const SizedBox(height: 20),

                    if (!canAdd)
                      Text(
                        "Anonim kullanıcılar tarif ekleyemez. Google/Facebook ile giriş yapın.",
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: Colors.orange),
                      ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: canAdd
                          ? () {
                              if (_formKey.currentState!.validate()) _submitRecipe();
                            }
                          : null,
                      style: _primaryBtnStyle(theme),
                      child: const Text("Kaydet"),
                    ),
                    if (_msg != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _msg!,
                        style: TextStyle(
                          color:
                              _msg!.startsWith("✅") ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
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