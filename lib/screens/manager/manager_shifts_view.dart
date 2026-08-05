import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shiftsmart/models/attendance.dart';
import 'package:shiftsmart/models/job.dart';
import 'package:shiftsmart/models/shift.dart';
import 'package:shiftsmart/services/employee_service.dart';
import 'package:shiftsmart/services/job_service.dart';
import 'package:shiftsmart/utils/fullscreen_helper.dart';
import 'package:shiftsmart/widgets/background.dart';
import 'package:shiftsmart/widgets/manager_screen_style.dart';
import 'package:shiftsmart/widgets/sidenav.dart';
import 'package:shiftsmart/widgets/uppernavbar.dart';
import 'package:shiftsmart/services/attendance_service.dart';
import 'package:shiftsmart/screens/manager/manager_create_shift.dart';

class ManagerShiftsView extends StatefulWidget {
  final Shift shift;
  final bool embedded;

  const ManagerShiftsView({
    super.key,
    required this.shift,
    this.embedded = false,
  });

  @override
  State<ManagerShiftsView> createState() => _ManagerShiftsViewState();
}

class _ManagerShiftsViewState extends State<ManagerShiftsView> {
  List<Job> allJobs = [];
  List<Job> filteredJobs = [];
  Map<int, String> employeeMap = {};
  Map<int, int> attendanceMap = {};
  final JobService _jobservice = JobService();
  final AttendanceService _attendanceService = AttendanceService();

  @override
  void initState() {
    super.initState();
    enableFullScreen();
    fetchJobs();
    fetchEmployees();
  }

  Future<void> fetchJobs() async {
    final jobs = await _jobservice.fetchAllJobs();

    setState(() {
      allJobs = jobs;
      filteredJobs = List.from(allJobs);
    });
  }

  Future<void> fetchEmployees() async {
    final map = await EmployeeService().fetchEmployeeNameMap();
    if (mounted) {
      setState(() {
        employeeMap = map;
      });
    }
  }

  String _getJobTitleByJobId(int jobId) {
    final job = allJobs.firstWhere(
      (j) => j.jobId == jobId,
      orElse: () => Job(
        jobId: 0,
        title: 'Unknown',
        description: '',
        status: '',
        projectId: 0,
        totalEstimatedTime: 0,
        siteId: 0,
        startDate: '',
        jobDueDate: '',
        jobImageUrl: '',
        jobRoles: [],
      ),
    );
    return job.title;
  }

