import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors - Core palette
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFCCCCCC);
  static const Color iconBorderColor = Color(0xFF7A8CA8);
  static const Color buttonHighlight = Color(0xFF326BFF);
  static const Color sidebarBg = Color(0xFF161622);
  static const Color backgroundColor = Color(0xFF1C2230);

  // Linear gradient for background
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color.fromARGB(180, 42, 50, 67),
      Color.fromARGB(180, 34, 40, 52),
    ],
  );

  // Linear gradient for background
  static const LinearGradient innerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF363E51),
      Color(0xFF191E26),
    ],
  );

  static const LinearGradient gradientBlueButton = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF34C8E8),
      Color(0xFF4E4AF2),
    ], // Dark to blue gradient
  );

  // Border Radius
  static const double borderRadiusS = 6.0; // Small buttons, chips
  static const double borderRadiusM = 8.0; // Input fields, cards
  static const double borderRadiusL = 12.0; // Large containers
  static const double borderRadiusXL = 24.0; // Full rounded corners

  // Component sizing
  static const double iconSizeS = 16.0;
  static const double iconSizeM = 22.0;
  static const double iconSizeL = 32.0;

  // Text Styles - Using Google Fonts
  static TextStyle headingLarge(BuildContext context) {
    return GoogleFonts.poppins(
      fontSize: 20.0,
      fontWeight: FontWeight.bold,
      color: textPrimary,
    );
  }

  static TextStyle headingMedium(BuildContext context) {
    return GoogleFonts.poppins(
      fontSize: 18.0,
      fontWeight: FontWeight.w600,
      color: textPrimary,
    );
  }

  static TextStyle headingSmall(BuildContext context) {
    return GoogleFonts.poppins(
      fontSize: 16.0,
      fontWeight: FontWeight.w600,
      color: textPrimary,
    );
  }

  static TextStyle headingExSmall(BuildContext context) {
    return GoogleFonts.poppins(
      fontSize: 14.0,
      fontWeight: FontWeight.w600,
      color: textPrimary,
    );
  }

  // Navigation text - for any navigation item, not just sidenav
  static TextStyle navText(BuildContext context) {
    return GoogleFonts.poppins(
      color: textPrimary,
      fontSize: 14.0,
      fontWeight: FontWeight.w500,
    );
  }

  // Helper methods for common UI elements
  static BoxDecoration gradientBoxDecoration() {
    return const BoxDecoration(
      gradient: backgroundGradient,
    );
  }

  static BoxDecoration cardBoxDecoration() {
    return BoxDecoration(
      color: sidebarBg,
      borderRadius: BorderRadius.circular(borderRadiusM),
      boxShadow: const [
        BoxShadow(
          color: Color(0x40000000),
          blurRadius: 4,
          offset: Offset(0, 2),
        ),
      ],
    );
  }
}
