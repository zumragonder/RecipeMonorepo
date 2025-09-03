import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  // 🔹 Backend URL (emülatör için 10.0.2.2, gerçek cihazda kendi IP adresini yaz)
  static const String _backendUrl = "http://10.0.2.2:8080/api/users/save";

  // 🔹 Kullanıcıyı backend’e kaydet
  static Future<void> saveUser(User user, String providerId) async {
    final body = {
      "email": user.email,
      "name": user.displayName,
      "pictureUrl": user.photoURL,
      "providerId": providerId,
    };

    try {
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        print("✅ Kullanıcı kaydedildi: ${response.body}");
      } else {
        print("❌ Backend hata: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("❌ Backend bağlantı hatası: $e");
    }
  }
}