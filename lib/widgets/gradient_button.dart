import 'package:flutter/material.dart';

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isCancel;
  final TextStyle? style;
  final List<Color>? gradientColors; // <-- Add this

  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isCancel = false,
    this.style,
    this.gradientColors, // <-- Add this
  });

  @override
  Widget build(BuildContext context) {
    final defaultGradient = isCancel
        ? [const Color(0xFF025769), const Color(0xFF4E4AF2)]
        : [const Color(0xFF34C8E8), const Color(0xFF4E4AF2)];

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors ?? defaultGradient, // <-- Use custom gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A1F2C).withValues(alpha: 0.6),
              spreadRadius: 0,
              blurRadius: 8,
              offset: const Offset(3, 3),
            ),
          ],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Container(
          alignment: Alignment.center,
          width: 120,
          height: 44,
          child: Text(
            text,
            style: style ??
                const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ),
    );
  }
}
