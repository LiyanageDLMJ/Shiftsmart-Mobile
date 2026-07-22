import 'package:flutter/material.dart';
import 'package:shiftsmart/screens/employee/employee_shift_view.dart';
import 'package:shiftsmart/screens/employee/media_viewer.dart';
import 'package:shiftsmart/widgets/success_dialog.dart';
import 'package:shiftsmart/services/image_picker_service.dart';
import 'package:shiftsmart/services/location_service.dart';
import 'package:shiftsmart/services/shared_preferences_service.dart';
import 'package:shiftsmart/services/shift_service.dart';
import 'package:shiftsmart/services/site_service.dart';
import 'package:shiftsmart/utils/fullscreen_helper.dart';
import 'package:shiftsmart/widgets/background.dart';
import 'package:shiftsmart/widgets/gradienthorizontal.dart';
import 'package:shiftsmart/widgets/uppernavbar.dart';
import 'package:shiftsmart/widgets/sidenav.dart';
import 'package:shiftsmart/models/job.dart';
import 'package:shiftsmart/models/site.dart';
import 'package:shiftsmart/widgets/gradient_button.dart';

class EmployeeJobView extends StatefulWidget {
  final Job job;
  final SharedPreferencesService prefsService;
  const EmployeeJobView({
    super.key,
    required this.job,
    required this.prefsService,
  });

  @override
  State<EmployeeJobView> createState() => _EmployeeJobViewState();
}

class _EmployeeJobViewState extends State<EmployeeJobView> {
  Site? _site;
  bool _loadingSite = true;
  bool _loadingShifts = true;
  List<Map<String, dynamic>> _jobShifts = [];
  int? _employeeId;

  // Services
  final SiteService _siteService = SiteService();
  final ShiftService _shiftService = ShiftService();

  @override
  void initState() {
    super.initState();
    enableFullScreen();
    // Load ID first, then fetch site and shift data
    _loadEmployeeId().then((_) {
      _fetchSite();
      _fetchJobShifts();
    });
  }

  // Gets the current logged-in employee ID
  Future<void> _loadEmployeeId() async {
    final id = await widget.prefsService.getEmployeeId();
    if (mounted) {
      setState(() => _employeeId = id);
    }
  }

  // Fetches location details for this job
  Future<void> _fetchSite() async {
    if (widget.job.siteId <= 0) {
      setState(() {
        _site = _unknownSite();
        _loadingSite = false;
      });
      return;
    }

    try {
      final site = await _siteService.fetchSiteById(widget.job.siteId);
      setState(() {
        _site = site ?? _unknownSite();
        _loadingSite = false;
      });
    } catch (e) {
      print("Error fetching site data: $e");
      setState(() => _loadingSite = false);
    }
  }

  Site _unknownSite() {
    return Site(
      siteId: 0,
      siteName: 'Unknown Location',
      latitude: '',
      longitude: '',
      geoFenceType: '',
      geoCoordinates: '',
      radius: 0,
      projectId: widget.job.projectId,
    );
  }

  // Loads specific shifts assigned to this employee for this job
  Future<void> _fetchJobShifts() async {
    if (_employeeId == null) {
      setState(() => _loadingShifts = false);
      return;
    }

    try {
      final jobShifts = await _shiftService.fetchShiftsForJobAndEmployee(
        jobId: widget.job.jobId,
        employeeId: _employeeId!,
      );
      setState(() {
        _jobShifts = jobShifts;
        _loadingShifts = false;
      });
      debugPrint(
          "Found ${_jobShifts.length} shifts for job ${widget.job.jobId}");
    } catch (e) {
      debugPrint("Error loading job shifts: $e");
      setState(() {
        _loadingShifts = false;
      });
    }
  }

