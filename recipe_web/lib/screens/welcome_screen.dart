import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String? _error;

  Future<void> _handleGoogleSignIn() async {
    try {
      final provider = GoogleAuthProvider()
        ..addScope('email')
        ..addScope('profile')
        ..setCustomParameters({'prompt': 'select_account'});

      await FirebaseAuth.instance.signInWithPopup(provider);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      setState(() => _error = 'Google giriş hatası: $e');
    }
  }

  Future<void> _handleAnonSignIn() async {
    try {
      await FirebaseAuth.instance.signInAnonymously();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      setState(() => _error = 'Anonim giriş hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 🔹 Arka plan resmi
          Image.asset(
            "assets/images/background.png",
            fit: BoxFit.cover,
          ),

          // 🔹 Hafif karartma
          Container(color: Colors.black.withOpacity(0.5)),

          // 🔹 İçerik
          Center(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 80.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔹 Başlık
                    const Text(
                      "Tarif Dünyası'na Hoşgeldiniz",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 10,
                            color: Colors.black54,
                            offset: Offset(2, 2),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    // 🔹 Google ile Giriş
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.deepOrange, width: 2),
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
                      ),
                      onPressed: _handleGoogleSignIn,
                      icon: const Icon(Icons.g_mobiledata, size: 28),
                      label: const Text(
                        "Google ile Giriş",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 🔹 Anonim Giriş
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.deepOrange, width: 2),
                        foregroundColor: Colors.deepOrange,
                        backgroundColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
                      ),
                      onPressed: _handleAnonSignIn,
                      icon: const Icon(Icons.person_outline, size: 26),
                      label: const Text(
                        "Anonim Giriş",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),

                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}