import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shiftsmart/providers/tenant_provider.dart';
import 'package:shiftsmart/screens/manager/manager_employee.dart';
import 'package:shiftsmart/screens/manager/manager_leave.dart';
import 'package:shiftsmart/screens/manager/manager_jobs.dart';
import 'package:shiftsmart/screens/manager/manager_projects.dart';
import 'package:shiftsmart/screens/manager/managerdashboard.dart';
import 'package:shiftsmart/widgets/sidenav.dart';
import 'package:shiftsmart/widgets/uppernavbar.dart';

class Bottomnavbar extends StatefulWidget {
  final int selectedIndex;
  final int jobsInitialTabIndex;

  const Bottomnavbar({
    required this.selectedIndex,
    this.jobsInitialTabIndex = 0,
    super.key,
  });

  @override
  State<Bottomnavbar> createState() => _BottomnavbarState();
}

class _BottomnavbarState extends State<Bottomnavbar> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;

    // Load available tenants once the navbar is mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TenantProvider>().loadTenants();
    });
  }

  List<Widget> get _pages => [
        const Managerdashboard(),
        const Managerprojects(),
        Managerjobs(initialTabIndex: widget.jobsInitialTabIndex),
        const Manageremployee(),
        const Managerleave(),
      ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<String> icons = [
    'assets/Home.png',
    'assets/projects.png',
    'assets/shifts.png',
    'assets/employee.png',
    'assets/request.png',
  ];

  String _getPageTitle() {
    switch (_selectedIndex) {
      case 0:
        return "Manager Dashboard";
      case 1:
        return "Projects";
      case 2:
        return "Jobs";
      case 3:
        return "Employees";
      case 4:
        return "Leave Requests";
      default:
        return "";
    }
  }

  // ── Tenant picker sheet ────────────────────────────────────────────────────
  void _showTenantPicker(BuildContext context) {
    final tenantProvider = context.read<TenantProvider>();
    final tenants = tenantProvider.tenants;

    if (tenants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No organisations available.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return Consumer<TenantProvider>(
          builder: (_, tp, __) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF262A34), Color(0xFF1C2230)],
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(color: Colors.white12, width: 1),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      children: [
                        Icon(Icons.business_rounded,
                            color: Colors.blueAccent, size: 22),
                        SizedBox(width: 10),
                        Text(
                          'SELECT ORGANISATION',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white12, height: 1),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: tp.tenants.length,
                      itemBuilder: (_, i) {
                        final tenant = tp.tenants[i];
                        final name =
                            (tenant['name'] ?? tenant['Name'] ?? 'Unnamed')
                                .toString();
                        final isSelected = name.toLowerCase() ==
                            tp.selectedOrganization.toLowerCase();

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 4),
                          leading: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.blueAccent.withOpacity(0.2)
                                  : Colors.white.withOpacity(0.05),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.blueAccent
                                    : Colors.white24,
                                width: 1.5,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.blueAccent
                                    : Colors.white70,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          title: Text(
                            name,
                            style: TextStyle(
                              color:
                                  isSelected ? Colors.blueAccent : Colors.white,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 15,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle,
                                  color: Colors.blueAccent, size: 20)
                              : null,
                          onTap: () async {
                            Navigator.pop(sheetCtx);
                            if (!isSelected) {
                              final success = await context
                                  .read<TenantProvider>()
                                  .switchTenant(tenant);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? 'Switched to $name'
                                          : 'Switched to $name (Offline Mode)',
                                    ),
                                    backgroundColor:
                                        success ? Colors.green : Colors.orange,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            }
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFF1C2230),
      drawer: Sidenav(currentScreen: _selectedIndex == 0 ? 'Home' : null),
      appBar: const Uppernavbar(),
      body: _pages[_selectedIndex],
      extendBody: true,
      bottomNavigationBar: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Background with clipped shape
          ClipPath(
            clipper: RightCornerClipper(),
            child: Container(
              height: 90,
              color: const Color.fromARGB(252, 60, 82, 170),
            ),
          ),

          // Floating icons + active background
          Positioned(
            bottom: 15,
            left: 1,
            right: 1,
            child: Consumer<TenantProvider>(
              builder: (context, tp, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(icons.length, (index) {
                    final bool isSelected = index == _selectedIndex;
                    final bool isBlocked = tp.isNavIndexBlocked(index);

                    return GestureDetector(
                      onTap: () => _onItemTapped(index),
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          // Active background
                          if (isSelected)
                            Transform(
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.001)
                                ..multiply(Matrix4.skewX(-0.4))
                                ..rotateZ(-15 * 3.1415927 / 180),
                              alignment: Alignment.center,
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          const Color.fromARGB(255, 32, 34, 36)
                                              .withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // Icon (floats with active bg)
                          Image.asset(
                            icons[index],
                            width: isSelected ? 30 : 25,
                            height: isSelected ? 30 : 25,
                            color: isSelected ? Colors.white : Colors.grey[400],
                          ),

                          // Crown badge for blocked endpoints
                          if (isBlocked)
                            Positioned(
                              top: isSelected ? -10 : -8,
                              right: isSelected ? -10 : -8,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF7A5C00),
                                      Color(0xFFB8880A)
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFB8880A)
                                          .withOpacity(0.5),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.workspace_premium_rounded,
                                  color: Color(0xFFFFD700),
                                  size: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class RightCornerClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.4); // Slant up from top-left
    path.lineTo(size.width, 0); // Top-right
    path.lineTo(size.width, size.height); // Bottom-right
    path.lineTo(0, size.height); // Bottom-left
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
