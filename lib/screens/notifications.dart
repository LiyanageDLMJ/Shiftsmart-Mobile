//lib/screens/Notifications.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftsmart/models/notification.dart';
import 'package:shiftsmart/services/notification_service.dart';
import 'package:shiftsmart/widgets/background.dart';
import 'package:intl/intl.dart'; // Add this for formatting dates
import 'package:shiftsmart/services/super_admin_service.dart'; // Add this to call your active announcements API
import 'package:provider/provider.dart';
import 'package:shiftsmart/providers/tenant_provider.dart';
import 'package:shiftsmart/utils/date_time_parser.dart';
import 'package:shiftsmart/widgets/emp_bottomnavbar.dart';
import 'package:shiftsmart/widgets/organization_selector.dart';

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  List<NotificationItem> allNotifications = [];
  List<int> unreadNotificationIds = [];
  List<dynamic> activeAnnouncements =
      []; // NEW: Array for real DB announcements
  bool isLoading = true;
  int _selectedTabIndex = 0; // Defaulting to 0 (Unread) is usually better UX
  String _userRole = 'Employee'; // Added to track user role

  final NotificationService _notificationService = NotificationService();
  final SuperAdminService _superAdminService =
      SuperAdminService(); // NEW: The announcement service

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    debugPrint('loadNotifications STARTED');
    if (mounted) {
      setState(() => isLoading = true);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final employeeId = prefs.getInt('employeeId');
      final role = prefs.getString('userRole') ?? 'Employee';

      if (employeeId == null) {
        throw Exception("Employee ID not found in SharedPreferences");
      }

      // --- Grab the actively selected organization's tenant Id ---
      final tp = context.read<TenantProvider>();
      final selectedTenant = tp.selectedTenant;

      int? currentTenantId;
      if (selectedTenant != null) {
        final idRaw = selectedTenant['tenantId'] ??
            selectedTenant['TenantId'] ??
            selectedTenant['id'] ??
            selectedTenant['ID'];
        if (idRaw != null) {
          currentTenantId = int.tryParse(idRaw.toString());
        }
      }
      currentTenantId = await _notificationService.resolveCurrentTenantId(
        tenantId: currentTenantId,
      );

      final List<NotificationItem> fetchedRead = [];
      final List<NotificationItem> fetchedUnread = [];
      List<dynamic> fetchedAnnouncements = [];

      // 1. Fetch Notifications independently (safely caught)
      try {
        final read = await _notificationService.fetchNotificationsread(
          employeeId,
          tenantId: currentTenantId,
        );
        fetchedRead.addAll(read);

        final unread = await _notificationService.fetchNotificationsUnread(
          employeeId,
          tenantId: currentTenantId,
        );
        fetchedUnread.addAll(unread);
      } catch (e) {
        debugPrint("Error fetching normal notifications: $e");
      }

      // 2. Fetch Announcements independently (safely caught)
      try {
        fetchedAnnouncements = await _superAdminService.getActiveAnnouncements(
            tenantId: currentTenantId);
      } catch (e) {
        debugPrint("Error fetching announcements: $e");
      }

      // Store unread IDs for marking later
      unreadNotificationIds = fetchedUnread.map((n) => n.id).toList();

      if (mounted) {
        setState(() {
          allNotifications = [...fetchedRead, ...fetchedUnread];
          allNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          activeAnnouncements = fetchedAnnouncements;
          _userRole = role; // Set the role in state
          isLoading = false;
        });
      }
    } catch (e, stack) {
      debugPrint(" Error loading setup: $e");
      debugPrint(stack.toString());
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _markAllUnreadAsRead() async {
    try {
      if (unreadNotificationIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No unread notifications.")),
        );
        return;
      }

      await _notificationService.markAsRead(unreadNotificationIds);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Marked unread notifications as read.")),
      );

      // Refresh after marking
      loadNotifications();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to mark as read: $e")),
      );
    }
  }

  Map<String, List<NotificationItem>> groupNotifications(
      List<NotificationItem> all) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final grouped = <String, List<NotificationItem>>{
      'New': [],
      'Earlier Today': [],
      'Yesterday': [],
      'Older': [],
    };

    for (var notif in all) {
      final notifDate = notif.createdAt;
      final difference = now.difference(notifDate);

      if (difference.inMinutes < 60) {
        grouped['New']!.add(notif);
      } else if (notifDate.isAfter(today)) {
        grouped['Earlier Today']!.add(notif);
      } else if (notifDate.isAfter(yesterday)) {
        grouped['Yesterday']!.add(notif);
      } else {
        grouped['Older']!.add(notif);
      }
    }

    return grouped;
  }

  List<Widget> buildGroupedNotifications(
      Map<String, List<NotificationItem>> grouped) {
    final widgets = <Widget>[];

    grouped.forEach((section, notifications) {
      if (notifications.isEmpty) return;

      widgets.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Text(
          section,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ));

      for (var notif in notifications) {
        final isUnread =
            unreadNotificationIds.contains(notif.id); //  check if unread

        widgets.add(Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(vertical: 6.0),
          color: Colors.transparent,
          elevation: 4,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isUnread
                    ? [
                        const Color.fromARGB(
                            200, 60, 70, 90), // Lighter for unread
                        const Color.fromARGB(200, 40, 50, 70),
                      ]
                    : [
                        const Color.fromARGB(180, 42, 50, 67),
                        const Color.fromARGB(180, 34, 40, 52),
                      ],
              ),
              borderRadius: const BorderRadius.all(Radius.circular(12)),
            ),
            child: ListTile(
              onTap: () async {
                if (isUnread) {
                  await _notificationService.markAsRead([notif.id]);
                  await loadNotifications();
                }

                if (!mounted) return;
                final role = _userRole.toLowerCase();
                if (notif.type.toLowerCase() == 'shift_assignment' &&
                    !role.contains('admin') &&
                    !role.contains('manager')) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EmpBottomnavbar(selectedIndex: 1),
                    ),
                  );
                }
              },
              leading: Icon(
                notif.type.toLowerCase() == 'shift_assignment'
                    ? Icons.calendar_month
                    : Icons.notifications,
                color: Colors.white,
              ),
              title: Text(
                notif.subject,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Text(
                notif.message,
                style: TextStyle(
                  color: isUnread ? Colors.white70 : Colors.grey,
                ),
              ),
            ),
          ),
        ));
      }
    });

    return widgets;
  }

  bool get _isAdminOrManager =>
      _userRole.toLowerCase().contains("admin") ||
      _userRole.toLowerCase().contains("manager");

  List<dynamic> get _visibleAnnouncements {
    return activeAnnouncements.where((ann) {
      if (_isAdminOrManager) return true;
      return !_isBillingAnnouncement(ann);
    }).toList();
  }

  Widget _buildTabButton(
    String title,
    int index,
    int count, {
    IconData? icon,
    int flex = 1,
  }) {
    final isActive = _selectedTabIndex == index;
    final foregroundColor = isActive ? Colors.white : Colors.white60;
    final content = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: foregroundColor, size: 14),
            const SizedBox(width: 4),
          ],
          Text(
            "$title ($count)",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: foregroundColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );

    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            content,
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  bool _isBillingAnnouncement(dynamic ann) {
    final title = (ann['title'] ?? ann['Title'] ?? '').toString().toLowerCase();
    final body =
        (ann['body'] ?? ann['Body'] ?? ann['message'] ?? ann['Message'] ?? '')
            .toString()
            .toLowerCase();

    // Check for common billing/subscription keywords
    return title.contains('billing alert') ||
        title.contains('subscription') ||
        title.contains('billing') ||
        body.contains('subscription') ||
        body.contains('grace period') ||
        body.contains('billing');
  }

  Widget _buildAnnouncementsList() {
    if (isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.blueAccent));
    }

    if (activeAnnouncements.isEmpty) {
      return const Center(
          child: Text("No active announcements.",
              style: TextStyle(color: Colors.white70)));
    }

    // Filter announcements based on role: Billing/Subscription alerts -> Admin/Manager only
    final filteredAnnouncements = _visibleAnnouncements;

    if (filteredAnnouncements.isEmpty) {
      return const Center(
          child: Text("No active announcements.",
              style: TextStyle(color: Colors.white70)));
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: filteredAnnouncements.length,
      itemBuilder: (context, index) {
        final ann = filteredAnnouncements[index];

        // Safely extract properties accommodating backend case-naming variations
        final title = ann['title'] ?? ann['Title'] ?? 'Announcement';
        final body = ann['body'] ??
            ann['Body'] ??
            ann['message'] ??
            ann['Message'] ??
            '';

        // Format the date securely
        final rawDate = ann['createdAt'] ?? ann['CreatedAt'] ?? '';
        final dateInfo = parseServerDateTime(rawDate) ?? DateTime.now();
        final displayDate = DateFormat('MM/dd/yyyy, HH:mm:ss').format(dateInfo);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1C2230),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              // Yellow vertical bar
              Container(
                width: 4,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFD700),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.campaign,
                          color: Color(0xFFFFD700), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              body,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              displayDate,
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // NEW: Filter notifications before sending them to the group builder
    final filteredNotifications = allNotifications.where((notif) {
      final isUnread = unreadNotificationIds.contains(notif.id);
      if (_selectedTabIndex == 0) {
        return isUnread; // If 'Unread' tab, only show unread
      }
      if (_selectedTabIndex == 1) {
        return !isUnread; // If 'Read' tab, only show already read
      }
      return false; // Tab 2 is announcements
    }).toList();
    final grouped = groupNotifications(filteredNotifications);
    final unreadCount = unreadNotificationIds.length;
    final readCount = allNotifications.length - unreadCount;
    final announcementCount = _visibleAnnouncements.length;

    return Stack(
      children: [
        const Positioned.fill(child: Background()),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    children: [
                      const Icon(Icons.notifications,
                          color: Colors.blueAccent, size: 28),
                      const SizedBox(width: 10),
                      const Text(
                        "Notifications",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: loadNotifications,
                        child: const Icon(Icons.refresh,
                            color: Colors.white54, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  OrganizationSelector(onTenantSwitched: loadNotifications),
                  const SizedBox(height: 16),

                  // Main container box
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D3243)
                            .withValues(alpha: 0.9), // Dark grayish blue
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tabs
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 12, right: 12, top: 18, bottom: 8),
                            child: Row(
                              children: [
                                _buildTabButton("Unread", 0, unreadCount,
                                    flex: 7),
                                const SizedBox(width: 8),
                                _buildTabButton("Read", 1, readCount, flex: 7),
                                const SizedBox(width: 8),
                                _buildTabButton(
                                  "Announcements",
                                  2,
                                  announcementCount,
                                  icon: Icons.campaign,
                                  flex: 13,
                                ),
                              ],
                            ),
                          ),
                          // Content area
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20.0),
                              child: _selectedTabIndex == 2
                                  ? _buildAnnouncementsList()
                                  : (isLoading
                                      ? const Center(
                                          child: CircularProgressIndicator(
                                              color: Colors.blueAccent))
                                      : filteredNotifications.isEmpty
                                          ? Center(
                                              child: Text(
                                                _selectedTabIndex == 0
                                                    ? "No unread notifications."
                                                    : "No read notifications.",
                                                style: const TextStyle(
                                                    color: Colors.white70),
                                              ),
                                            )
                                          : ListView(
                                              padding: const EdgeInsets.only(
                                                  top: 10),
                                              children: [
                                                if (_selectedTabIndex == 0 &&
                                                    unreadNotificationIds
                                                        .isNotEmpty)
                                                  Align(
                                                    alignment:
                                                        Alignment.centerRight,
                                                    child: TextButton(
                                                      onPressed:
                                                          _markAllUnreadAsRead,
                                                      child: const Text(
                                                          "Mark all as read",
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .blueAccent)),
                                                    ),
                                                  ),
                                                ...buildGroupedNotifications(
                                                    grouped)
                                              ],
                                            )),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  // Close Button
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A8B9C), // Teal button
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: const Text(
                      "Close",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
