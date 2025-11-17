// lib/models/theme.dart
import 'package:flutter/material.dart';

const Color cyan = Color(0xFF00B8D9);       // Bright cyan
const Color cyanBlue = Color(0xFFE0F7FA);   // Light cyan blue background
const Color black = Colors.black;           // Black
const Color white = Colors.white;           // White text/icons
const Color grey = Colors.grey;             // Light grey for subtext
const Color lightGrey = Color(0xFFF5F5F5);  // Light grey for buttons/containers
const Color darkBackground = Color(0xFF0F1C2E); // Optional: subtle dark background


class NoScrollbarBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child; // No scrollbar
  }
}
