import 'package:flutter/material.dart';
import 'package:placement_portal_frontend/views/auth/login_screen.dart';
import 'package:placement_portal_frontend/views/auth/signup_screen.dart';
import 'package:placement_portal_frontend/views/auth/forgot_password_screen.dart';

void main() {
  runApp(const BMUPlacementPortalApp());
}

class BMUPlacementPortalApp extends StatelessWidget {
  const BMUPlacementPortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BMU Student Placement Portal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF6366F1),
        scaffoldBackgroundColor: const Color(0xFF0F0C1B),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          secondary: Color(0xFF8B5CF6),
          surface: Color(0xFF1B1425),
        ),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
      },
    );
  }
}
