import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftsmart/providers/user_provider.dart';
import 'package:shiftsmart/screens/chats/chatlist.dart';
import 'package:shiftsmart/screens/login.dart';
import 'package:shiftsmart/screens/manager/manager_employee_reports.dart';
import 'package:shiftsmart/screens/manager/manager_location_tracking.dart';
import 'package:shiftsmart/screens/manager/manager_profile.dart';
import 'package:shiftsmart/screens/manager/manager_settings.dart';
import 'package:shiftsmart/services/auth_service.dart';
import 'package:shiftsmart/utils/profile_helper.dart';
import 'package:shiftsmart/widgets/bottomnavbar.dart';
import 'package:shiftsmart/widgets/sidenav_profile_header.dart';

class AppTextStyle {
  static const sidenavtext = TextStyle(
    color: Colors.white,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
}

class Sidenav extends StatefulWidget {
  final String? currentScreen;
  const Sidenav({super.key, this.currentScreen});

  @override
  State<Sidenav> createState() => _SidenavState();
}

class _SidenavState extends State<Sidenav> {
  final AuthService _authService = AuthService();

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
      // Selectively clear session data, preserving biometric preferences
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
    // ... (Keep existing build method logic for layout)
    // Copy the `build` method from your original code, it was fine.
    // Just ensure `_showSitePicker(context)` is called in the Location Tracking item.
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
                            builder: (context) => ManagerProfile()),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  const Divider(color: Colors.white24, thickness: 1),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  buildNavItem('Home', 'assets/Home.png', iconSize, () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const Bottomnavbar(selectedIndex: 0)));
                  }, isActive: widget.currentScreen == 'Home'),
                  buildNavItem('Settings', 'assets/settings.png', iconSize, () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ManagerSettings()));
                  }, isActive: widget.currentScreen == 'ManagerSettings'),
                  buildNavItem('Reports', 'assets/Report.png', iconSize, () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const ManagerEmployeeReports()));
                  }, isActive: widget.currentScreen == 'ManagerReports'),
                  buildNavItem('Chat', 'assets/Chat.png', iconSize, () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const Chatlist()));
                  }, isActive: widget.currentScreen == 'Chat'),

                  //  Navigate directly to map screen
                  buildNavItem(
                      'Location Tracking', 'assets/Location.png', iconSize, () {
                    Navigator.of(context).pop(); // close drawer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ManagerLocationTracking(),
                      ),
                    );
                  }, isActive: widget.currentScreen == 'LocationTracking'),

                  buildNavItem('Log out', 'assets/logout.png', iconSize, () {
                    _handleLogout();
                  }),
                  const Divider(color: Colors.white24, thickness: 1),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Image.asset('assets/logo.png',
                  height: logoSize, width: logoSize),
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
        onTap: isActive ? null : onTap,
      ),
    );
  }
}
