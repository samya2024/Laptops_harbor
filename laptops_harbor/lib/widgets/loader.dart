import 'package:flutter/material.dart';
import 'package:laptops_harbor/style/theme.dart';

class Loader extends StatelessWidget {
  const Loader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
       color: darkBackground.withOpacity(0.7),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(cyan),
          strokeWidth: 3.5,
        ),
      ),
    );
  }
}
