import 'package:flutter/material.dart';

class AppPopup extends StatelessWidget {
  final String title;
  final String message;
  final String? imagePath; // optional image
  final List<Widget>? actions;
  final double? customWidth;

  const AppPopup({
    super.key,
    required this.title,
    required this.message,
    this.imagePath,
    this.actions,
    this.customWidth,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Dialog(
      backgroundColor: Colors.transparent, // Transparent to allow custom container
      child: Center(
        child: Container(
          width: customWidth ?? (isSmallScreen ? screenWidth * 0.95 : screenWidth * 0.9),
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (imagePath != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.cyan.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    imagePath!,
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 20 : 24,
                  color: Colors.cyan[800],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: actions ??
                    [
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyan,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'OK',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper to show the popup
Future<T?> showAppPopup<T>(
  BuildContext context, {
  required String title,
  required String message,
  String? imagePath,
  List<Widget>? actions,
  double? customWidth,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: true,
    builder: (context) => AppPopup(
      title: title,
      message: message,
      imagePath: imagePath,
      actions: actions,
      customWidth: customWidth,
    ),
  );
}
