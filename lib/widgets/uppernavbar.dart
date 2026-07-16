// import 'package:flutter/material.dart';
// import 'package:shiftsmart/screens/notifications.dart';
// import 'package:shiftsmart/services/notification_service.dart';

// class Uppernavbar extends StatefulWidget implements PreferredSizeWidget {
//   final bool showBackButton;

//   const Uppernavbar({super.key, this.showBackButton = false});

//   @override
//   Size get preferredSize => const Size.fromHeight(kToolbarHeight);

//   @override
//   State<Uppernavbar> createState() => _UppernavbarState();
// }

//   class _UppernavbarState extends State<Uppernavbar> {
//   bool hasUnreadNotifications = false;
//   // final NotificationService _notificationService = NotificationService();

//   @override
//   void initState() {
//     super.initState();
//     // checkUnreadNotifications();
//   }

//   // Future<void> checkUnreadNotifications() async {
//   //   try {
//   //     final result = await _notificationService.fetchNotifications('user_33', status: 'unread');
//   //     setState(() {
//   //       hasUnreadNotifications = result.isNotEmpty;
//   //     });
//   //   } catch (e) {
//   //     print("Error checking unread notifications: $e");
//   //   }
//   // }

//   @override
//   Widget build(BuildContext context) {
//     return AppBar(
//       backgroundColor: Colors.transparent,
//       elevation: 0,
//       automaticallyImplyLeading: false,
//       flexibleSpace: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [
//               Colors.transparent,
//               Colors.transparent,
//             ],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//         ),
//       ),
//       title: Row(
//         children: [
//           widget.showBackButton
//               ? GestureDetector(
//                   onTap: () => Navigator.pop(context),
//                   child: const Icon(Icons.arrow_back_ios_new,
//                       color: Colors.white, size: 28),
//                 )
//               : Image.asset('assets/logo.png', height: 100),
//           const Spacer(),

//           // Notification Icon with Red Dot
//           GestureDetector(
//             onTap: () async {
//               final currentRoute = ModalRoute.of(context)?.settings.name;

//               if (currentRoute == '/notifications') {
//                 Navigator.pop(context);
//               } else {
//                 await Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => Notifications(),
//                     settings: const RouteSettings(name: '/notifications'),
//                   ),
//                 );
//                 // checkUnreadNotifications(); // Recheck on return
//               }
//             },
//             child: Stack(
//               children: [
//                 const Padding(
//                   padding: EdgeInsets.all(10),
//                   child: Icon(Icons.notifications, color: Colors.blueAccent, size: 30),
//                 ),
//                 if (hasUnreadNotifications)
//                   Positioned(
//                     right: 6,
//                     top: 6,
//                     child: Container(
//                       width: 10,
//                       height: 10,
//                       decoration: const BoxDecoration(
//                         color: Colors.red,
//                         shape: BoxShape.circle,
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//           ),

//           // Drawer menu
//           Builder(
//             builder: (context) => GestureDetector(
//               onTap: () {
//                 Scaffold.of(context).openDrawer();
//               },
//               child: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
//                 decoration: BoxDecoration(
//                   gradient: const LinearGradient(
//                     colors: [
//                       Color(0xFF34C8E8),
//                       Color(0xFF4E4AF2),
//                     ],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                   borderRadius: BorderRadius.circular(10),
//                   boxShadow: [
//                     BoxShadow(
//                       color: const Color.fromARGB(98, 0, 0, 0).withValues(alpha: 0.3),
//                       offset: const Offset(3, 3),
//                       blurRadius: 8,
//                     ),
//                   ],
//                 ),
//                 child: Image.asset('assets/Menu.png', height: 30),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

// }

