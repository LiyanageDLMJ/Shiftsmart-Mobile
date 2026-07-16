import 'package:flutter/material.dart';
import 'package:shiftsmart/screens/manager/manager_employee_performance_report.dart';
import 'package:shiftsmart/screens/manager/manager_attendance_report.dart';
import 'package:shiftsmart/utils/fullscreen_helper.dart';
import 'package:shiftsmart/widgets/background.dart';
import 'package:shiftsmart/widgets/sidenav.dart';
import 'package:shiftsmart/widgets/uppernavbar.dart';
import 'package:provider/provider.dart';
import 'package:shiftsmart/providers/tenant_provider.dart';
import 'package:shiftsmart/widgets/premium_feature_gate.dart';

class ManagerEmployeeReports extends StatefulWidget {
  const ManagerEmployeeReports({super.key});

  @override
  State<ManagerEmployeeReports> createState() => _ManagerEmployeeReportsState();
}

class _ManagerEmployeeReportsState extends State<ManagerEmployeeReports> {
  @override
  void initState() {
    super.initState();
    enableFullScreen();
    
  }
  @override
  Widget build(BuildContext context) {
    return Consumer<TenantProvider>(
      builder: (context, tp, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF1C2230),
          appBar: const Uppernavbar(),
          drawer: const Sidenav(
            currentScreen: 'ManagerReports',
          ),
          body: Stack(
            children: [
              const Positioned(child: Background()),
              Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 20),
                      child: Column(
                        children: [
                          _buildReportCard(
                            icon: Icons.line_axis_sharp,
                            title: "Employee Performance Reports",
                            isBlocked: !tp.isFeatureEnabled('reporting_analytics') || 
                                       !tp.isFeatureEnabled('performance_reports') || 
                                       tp.isEndpointBlocked('report') || 
                                       tp.isEndpointBlocked('employee'),
                            onPressed: () {
                              if (!tp.isFeatureEnabled('reporting_analytics') || 
                                  !tp.isFeatureEnabled('performance_reports') || 
                                  tp.isEndpointBlocked('report') || 
                                  tp.isEndpointBlocked('employee')) {
                                PremiumFeatureGate.showDialog(
                                  context,
                                  featureName: 'Performance Reports',
                                  blockedEndpoint: '/api/employee/all',
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ManagerEmployeePerformanceReport(),
                                  ),
                                );
                              }
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildReportCard(
                            icon: Icons.fact_check_outlined,
                            title: "Shift Attendance Report",
                            isBlocked: !tp.isFeatureEnabled('attendance_tracking') || 
                                       tp.isEndpointBlocked('attendance'),
                            onPressed: () {
                              if (!tp.isFeatureEnabled('attendance_tracking') || 
                                  tp.isEndpointBlocked('attendance')) {
                                PremiumFeatureGate.showDialog(
                                  context,
                                  featureName: 'Attendance Reports',
                                  blockedEndpoint: '/api/attendance/all',
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const Managerattendancereport(),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportCard({
    required IconData icon,
    required String title,
    required VoidCallback onPressed,
    bool isBlocked = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromARGB(180, 42, 50, 67),
            Color.fromARGB(180, 34, 40, 52),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00B6E6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(icon, color: Colors.white, size: 24),
                      if (isBlocked)
                        Positioned(
                          top: -8,
                          right: -8,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF7A5C00), Color(0xFFB8880A)],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFB8880A).withOpacity(0.5),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.workspace_premium_rounded,
                              color: Color(0xFFFFD700),
                              size: 10,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_sharp, color: Colors.white, size: 35),
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }


}
