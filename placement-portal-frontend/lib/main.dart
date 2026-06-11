import 'package:flutter/material.dart';
import 'package:placement_portal_frontend/views/auth/login_screen.dart';
import 'package:placement_portal_frontend/views/auth/signup_screen.dart';
import 'package:placement_portal_frontend/views/auth/forgot_password_screen.dart';
import 'package:placement_portal_frontend/views/auth/otp_verification_screen.dart';
import 'package:placement_portal_frontend/views/student/student_profile_screen.dart';
import 'package:placement_portal_frontend/views/student/student_home_screen.dart';
import 'package:placement_portal_frontend/views/recruiter/recruiter_dashboard_screen.dart';

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
        fontFamily: 'Roboto',
        primaryColor: const Color(0xFF14B8A6),
        scaffoldBackgroundColor: const Color(0xFF0A0E17),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF14B8A6),
          secondary: Color(0xFF3B82F6),
          surface: Color(0xFF111827),
        ),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/verify-otp': (context) {
          final email = ModalRoute.of(context)!.settings.arguments as String? ?? '';
          return OtpVerificationScreen(email: email);
        },
        '/student/profile': (context) => const StudentProfileScreen(),
        '/student/home': (context) => const StudentHomeScreen(),
        '/recruiter/dashboard': (context) => const RecruiterDashboardScreen(),
      },
    );
  }
}
