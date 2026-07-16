import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shiftsmart/models/employee.dart';
import 'package:shiftsmart/models/shift.dart';
import 'package:shiftsmart/services/employee_service.dart';
import 'package:shiftsmart/services/shift_service.dart';
import 'package:shiftsmart/services/attendance_service.dart';
import 'package:shiftsmart/widgets/background.dart';
import 'package:shiftsmart/widgets/uppernavbar.dart';

class ManagerPendingRequests extends StatefulWidget {
  const ManagerPendingRequests({super.key});

  @override
  State<ManagerPendingRequests> createState() => _ManagerPendingRequestsState();
}

class _ManagerPendingRequestsState extends State<ManagerPendingRequests> {
  final ShiftService _shiftService = ShiftService();
  final EmployeeService _employeeService = EmployeeService();
  final AttendanceService _attendanceService = AttendanceService();

  List<PendingItem> _pendingItems = [];
  Map<int, Employee> _employeeMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load all employees first to have mapping
      final employees = await _employeeService.fetchAllEmployees();
      _employeeMap = {for (var e in employees) e.employeeId: e};

      // Load all shifts and extract pending responses
      final rawShifts = await _shiftService.fetchAllRawShifts();
      final List<PendingItem> items = [];

      for (var shiftData in rawShifts) {
        final shift = Shift.fromJson(shiftData);
        for (var response in shift.employeeResponses) {
          final isPendingAttendance = response.approvalStatus == "Pending" ||
              (response.isEarlyExit && response.approvalStatus == null);
          if (isPendingAttendance || response.isSwapRequested) {
            items.add(PendingItem(
              shift: shift,
              response: response,
              type: response.isSwapRequested
                  ? PendingRequestType.shiftSwap
                  : PendingRequestType.attendance,
            ));
          }
        }
      }

      setState(() {
        _pendingItems = items;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading pending requests: $e");
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading data: $e")),
        );
      }
    }
  }

  Future<void> _handleAction(PendingItem item, String status) async {
    if (item.isShiftSwap) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "Shift swap approve/reject needs a backend endpoint. This app can show the pending swap request now."),
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // First, we need the Attendance record to get AttendanceId
      final attendanceList =
          await _attendanceService.getShiftsByShiftId(item.response.employeeId);
      final record = (attendanceList as List).firstWhere(
        (a) => a['ShiftId'] == item.shift.shiftId,
        orElse: () => null,
      );

      if (record != null && record['AttendanceId'] != null) {
        final success = await _attendanceService.approveAttendance(
            record['AttendanceId'], status);
        Navigator.pop(context); // Pop loading

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: status == "Approved" ? Colors.green : Colors.red,
              content: Text("Request ${status.toLowerCase()} successfully!"),
            ),
          );
          _loadData(); // Reload list
        } else {
          throw Exception("Failed to update status on server");
        }
      } else {
        Navigator.pop(context);
        throw Exception("Attendance record not found");
      }
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Uppernavbar(showBackButton: true),
      body: Stack(
        children: [
          const Background(),
          Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Pending Approval Requests",
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadData,
                  color: const Color(0xFF724584),
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF724584)))
                      : _pendingItems.isEmpty
                          ? ListView(
                              children: const [
                                SizedBox(height: 100),
                                Center(
                                  child: Text(
                                    "No pending requests found.",
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 16),
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(16),
                              itemCount: _pendingItems.length,
                              itemBuilder: (context, index) {
                                final item = _pendingItems[index];
                                final employee =
                                    _employeeMap[item.response.employeeId];

                                return _buildRequestCard(item, employee);
                              },
                            ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(PendingItem item, Employee? employee) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[800],
                backgroundImage: (employee?.profilePicture != null &&
                        employee!.profilePicture!.isNotEmpty)
                    ? (employee.profilePicture!.startsWith('data:image')
                        ? MemoryImage(base64Decode(
                                employee.profilePicture!.split(',').last))
                            as ImageProvider
                        : NetworkImage(employee.profilePicture!))
                    : null,
                child: (employee?.profilePicture == null ||
                        employee!.profilePicture!.isEmpty)
                    ? const Icon(Icons.person, color: Colors.white, size: 20)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee?.firstName ?? 'Unknown Employee',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                    Text(
                      item.shift.taskName,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: item.badgeColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.badgeLabel,
                  style: TextStyle(
                    color: item.badgeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 24),
          Row(
            children: [
              const Icon(Icons.schedule, color: Colors.blueAccent, size: 16),
              const SizedBox(width: 8),
              Text(
                "Shift: ${item.shift.startTime} - ${item.shift.endTime}",
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (item.response.clockOutTime != null)
            Row(
              children: [
                const Icon(Icons.logout, color: Colors.redAccent, size: 16),
                const SizedBox(width: 8),
                Text(
                  "Clocked Out: ${DateFormat('hh:mm a').format(item.response.clockOutTime!.toLocal())}",
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "REASON:",
                  style: TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1),
                ),
                const SizedBox(height: 4),
                Text(
                  item.reasonText,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => _handleAction(item, "Rejected"),
                  child: const Text("REJECT",
                      style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => _handleAction(item, "Approved"),
                  child: const Text("APPROVE",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PendingItem {
  final Shift shift;
  final EmployeeResponse response;
  final PendingRequestType type;

  PendingItem({
    required this.shift,
    required this.response,
    required this.type,
  });

  bool get isShiftSwap => type == PendingRequestType.shiftSwap;

  String get badgeLabel => isShiftSwap ? "Shift Swap" : "Early Exit";

  Color get badgeColor => isShiftSwap ? Colors.blueAccent : Colors.orangeAccent;

  String get reasonText => isShiftSwap
      ? "Employee requested a shift swap. Status: ${response.status}"
      : response.earlyExitReason ?? "Emergency/Personal";
}

enum PendingRequestType {
  attendance,
  shiftSwap,
}
