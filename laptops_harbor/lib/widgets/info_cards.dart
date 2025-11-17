import 'package:flutter/material.dart';
import 'package:laptops_harbor/style/theme.dart';

class InfoCard extends StatelessWidget {
  final String title;
  final String content;
  final TextStyle? titleStyle;

  const InfoCard({super.key, required this.title, required this.content, this.titleStyle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.grey[300],// light grey background
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          // BoxShadow(
          
          //   blurRadius: 8,
          //   offset: const Offset(0, 4),
          // ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: black,
            ).merge(titleStyle),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              color: black,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
