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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Şefler"),
        backgroundColor: Colors.deepOrange,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _chefs.isEmpty
              ? const Center(child: Text("Hiç şef bulunamadı"))
              : ListView.builder(
                  itemCount: _chefs.length,
                  itemBuilder: (context, index) {
                    final chef = _chefs[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.person, color: Colors.deepOrange),
                        title: Text(chef["name"] ?? chef["email"]),
                        subtitle: Text(chef["email"] ?? ""),
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