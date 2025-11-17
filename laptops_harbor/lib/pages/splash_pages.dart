import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:laptops_harbor/screens/auth_page.dart';
import 'package:laptops_harbor/widgets/animated_logo.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/home_page.dart';
import 'auth/login.dart';
import '../style/theme.dart';

// 🌊 Splash Screen Page
class SplashPage extends StatefulWidget {
  static const String routeName = '/splash';

  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  final List<String> sayings = [
    "Fast & Reliable Tech Solutions",
    "Quality Laptops & Accessories",
    "Your Tech Partner",
    "Innovation at Its Best",
    "Tech Made Simple"
  ];

  String currentSaying = "";
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    final random = Random();
    currentSaying = sayings[random.nextInt(sayings.length)];

    // ✨ Fade animation setup
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();

    // ⏳ Check login faster (3 seconds instead of 5)
    _checkLogin();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('uid');

    // Check login status immediately
    await Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;

      if (uid != null && uid.isNotEmpty) {
        // User logged in → go to HomePage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else {
        // User not logged in → go to LoginPage
        Navigator.of(context).pushReplacementNamed('/auth');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
          backgroundColor: Colors.cyan.shade50,
      // backgroundColor: cyanBlue,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 🌆 Background Image
          Image.asset(
            'assets/backgroundimage1.jpg',
            fit: BoxFit.cover,
            errorBuilder: (BuildContext context, Object exception,
                StackTrace? stackTrace) {
              return Container(
                // color: Colors.grey.shade300,
                child: const Center(
                  child: Text(
                    'WELCOME',
                    style: TextStyle(color: Colors.black54, fontSize: 20),
                  ),
                ),
              );
            },
          ),

          // 💧 Cyan overlay image color
          Container(
         color:  Colors.cyan.withAlpha((0.2 * 255).toInt())

          ),

          // 🌟 Main Content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // 🌀 App Logo
              Center(
                child: Hero(tag: "logo_splash", child: AnimatedLogo(size: 150)),
              ),

              const SizedBox(height: 20),

              // 🌈 App Name
              const Text(
                "Laptop Harbor",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyan,
                  letterSpacing: 1.5,
                ),
              ),

              const SizedBox(height: 10),

              // 🪄 Tagline
              const Text(
                "Your One-Stop Laptop Hub 💻",
                style: TextStyle(
                  fontSize: 17,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 40),

              // 🔵 Circular Loader
              const CircularProgressIndicator(
                color: Colors.cyan,
                strokeWidth: 4,
              ),

              const SizedBox(height: 40),

              // ✨ Static Quote
              Text(
                currentSaying,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.cyan,
                ),
              ),

              const Spacer(),

              // ⚡ Footer Text
              const Padding(
                padding: EdgeInsets.only(bottom: 25.0),
                child: Column(
                  children: [
                    Text(
                      "Welcome to Laptop Harbor 💙",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Powered by Flutter 🔥",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black45,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
