import 'dart:ui';
import 'package:flutter/material.dart';

class Gradientbox extends StatefulWidget {
  final double width;
  final double height;
  final Widget? child;

  const Gradientbox({
    super.key,
    required this.width,
    required this.height,
    this.child,
  });

  @override
  State<Gradientbox> createState() => _GradientboxState();
}

class _GradientboxState extends State<Gradientbox> {
  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: SlantedClipper(), // Apply the slanted clipper here
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20), // Match the container's border
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0), // Blur effect
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color.fromARGB(180, 53, 63, 84),
                  Color.fromARGB(180, 34, 40, 52),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: widget.child, // Ensure child content is displayed
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom Clipper to create a slanted right side
class SlantedClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(0, 0); // Top-left corner
    path.lineTo(size.width, 0); // Top-right corner
    path.lineTo(size.width, size.height * 0.85); // Slanted bottom-right
    path.lineTo(0, size.height); // Bottom-left corner
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
