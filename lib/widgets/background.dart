import 'package:flutter/material.dart';

class Background extends StatelessWidget {
  const Background({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dark background
        Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1C2230), // Dark navy background color
          ),
        ),

        // Slanted gradient shape
        Align(
          alignment: Alignment.bottomRight,
          child: ClipPath(
            clipper: CustomShapeClipper(),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.8,
              width: MediaQuery.of(context).size.width,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    Color(0xFF2DA6FF), // Light blue
                    Color(0xFF3C5AFF), // Dark blue
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Custom clipper for the slanted shape
class CustomShapeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(size.width * 0.8, 0); // Starting point (angled top)
    path.lineTo(size.width, size.height * 0.1); // Slant down
    path.lineTo(size.width, size.height); // Bottom right
    path.lineTo(0, size.height); // Bottom left
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