import 'package:flutter/material.dart';
import 'package:shiftsmart/screens/notifications.dart';
import 'package:shiftsmart/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:shiftsmart/providers/tenant_provider.dart';
import 'package:shiftsmart/providers/user_provider.dart';
import 'package:shiftsmart/widgets/bottomnavbar.dart';
import 'package:shiftsmart/widgets/emp_bottomnavbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Uppernavbar extends StatefulWidget implements PreferredSizeWidget {
  final bool showBackButton;
  final String? title;
  final String? profileImageUrl; // Added profileImageUrl

  const Uppernavbar({
    super.key,
    this.showBackButton = false,
    this.title,
    this.profileImageUrl, // Initialize it
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<Uppernavbar> createState() => _UppernavbarState();
}

class _UppernavbarState extends State<Uppernavbar> {
  int _unreadNotificationCount = 0;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadUnreadNotificationCount();
  }

  Future<void> _loadUnreadNotificationCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final employeeId = prefs.getInt('employeeId') ?? prefs.getInt('userId');
      if (employeeId == null) return;

      final unread = await _notificationService.fetchNotificationsUnread(
        employeeId,
        tenantId: _currentTenantId,
      );
      if (!mounted) return;
      setState(() => _unreadNotificationCount = unread.length);
    } catch (e) {
      debugPrint("Error checking unread notifications: $e");
    }
  }

  int? get _currentTenantId {
    try {
      final selectedTenant =
          Provider.of<TenantProvider>(context, listen: false).selectedTenant;
      final idRaw = selectedTenant?['tenantId'] ??
          selectedTenant?['TenantId'] ??
          selectedTenant?['id'] ??
          selectedTenant?['ID'];
      return idRaw == null ? null : int.tryParse(idRaw.toString());
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              Colors.transparent,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      title: Row(
        children: [
          // --- LEFT SIDE: Back Button OR Logo ---
          if (widget.showBackButton)
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Padding(
                padding: EdgeInsets.only(right: 12.0),
                child: Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 24),
              ),
            ),

          // --- MIDDLE: Title Text (+ Profile Image) OR Logo Image ---
          if (widget.title != null)
            Expanded(
              child: Row(
                children: [
                  if (widget.profileImageUrl != null &&
                      widget.profileImageUrl!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 10.0),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white24,
                        backgroundImage: NetworkImage(widget.profileImageUrl!),
                      ),
                    )
                  else if (widget.profileImageUrl != null)
                    const Padding(
                      padding: EdgeInsets.only(right: 10.0),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white24,
                        child:
                            Icon(Icons.person, color: Colors.white, size: 20),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      widget.title!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18, // Slightly smaller to fit image
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            )
          else
            GestureDetector(
              onTap: () {
                final userProvider =
                    Provider.of<UserProvider>(context, listen: false);
                final role =
                    userProvider.userProfile['userRole']?.toString() ?? '';
                final normalizedRole = role.trim().toLowerCase();

                if (normalizedRole.contains('manager') ||
                    normalizedRole.contains('admin')) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const Bottomnavbar(selectedIndex: 0)),
                    (route) => false,
                  );
                } else {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const EmpBottomnavbar()),
                    (route) => false,
                  );
                }
              },
              child: Image.asset('assets/logo.png', height: 100),
            ),

          // If we are showing the Title (Expanded), we don't need a spacer.
          // If we are showing the Logo (not Expanded), we need a spacer to push icons to the right.
          if (widget.title == null) const Spacer(),

          // --- RIGHT SIDE: Actions ---

          // Notification Icon with Red Dot
          GestureDetector(
            onTap: () async {
              final currentRoute = ModalRoute.of(context)?.settings.name;

              if (currentRoute == '/notifications') {
                Navigator.pop(context);
              } else {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const Notifications(),
                    settings: const RouteSettings(name: '/notifications'),
                  ),
                );
                _loadUnreadNotificationCount();
              }
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.notifications,
                      color: Colors.blueAccent, size: 30),
                ),
                if (_unreadNotificationCount > 0)
                  Positioned(
                    right: 0,
                    top: 2,
                    child: Container(
                      constraints:
                          const BoxConstraints(minWidth: 18, minHeight: 18),
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        _unreadNotificationCount > 99
                            ? '99+'
                            : _unreadNotificationCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 8), // Small gap between Notification and Menu

          // Drawer menu
          Builder(
            builder: (context) => GestureDetector(
              onTap: () {
                Scaffold.of(context).openDrawer();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF34C8E8),
                      Color(0xFF4E4AF2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(98, 0, 0, 0)
                          .withValues(alpha: 0.3),
                      offset: const Offset(3, 3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Image.asset('assets/Menu.png', height: 30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
