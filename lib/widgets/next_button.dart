import 'package:flutter/material.dart';

class Nextbutton extends StatefulWidget {
  final VoidCallback onPressed;

  const Nextbutton({
    super.key,
    required this.onPressed,
  });

  @override
  State<Nextbutton> createState() => _NextbuttonState();
}

class _NextbuttonState extends State<Nextbutton> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(98, 0, 0, 0).withValues(alpha: 0.3), // Dark shadow
            offset: const Offset(3, 3), // Position of the shadow
            blurRadius: 8, // Blur effect
          ),
          
        ],
      ),
      child: ElevatedButton(
        onPressed: widget.onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: EdgeInsets.zero,
          minimumSize: const Size(40, 40),
          fixedSize: const Size(40, 40),
          elevation: 6, // Gives a lifted effect
          shadowColor: Colors.black.withValues(alpha: 0.5), // Shadow color
        ),
        child: const Icon(
          Icons.navigate_next,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
