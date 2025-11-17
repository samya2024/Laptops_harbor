import 'dart:math';

import 'package:flutter/material.dart';
import 'package:laptops_harbor/services/auth_helper.dart';
import 'package:laptops_harbor/pages/auth/login.dart';
import 'package:laptops_harbor/pages/auth/register.dart';
import 'package:laptops_harbor/style/theme.dart';
import 'package:laptops_harbor/widgets/animated_logo.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  static const String routeName = '/auth';

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with SingleTickerProviderStateMixin {
  bool showLogin = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();

    // Auto redirect if already logged in
    if (AuthService().currentUser != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/');
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void toggle() {
    setState(() {
      showLogin = !showLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/backgroundimage1.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Animated border effect
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _animationController.value * 2 * pi,
                    child: Container(
                      width: 380,
                      height: 420,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            const Color(0xFF45F3FF),
                            Colors.transparent,
                            const Color(0xFF45F3FF),
                          ],
                          stops: const [0.0, 0.25, 0.75, 1.0],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                },
              ),
              // Second animated border with delay
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: (_animationController.value - 0.5) * 2 * pi, // Delay effect
                    child: Container(
                      width: 380,
                      height: 420,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            const Color(0xFF45F3FF),
                            Colors.transparent,
                            const Color(0xFF45F3FF),
                          ],
                          stops: const [0.0, 0.25, 0.75, 1.0],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                },
              ),
              // Main box
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 380,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1C),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: cyan.withOpacity(0.5),
                        blurRadius: 15,
                        spreadRadius: 2,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4), // inset 4px
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF23242A), // Assuming background for form
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 50),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                showLogin ? 'Login' : 'Register',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 24,
                                  letterSpacing: 0.1,
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Form content with animation
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 500),
                                child: showLogin ? const LoginScreen() : const RegisterScreen(),
                              ),
                              const SizedBox(height: 15),
                              // Switch button
                              TextButton(
                                onPressed: toggle,
                                child: Text(
                                  showLogin
                                      ? "Don't have an account? Register"
                                      : "Already have an account? Login",
                                  style: const TextStyle(
                                    color: Color(0xFF8F8F8F),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


