import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'dart:convert'; // JSON işlemleri için
import 'package:http/http.dart' as http; // HTTP istekleri için

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key}); 

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  String? _error;  // Giriş hatalarını göstermek için kullanılan değişken

  // 🔹 Google ile giriş yapma fonksiyonu
  Future<void> _handleGoogleSignIn() async {
    try {

            // Google login sağlayıcısı ayarlanıyor
      final provider = GoogleAuthProvider()
        ..addScope('email')
        ..addScope('profile')
        ..setCustomParameters({'prompt': 'select_account'});   //dart object

      // Firebase üzerinden Google popup login işlemi başlatılıyor
      final cred = await FirebaseAuth.instance.signInWithPopup(provider);
      final user = cred.user;

      if (user != null) {
                // Backend'e gönderilecek kullanıcı bilgileri
        final body = {
          "email": user.email,
          "name": user.displayName,
          "pictureUrl": user.photoURL,
          "providerId": "google.com"
        };  

        // 🔹 Spring Boot backend'e POST isteği
        final response = await http.post(
          Uri.parse("http://localhost:8080/api/auth/google"),
          headers: {"Content-Type": "application/json"}, // JSON içeriği
          body: jsonEncode(body),  
        );

        if (response.statusCode == 200) { 
          print("✅ Backend'e kaydedildi: ${response.body}"); 

          if (!mounted) return; // context geçerli mi kontrol et

          // 🔹 Başarılı giriş sonrası HomeScreen’e yönlendir
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        } else {
                    // Backend’ten hata dönerse ekranda göster
          setState(() => _error =
              "❌ Backend hata: ${response.statusCode} - ${response.body}");
        }
      }
    } catch (e) {      // Firebase login hatası
      setState(() => _error = "Google giriş hatası: $e");
    }
  }

  // 🔹 Facebook ile giriş yapma fonksiyonu
  Future<void> _handleFacebookSignIn() async {
    try {
      final provider = FacebookAuthProvider();
      provider.addScope('email');
      provider.addScope('public_profile');
      
      // Firebase popup ile giriş
      await FirebaseAuth.instance.signInWithPopup(provider);
     
      // Başarılı giriş sonrası HomeScreen’e geç
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
            // Özel hata: e-posta başka giriş yöntemine bağlıysa uyarı
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

  // 🔹 Anonim giriş fonksiyonu (misafir kullanıcı)
  Future<void> _handleAnonSignIn() async {
    try {
      await FirebaseAuth.instance.signInAnonymously();
     
      // Başarılı giriş sonrası HomeScreen’e yönlendir
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

                    // 🔹 Sosyal giriş butonları yan yana
                    Row(
                      children: [
                        // Google Button
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: Colors.deepOrange, width: 2),
                              backgroundColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _handleGoogleSignIn,
                            child: const Icon(
                              Icons.g_mobiledata,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),

                        // Facebook Button
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side:
                                  const BorderSide(color: Colors.blue, width: 2),
                              backgroundColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _handleFacebookSignIn,
                            child: const Icon(
                              Icons.facebook,
                              size: 36,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),

                        // Anonim Button
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                  color: Colors.deepOrange, width: 2),
                              backgroundColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: _handleAnonSignIn,
                            child: const Icon(
                              Icons.person_outline,
                              size: 36,
                              color: Colors.deepOrange,
                            ),
                          ),
                        ),
                      ],
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