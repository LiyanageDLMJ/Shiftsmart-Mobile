import 'dart:ui';

import 'package:flutter/material.dart';

class Gradienthorizontal extends StatefulWidget {
  final double width;
  final double? height;
  final Widget? child;
  const Gradienthorizontal({super.key, required this.width, this.height, this.child});

  @override
  State<Gradienthorizontal> createState() => _GradienthorizontalState();
}

class _GradienthorizontalState extends State<Gradienthorizontal> {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0), 
        child: Container(
          width: widget.width,
          height: widget.height, 
          constraints: widget.height == null
              ? const BoxConstraints(minHeight: 200) 
              : null,
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
            child: widget.child, 
          ),
        ),
      ),
    );
  }
}
