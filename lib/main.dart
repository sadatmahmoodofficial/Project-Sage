import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/main_navigation_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationService.instance.initialize();

  // 1. Purge any old anonymous test sessions
  User? currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser != null && currentUser.isAnonymous) {
    await FirebaseAuth.instance.signOut();
    currentUser = null;
  }

  // 2. Silently sign into the shared hardware account
  if (currentUser == null) {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: 'demo@sage.com',       
        password: 'password123',    
      );
    } catch (e) {
      debugPrint('Silent login error: $e');
    }
  }

  runApp(const SageApp());
}

class SageApp extends StatelessWidget {
  const SageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sage Wellness',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      debugShowCheckedModeBanner: false,
      // 3. Listen safely so the app doesn't crash if offline
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: Colors.tealAccent)),
            );
          }
          
          if (snapshot.hasData && snapshot.data != null) {
            return MainNavigationScreen(user: snapshot.data!);
          }
          
          // Fallback if the login fails due to network issues
          return const Scaffold(
            body: Center(
              child: Text("Network Error. Please restart the app with internet access."),
            ),
          );
        },
      ),
    );
  }
}