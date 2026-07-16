import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:shiftsmart/services/notification_service.dart';
import 'package:shiftsmart/utils/fullscreen_helper.dart';
import 'package:shiftsmart/widgets/background.dart';
import 'package:shiftsmart/widgets/gradient_button.dart';
import 'package:shiftsmart/widgets/premium_feature_gate.dart';
import 'package:shiftsmart/widgets/bottomnavbar.dart';

import 'package:shiftsmart/models/leave_request.dart';
import 'package:shiftsmart/models/employee.dart';
import 'package:shiftsmart/services/leave_service.dart';
import 'package:shiftsmart/services/employee_service.dart';
import 'package:provider/provider.dart';
import 'package:shiftsmart/providers/tenant_provider.dart';
import 'package:shiftsmart/screens/manager/manager_view_employee.dart';

class Managerleave extends StatefulWidget {
  const Managerleave({super.key});

  @override
  State<Managerleave> createState() => _ManagerleaveState();
}

class _LeaveTabData {
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  const _LeaveTabData({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });
}

class _ManagerleaveState extends State<Managerleave> {
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();

  final LeaveService _leaveService = LeaveService();
  List<Employee> filteredEmployees = [];
  List<LeaveRequest> _leaveRequests = [];
  bool _isLoading = true;
  List<Employee> _allEmployees = [];
  final EmployeeService _employeeService = EmployeeService();
  final NotificationService _notificationService = NotificationService();
  String _lastTenant = '';
  int _selectedLeaveTab = 0;
  String _leaveSearchQuery = '';
  final Map<int, String> _localRejectionReasons = {};

