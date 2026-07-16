import 'package:flutter/material.dart';

Theme datePickerThemeBuilder(BuildContext context, Widget? child) {
  return Theme(
    data: Theme.of(context).copyWith(
      colorScheme: const ColorScheme.dark(
        surface: Color(0xFF1E2433),
        primary: Color(0xFF34C8E8),
        onPrimary: Colors.white,
        onSurface: Colors.white,
        secondary: Color(0xFF4E4AF2),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
        bodyLarge: TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
        labelLarge: TextStyle(
          color: Color(0xFF34C8E8),
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    child: child!,
  );
}
