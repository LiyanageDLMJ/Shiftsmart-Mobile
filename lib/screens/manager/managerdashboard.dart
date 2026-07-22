import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shiftsmart/models/employee.dart';
import 'package:shiftsmart/models/leave_request.dart';
import 'package:shiftsmart/models/shift.dart';
import 'package:shiftsmart/screens/manager/manager_shifts_view.dart';
import 'package:shiftsmart/services/leave_service.dart';
import 'package:shiftsmart/services/project_service.dart';
import 'package:shiftsmart/services/employee_service.dart';
import 'package:shiftsmart/services/shift_service.dart';
import 'package:shiftsmart/utils/fullscreen_helper.dart';
import 'package:shiftsmart/widgets/background.dart';
import 'package:shiftsmart/widgets/gradienthorizontal.dart';
import 'package:shiftsmart/models/project.dart';
import 'package:shiftsmart/services/attendance_service.dart';
import 'package:provider/provider.dart';
import 'package:shiftsmart/providers/tenant_provider.dart';
import 'package:shiftsmart/providers/user_provider.dart';
import 'package:shiftsmart/services/super_admin_service.dart';
import 'package:shiftsmart/services/auth_service.dart';
import 'package:shiftsmart/widgets/bottomnavbar.dart';
import 'package:shiftsmart/widgets/organization_selector.dart';

class Managerdashboard extends StatefulWidget {
  const Managerdashboard({super.key});

  @override
  State<Managerdashboard> createState() => _ManagerdashboardState();
}

class _ManagerdashboardState extends State<Managerdashboard> {
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();

  int completed = 0;
  int total = 0;
  int inProgress = 0;
  List<Project> allProjects = [];
  List<String> filteredEmployees = [];
  List<LeaveRequest> _leaveRequests = [];
  bool _isLoading = true;
  List<Employee> _allEmployees = [];
  List<Shift> _todayShifts = [];
  int _pendingCount = 0;

  // Local tenant state removed in favor of global TenantProvider

  final SuperAdminService _superAdminService = SuperAdminService();

  final ProjectService _projectService = ProjectService();
  final LeaveService _leaveService = LeaveService();
  final EmployeeService _employeeService = EmployeeService();
  final ShiftService _shiftService = ShiftService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    enableFullScreen();

