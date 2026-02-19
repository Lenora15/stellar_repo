import 'package:flutter/material.dart';
import 'Pages/home.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Pages/authentication/login.dart';
import 'themes/app_themes.dart';

void main() async {
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
    final currentThemeData = AppThemes.getThemeForTimeOfDay();

    return MaterialApp(
      title: 'Stellar',
      theme: currentThemeData.theme,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(currentThemeData.backgroundImage),
              fit: BoxFit.cover,
            ),
          ),
          child: child,
        );
      },
      home: const LoginScreen(),
    );
  }
}