  @override
  void initState() {
    super.initState();
    enableFullScreen();
    filteredEmployees = List.from(_allEmployees);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshKey.currentState?.show(); // optional spinner
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    await _fetchAllEmployees(); // Fetch employees first to get tenant scope
    await _fetchLeaveRequests();
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _fetchLeaveRequests() async {
    try {
      final leaveRequests = await _leaveService.fetchLeaveRequests();
      if (!mounted) return;
      setState(() {
        final tenantEmployeeIds =
            _allEmployees.map((e) => e.employeeId).toSet();
        final scopedRequests = leaveRequests
            .where((req) => tenantEmployeeIds.contains(req.employeeId))
            .toList();

        for (final request in scopedRequests) {
          final serverReason = request.rejectionReason.trim();
          if (serverReason.isNotEmpty) {
            _localRejectionReasons[request.leaveRequestId] = serverReason;
          } else {
            final localReason = _localRejectionReasons[request.leaveRequestId];
            if (localReason != null && localReason.trim().isNotEmpty) {
              request.rejectionReason = localReason.trim();
            }
          }
        }

        _leaveRequests = scopedRequests;
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error fetching leave requests: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<int?> _fetchLeaveBalance(int employeeId) async {
    try {
      return await _leaveService.fetchLeaveBalance(employeeId);
    } catch (e) {
      debugPrint("Leave balance fetch error: $e");
      return null;
    }
  }

  Future<void> _updateLeaveStatus(int id, String newStatus,
      {String? rejectionReason}) async {
    try {
      await _leaveService.updateLeaveStatus(
        id,
        newStatus,
        rejectionReason: rejectionReason,
      );

      if (!mounted) return;

      // Find the updated request
      final updatedRequest = _leaveRequests.firstWhere(
        (req) => req.leaveRequestId == id,
      );

      //  Send notification using employeeId from the request model
      await _notificationService.leaveNotification(
          updatedRequest.employeeId, newStatus);

      // Show feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Leave $newStatus")),
      );

      // Update state
      setState(() {
        updatedRequest.status = newStatus;
        if (rejectionReason != null && rejectionReason.trim().isNotEmpty) {
          final trimmedReason = rejectionReason.trim();
          updatedRequest.rejectionReason = trimmedReason;
          _localRejectionReasons[id] = trimmedReason;
        } else if (newStatus.toLowerCase() == 'approved') {
          updatedRequest.rejectionReason = '';
          _localRejectionReasons.remove(id);
        }
      });
    } catch (e) {
      if (!mounted) return;

      debugPrint('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<String?> _showRejectReasonDialog() async {
    String reasonText = '';

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final hasReason = reasonText.trim().isNotEmpty;

            return AlertDialog(
              backgroundColor: const Color(0xFF2A3243),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.error_rounded, color: Colors.redAccent, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Reject Request',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Please provide a reason for rejecting this leave request.',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    maxLines: 4,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    onChanged: (value) {
                      setDialogState(() => reasonText = value);
                    },
                    decoration: InputDecoration(
                      hintText: 'Enter rejection reason...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF1E2433),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.redAccent),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                ElevatedButton(
                  onPressed: hasReason
                      ? () => Navigator.of(dialogContext).pop(reasonText.trim())
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    disabledBackgroundColor:
                        Colors.redAccent.withValues(alpha: 0.28),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _fetchAllEmployees() async {
    try {
      final employees = await _employeeService.fetchAllEmployees();
      setState(() {
        _allEmployees = employees;
      });
    } catch (e) {
      debugPrint("Error fetching employees: $e");
    }
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

  void _openEmployeeProfile(Employee employee) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Managerviewemployee(employee: employee),
      ),
    );
  }

  List<LeaveRequest> getTodayLeaveRequests() {
    final today = DateTime.now();
    return _leaveRequests.where((req) {
      final isToday =
          !today.isBefore(req.startDate) && !today.isAfter(req.endDate);
      final isApproved = req.status.toLowerCase() == 'approved';

      return isToday && isApproved;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TenantProvider>(
      builder: (context, tp, _) {
        if (tp.selectedOrganization != _lastTenant) {
          _lastTenant = tp.selectedOrganization;
          if (_lastTenant.isNotEmpty && mounted && !_isLoading) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _refreshData();
            });
          }
        }

        if (!tp.isFeatureEnabled('leave_management') ||
            tp.isNavIndexBlocked(4)) {
          return Stack(
            children: [
              const Positioned.fill(child: Background()),
              Scaffold(
                resizeToAvoidBottomInset: false,
                backgroundColor: Colors.transparent,
                body: SafeArea(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: PremiumFeatureGate(
                        featureName: 'Leave Management',
                        blockedEndpoint: '/api/leave/list',
                        onGotIt: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const Bottomnavbar(selectedIndex: 0),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return Stack(
          children: [
            const Positioned.fill(child: Background()),
            Scaffold(
              resizeToAvoidBottomInset: false,
              backgroundColor: Colors.transparent,
              body: _isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF724584)),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: RefreshIndicator(
                            key: _refreshKey,
                            onRefresh: _refreshData,
                            child: SingleChildScrollView(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 20),
                                  const Text(
                                    "Today on Leave",
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: getTodayLeaveRequests()
                                              .isNotEmpty
                                          ? getTodayLeaveRequests()
                                              .map((leave) {
                                              final employee = getEmployeeById(
                                                  leave.employeeId);
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 12),
                                                child: Column(
                                                  children: [
                                                    GestureDetector(
                                                      behavior: HitTestBehavior
                                                          .opaque,
                                                      onTap: employee == null
                                                          ? null
                                                          : () =>
                                                              _openEmployeeProfile(
                                                                  employee),
                                                      child: CircleAvatar(
                                                        radius: 30,
                                                        backgroundColor:
                                                            Colors.grey[800],
                                                        backgroundImage: (employee
                                                                        ?.profilePicture !=
                                                                    null &&
                                                                employee!
                                                                    .profilePicture!
                                                                    .startsWith(
                                                                        'data:image'))
                                                            ? MemoryImage(
                                                                base64Decode(
                                                                    employee
                                                                        .profilePicture!
                                                                        .split(
                                                                            ',')
                                                                        .last),
                                                              )
                                                            : (employee?.profilePicture !=
                                                                        null &&
                                                                    employee!
                                                                        .profilePicture!
                                                                        .isNotEmpty)
                                                                ? NetworkImage(
                                                                    employee
                                                                        .profilePicture!)
                                                                : null,
                                                        child: (employee?.profilePicture ==
                                                                    null ||
                                                                employee!
                                                                    .profilePicture!
                                                                    .isEmpty)
                                                            ? const Icon(
                                                                Icons.person,
                                                                size: 30,
                                                                color: Colors
                                                                    .white)
                                                            : null,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    SizedBox(
                                                      width: 70,
                                                      child: Text(
                                                        employee?.firstName ??
                                                            'Unknown',
                                                        style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 12),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        textAlign:
                                                            TextAlign.center,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList()
                                          : [
                                              const Padding(
                                                padding: EdgeInsets.symmetric(
                                                    vertical: 12),
                                                child: Text(
                                                  "No one is on leave today.",
                                                  style: TextStyle(
                                                      color: Colors.white70),
                                                ),
                                              ),
                                            ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  _leaveSearchSection(),
                                  const SizedBox(height: 14),
                                  _leaveStatusTabs(),
                                  const SizedBox(height: 16),
                                  _leaveList(),
                                  const SizedBox(height: 100),
                                ],
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _leaveStatusTabs() {
    final searchableRequests = _searchFilteredLeaveRequests();
    final tabs = [
      _LeaveTabData(
        label: 'Awaiting Approval',
        count: searchableRequests.where((request) => request.isPending).length,
        icon: Icons.hourglass_empty,
        color: const Color(0xFFFFD43B),
      ),
      _LeaveTabData(
        label: 'Approved',
        count: searchableRequests
            .where((request) => request.status.toLowerCase() == 'approved')
            .length,
        icon: Icons.check_circle,
        color: const Color(0xFF69DB7C),
      ),
      _LeaveTabData(
        label: 'Rejected',
        count: searchableRequests
            .where((request) => _isRejectedLeave(request.status))
            .length,
        icon: Icons.cancel,
        color: const Color(0xFFFF8787),
      ),
    ];

    return SizedBox(
      width: double.infinity,
      child: FittedBox(
        alignment: Alignment.centerLeft,
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < tabs.length; i++) ...[
              _leaveTab(tabs[i], isSelected: _selectedLeaveTab == i, index: i),
              if (i != tabs.length - 1) const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _leaveSearchSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LEAVE REQUESTS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            onChanged: (value) {
              setState(() => _leaveSearchQuery = value.trim());
            },
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search leave requests',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              filled: true,
              fillColor: const Color(0xFF1F293B),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.white12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF4D8DFF)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _leaveTab(_LeaveTabData tab,
      {required bool isSelected, required int index}) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => setState(() => _selectedLeaveTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF20283A) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border(
            bottom: BorderSide(
              color: isSelected ? tab.color : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(tab.icon, color: tab.color, size: 18),
            const SizedBox(width: 7),
            Text(
              tab.label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              '(${tab.count})',
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  List<LeaveRequest> _selectedLeaveRequests() {
    final searchableRequests = _searchFilteredLeaveRequests();
    switch (_selectedLeaveTab) {
      case 1:
        return searchableRequests
            .where((request) => request.status.toLowerCase() == 'approved')
            .toList()
          ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
      case 2:
        return searchableRequests
            .where((request) => _isRejectedLeave(request.status))
            .toList()
          ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
      case 0:
      default:
        return searchableRequests.where((request) => request.isPending).toList()
          ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
    }
  }

  List<LeaveRequest> _searchFilteredLeaveRequests() {
    if (_leaveSearchQuery.isEmpty) {
      return List<LeaveRequest>.from(_leaveRequests);
    }

    final query = _leaveSearchQuery.toLowerCase();
    return _leaveRequests.where((request) {
      final employee = getEmployeeById(request.employeeId);
      return _employeeName(employee).toLowerCase().contains(query);
    }).toList();
  }

  Widget _leaveList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final requests = _selectedLeaveRequests();
    if (requests.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Text(
            _selectedLeaveTab == 0
                ? "No pending requests."
                : _selectedLeaveTab == 1
                    ? "No approved requests."
                    : "No rejected requests.",
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Column(
      children: requests.map((request) {
        final employee = getEmployeeById(request.employeeId);
        return _leaveRequestCard(request, employee);
      }).toList(),
    );
  }

  Widget _leaveRequestCard(LeaveRequest request, Employee? employee) {
    final statusColor = _leaveStatusColor(request.status);
    final requestDays = _leaveDays(request);
    final profileImage = _profileImage(employee?.profilePicture);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _showDetailsDialog(request),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF121B2E).withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedLeaveTab == 0
                ? const Color(0xFF2F5DA8)
                : Colors.white12,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: employee == null
                      ? null
                      : () => _openEmployeeProfile(employee),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFF172A52),
                    backgroundImage: profileImage,
                    child: profileImage == null
                        ? const Icon(Icons.person,
                            size: 28, color: Color(0xFF6EA8FE))
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _employeeName(employee),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _displayValue(employee?.jobRole, 'Employee'),
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _leaveStatusBadge(request.status, statusColor),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _leaveInfoRow(
                        icon: Icons.layers,
                        label: "Type:",
                        value: _displayValue(request.leaveType, 'Leave'),
                      ),
                      const SizedBox(height: 10),
                      _leaveInfoRow(
                        icon: Icons.calendar_month,
                        label: "",
                        value:
                            "${_formatLeaveDate(request.startDate)} \u2192 ${_formatLeaveDate(request.endDate)}",
                      ),
                      const SizedBox(height: 6),
                      _leaveInfoRow(
                        icon: Icons.schedule,
                        label: "",
                        value:
                            "$requestDays ${requestDays == 1 ? 'Day' : 'Days'}",
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: () => _showDetailsDialog(request),
                  icon: const Icon(Icons.chevron_right,
                      color: Color(0xFF3498DB), size: 28),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _leaveStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_leaveStatusIcon(status), color: color, size: 14),
          const SizedBox(width: 5),
          Text(
            _leaveStatusLabel(status),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _leaveInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF66D9EF), size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.25,
              ),
              children: [
                if (label.isNotEmpty)
                  TextSpan(
                    text: "$label ",
                    style: const TextStyle(color: Colors.white54),
                  ),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    color: Color(0xFFA8C7FF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  ImageProvider? _profileImage(String? profilePicture) {
    final value = profilePicture?.trim();
    if (value == null || value.isEmpty) return null;

    if (value.startsWith('data:image')) {
      try {
        return MemoryImage(base64Decode(value.split(',').last));
      } catch (_) {
        return null;
      }
    }

    return NetworkImage(value);
  }

  Color _leaveStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF69DB7C);
      case 'rejected':
      case 'denied':
        return const Color(0xFFFF8787);
      case 'pending':
      default:
        return const Color(0xFFFFD43B);
    }
  }

  IconData _leaveStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
      case 'denied':
        return Icons.cancel;
      case 'pending':
      default:
        return Icons.hourglass_empty;
    }
  }

  String _leaveStatusLabel(String status) {
    final normalized = status.trim();
    if (normalized.isEmpty) return 'Pending';
    final lower = normalized.toLowerCase();
    if (lower == 'pending') return 'Awaiting Approval';
    if (lower == 'denied') return 'Rejected';
    return normalized;
  }

  bool _isRejectedLeave(String status) {
    final lower = status.toLowerCase();
    return lower == 'rejected' || lower == 'denied';
  }

  String _employeeName(Employee? employee) {
    if (employee == null) return 'Unknown';
    final parts = [
      employee.firstName,
      employee.middleName,
      employee.lastName,
    ].where((part) => part != null && part.trim().isNotEmpty);
    final name = parts.join(' ');
    return name.isEmpty ? 'Unknown' : name;
  }

  String _displayValue(String? value, String fallback) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? fallback : trimmed;
  }

  int _leaveDays(LeaveRequest request) {
    return request.endDate.difference(request.startDate).inDays + 1;
  }

  String _formatLeaveDate(DateTime date) {
    return DateFormat('d MMM yyyy').format(date);
  }

  Future<void> _showDetailsDialog(LeaveRequest request) async {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final employee = getEmployeeById(request.employeeId);

    final requestDays =
        request.endDate.difference(request.startDate).inDays + 1;
    final isApprovedRequest = request.status.toLowerCase() == 'approved';
    final isRejectedRequest = _isRejectedLeave(request.status);
    final canReject = request.isPending || isApprovedRequest;
    final canApprove = request.isPending || isRejectedRequest;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF363E51), Color(0xFF191E26)],
              ),
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Leave Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _detailRow("Employee Name", _employeeName(employee)),
                    _detailRow("Leave Type", request.leaveType),
                    _detailRow(
                        "Start Date", dateFormat.format(request.startDate)),
                    _detailRow("End Date", dateFormat.format(request.endDate)),
                    _detailRow("Requested Days", "$requestDays"),
                    _detailRow("Reason", request.reason),
                    _detailRow(
                      "Status",
                      request.status,
                      valueColor: request.status.toLowerCase() == "approved"
                          ? Colors.green
                          : _isRejectedLeave(request.status)
                              ? Colors.red
                              : Colors.white,
                    ),
                    if (isRejectedRequest)
                      _detailRow(
                        "Rejection Reason",
                        request.rejectionReason.trim().isEmpty
                            ? "Not provided"
                            : request.rejectionReason,
                      ),
                    _detailRow(
                        "Requested At", dateFormat.format(request.requestedAt)),
                    if (canReject || canApprove) ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          if (canReject)
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  final rejectionReason =
                                      await _showRejectReasonDialog();
                                  if (rejectionReason == null ||
                                      rejectionReason.trim().isEmpty) {
                                    return;
                                  }
                                  if (!context.mounted) return;

                                  Navigator.of(context).pop();
                                  _updateLeaveStatus(
                                    request.leaveRequestId,
                                    "Rejected",
                                    rejectionReason: rejectionReason,
                                  ).then((_) {
                                    _fetchLeaveRequests();
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                ),
                                child: Ink(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color.fromARGB(255, 226, 66, 63),
                                        Color.fromARGB(255, 133, 5, 5),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF1A1F2C)
                                            .withValues(alpha: 0.6),
                                        spreadRadius: 0,
                                        blurRadius: 8,
                                        offset: const Offset(3, 3),
                                      ),
                                    ],
                                  ),
                                  child: Container(
                                    alignment: Alignment.center,
                                    height: 44,
                                    child: const Text(
                                      "Reject",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (canReject && canApprove)
                            const SizedBox(width: 12),
                          if (canApprove)
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  _updateLeaveStatus(
                                    request.leaveRequestId,
                                    "Approved",
                                  ).then((_) {
                                    _fetchLeaveRequests();
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                ),
                                child: Ink(
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
                                        color: const Color(0xFF1A1F2C)
                                            .withValues(alpha: 0.6),
                                        spreadRadius: 0,
                                        blurRadius: 8,
                                        offset: const Offset(3, 3),
                                      ),
                                    ],
                                  ),
                                  child: Container(
                                    alignment: Alignment.center,
                                    height: 44,
                                    child: const Text(
                                      "Approve",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