    // After the first frame, show the pull-to-refresh indicator
    // and perform the initial tenant/data setup for the dashboard.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshKey.currentState?.show();
      _initializeDashboard();
    });
  }

  Future<void> _initializeDashboard() async {
    setState(() => _isLoading = true);

    try {
      final tp = context.read<TenantProvider>();

      // 1. Load tenant list if not already loaded.
      //    TenantProvider stores available organizations globally.
      if (tp.tenants.isEmpty) {
        await tp.loadTenants();
      }

      // 1.5 If the tenant list is still empty, use cached user tenant data.
      if (tp.tenants.isEmpty) {
        final up = context.read<UserProvider>();
        if (up.tenants.isNotEmpty) {
          tp.setTenants(
              up.tenants.map((t) => t as Map<String, dynamic>).toList());
          debugPrint("Initialized TenantProvider from UserProvider tenants");
        }
      }

      // 2. If the user does not yet have a selected tenant, try to infer it from the current user info.
      if (!tp.hasTenant) {
        try {
          final userInfo = await _authService.getCurrentUserInfo();
          if (userInfo != null) {
            final currentTenantName =
                userInfo['tenantName'] ?? userInfo['TenantName'];
            if (currentTenantName != null) {
              final tenantMap = userInfo['tenant'] ??
                  userInfo['Tenant'] ??
                  tp.findTenantByName(currentTenantName.toString());
              tp.initFromCurrentTenant(currentTenantName.toString(), tenantMap);
            }
          }
        } catch (e) {
          debugPrint("Error fetching current user info: $e");
        }
      }

      // 3. Fallback: if no tenant is selected yet, choose the first available tenant automatically.
      if (!tp.hasTenant && tp.tenants.isNotEmpty) {
        final first = tp.tenants.first;
        final name = (first['name'] ?? first['Name'] ?? 'Unnamed').toString();
        tp.initFromCurrentTenant(name, first);
      }

      // 4. Load dashboard data using the current tenant context.
      await _refreshData();
    } catch (e) {
      debugPrint("Error initializing dashboard: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    await fetchProjects();
    await _fetchLeaveRequests();
    await _fetchAllEmployees();
    await _fetchAllShifts();

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _fetchAllEmployees() async {
    try {
      final employees = await _employeeService.fetchAllEmployees();
      setState(() {
        _allEmployees = employees;
      });
    } catch (e) {
      print("Error fetching employees: $e");
    }
  }

  Future<void> _fetchLeaveRequests() async {
    try {
      final requests = await _leaveService.fetchLeaveRequests();
      setState(() {
        _leaveRequests = requests;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching leave requests: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> fetchProjects() async {
    final projects = await _projectService.fetchAllProjects();
    if (!mounted) return;
    final currentOrg = context.read<TenantProvider>().selectedOrganization;
    setState(() {
      // The backend is tenant-isolated via the JWT token.
      // We rely on the API to return only projects for the active tenant.
      allProjects = projects;

      total = allProjects.length;
      completed = getCompletedProjectsCount();
      inProgress = getInProgressProjectsCount();
    });
  }

  Future<void> _fetchAllShifts() async {
    try {
      final allRawShifts = await _shiftService.fetchAllRawShifts();

      // Filter shifts to only include those belonging to the selected organization's projects
      final projectIds = allProjects.map((p) => p.projectId).toSet();
      final filteredRawShifts = allRawShifts.where((s) {
        final pid = s['ProjectId'] ?? s['projectId'];
        return projectIds.contains(pid);
      }).toList();

      final today = DateTime.now();
      final todayOnly = filteredRawShifts
          .map((shiftData) => Shift.fromJson(shiftData))
          .where((shift) =>
              shift.date.year == today.year &&
              shift.date.month == today.month &&
              shift.date.day == today.day)
          .toList();

      int pending = 0;
      for (var s in filteredRawShifts) {
        final shift = Shift.fromJson(s);
        for (var resp in shift.employeeResponses) {
          if (resp.approvalStatus == "Pending" || resp.isSwapRequested) {
            pending++;
          }
        }
      }

      setState(() {
        _todayShifts = todayOnly;
        _pendingCount = pending;
        debugPrint(
            "Today shifts: $_todayShifts, Pending count: $_pendingCount");
      });
    } catch (e) {
      debugPrint("Error fetching today's shifts: $e");
    }
  }

  Future<void> _fetchTenants() async {
    try {
      await context.read<TenantProvider>().loadTenants();
    } catch (e) {
      debugPrint("Error fetching tenants: $e");
    }
  }

  Future<void> _handleTenantSwitch(String? orgName) async {
    if (orgName == null) return;

    final tp = context.read<TenantProvider>();
    final tenant = tp.tenants.firstWhere(
      (t) =>
          (t['name'] ?? t['Name'] ?? '').toString().toLowerCase() ==
          orgName.toLowerCase(),
      orElse: () => {},
    );

    if (tenant.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // Use TenantProvider to switch tenant so feature flags are updated globally
      final success = await context.read<TenantProvider>().switchTenant(tenant);

      if (success) {
        // The provider already updates the selected tenant state.
        // Refresh dashboard content so it matches the new tenant context.
        await _refreshData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Switched to $orgName'),
                backgroundColor: Colors.green),
          );
        }
      } else {
        // Even if the backend switch fails, refresh local data to keep UI stable.
        await _refreshData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to switch tenant context completely.'),
                backgroundColor: Colors.orange),
          );
        }
      }
    } catch (e) {
      debugPrint("Error switching tenant: $e");
      await _refreshData();
    }
    setState(() => _isLoading = false);
  }

  int getCompletedProjectsCount() {
    return allProjects.where((project) {
      final status = project.status.trim().toLowerCase();
      return status == 'completed' || status == 'complete';
    }).length;
  }

  int getInProgressProjectsCount() {
    return allProjects.where((project) {
      final status = project.status.trim().toLowerCase();
      return status == 'active' ||
          status == 'in progress' ||
          status == 'inprogress';
    }).length;
  }

  Employee? getEmployeeById(int id) {
    return _allEmployees.firstWhere(
      (emp) => emp.employeeId == id,
      orElse: () => Employee(
          employeeId: id,
          firstName: 'Unknown',
          profilePicture: '',
          nextOfKins: []),
    );
  }

  String formatTime(String timeString) {
    try {
      final parsedTime = DateFormat("HH:mm:ss").parse(timeString);
      return DateFormat("HH:mm").format(parsedTime);
    } catch (e) {
      return timeString;
    }
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  List<LeaveRequest> getTodayLeaveRequests() {
    final today = _dateOnly(DateTime.now());
    return _leaveRequests.where((req) {
      final startDate = _dateOnly(req.startDate);
      final endDate = _dateOnly(req.endDate);
      final isToday =
          !today.isBefore(startDate) && !today.isAfter(endDate);
      final isApproved = req.status.toLowerCase() == 'approved';
      return isApproved && isToday;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Stack(
      children: [
        const Positioned.fill(child: Background()),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF724584)),
                )
              : Consumer<UserProvider>(
                  builder: (context, userProvider, child) {
                    return Column(
                      children: [
                        // Organization Selection Bar
                        // This is the tenant picker displayed at the top of the dashboard.
                        // When the user chooses a new organization, the dashboard refreshes
                        // using the selected tenant context from TenantProvider.
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 0, vertical: 8),
                          child: OrganizationSelector(
                            onTenantSwitched: () {
                              _refreshData();
                            },
                          ),
                        ),

                        Expanded(
                            child: RefreshIndicator(
                                key: _refreshKey,
                                onRefresh: _refreshData,
                                child: SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                      vertical: 16.0,
                                    ),
                                    child: Column(
                                      children: [
                                        _buildProjectOverviewCard(
                                          screenWidth: screenWidth,
                                          totalProjects: total,
                                          completedProjects: completed,
                                          activeProjects: inProgress,
                                        ),
                                        SizedBox(height: screenHeight * 0.025),
                                        _buildTodayOnLeaveCard(
                                          screenWidth: screenWidth,
                                          screenHeight: screenHeight,
                                        ),
                                        SizedBox(height: screenHeight * 0.025),
                                        ConstrainedBox(
                                            constraints: BoxConstraints(
                                              minHeight: screenHeight * 0.18,
                                              maxHeight: screenHeight * 0.45,
                                            ),
                                            child: Gradienthorizontal(
                                              width: double.infinity,
                                              height: double.infinity,
                                              child: Padding(
                                                padding: EdgeInsets.all(
                                                    screenWidth * 0.04),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        const Expanded(
                                                          child: Text(
                                                            "TODAY'S SHIFTS",
                                                            style: TextStyle(
                                                              fontSize: 18,
                                                              color: Colors.white,
                                                              fontWeight:
                                                                  FontWeight.bold,
                                                            ),
                                                          ),
                                                        ),
                                                        _buildDashboardArrowButton(
                                                          onTap: () {
                                                            Navigator.of(context)
                                                                .pushReplacement(
                                                              MaterialPageRoute(
                                                                builder: (context) =>
                                                                    const Bottomnavbar(
                                                                  selectedIndex: 2,
                                                                  jobsInitialTabIndex: 1,
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      "${_todayShifts.length} shift(s) scheduled for today",
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 10),
                                                    SizedBox(
                                                      height:
                                                          screenHeight * 0.25,
                                                      child:
                                                          _todayShifts.isEmpty
                                                              ? const Center(
                                                                  child: Text(
                                                                    "No shifts scheduled today.",
                                                                    style: TextStyle(
                                                                        color: Colors
                                                                            .white70),
                                                                  ),
                                                                )
                                                              : ListView
                                                                  .builder(
                                                                  physics:
                                                                      const BouncingScrollPhysics(),
                                                                  itemCount:
                                                                      _todayShifts
                                                                          .length,
                                                                  itemBuilder:
                                                                      (context,
                                                                          index) {
                                                                    final shift =
                                                                        _todayShifts[
                                                                            index];
                                                                    return Padding(
                                                                        padding: EdgeInsets.symmetric(
                                                                            vertical: screenHeight *
                                                                                0.008),
                                                                        child:
                                                                            InkWell(
                                                                          onTap:
                                                                              () {
                                                                            Navigator.push(
                                                                              context,
                                                                              MaterialPageRoute(
                                                                                builder: (context) => ManagerShiftsView(shift: shift),
                                                                              ),
                                                                            );
                                                                          },
                                                                          child:
                                                                              Container(
                                                                            padding:
                                                                                EdgeInsets.all(screenWidth * 0.03),
                                                                            decoration:
                                                                                BoxDecoration(
                                                                              color: Colors.white.withOpacity(0.08),
                                                                              borderRadius: BorderRadius.circular(15),
                                                                              border: Border.all(
                                                                                color: Colors.white.withOpacity(0.1),
                                                                                width: 1,
                                                                              ),
                                                                              boxShadow: [
                                                                                BoxShadow(
                                                                                  color: Colors.black.withOpacity(0.1),
                                                                                  blurRadius: 10,
                                                                                  offset: const Offset(0, 4),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                            child:
                                                                                Column(
                                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                                              children: [
                                                                                Row(
                                                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                                  children: [
                                                                                    Expanded(
                                                                                      child: Text(
                                                                                        shift.taskName,
                                                                                        style: const TextStyle(
                                                                                          fontSize: 16,
                                                                                          fontWeight: FontWeight.bold,
                                                                                          color: Colors.white,
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                    Text(
                                                                                      shift.status,
                                                                                      style: TextStyle(
                                                                                        fontSize: 13,
                                                                                        fontWeight: FontWeight.w500,
                                                                                        color: shift.status.trim().toLowerCase() == 'active'
                                                                                            ? Colors.greenAccent
                                                                                            : (shift.status.trim().toLowerCase() == 'scheduled' || shift.status.trim().toLowerCase() == 'pending')
                                                                                                ? Colors.yellowAccent
                                                                                                : Colors.white70,
                                                                                      ),
                                                                                    ),
                                                                                    const SizedBox(
                                                                                      height: 10,
                                                                                    ),
                                                                                    const Icon(
                                                                                      Icons.arrow_forward_ios,
                                                                                      color: Colors.white70,
                                                                                      size: 14,
                                                                                    )
                                                                                  ],
                                                                                ),
                                                                                const SizedBox(height: 6),
                                                                                Text(
                                                                                  "${formatTime(shift.startTime)} - ${formatTime(shift.endTime)}",
                                                                                  style: const TextStyle(
                                                                                    fontSize: 13,
                                                                                    color: Colors.white70,
                                                                                  ),
                                                                                ),
                                                                                const SizedBox(height: 12),
                                                                                Text(
                                                                                  "Assigned employees: ",
                                                                                  style: const TextStyle(
                                                                                    fontSize: 15,
                                                                                    color: Colors.white,
                                                                                    fontWeight: FontWeight.w500,
                                                                                  ),
                                                                                ),
                                                                                const SizedBox(height: 12),
                                                                                Column(
                                                                                  children: shift.employeeResponses.map((response) {
                                                                                    final employee = getEmployeeById(response.employeeId);
                                                                                    final isPendingApproval = response.approvalStatus == "Pending";

                                                                                    return Container(
                                                                                      margin: const EdgeInsets.only(bottom: 12),
                                                                                      padding: const EdgeInsets.all(10),
                                                                                      decoration: BoxDecoration(
                                                                                        color: Colors.black26,
                                                                                        borderRadius: BorderRadius.circular(8),
                                                                                        border: isPendingApproval ? Border.all(color: Colors.orangeAccent.withValues(alpha: 0.5)) : null,
                                                                                      ),
                                                                                      child: Column(
                                                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                                                        children: [
                                                                                          Row(
                                                                                            children: [
                                                                                              CircleAvatar(
                                                                                                radius: 18,
                                                                                                backgroundColor: Colors.grey[800],
                                                                                                backgroundImage: (employee?.profilePicture != null && employee!.profilePicture!.startsWith('data:image'))
                                                                                                    ? MemoryImage(base64Decode(employee.profilePicture!.split(',').last))
                                                                                                    : (employee?.profilePicture != null && employee!.profilePicture!.isNotEmpty)
                                                                                                        ? NetworkImage(employee.profilePicture!)
                                                                                                        : null,
                                                                                                child: (employee?.profilePicture == null || employee!.profilePicture!.isEmpty) ? const Icon(Icons.person, color: Colors.white, size: 18) : null,
                                                                                              ),
                                                                                              const SizedBox(width: 10),
                                                                                              Expanded(
                                                                                                child: Column(
                                                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                                                  children: [
                                                                                                    Text(
                                                                                                      employee?.firstName ?? 'Unknown',
                                                                                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                                                                                    ),
                                                                                                    Text(
                                                                                                      response.status,
                                                                                                      style: TextStyle(
                                                                                                        color: _getStatusColor(response.status),
                                                                                                        fontSize: 11,
                                                                                                        fontWeight: FontWeight.w600,
                                                                                                      ),
                                                                                                    ),
                                                                                                  ],
                                                                                                ),
                                                                                              ),
                                                                                              if (isPendingApproval)
                                                                                                ElevatedButton(
                                                                                                  style: ElevatedButton.styleFrom(
                                                                                                    backgroundColor: Colors.green,
                                                                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                                                                                    minimumSize: const Size(60, 30),
                                                                                                  ),
                                                                                                  onPressed: () => _handleApproval(response.employeeId, shift.shiftId, "Approved"),
                                                                                                  child: const Text("Approve", style: TextStyle(fontSize: 12, color: Colors.white)),
                                                                                                ),
                                                                                            ],
                                                                                          ),
                                                                                          if (response.clockInTime != null)
                                                                                            Padding(
                                                                                              padding: const EdgeInsets.only(top: 8, left: 4),
                                                                                              child: Text(
                                                                                                "Clock In: ${DateFormat('hh:mm a').format(response.clockInTime!.toLocal())}",
                                                                                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                                                                                              ),
                                                                                            ),
                                                                                          if (response.clockOutTime != null)
                                                                                            Padding(
                                                                                              padding: const EdgeInsets.only(top: 2, left: 4),
                                                                                              child: Text(
                                                                                                "Clock Out: ${DateFormat('hh:mm a').format(response.clockOutTime!.toLocal())}",
                                                                                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                                                                                              ),
                                                                                            ),
                                                                                          if (response.isEarlyExit)
                                                                                            Padding(
                                                                                              padding: const EdgeInsets.only(top: 4, left: 4),
                                                                                              child: Row(
                                                                                                children: [
                                                                                                  const Icon(Icons.warning, color: Colors.orange, size: 14),
                                                                                                  const SizedBox(width: 4),
                                                                                                  Expanded(
                                                                                                    child: Text(
                                                                                                      "Reason: ${response.earlyExitReason ?? 'Emergency'}",
                                                                                                      style: const TextStyle(color: Colors.orange, fontSize: 12),
                                                                                                    ),
                                                                                                  ),
                                                                                                ],
                                                                                              ),
                                                                                            ),
                                                                                        ],
                                                                                      ),
                                                                                    );
                                                                                  }).toList(),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ),
                                                                        ));
                                                                  },
                                                                ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                )))
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'clockedin':
        return Colors.green;
      case 'clockedout':
        return Colors.blue;
      case 'completed':
        return Colors.purple;
      case 'pending':
        return Colors.orange;
      case 'swap requested':
        return Colors.blueAccent;
      case 'declined':
      case 'rejected':
        return Colors.red;
      default:
        return Colors.white54;
    }
  }

  Widget _buildDashboardArrowButton({
    required VoidCallback onTap,
    double size = 44,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFF1A315E),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6EA7FF).withValues(alpha: 0.2),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.north_east_rounded,
            color: Color(0xFF78AFFF),
            size: 24,
          ),
        ),
      ),
    );
  }
  Widget _buildProjectOverviewCard({
    required double screenWidth,
    required int totalProjects,
    required int completedProjects,
    required int activeProjects,
  }) {
    const completedColor = Color(0xFF66BE8B);
    const activeColor = Color(0xFFFFD246);
    const cardBorder = Color(0x1FFFFFFF);

    final completedValue =
        totalProjects > 0 ? completedProjects / totalProjects : 0.0;
    final activeValue =
        totalProjects > 0 ? activeProjects / totalProjects : 0.0;
    final completedPercent = (completedValue * 100).round();
    final activePercent = (activeValue * 100).round();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenWidth < 390 ? 22 : 28,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cardBorder),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2B3446),
            Color(0xFF29384F),
            Color(0xFF315684),
          ],
          stops: [0.0, 0.54, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final compactScale = (width / 520).clamp(0.64, 1.0);
          final donutSize = 176.0 * compactScale;
          final titleSize = 28.0 * compactScale;
          final subtitleSize = 18.0 * compactScale;
          final chart = _ProjectDonutChart(
            size: donutSize,
            totalProjects: totalProjects,
            completedProjects: completedProjects,
            activeProjects: activeProjects,
            completedValue: completedValue,
            activeValue: activeValue,
            completedPercent: completedPercent,
            activePercent: activePercent,
            completedColor: completedColor,
            activeColor: activeColor,
          );
          final legend = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _projectOverviewLegendRow(
                color: completedColor,
                label: 'COMPLETED',
                percent: completedPercent,
                scale: compactScale,
              ),
              SizedBox(height: 34 * compactScale),
              _projectOverviewLegendRow(
                color: activeColor,
                label: 'ACTIVE',
                percent: activePercent,
                scale: compactScale,
              ),
            ],
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Project Overview',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: titleSize,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Status of current projects',
                          style: TextStyle(
                            color: Color(0xFF9AA8BE),
                            fontSize: subtitleSize,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildDashboardArrowButton(
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) =>
                              const Bottomnavbar(selectedIndex: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: 32 * compactScale),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  chart,
                  SizedBox(width: width < 460 ? 22 * compactScale : 52),
                  Flexible(child: legend),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _projectOverviewLegendRow({
    required Color color,
    required String label,
    required int percent,
    double scale = 1,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18 * scale,
          height: 46 * scale,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.36),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        SizedBox(width: 18 * scale),
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFFD7DDE8),
            fontSize: 22 * scale,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        SizedBox(width: 20 * scale),
        Text(
          '$percent%',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24 * scale,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildTodayOnLeaveCard({
    required double screenWidth,
    required double screenHeight,
  }) {
    final todayLeaves = getTodayLeaveRequests();
    return Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: screenHeight * 0.20),
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenHeight * 0.022,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2B3446),
                Color(0xFF29384F),
                Color(0xFF315684),
              ],
              stops: [0.0, 0.54, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Today on Leave",
                      style: TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  _buildDashboardArrowButton(
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const Bottomnavbar(selectedIndex: 4),
                        ),
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.028),
              if (todayLeaves.isEmpty)
                const Text(
                  "No one is on leave today.",
                  style: TextStyle(
                    color: Color(0xFFC7CEDB),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: todayLeaves.map((leave) {
                      final employee = getEmployeeById(leave.employeeId);
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.grey[800],
                              backgroundImage: (employee?.profilePicture !=
                                          null &&
                                      employee!.profilePicture!
                                          .startsWith('data:image'))
                                  ? MemoryImage(
                                      base64Decode(
                                        employee.profilePicture!
                                            .split(',')
                                            .last,
                                      ),
                                    )
                                  : (employee?.profilePicture != null &&
                                          employee!.profilePicture!.isNotEmpty)
                                      ? NetworkImage(employee.profilePicture!)
                                      : null,
                              child: (employee?.profilePicture == null ||
                                      employee!.profilePicture!.isEmpty)
                                  ? const Icon(
                                      Icons.person,
                                      size: 30,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: 70,
                              child: Text(
                                employee?.firstName ?? 'Unknown',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        );
  }

  Future<void> _handleApproval(
      int employeeId, int shiftId, String status) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Processing approval for shift $shiftId...")),
    );

    final attendanceService = AttendanceService();
    try {
      final record = await attendanceService.getShiftsByShiftId(employeeId,
          shiftId: shiftId);
      if (record != null && record['AttendanceId'] != null) {
        final success = await attendanceService.approveAttendance(
            record['AttendanceId'], status);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Attendance Approved successfully!")),
          );
          _refreshData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to approve attendance.")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Attendance record not found.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }
}

enum _ProjectDonutSegment { completed, active }

class _ProjectDonutChart extends StatefulWidget {
  const _ProjectDonutChart({
    required this.size,
    required this.totalProjects,
    required this.completedProjects,
    required this.activeProjects,
    required this.completedValue,
    required this.activeValue,
    required this.completedPercent,
    required this.activePercent,
    required this.completedColor,
    required this.activeColor,
  });

  final double size;
  final int totalProjects;
  final int completedProjects;
  final int activeProjects;
  final double completedValue;
  final double activeValue;
  final int completedPercent;
  final int activePercent;
  final Color completedColor;
  final Color activeColor;

  @override
  State<_ProjectDonutChart> createState() => _ProjectDonutChartState();
}

class _ProjectDonutChartState extends State<_ProjectDonutChart> {
  _ProjectDonutSegment? _hoveredSegment;

  void _updateSegment(Offset localPosition) {
    final segment = _segmentForPosition(localPosition);
    if (segment != _hoveredSegment) {
      setState(() => _hoveredSegment = segment);
    }
  }

  _ProjectDonutSegment? _segmentForPosition(Offset position) {
    final center = Offset(widget.size / 2, widget.size / 2);
    final distance = (position - center).distance;
    final outerRadius = widget.size / 2;
    final innerRadius = outerRadius - (widget.size * 0.16);

    if (distance < innerRadius || distance > outerRadius) {
      return null;
    }

    var angle = math.atan2(position.dy - center.dy, position.dx - center.dx);
    angle = (angle + math.pi / 2) % (math.pi * 2);

    final completedSweep = widget.completedValue.clamp(0.0, 1.0) * math.pi * 2;
    final activeSweep = widget.activeValue.clamp(0.0, 1.0) * math.pi * 2;

    if (completedSweep > 0 && angle <= completedSweep) {
      return _ProjectDonutSegment.completed;
    }
    if (activeSweep > 0 && angle <= completedSweep + activeSweep) {
      return _ProjectDonutSegment.active;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scale = (widget.size / 176).clamp(0.64, 1.0);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: MouseRegion(
        cursor: _hoveredSegment == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        onHover: (event) => _updateSegment(event.localPosition),
        onExit: (_) => setState(() => _hoveredSegment = null),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapDown: (details) => _updateSegment(details.localPosition),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(widget.size),
                painter: _ProjectDonutPainter(
                  completedValue: widget.completedValue,
                  activeValue: widget.activeValue,
                  completedColor: widget.completedColor,
                  activeColor: widget.activeColor,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${widget.totalProjects}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 42 * scale,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  SizedBox(height: 2 * scale),
                  Text(
                    'Total\nProjects',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFFE2E7F0),
                      fontSize: 15 * scale,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
              if (_hoveredSegment == _ProjectDonutSegment.completed)
                Positioned(
                  top: -14 * scale,
                  right: -112 * scale,
                  child: _ProjectDonutTooltip(
                    color: widget.completedColor,
                    label: 'COMPLETED',
                    count: widget.completedProjects,
                    percent: widget.completedPercent,
                    scale: scale,
                  ),
                ),
              if (_hoveredSegment == _ProjectDonutSegment.active)
                Positioned(
                  left: -108 * scale,
                  bottom: -26 * scale,
                  child: _ProjectDonutTooltip(
                    color: widget.activeColor,
                    label: 'ACTIVE',
                    count: widget.activeProjects,
                    percent: widget.activePercent,
                    scale: scale,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectDonutTooltip extends StatelessWidget {
  const _ProjectDonutTooltip({
    required this.color,
    required this.label,
    required this.count,
    required this.percent,
    required this.scale,
  });

  final Color color;
  final String label;
  final int count;
  final int percent;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final tooltipScale = scale.clamp(0.82, 1.0);

    return Container(
      width: 194 * tooltipScale,
      height: 96 * tooltipScale,
      padding: EdgeInsets.symmetric(
        horizontal: 16 * tooltipScale,
        vertical: 12 * tooltipScale,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF050918).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16 * tooltipScale),
        border: Border.all(color: const Color(0xFF242B3E)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.36),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 14 * tooltipScale,
                height: 14 * tooltipScale,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 12 * tooltipScale),
              Text(
                label,
                style: TextStyle(
                  color: const Color(0xFFAAB3C5),
                  fontSize: 13 * tooltipScale,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 5 * tooltipScale,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                '$count',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28 * tooltipScale,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12 * tooltipScale,
                  vertical: 4 * tooltipScale,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF252838),
                  borderRadius: BorderRadius.circular(20 * tooltipScale),
                ),
                child: Text(
                  '$percent%',
                  style: TextStyle(
                    color: const Color(0xFFE9ECF3),
                    fontSize: 16 * tooltipScale,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProjectDonutPainter extends CustomPainter {
  const _ProjectDonutPainter({
    required this.completedValue,
    required this.activeValue,
    required this.completedColor,
    required this.activeColor,
  });

  final double completedValue;
  final double activeValue;
  final Color completedColor;
  final Color activeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.16;
    final inset = strokeWidth / 2;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final trackPaint = Paint()
      ..color = const Color(0xFF182235)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    final completedPaint = Paint()
      ..color = completedColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0, math.pi * 2, false, trackPaint);

    const startAngle = -math.pi / 2;
    final completedSweep = (completedValue.clamp(0.0, 1.0)) * math.pi * 2;
    final activeSweep = (activeValue.clamp(0.0, 1.0)) * math.pi * 2;

    if (completedSweep > 0) {
      canvas.drawArc(rect, startAngle, completedSweep, false, completedPaint);
    }

    if (activeSweep > 0) {
      canvas.drawArc(
        rect,
        startAngle + completedSweep,
        activeSweep,
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ProjectDonutPainter oldDelegate) {
    return oldDelegate.completedValue != completedValue ||
        oldDelegate.activeValue != activeValue ||
        oldDelegate.completedColor != completedColor ||
        oldDelegate.activeColor != activeColor;
  }
}
