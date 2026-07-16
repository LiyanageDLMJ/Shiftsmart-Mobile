import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shiftsmart/providers/tenant_provider.dart';
import 'package:shiftsmart/widgets/premium_feature_gate.dart';
import 'package:shiftsmart/widgets/background.dart';
import 'package:shiftsmart/widgets/uppernavbar.dart';
import 'package:shiftsmart/widgets/sidenav.dart';

/// A wrapper widget that checks if a specific feature is enabled for the current tenant.
/// If disabled, it displays a "Premium Access Required" screen.
class FeatureGate extends StatelessWidget {
  final String featureKey;
  final String featureName;
  final Widget child;
  final String? currentScreen;

  const FeatureGate({
    super.key,
    required this.featureKey,
    required this.featureName,
    required this.child,
    this.currentScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<TenantProvider>(
      builder: (context, tp, _) {
        // List of features that should be strictly gated pre-emptively
        const List<String> gatedFeatures = [
          'job_management',
          'shift_scheduling',
          'leave_management',
          'attendance_tracking',
          'performance_reports',   // Added
          'reporting_analytics',   // Added (alternative key)
          'location_tracking',
          'site_management',       // Added
          'project_management',    // Added (alternative key)
          'notifications',
        ];

        // If the feature is in our gated list AND is not enabled, show the block UI
        if (gatedFeatures.contains(featureKey) && !tp.isFeatureEnabled(featureKey)) {
          return Stack(
            children: [
              const Positioned.fill(child: Background()),
              Scaffold(
                backgroundColor: Colors.transparent,
                appBar: const Uppernavbar(),
                drawer: Sidenav(currentScreen: currentScreen),
                body: SafeArea(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: PremiumFeatureGate(
                        featureName: featureName,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        // For all other features, or if enabled, show the actual screen
        return child;
      },
    );
  }
}
