import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:stellar_project/Pages/home.dart';
import 'package:stellar_project/Pages/main_screen.dart';
import 'firebase_options.dart';
import 'Pages/authentication/login.dart';
import 'themes/app_themes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Timer? _themeTimer;

  @override
  void initState() {
    super.initState();
    _themeTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      _refreshApp();
    });
  }
    void _refreshApp() async {
      if (mounted){
        setState(() {});
      }
    
    try { 
      final user = FirebaseAuth.instance.currentUser;
      if (user != null){
        await user.getIdToken(true);
      }
    } catch (e) {
      debugPrint("Security Error: User session has expired, please log in again.");
    }
  }


@override
void dispose() {
  _themeTimer?.cancel();
  super.dispose();
}

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

      // handles login state. If user is logged in, home page will display.
      // if not they have to log in or create an account.
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot){
          if (snapshot.connectionState == ConnectionState.waiting){
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          //takes the user to the home page upon opening/login
          if (snapshot.hasData){
            return const MainScreen();
          }
          return const LoginScreen();
        }
      ),
    );
  }
}