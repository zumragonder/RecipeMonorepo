import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String? _error;

// Google login sonrası
Future<void> _handleGoogleSignIn() async {
  try {
    final provider = GoogleAuthProvider()
      ..addScope('email')
      ..addScope('profile')
      ..setCustomParameters({'prompt': 'select_account'});

    final cred = await FirebaseAuth.instance.signInWithPopup(provider);
    final user = cred.user;

    if (user != null) {
      final body = {
        "email": user.email,
        "name": user.displayName,
        "pictureUrl": user.photoURL,
        "providerId": "google.com"
      };

      // 🔹 Spring Boot backend'e POST at
      final response = await http.post(
        Uri.parse("http://localhost:8080/api/auth/google"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        print("✅ Backend'e kaydedildi: ${response.body}");

        if (!mounted) return; // context kontrolü

        // 🔹 HomeScreen’e geçiş
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        setState(() => _error =
            "❌ Backend hata: ${response.statusCode} - ${response.body}");
      }
    }
  } catch (e) {
    setState(() => _error = "Google giriş hatası: $e");
  }
}

  Future<void> _handleFacebookSignIn() async {
    try {
      final provider = FacebookAuthProvider();
      provider.addScope('email');
      provider.addScope('public_profile');

      await FirebaseAuth.instance.signInWithPopup(provider);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        setState(() {
          _error =
              "Bu e-posta adresi başka bir giriş yöntemiyle (ör. Google) zaten kayıtlı. "
              "Lütfen o yöntemle giriş yapın.";
        });
      } else {
        setState(() => _error = 'Facebook giriş hatası: ${e.message}');
      }
    } catch (e) {
      setState(() => _error = 'Facebook giriş hatası: $e');
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

                    // 🔹 Google ile Giriş (sadece ikon)
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.deepOrange, width: 2),
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _handleGoogleSignIn,
                      child: const Icon(
                        Icons.g_mobiledata,
                        size: 36,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 🔹 Facebook ile Giriş (sadece ikon)
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.blue, width: 2),
                        foregroundColor: Colors.blue,
                        backgroundColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _handleFacebookSignIn,
                      child: const Icon(
                        Icons.facebook,
                        size: 32,
                        color: Colors.blue,
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