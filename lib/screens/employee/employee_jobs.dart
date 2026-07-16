import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftsmart/screens/employee/employee_job_view.dart';
import 'package:shiftsmart/services/job_service.dart';
import 'package:shiftsmart/services/shared_preferences_service.dart';
import 'package:shiftsmart/services/shift_service.dart';
import 'package:shiftsmart/utils/fullscreen_helper.dart';
import 'package:shiftsmart/widgets/background.dart';
import 'package:shiftsmart/widgets/gradienthorizontal.dart';
import 'package:shiftsmart/widgets/search.dart';
import 'package:shiftsmart/models/job.dart';

class Employeeshifts extends StatefulWidget {
  const Employeeshifts({super.key});

  @override
  State<Employeeshifts> createState() => _EmployeeshiftsState();
}

class _EmployeeshiftsState extends State<Employeeshifts> {
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();

  // State variables
  List<Job> allJobs = [];
  List<Job> filteredJobs = [];
  int? employeeId;
  bool _isLoading = true;

  // Services
  final JobService _jobService = JobService();
  final ShiftService _shiftService = ShiftService();

  @override
  void initState() {
    super.initState();
    enableFullScreen();
    _refreshData();
  }

  // Reloads data by first checking the user ID
  Future<void> _refreshData() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    employeeId = prefs.getInt('employeeId');

    if (employeeId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Employee ID not found.")),
        );
      }
      setState(() => _isLoading = false);
      return;
    }
    await fetchJobs();
    setState(() => _isLoading = false);
  }

  // Fetches jobs assigned to the current employee
  Future<void> fetchJobs() async {
    try {
      // 1. Get shifts specifically for this employee
      final myShifts = await _shiftService.fetchShiftsByEmployeeId(employeeId!);

      // 2. Extract unique Job IDs from those shifts (ignoring nulls)
      final Set<int> myJobIds = myShifts
          .map((shift) => shift.jobId)
          .where((id) => id != null)
          .cast<int>()
          .toSet();

      // 3. Fetch the full list of jobs
      final allJobsData = await _jobService.fetchAllJobs();

      // 4. Filter the full list to keep only jobs matching our IDs or assigned directly
      final assignedJobs = allJobsData.where((job) {
        return myJobIds.contains(job.jobId) || job.employeeId == employeeId;
      }).toList();

      if (mounted) {
        setState(() {
          allJobs = assignedJobs;
          filteredJobs = List.from(assignedJobs);
        });
      }
    } catch (e) {
      debugPrint("Fetch error: $e");
    }
  }

  // Filters the list based on search text
  void onQueryChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredJobs = List.from(allJobs);
      } else {
        filteredJobs = allJobs.where((job) {
          return job.title.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: MediaQuery.removeViewInsets(
                context: context,
                removeBottom: true,
                child: const Background(),
              ),
            ),
          ),
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF724584)),
                )
              : RefreshIndicator(
                  key: _refreshKey,
                  onRefresh: _refreshData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        // Search Bar
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                          child: Search(onQueryChanged: onQueryChanged),
                        ),
                        // Main Content Area
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Gradienthorizontal(
                            width: double.infinity,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      "JOB LIST",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Show list or empty state
                                  _isLoading
                                      ? const Padding(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 20),
                                          child: Align(
                                            alignment: Alignment.center,
                                            child: CircularProgressIndicator(
                                                color: Color(0xFF724584)),
                                          ),
                                        )
                                      : filteredJobs.isEmpty
                                          ? const Center(
                                              child: Padding(
                                                padding: EdgeInsets.all(20.0),
                                                child: Text("No jobs assigned.",
                                                    style: TextStyle(
                                                        color: Colors.white70)),
                                              ),
                                            )
                                          : ListView.builder(
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              shrinkWrap: true,
                                              itemCount: filteredJobs.length,
                                              itemBuilder: (context, index) {
                                                return shiftCard(
                                                    filteredJobs[index],
                                                    employeeId!);
                                              },
                                            ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
  // Widget to display individual job details
  Widget shiftCard(Job job, int employeeId) {
    final String status = job.status;
    IconData statusIcon;
    Color statusColor;

    // Determine color and icon based on status
    switch (status.toLowerCase()) {
      case 'active':
        statusIcon = Icons.donut_large_sharp;
        statusColor = Colors.amberAccent;
        break;
      case 'pending':
        statusIcon = Icons.hourglass_top;
        statusColor = Colors.red;
        break;
      case 'completed':
      case 'done':
        statusIcon = Icons.domain_verification_outlined;
        statusColor = Colors.greenAccent;
        break;
      default:
        statusIcon = Icons.info_outline;
        statusColor = Colors.grey;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EmployeeJobView(
              job: job,
              prefsService: RealSharedPreferencesService(),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF363E51), Color(0xFF191E26)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.checklist_rtl, color: Color(0xFF3498DB), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text("Estimated Time:",
                          style: TextStyle(color: Colors.white60)),
                      const SizedBox(width: 5),
                      Text("${job.totalEstimatedTime} Hrs",
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 14)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  status,
                  style: TextStyle(color: statusColor, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Icon(statusIcon, color: statusColor, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

