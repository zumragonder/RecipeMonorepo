import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'chef_recipes_screen.dart';

class ChefsScreen extends StatefulWidget {
  const ChefsScreen({super.key});

  @override
  State<ChefsScreen> createState() => _ChefsScreenState();
}

class _ChefsScreenState extends State<ChefsScreen> {
  List<dynamic> _chefs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchChefs();
  }

  Future<void> _fetchChefs() async {
    final uri = Uri.parse("http://localhost:8080/api/users");
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      setState(() {
        _chefs = jsonDecode(response.body);
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          "Şefler",
          style: TextStyle(
            color: Colors.deepOrange,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _chefs.isEmpty
              ? Center(
                  child: Text(
                    "Hiç şef bulunamadı",
                    style: theme.textTheme.bodyMedium,
                  ),
                )
              : ListView.builder(
                  itemCount: _chefs.length,
                  itemBuilder: (context, index) {
                    final chef = _chefs[index];
                    return Card(
                      margin:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      color: theme.cardColor,
                      child: ListTile(
                        leading: Icon(
                          Icons.person,
                          color: theme.colorScheme.primary,
                        ),
                        title: Text(
                          chef["name"] ?? chef["email"],
                          style: theme.textTheme.bodyMedium,
                        ),
                        subtitle: Text(
                          chef["email"] ?? "",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.brightness == Brightness.dark
                                ? Colors.white70 // koyu temada açık gri
                                : Colors.black87, // açık temada siyah
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChefRecipesScreen(
                                chefId: chef["id"],
                                chefName: chef["name"] ?? chef["email"],
                              ),
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