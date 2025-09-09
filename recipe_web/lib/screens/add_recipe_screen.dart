import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

/// Backend enum’ları (wire değerleri)
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

  // ---- ortak stil
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

  Future<void> _submitRecipe() async {
    if (!_isSocialLoggedIn()) {
      setState(() => _msg = "❌ Tarif eklemek için Google veya Facebook ile giriş yapın.");
      return;
    }

    final body = {
      "title": _title.text.trim(),
      "description": _desc.text.trim(),
      "authorId": 1, // TODO: backend user id eşleme
      "ingredients": _selected.map((s) => {
        "ingredientId": s.ingredientId,
        "amount": s.amount.trim().isEmpty ? "1" : s.amount.trim(),
        "unit": s.unit.trim().isEmpty ? "adet" : s.unit.trim(),
      }).toList()
    };

    try {
      final res = await http.post(
        Uri.parse("http://localhost:8080/api/recipes"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        setState(() => _msg = "✅ Tarif eklendi");
        _title.clear();
        _desc.clear();
        _selected.clear();
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
            // Aynı kategorideyse ekrana anında yansıt
            if (ing["category"] == _selectedCategory) {
              _pool.add(ing);
            } else {
              // farklı kategoriye eklendiyse, mesajı verip aktif kategori değişirse yüklenir
            }
            _msg = "✅ \"${ing["name"]}\" havuza eklendi";
          });
        } else if (res.statusCode == 409) {
          final body = jsonDecode(res.body);
          final exist = body["data"];
          setState(() {
            _msg = "ℹ️ \"${exist["name"]}\" zaten ${kCategoryLabels[exist["category"]]} kategorisinde mevcut.";
            // aktif kategori farklıysa ve kullanıcı o kategoriye geçerse görsün diye seçenek:
            // eğer mevcut kategori ise havuzu güncelleyelim (görsel olarak en üstte dursun diye)
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: kCategories.map((c) {
          final selected = c == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
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
            ),
          );
        }).toList(),
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
                  setState(() {
                    _selected.add(_SelIng(
                      pickedId!,
                      amount: amountCtrl.text,
                      unit: unitCtrl.text,
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
          final name = _pool.firstWhere((p) => p["id"] == s.ingredientId, orElse: () => {"name": "Malzeme"})["name"];
          return ListTile(
            dense: true,
            title: Text("$name  •  ${s.amount} ${s.unit}", style: const TextStyle(color: Colors.white)),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.white70),
              onPressed: () => setState(() => _selected.remove(s)),
            ),
          );
        }),
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
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: _whiteInput("Tarif Açıklaması"),
                validator: (v) => (v == null || v.trim().isEmpty) ? "Açıklama giriniz" : null,
              ),
              const SizedBox(height: 16),
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
                  style: TextStyle(color: _msg!.startsWith("✅") ? Colors.green : Colors.red),
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
  String amount;
  String unit;
  _SelIng(this.ingredientId, {this.amount = "1", this.unit = "adet"});
}