import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftsmart/providers/user_provider.dart';
import 'package:shiftsmart/screens/employee/employee_cert.dart';
import 'package:shiftsmart/screens/employee/employee_emergency.dart';
import 'package:shiftsmart/screens/employee/employee_faq.dart';
import 'package:shiftsmart/screens/employee/employee_settings.dart';
import 'package:shiftsmart/screens/login.dart';

import 'package:shiftsmart/screens/employee/employee_profile.dart';
import 'package:shiftsmart/services/phone_service.dart';
import 'package:shiftsmart/utils/profile_helper.dart';
import 'package:shiftsmart/widgets/emp_bottomnavbar.dart';
import 'package:shiftsmart/services/auth_service.dart';
import 'package:shiftsmart/widgets/sidenav_profile_header.dart';

class AppTextStyle {
  static const sidenavtext = TextStyle(
    color: Colors.white,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );
}

class EmpSidenav extends StatefulWidget {
  final String? currentScreen;
  const EmpSidenav({super.key, this.currentScreen});

  @override
  State<EmpSidenav> createState() => _EmpSidenavState();
}

class _EmpSidenavState extends State<EmpSidenav> {
  final AuthService _authService = AuthService();

  // ignore: prefer_typing_uninitialized_variables
  late final userProfile;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      refreshUserProfileFromBackend(context, authService: _authService);
    });
  }

  void _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    int? employeeId = prefs.getInt('employeeId');

    bool success = await _authService.logout(employeeId);

    if (success) {
      // Selectively clear session data, preserving biometric preferences and email
      await prefs.remove('appToken');
      await prefs.remove('userId');
      await prefs.remove('userRole');
      await prefs.remove('userName');
      await prefs.remove('employeeId');

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Logout failed. Please try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final userProfile = userProvider.userProfile;

    if (userProfile.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final size = MediaQuery.of(context).size;
    final paddingUnit = size.width * 0.05;
    final iconSize = size.width * 0.06;
    final logoSize = size.width * 0.4;
    return Drawer(
      width: size.width * 0.5,
      child: Container(
        color: const Color(0xFF161622),
        child: Column(
          children: [
            Padding(
              padding:
                  EdgeInsets.only(top: paddingUnit * 3, bottom: paddingUnit),
              child: Column(
                children: [
                  SidenavProfileHeader(
                    userProfile: userProfile,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const EmployeeProfile()),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  const Divider(color: Colors.white24, thickness: 1),
                ],
              ),
            ),

            // Navigation Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  buildNavItem('Home', 'assets/Home.png', iconSize, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EmpBottomnavbar(),
                      ),
                    );
                  }, isActive: widget.currentScreen == 'Home'),
                  buildNavItem(
                    'Settings',
                    'assets/settings.png',
                    iconSize,
                    () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EmployeeSettings(),
                          settings:
                              const RouteSettings(name: 'EmployeeSettings'),
                        ),
                      );
                    },
                    isActive: widget.currentScreen == 'EmployeeSettings',
                  ),
                  buildNavItem(
                    'Emergency',
                    'assets/Siren.png',
                    iconSize,
                    () {
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EmployeeEmergency(
                                phoneService: RealPhoneService()),
                            settings:
                                const RouteSettings(name: 'EmployeeEmergency'),
                          ));
                    },
                    isActive: widget.currentScreen == 'EmployeeEmergency',
                  ),
                  buildNavItem(
                    'Certificate',
                    'assets/Diploma.png',
                    iconSize,
                    () {
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Employeecert(),
                            settings: const RouteSettings(name: 'EmployeeCert'),
                          ));
                    },
                    isActive: widget.currentScreen == 'EmployeeCert',
                  ),
                  buildNavItem(
                    'FAQ',
                    'assets/faq.png',
                    iconSize,
                    () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EmployeeFaq(),
                            settings: const RouteSettings(name: 'EmployeeFAQ'),
                          ));
                    },
                    isActive: widget.currentScreen == 'EmployeeFAQ',
                  ),
                  buildNavItem('Log out', 'assets/logout.png', iconSize, () {
                    // Navigator.push(context,
                    //     MaterialPageRoute(builder: (context) => const Login()));
                    _handleLogout();
                  }),
                  const Divider(color: Colors.white24, thickness: 1),
                ],
              ),
            ),

            // Bottom Logo
            Padding(
              padding: EdgeInsets.symmetric(vertical: paddingUnit * 1.5),
              child: Image.asset(
                'assets/logo.png',
                height: logoSize,
                width: logoSize,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildNavItem(
      String title, String iconPath, double iconSize, VoidCallback? onTap,
      {bool isActive = false}) {
    final textStyle = AppTextStyle.sidenavtext.copyWith(
      fontSize: MediaQuery.of(context).size.width * 0.03,
      color: Colors.white,
      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.blueAccent.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isActive
            ? Border.all(color: Colors.blueAccent.withValues(alpha: 0.3))
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        title: Row(
          children: [
            Image.asset(
              iconPath,
              height: iconSize,
              color: isActive ? Colors.blueAccent : Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textStyle,
              ),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
