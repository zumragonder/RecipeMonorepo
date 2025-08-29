import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

const String kBackendUrl = 'http://localhost:8080/api/session';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Auth Demo',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      home: const MyHomePage(title: 'Firebase Auth Demo Home Page'),
    );
  }
}

// ---- idToken'ı backend'e POST eden ortak fonksiyon ----
Future<void> sendIdTokenToBackend() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    print('Not signed in');
    return;
  }

  final idToken = await user.getIdToken(true); // imzalı JWT
  print('ID TOKEN -> $idToken');
  /* final resp = await http.post(
    Uri.parse(kBackendUrl),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'idToken': idToken}),
  ); */

  // print('SERVER RESPONSE -> ${resp.statusCode} ${resp.body}');
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? _shownId;
  String? _error;

  Future<void> _handleGoogleSignIn() async {
    try {
      final provider = GoogleAuthProvider()
        ..addScope('email')
        ..addScope('profile')
        ..setCustomParameters({'prompt': 'select_account'});

      final cred = await FirebaseAuth.instance.signInWithPopup(provider);
      final uid = cred.user?.uid;

      setState(() {
        _shownId = uid;
        _error = null;
      });

      // ✅ girişten hemen sonra token'ı backend'e gönder
      await sendIdTokenToBackend();
    } catch (e) {
      setState(() {
        _error = 'Google sign-in failed: $e';
        _shownId = null;
      });
    }
  }

  Future<void> _handleAnonSignIn() async {
    try {
      final cred = await FirebaseAuth.instance.signInAnonymously();
      final uid = cred.user?.uid;

      setState(() {
        _shownId = uid;
        _error = null;
      });

      // ✅ girişten hemen sonra token'ı backend'e gönder
      await sendIdTokenToBackend();
    } catch (e) {
      setState(() {
        _error = 'Anonim giriş başarısız: $e';
        _shownId = null;
      });
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    setState(() {
      _shownId = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(onPressed: _signOut, icon: const Icon(Icons.logout)),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _handleGoogleSignIn,
              child: const Text("Google ile Giriş"),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _handleAnonSignIn,
              child: const Text("Anonim Giriş"),
            ),
            const SizedBox(height: 24),
            if (_shownId != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SelectableText(
                  'Kullanıcı UID:\n$_shownId',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}