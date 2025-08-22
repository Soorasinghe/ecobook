// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/business_provider.dart'; // <-- 1. Import the new provider
import 'screens/login_screen.dart';
import 'screens/tabs_screen.dart';

void main() {
  runApp(
    // V-- 2. Use MultiProvider to provide both Auth and Business state --V
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => AuthProvider()),
        ChangeNotifierProvider(create: (ctx) => BusinessProvider()),
      ],
      child: const EcoBookApp(),
    ),
  );
}

class EcoBookApp extends StatelessWidget {
  const EcoBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoBook',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: Consumer<AuthProvider>(
        builder: (ctx, auth, _) => auth.isAuth
            ? const TabsScreen() // If logged in, go to TabsScreen
            : FutureBuilder(
                future: auth.tryAutoLogin(),
                builder: (ctx, authResultSnapshot) =>
                    authResultSnapshot.connectionState ==
                        ConnectionState.waiting
                    ? const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      ) // Show a loading spinner
                    : const LoginScreen(), // Otherwise, show LoginScreen
              ),
      ),
    );
  }
}
