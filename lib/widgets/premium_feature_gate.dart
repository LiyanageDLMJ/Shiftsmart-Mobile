import 'package:flutter/material.dart';

/// Shows the "Premium Access" lock card as a bottom sheet or dialog.
///
/// Usage (show as modal):
/// ```dart
/// PremiumFeatureGate.show(
///   context,
///   featureName: 'Job Management',
///   blockedEndpoint: '/api/job/list',
/// );
/// ```
///
/// Usage (inline widget, e.g. replacing a disabled screen body):
/// ```dart
/// PremiumFeatureGate(
///   featureName: 'Job Management',
///   blockedEndpoint: '/api/job/list',
/// )
/// ```
class PremiumFeatureGate extends StatelessWidget {
  final String featureName;
  final String? blockedEndpoint;
  final String? customMessage;
  final VoidCallback? onGotIt;

  const PremiumFeatureGate({
    super.key,
    required this.featureName,
    this.blockedEndpoint,
    this.customMessage,
    this.onGotIt,
  });

  // ── Static helper: show as a modal bottom sheet 
  static Future<void> show(
    BuildContext context, {
    required String featureName,
    String? blockedEndpoint,
    String? customMessage,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => PremiumFeatureGate(
        featureName: featureName,
        blockedEndpoint: blockedEndpoint,
        customMessage: customMessage,
        onGotIt: () => Navigator.of(context).pop(),
      ),
    );
  }

  // ── Static helper: show as a dialog 
  static Future<void> showDialog(
    BuildContext context, {
    required String featureName,
    String? blockedEndpoint,
    String? customMessage,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Premium Feature',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (ctx, anim, _, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      pageBuilder: (ctx, _, __) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: PremiumFeatureGate(
            featureName: featureName,
            blockedEndpoint: blockedEndpoint,
            customMessage: customMessage,
            onGotIt: () => Navigator.of(ctx).pop(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF141B2D),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white12, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 40,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: badge + close button ───────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Crown + PREMIUM ACCESS badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7A5C00), Color(0xFFB8880A)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFB8880A).withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.workspace_premium_rounded,
                          color: Color(0xFFFFD700), size: 16),
                      SizedBox(width: 6),
                      Text(
                        'PREMIUM ACCESS',
                        style: TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),

                // Close button
                if (onGotIt != null)
                  GestureDetector(
                    onTap: onGotIt,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: const Icon(Icons.close,
                          color: Colors.white54, size: 20),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 22),

            // ── Lock icon + title ────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Lock icon box
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A3040),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.cyan.withOpacity(0.3), width: 1),
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: Color(0xFF2DA6C8),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$featureName is not included in your package',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Upgrade your tenant package to unlock this feature.',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Admin contact message ────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12, width: 1),
              ),
              child: Text(
                customMessage ??
                    'Contact your administrator to enable this module for your tenant.',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 22),

            // ── Got it button ────────────────────────────────────────────
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: onGotIt ?? () => Navigator.of(context).pop(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 13),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2DA6C8), Color(0xFF1976D2)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2DA6C8).withOpacity(0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Text(
                    'Got it',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