  // Navigates to the detailed view of a specific shift
  void _navigateToShiftView(Map<String, dynamic> shift) {
    if (_employeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: Employee ID not found")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Employeeshiftview(
          job: widget.job,
          shiftId: shift['ShiftId'],
          employeeId: _employeeId!,
          scheduledStartTime: shift['StartTime'],
          scheduledEndTime: shift['EndTime'],
          imagePickerService: RealImagePickerService(),
          locationService: RealLocationService(),
        ),
      ),
    );
  }

  // --- NEW: Handles the "Acknowledge" button click ---
  void _handleJobAcknowledgement() {
    // Here you would typically send an API call to mark the job as "Seen"

    // Show the new Success Dialog
    SuccessDialog.show(
      context,
      title: "Confirm",
      message: "You have successfully acknowledged this job assignment.",
      buttonText: "OK",
      onPressed: () {
        Navigator.pop(context); // Close the dialog
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    return Stack(
      children: [
        const Positioned.fill(child: Background()),
        Scaffold(
          drawer: const Sidenav(),
          appBar: const Uppernavbar(showBackButton: true),
          backgroundColor: Colors.transparent,
          body: (_loadingSite || _loadingShifts)
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF724584)))
              : SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: screenW * 0.07, vertical: 20),
                    child: Gradienthorizontal(
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 30),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Job Title
                            Text(
                              widget.job.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 30),

                            // Job Details
                            _infoRow("Status", widget.job.status,
                                isStatus: true),
                            const SizedBox(height: 15),
                            _infoRowWithIcon(
                              label: "Location",
                              value: _site?.siteName ?? 'Loading location...',
                              icon: Icons.location_on,
                              iconColor: Colors.redAccent,
                            ),
                            const SizedBox(height: 15),
                            _infoRow("Estimated Time",
                                "${widget.job.totalEstimatedTime} Hrs"),
                            const SizedBox(height: 15),

                            // Media Button
                            _infoRowWithButton(
                              label: "Job Media",
                              button: GradientButton(
                                text: "Media",
                                onPressed: () {
                                  if (widget.job.jobImageUrl
                                      .trim()
                                      .isNotEmpty) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => MediaViewer(
                                            url: widget.job.jobImageUrl),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text("No media available")),
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Description Section
                            const Text(
                              "Description",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.job.description.isNotEmpty
                                  ? widget.job.description
                                  : "No description available.",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 30),

                            // Shifts List Section
                            const Text(
                              "Available Shifts",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 15),
                            _buildShiftsList(),

                            const SizedBox(height: 30),

                            // --- NEW BUTTON: Triggers the Success Popup ---
                            SizedBox(
                              width: double.infinity,
                              child: GradientButton(
                                text: "Confirm",
                                onPressed: _handleJobAcknowledgement,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  // Helper widget to display the list of shifts
  Widget _buildShiftsList() {
    if (_jobShifts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: const Center(
          child: Text(
            "No shifts available for this job",
            style: TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: _jobShifts.map((shift) => _buildShiftCard(shift)).toList(),
    );
  }

  // Helper widget for individual shift cards
  Widget _buildShiftCard(Map<String, dynamic> shift) {
    final taskName = shift['TaskName'] ?? 'Unnamed Task';
    final startTime = shift['StartTime'] ?? '';
    final endTime = shift['EndTime'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(180, 53, 63, 84),
            Color.fromARGB(180, 34, 40, 52),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: InkWell(
        onTap: () => _navigateToShiftView(shift),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3498DB).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.asset(
                  "assets/cShift.png",
                  width: 28,
                  height: 28,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      taskName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const SizedBox(width: 4),
                        Text(
                          '$startTime - $endTime',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white54,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // UI Helper for basic text rows
  Widget _infoRow(String label, String value, {bool isStatus = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: isStatus ? const Color(0xFFEBCC46) : Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  // UI Helper for rows with a button
  Widget _infoRowWithButton({required String label, required Widget button}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        button,
      ],
    );
  }

  // UI Helper for rows that include an icon
  Widget _infoRowWithIcon({
    required String label,
    required String value,
    required IconData icon,
    Color iconColor = Colors.white,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  softWrap: true,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
