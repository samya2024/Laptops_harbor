import 'package:flutter/material.dart';
import 'dart:math';

class AnimatedLogo extends StatefulWidget {
  const AnimatedLogo({super.key, this.size = 130});
  final double size;

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _rotationAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
        );
      },
      child: Image.asset(
        'assets/logo3.png',
        width: widget.size,
        height: widget.size,
      ),
    );
  }
}

// =========================
// Animated Logo + Text Combo
// =========================
class AnimatedLogoWithName extends StatefulWidget {
  final double logoSize;
  const AnimatedLogoWithName({super.key, this.logoSize = 80});

  @override
  State<AnimatedLogoWithName> createState() => _AnimatedLogoWithNameState();
}

class _AnimatedLogoWithNameState extends State<AnimatedLogoWithName>
    with SingleTickerProviderStateMixin {
  bool _isTapped = false;
  late AnimationController _colorController;

  @override
  void initState() {
    super.initState();
    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isTapped = true),
      onTapUp: (_) => Future.delayed(
        const Duration(milliseconds: 200),
        () => setState(() => _isTapped = false),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedLogo(size: widget.logoSize),
          const SizedBox(width: 10),
          AnimatedBuilder(
            animation: _colorController,
            builder: (context, child) {
              final gradient = LinearGradient(
                colors: _isTapped
                    ? [Colors.purpleAccent, Colors.cyan]
                    : [
                        Colors.blue,
                        Color.lerp(Colors.cyan, Colors.white,
                            _colorController.value)!,
                      ],
              );
              return ShaderMask(
                shaderCallback: (bounds) =>
                    gradient.createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                child: const Text(
                  'LaptopHarborApp',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Keep white for shader base
                    letterSpacing: 1.2,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// =========================
// Example Drawer with Logo
// =========================
class LogoDrawerPage extends StatelessWidget {
  const LogoDrawerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Animated Logo Drawer',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.cyan,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: const [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.cyan),
              child: Center(
                child: AnimatedLogoWithName(logoSize: 70),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home, color: Colors.cyan),
              title: Text('Home', style: TextStyle(color: Colors.black)),
            ),
            ListTile(
              leading: Icon(Icons.shopping_cart, color: Colors.cyan),
              title: Text('Cart', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
      body: const Center(
        child: AnimatedLogoWithName(),
      ),
    );
  }
}
