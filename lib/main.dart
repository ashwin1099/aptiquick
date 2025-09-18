// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart'; // ✅ IMPORT THE GENERATED FILE

// Assuming these files exist in your project structure
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

// Global ValueNotifier for theme mode
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

void main() async {
  // Ensure bindings are initialized before async calls
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Securely initialize Firebase using the generated options file
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'Apti Quick',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            brightness: Brightness.light,
            textTheme: const TextTheme(
              bodyMedium: TextStyle(fontWeight: FontWeight.w400),
              bodyLarge: TextStyle(fontWeight: FontWeight.w500),
              titleMedium: TextStyle(fontWeight: FontWeight.w600),
              titleLarge: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
            ),
            textTheme: const TextTheme(
              bodyMedium: TextStyle(fontWeight: FontWeight.w400),
              bodyLarge: TextStyle(fontWeight: FontWeight.w500),
              titleMedium: TextStyle(fontWeight: FontWeight.w600),
              titleLarge: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          themeMode: currentMode,
          // RootScreen correctly handles the auth state to show the right screen
          home: const RootScreen(),
        );
      },
    );
  }
}

class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show a loading indicator while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If user is not logged in, show the splash/login flow
        if (!snapshot.hasData) {
          return const SplashScreen();
        }

        // If user is logged in, go directly to the home screen
        return const HomeScreen();
      },
    );
  }
}