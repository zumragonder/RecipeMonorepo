import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart'; // ekledim

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(RecipeApp());
}

/// Tema kontrolü için global değişken
ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

class RecipeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'Tarif Dünyası',
          debugShowCheckedModeBanner: false,

          // 🔹 Açık Tema
          theme: ThemeData.light().copyWith(
            scaffoldBackgroundColor: Colors.white,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.deepOrange,
              foregroundColor: Colors.white,
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
            textTheme: const TextTheme(
              bodyMedium: TextStyle(color: Colors.black87),
            ),
          ),

          // 🔹 Koyu Tema
          darkTheme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: const Color(0xFF2B2B2B),
            colorScheme: const ColorScheme.dark(
              primary: Colors.deepOrange,
              secondary: Colors.deepOrange,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.black,
              titleTextStyle: TextStyle(
                color: Colors.deepOrange,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrange,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
            textTheme: const TextTheme(
              bodyMedium: TextStyle(color: Colors.white),
            ),
          ),

          // 🔹 Tema seçimi
          themeMode: currentMode,

          // İlk açılan ekran
          home: const WelcomeScreen(),

          // 🔹 Route tanımları (login sonrası yönlendirme için)
          routes: {
            "/home": (context) => const HomeScreen(),
          },
        );
      },
    );
  }
}