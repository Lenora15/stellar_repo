import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:stellar_project/Pages/main_screen.dart';
import 'firebase_options.dart';
import 'Pages/authentication/login.dart';
import 'themes/app_themes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';


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

  //security listeners
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot>? _securitySubscription;

  //theme management
  Timer? _themeTimer;
  final ValueNotifier<DateTime> _timeNotifier = ValueNotifier(DateTime.now());

  @override
  void initState() {
    super.initState();
    
    //prevent navigation stack from resetting by updating ValueNotifier instead of
    //calling setState()
        _themeTimer = Timer.periodic(Duration(minutes: 1), (timer) {
        _timeNotifier.value = DateTime.now();
    });

    //watches for password reset in real time
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user){
      _securitySubscription?.cancel();

      if (user != null) {
      _securitySubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((snapshot){
          if (snapshot.exists){
            final data = snapshot.data() as Map<String, dynamic>;

            if (data != null && data['forceLogout'] == true) {
              _preformSecurityLogout(user.uid);
            }
          }
        });
      }
    });
  }

  Future<void> _preformSecurityLogout(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'forceLogout': false,
      });
    } catch (e) {
      debugPrint("Security reset failed: $e");
    }

    await FirebaseAuth.instance.signOut();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _securitySubscription?.cancel();
    _themeTimer?.cancel();
    _timeNotifier.dispose();
    super.dispose();
  }

@override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stellar',
      builder: (context, child) {
        return ValueListenableBuilder<DateTime>(
          valueListenable: _timeNotifier,
          builder: (context, time, _) {
            final currentThemeData = AppThemes.getThemeForTimeOfDay();
            return Theme(
              data: currentThemeData.theme,
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(currentThemeData.backgroundImage),
                    fit: BoxFit.cover,
                  ),
                ),
                child: child,
              ),
            );
          },
        );
      },
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData) {
            return const MainScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
  