  String _formatTime(String timeString) {
    try {
      final time = DateFormat.Hms().parse(timeString);
      return DateFormat.Hm().format(time);
    } catch (e) {
      return timeString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final shift = widget.shift;
    if (widget.embedded) {
      return _buildDetailsPanel(shift);
    }

    return Scaffold(
      drawer: const Sidenav(),
      backgroundColor: const Color(0xFF1C2230),
      appBar: const Uppernavbar(
        showBackButton: true,
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: Background()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child: _buildDetailsPanel(shift),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsPanel(Shift shift) {
    final assignedEmployees = _assignedEmployeeRows(shift);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF262D3F).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 64, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SHIFT DETAILS',
                  style: TextStyle(
                    color: ManagerScreenStyle.cyan,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 18,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      shift.taskName,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    _statusBadge(shift.status),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 820
                        ? 3
                        : constraints.maxWidth >= 560
                            ? 2
                            : 1;
                    final spacing = 16.0;
                    final width =
                        (constraints.maxWidth - spacing * (columns - 1)) /
                            columns;

                    return Wrap(
                      spacing: spacing,
                      runSpacing: 12,
                      children: [
                        _detailTile(
                            width,
                            'DATE',
                            DateFormat.yMMMMd().format(shift.date),
                            Icons.calendar_month_rounded),
                        _detailTile(
                            width,
                            'START TIME',
                            _formatTime(shift.startTime),
                            Icons.schedule_rounded),
                        _detailTile(width, 'END TIME',
                            _formatTime(shift.endTime), Icons.schedule_rounded),
                        _detailTile(
                            width,
                            'JOB',
                            _getJobTitleByJobId(shift.jobId ?? 0),
                            Icons.work_rounded),
                        _detailTile(
                            width,
                            'EMPLOYEES',
                            assignedEmployees.length.toString(),
                            Icons.groups_rounded),
                        _detailTile(
                            width, 'STATUS', shift.status, Icons.flag_rounded),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),
                const Text(
                  "ASSIGNED EMPLOYEES",
                  style: TextStyle(
                    color: ManagerScreenStyle.cyan,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 10),
                if (assignedEmployees.isEmpty)
                  const Text(
                    'No assigned employees available.',
                    style: TextStyle(color: Colors.white70),
                  )
                else
                  ...assignedEmployees.map((response) {
                    final name = _getEmployeeNameById(response.employeeId);
                    return _buildEmployeeCard(name, response);
                  }),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Align(
              alignment: Alignment.centerRight,
              child: ManagerActionButton(
                text: 'Edit Shift',
                icon: Icons.edit_rounded,
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          Managercreateshift(shift: widget.shift),
                    ),
                  );
                  if (result == true && mounted) {
                    Navigator.pop(context, true);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailTile(double width, String label, String value, IconData icon) {
    return SizedBox(
      width: width,
      child: Container(
        constraints: const BoxConstraints(minHeight: 70),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ManagerScreenStyle.tileBg.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.56),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value.trim().isEmpty ? 'Not provided' : value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(icon, color: ManagerScreenStyle.cyan, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final color = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(
        status.trim().isEmpty ? 'UNKNOWN' : status.trim().toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(String name, EmployeeResponse response) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ManagerScreenStyle.tileBg.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(response.status).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      _getStatusColor(response.status).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  response.status,
                  style: TextStyle(
                    color: _getStatusColor(response.status),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (response.clockInTime != null)
            _buildDetailRow(
                Icons.login,
                "Clock In:",
                DateFormat('MMM d, hh:mm a')
                    .format(response.clockInTime!.toLocal())),
          if (response.clockOutTime != null)
            _buildDetailRow(
                Icons.logout,
                "Clock Out:",
                DateFormat('MMM d, hh:mm a')
                    .format(response.clockOutTime!.toLocal())),
          if (response.isEarlyExit) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Early Exit: ${response.earlyExitReason ?? response.reason ?? 'No reason provided'}",
                    style: const TextStyle(color: Colors.orange, fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1BAFFF),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 3,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onPressed: () async {
                final photos =
                    await _attendanceService.fetchAttendancePhotoLists(
                        response.employeeId, widget.shift.shiftId);

                final clockInPhotos =
                    photos['clockIn'] ?? const <AttendancePhoto>[];
                final clockOutPhotos =
                    photos['clockOut'] ?? const <AttendancePhoto>[];

                if (clockInPhotos.isEmpty && clockOutPhotos.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Attendance images not found for this shift')),
                  );
                  return;
                }

                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: const Color(0xFF2C2F36),
                    title: const Text("Evidence"),
                    titleTextStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    content: SingleChildScrollView(
                      child: SizedBox(
                        width: _evidenceDialogWidth(context),
                        child: Column(
                          children: [
                            if (clockInPhotos.isNotEmpty) ...[
                              const Text("Clock In",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              _buildEvidencePhotoGrid(clockInPhotos),
                            ] else
                              const Text("Clock In image not available",
                                  style: TextStyle(color: Colors.white70)),
                            const SizedBox(height: 20),
                            if (clockOutPhotos.isNotEmpty) ...[
                              const Text("Clock Out",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              _buildEvidencePhotoGrid(clockOutPhotos),
                            ] else
                              const Text("Clock Out image not available",
                                  style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Close",
                            style: TextStyle(color: Color(0xFF1BAFFF))),
                      )
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
              label: const Text("View Evidence",
                  style: TextStyle(color: Colors.white, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidencePhotoGrid(List<AttendancePhoto> photos) {
    final gridWidth = _evidenceDialogWidth(context);
    final tileWidth = photos.length == 1 ? gridWidth : (gridWidth - 12) / 2;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: photos
          .map((photo) => SizedBox(
                width: tileWidth,
                height: 150,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildEvidenceImage(photo.url),
                ),
              ))
          .toList(),
    );
  }

  double _evidenceDialogWidth(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    if (screenWidth < 360) return 240;
    if (screenWidth < 520) return screenWidth - 96;
    return 420;
  }

  Widget _buildEvidenceImage(String value) {
    final bytes = _decodeImageBytes(value);
    if (bytes != null) {
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _evidenceImageError(),
      );
    }

    return Image.network(
      value,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _evidenceImageError(),
    );
  }

  Widget _evidenceImageError() {
    return Container(
      height: 140,
      color: Colors.white10,
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image, color: Colors.white38),
    );
  }

  Uint8List? _decodeImageBytes(String value) {
    final trimmed = value.trim();
    final commaIndex = trimmed.indexOf(',');
    final base64Value =
        trimmed.toLowerCase().startsWith('data:image') && commaIndex != -1
            ? trimmed.substring(commaIndex + 1)
            : trimmed;

    if (base64Value.startsWith('http://') ||
        base64Value.startsWith('https://')) {
      return null;
    }

    try {
      return base64Decode(base64Value);
    } catch (_) {
      return null;
    }
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(width: 8),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return const Color(0xFFFFFF2E);
      case 'scheduled':
        return const Color(0xFFFFC56D);
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
        return ManagerScreenStyle.cyan;
    }
  }

  String _getEmployeeNameById(int id) {
    return employeeMap[id] ?? "$id";
  }

  List<EmployeeResponse> _assignedEmployeeRows(Shift shift) {
    final rowsByEmployeeId = <int, EmployeeResponse>{};

    for (final response in shift.employeeResponses) {
      if (response.employeeId > 0) {
        rowsByEmployeeId[response.employeeId] = response;
      }
    }

    for (final employeeId in shift.assignedEmployeeIds) {
      if (employeeId > 0) {
        rowsByEmployeeId.putIfAbsent(
          employeeId,
          () => EmployeeResponse(
            employeeId: employeeId,
            status: 'Pending',
            isEarlyExit: false,
          ),
        );
      }
    }

    return rowsByEmployeeId.values.toList();
  }
}

class LabelWithImageDialog extends StatelessWidget {
  final String label;
  final String buttonLabel;
  final String? imageUrl;

  const LabelWithImageDialog({
    super.key,
    required this.label,
    required this.buttonLabel,
    required this.imageUrl,
  });

  void _showImageDialog(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No image available')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: InteractiveViewer(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl!,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Padding(
                padding: EdgeInsets.all(20),
                child: Text('Failed to load image',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            )),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1BAFFF),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 5,
          ),
          onPressed: () => _showImageDialog(context),
          icon: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
          label: Text(buttonLabel, style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
