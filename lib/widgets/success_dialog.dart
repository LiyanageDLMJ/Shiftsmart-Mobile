import 'package:flutter/material.dart';
import 'package:shiftsmart/widgets/gradient_button.dart';

class SuccessDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final VoidCallback onPressed;

  const SuccessDialog({
    super.key,
    required this.title,
    required this.message,
    required this.buttonText,
    required this.onPressed,
  });

  // A static helper method to show the dialog easily from anywhere
  static void show(
    BuildContext context, {
    required String title,
    required String message,
    required String buttonText,
    VoidCallback? onPressed,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return SuccessDialog(
          title: title,
          message: message,
          buttonText: buttonText,
          onPressed: () {
            // Close the dialog using the dialog's own context
            Navigator.of(dialogContext, rootNavigator: true).pop();
            // Then execute any additional logic if provided
            if (onPressed != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) => onPressed());
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2A2F45), // Your specific dark blue color
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          // The Icon Circle
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.check_circle, color: Colors.green, size: 60),
          ),
          const SizedBox(height: 20),
          // Title
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          // Message
          Text(
            message,
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          // Button
          SizedBox(
            width: double.infinity,
            child: GradientButton(
              text: buttonText,
              onPressed:
                  onPressed, // Calls the internal wrapper that pops the dialog
            ),
          ),
        ],
      ),
    );
  }
}
