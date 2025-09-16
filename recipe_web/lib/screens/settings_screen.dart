import 'package:flutter/material.dart';
import '../main.dart'; // themeNotifier için import

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    bool isDark = themeNotifier.value == ThemeMode.dark; // Tema durumunu kontrol et

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ayarlar"),
        backgroundColor: Colors.deepOrange,
      ),
      body: ListView(
        children: [
          // 🔹 Tema değiştirme switch
          SwitchListTile(
            title: const Text("Koyu Tema"),
            value: isDark,
            activeColor: Colors.deepOrange,
            onChanged: (val) {
              setState(() {
                themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
              });
            },
          ),

          const Divider(),

          // 🔹 Hakkında kısmı
          const ListTile(
            title: Text("Hakkında"),
            subtitle: Text("Tarif Dünyası v1.0.0\nGeliştirici: Zumra"),
          ),
        ],
      ),
    );
  }
}