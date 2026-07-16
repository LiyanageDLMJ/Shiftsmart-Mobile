import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftsmart/models/shift.dart';
import 'package:shiftsmart/models/job.dart';
import 'package:shiftsmart/screens/employee/employee_shift_view.dart';
import 'package:shiftsmart/services/image_picker_service.dart';
import 'package:shiftsmart/services/job_service.dart';
import 'package:shiftsmart/services/location_service.dart';
import 'package:shiftsmart/services/shift_service.dart';
import 'package:shiftsmart/utils/date_time_parser.dart';
import 'package:shiftsmart/utils/fullscreen_helper.dart';
import 'package:shiftsmart/widgets/background.dart';
import 'package:shiftsmart/responsive.dart';

class Employeedashboard extends StatefulWidget {
  const Employeedashboard({super.key});

  @override
  State<Employeedashboard> createState() => _EmployeedashboardState();
}

class _EmployeedashboardState extends State<Employeedashboard> {
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();

  File? selectedFile;
  String? fileName;
//   List<Job> allJobs = [];
//   List<Job> filteredJobs = [];

  int? employeeId;
  Map<int, String> uploadedFiles = {};
  Shift? currentShift;
  bool _isLoading = true;
  List<Map<String, dynamic>> jobs = []; // today's jobs
  List<Map<String, dynamic>> upcomingJobs = []; // tomorrow and future jobs

  Map<int, bool> expandedJobs = {}; // tracking expanded job
  Map<int, List<Map<String, dynamic>>> jobShifts =
      {}; // Store all shifts grouped by job ID

  @override
  void initState() {
    super.initState();
    enableFullScreen();
    _loadEmployeeId().then((_) {
      if (employeeId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _refreshKey.currentState?.show(); // optional spinner
          _refreshData();
        });
      }
    });
  }

  Future<void> _refreshData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    await fetchJobs();
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _loadEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('employeeId');

    setState(() {
      employeeId = id;
    });

    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Error: employeeId not set. Please login again.")),
      );
    }
  }

  Future<void> fetchJobs() async {
    final jobService = JobService();
    final shiftService = ShiftService();

    if (employeeId == null) return;

    try {
      // 1. Fetch Jobs
      final jobsData = await jobService.fetchAllJobs();

      // 2. Fetch Shifts (FIX: Use the new method that works for Employees)
      // OLD: final shiftsData = await shiftService.fetchAllRawShifts(); // Caused 403
      final List<Shift> shiftsList =
          await shiftService.fetchShiftsByEmployeeId(employeeId!);

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // 3. Convert List<Shift> to Maps to keep your existing logic working
      // Note: We don't need to filter by employeeId here because the API already did it!
      final employeeShifts = shiftsList.map((s) => s.toJson()).toList();

      final jobMap = {for (var job in jobsData) job.jobId: job};

      List<Map<String, dynamic>> futureJobs = [];
      List<Map<String, dynamic>> todayJobs = [];
      Map<int, List<Map<String, dynamic>>> tempJobShifts = {};

      for (var shift in employeeShifts) {
        try {
          // Check if your Shift model returns 'Date' or 'date' (adjust case if needed)
          final shiftDateStr = shift['Date'] ?? shift['date'];
          final shiftStartTimeStr = shift['StartTime'] ?? shift['startTime'];
          final shiftJobId = shift['JobId'] ?? shift['jobId'];

          if (shiftDateStr == null || shiftStartTimeStr == null) continue;

          final shiftDate = parseServerDateTime(shiftDateStr);
          if (shiftDate == null) continue;
          // Fix logic to handle Time format correctly
          final shiftStart = parseServerDateTime(
                  "${shiftDateStr.toString().split("T")[0]} $shiftStartTimeStr") ??
              shiftDate;

          final job = jobMap[shiftJobId];
          if (job == null) continue;

          final fullJob = {
            ...job.toJson(),
            'Shift': shift,
            'ShiftStart': shiftStart,
          };

          // Only show shifts scheduled for today
          final localShiftDate = shiftDate.toLocal();
          final shiftDay = DateTime(
              localShiftDate.year, localShiftDate.month, localShiftDate.day);

          if (shiftDay == today) {
            todayJobs.add(fullJob);

            tempJobShifts.putIfAbsent(shiftJobId, () => []);
            tempJobShifts[shiftJobId]!.add(fullJob);
          }

          if (shiftDay.isAfter(today)) {
            futureJobs.add(fullJob);
          }
        } catch (e) {
          debugPrint("Error processing shift: $e");
        }
      }

      futureJobs.sort((a, b) => a['ShiftStart'].compareTo(b['ShiftStart']));
      todayJobs.sort((a, b) => a['ShiftStart'].compareTo(b['ShiftStart']));
      for (var jobId in tempJobShifts.keys) {
        tempJobShifts[jobId]!
            .sort((a, b) => a['ShiftStart'].compareTo(b['ShiftStart']));
      }

      setState(() {
        jobs = todayJobs;
        jobShifts = tempJobShifts;
        upcomingJobs = futureJobs;
      });
    } catch (e) {
      debugPrint("Error fetching dashboard data: $e");
    }
  }

  void _navigateToShiftView(Map<String, dynamic> shiftData) {
    final shift = shiftData['Shift'];

    // Improved SiteId resolution: fallback to shift's SiteId if job's SiteId is 0 or null
    final siteId = (shiftData['SiteId'] != null && shiftData['SiteId'] != 0)
        ? shiftData['SiteId']
        : (shift != null ? (shift['SiteId'] ?? shift['siteId'] ?? 0) : 0);

    final job = Job(
      jobId: shiftData['JobId'],
      title: shiftData['Title'] ?? 'No Title',
      description: shiftData['Description'] ?? 'No Description',
      siteId: siteId,
      startDate: '',
      jobDueDate: '',
      status: '',
      projectId: shiftData['ProjectId'],
      totalEstimatedTime: shiftData['TotalEstimatedTime'],
      jobImageUrl: '',
      jobRoles: [],
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Employeeshiftview(
          job: job,
          shiftId: shift['ShiftId'],
          employeeId: employeeId!,
          scheduledStartTime: shift['StartTime'],
          scheduledEndTime: shift['EndTime'],
          imagePickerService: RealImagePickerService(),
          locationService: RealLocationService(),
        ),
      ),
    );
  }

//   void onQueryChanged(String query) {
//     setState(() {
//       if (query.isEmpty) {
//         filteredJobs = List.from(allJobs);
//       } else {
//         filteredJobs = allJobs.where((job) {
//           return job.title.toLowerCase().contains(query.toLowerCase());
//         }).toList();
//       }
//     });
//   }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: Background()),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF724584)),
                )
              : Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        key: _refreshKey,
                        onRefresh: _refreshData,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                            Responsive.isDesktop(context)
                                ? 100
                                : (Responsive.isTablet(context) ? 40 : 20),
                            10,
                            Responsive.isDesktop(context)
                                ? 100
                                : (Responsive.isTablet(context) ? 40 : 20),
                            0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
//                               Search(onQueryChanged: onQueryChanged),
//                               const SizedBox(height: 10),
                              jobListCard(),
                              const SizedBox(height: 20),
                              upcomingJobCard(),
                              const SizedBox(height: 80),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget jobListCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromARGB(180, 42, 50, 67),
            Color.fromARGB(180, 34, 40, 52),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "TODAY'S SCHEDULED SHIFTS",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          // Group jobs by JobId to avoid duplicates
          if (jobs.isEmpty)
            const Center(
              child: Text(
                "No shifts scheduled for today.",
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            ...jobs
                .fold<Map<int, Map<String, dynamic>>>({}, (map, job) {
                  map[job['JobId']] = job;
                  return map;
                })
                .values
                .map((job) => upcomingJobItem(job)),
        ],
      ),
    );
  }

  Widget expandableJobCard(Map<String, dynamic> job) {
    final jobId = job['JobId'];
    final isExpanded = expandedJobs[jobId] ?? false;
    final shifts = jobShifts[jobId] ?? [];
    final status = job['Status'] ?? 'Pending';
    final estimatedTime = job['TotalEstimatedTime'] ?? 0;

    IconData statusIcon;
    Color statusColor;

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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Color(0xFF1C2230),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Main job card
          InkWell(
            onTap: () {
              setState(() {
                expandedJobs[jobId] = !isExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.checklist_rtl,
                    color: Color(0xFF3498DB),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job['Title'] ?? 'No Title',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Estimated Time: $estimatedTime Hrs",
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${shifts.length} shift${shifts.length != 1 ? 's' : ''} available",
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    children: [
                      Text(
                        status,
                        style: TextStyle(color: statusColor, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Icon(statusIcon, color: statusColor, size: 28),
                      const SizedBox(height: 8),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Expanded shifts list
          if (isExpanded)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.fromARGB(180, 53, 63, 84),
                      Color.fromARGB(180, 34, 40, 52),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Column(
                  children: shifts.map((shift) => shiftItem(shift)).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget shiftItem(Map<String, dynamic> shiftData) {
    final shift = shiftData['Shift'];
    // final shiftStart = shiftData['ShiftStart'] as DateTime;
    final startTime = shift['StartTime'] ?? '';
    final endTime = shift['EndTime'] ?? '';
    // final location = shift['Location'] ?? 'No location';
    // final date = DateTime.parse(shift['Date']);

    return InkWell(
      onTap: () => _navigateToShiftView(shiftData),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.white12, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF3498DB).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Image.asset("assets/cShift.png",
                  width: 28, height: 28, fit: BoxFit.contain),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shift['TaskName'] ?? 'No Title',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$startTime - $endTime',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white38,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text("$label: ", style: const TextStyle(color: Colors.white70)),
          Expanded(
              child: Text(value, style: const TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  Widget upcomingJobCard() {
    if (upcomingJobs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            "No upcoming shifts scheduled.",
            style: TextStyle(
              color: Colors.white60,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromARGB(180, 42, 50, 67),
            Color.fromARGB(180, 34, 40, 52),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text(
                "UPCOMING SHIFTS",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
              Spacer(),
              Icon(Icons.notifications_active, color: Color(0xFF00C8FF)),
            ],
          ),
          const SizedBox(height: 20),
          ...upcomingJobs.map((job) => upcomingJobItem(job)),
        ],
      ),
    );
  }

  Widget upcomingJobItem(Map<String, dynamic> job) {
    final shift = job['Shift'];
    final taskName = shift['ShiftName'] ??
        shift['TaskName'] ??
        job['Title'] ??
        "Unnamed Shift";
    final location = shift['Location'] ?? "No location";
    final startTime = shift['StartTime'] ?? "TBD";
    final shiftStart = job['ShiftStart'];
    final date = shiftStart is DateTime
        ? DateFormat('dd MMM yyyy').format(shiftStart.toLocal())
        : "TBD";
    final endTime = shift['EndTime'] ?? "TBD";
    final status = shift['Status'] ?? "Scheduled";

    return InkWell(
      onTap: () => _navigateToShiftView(job),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C2230),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.event_available,
                  color: Color(0xFF00C8FF),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        taskName,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      shiftInfoRowInline("Date", date),
                      shiftInfoRowInline("Location", location),
                      shiftInfoRowInline("Start Time", startTime),
                      shiftInfoRowInline("End Time", endTime),
                      shiftInfoRowInline("Status", status),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white38,
                  size: 16,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget shiftInfoRowInline(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              "$label:",
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}

// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:shiftsmart/models/shift.dart';
// import 'package:shiftsmart/models/job.dart';
// import 'package:shiftsmart/screens/employee/employee_shift_view.dart';
// import 'package:shiftsmart/services/image_picker_service.dart';
// import 'package:shiftsmart/services/job_service.dart';
// import 'package:shiftsmart/services/location_service.dart';
// import 'package:shiftsmart/services/shift_service.dart';
// import 'package:shiftsmart/utils/fullscreen_helper.dart';
// import 'package:shiftsmart/widgets/background.dart';
// import 'package:shiftsmart/responsive.dart';
// import 'package:shiftsmart/widgets/search.dart';

// class Employeedashboard extends StatefulWidget {
//   const Employeedashboard({super.key});

//   @override
//   State<Employeedashboard> createState() => _EmployeedashboardState();
// }

// class _EmployeedashboardState extends State<Employeedashboard> {
//   final GlobalKey<RefreshIndicatorState> _refreshKey =
//       GlobalKey<RefreshIndicatorState>();

//   File? selectedFile;
//   String? fileName;
//   List<Job> allJobs = [];
//   List<Job> filteredJobs = [];

//   int? employeeId;
//   Map<int, String> uploadedFiles = {};
//   Shift? currentShift;
//   bool _isLoading = true;
//   List<Map<String, dynamic>> jobs = []; // today's jobs
//   Map<String, dynamic>? upcomingJob; // only one upcoming job

//   Map<int, bool> expandedJobs = {}; // tracking expanded job
//   Map<int, List<Map<String, dynamic>>> jobShifts =
//       {}; // Store all shifts grouped by job ID

//   @override
//   void initState() {
//     super.initState();
//     enableFullScreen();
//     _loadEmployeeId().then((_) {
//       if (employeeId != null) {
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           _refreshKey.currentState?.show(); // optional spinner
//           _refreshData();
//         });
//       }
//     });
//   }

//   Future<void> _refreshData() async {
//     if (!mounted) return;
//     setState(() => _isLoading = true);
//     await fetchJobs();
//     if (!mounted) return;
//     setState(() => _isLoading = false);
//   }

//   Future<void> _loadEmployeeId() async {
//     final prefs = await SharedPreferences.getInstance();
//     final id = prefs.getInt('employeeId');

//     setState(() {
//       employeeId = id;
//     });

//     if (id == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//             content: Text("Error: employeeId not set. Please login again.")),
//       );
//     }
//   }

//   Future<void> fetchJobs() async {
//     final jobService = JobService();
//     final shiftService = ShiftService();

//     if (employeeId == null) return;

//     try {
//       // 1. Fetch Jobs
//       final jobsData = await jobService.fetchAllJobs();

//       // 2. Fetch Shifts (FIX: Use the new method that works for Employees)
//       // OLD: final shiftsData = await shiftService.fetchAllRawShifts(); // Caused 403
//       final List<Shift> shiftsList =
//           await shiftService.fetchShiftsByEmployeeId(employeeId!);

//       final now = DateTime.now();
//       final today = DateTime(now.year, now.month, now.day);

//       // 3. Convert List<Shift> to Maps to keep your existing logic working
//       // Note: We don't need to filter by employeeId here because the API already did it!
//       final employeeShifts = shiftsList.map((s) => s.toJson()).toList();

//       final jobMap = {for (var job in jobsData) job.jobId: job};

//       List<Map<String, dynamic>> upcomingJobs = [];
//       List<Map<String, dynamic>> todayJobs = [];
//       Map<int, List<Map<String, dynamic>>> tempJobShifts = {};

//       for (var shift in employeeShifts) {
//         try {
//           // Check if your Shift model returns 'Date' or 'date' (adjust case if needed)
//           final shiftDateStr = shift['Date'] ?? shift['date'];
//           final shiftStartTimeStr = shift['StartTime'] ?? shift['startTime'];
//           final shiftJobId = shift['JobId'] ?? shift['jobId'];

//           if (shiftDateStr == null || shiftStartTimeStr == null) continue;

//           final shiftDate = DateTime.parse(shiftDateStr);
//           // Fix logic to handle Time format correctly
//           final shiftStart = DateTime.parse(
//               "${shiftDateStr.split("T")[0]} $shiftStartTimeStr");

//           final job = jobMap[shiftJobId];
//           if (job == null) continue;

//           final fullJob = {
//             ...job.toJson(),
//             'Shift': shift,
//             'ShiftStart': shiftStart,
//           };

//           // Only show shifts scheduled for today
//           if (shiftDate.year == today.year &&
//               shiftDate.month == today.month &&
//               shiftDate.day == today.day) {
//             todayJobs.add(fullJob);

//             tempJobShifts.putIfAbsent(shiftJobId, () => []);
//             tempJobShifts[shiftJobId]!.add(fullJob);
//           }

//           // For upcomingJob only
//           if (shiftStart.isAfter(now)) {
//             upcomingJobs.add(fullJob);
//           }
//         } catch (e) {
//           debugPrint("Error processing shift: $e");
//         }
//       }

//       upcomingJobs.sort((a, b) => a['ShiftStart'].compareTo(b['ShiftStart']));
//       todayJobs.sort((a, b) => a['ShiftStart'].compareTo(b['ShiftStart']));
//       for (var jobId in tempJobShifts.keys) {
//         tempJobShifts[jobId]!
//             .sort((a, b) => a['ShiftStart'].compareTo(b['ShiftStart']));
//       }

//       setState(() {
//         jobs = todayJobs;
//         jobShifts = tempJobShifts;
//         upcomingJob = upcomingJobs.isNotEmpty ? upcomingJobs.first : null;
//       });
//     } catch (e) {
//       debugPrint("Error fetching dashboard data: $e");
//     }
//   }

//   void _navigateToShiftView(Map<String, dynamic> shiftData) {
//     final job = Job(
//       jobId: shiftData['JobId'],
//       title: shiftData['Title'] ?? 'No Title',
//       description: shiftData['Description'] ?? 'No Description',
//       siteId: shiftData['SiteId'] ?? 0,
//       startDate: '',
//       jobDueDate: '',
//       status: '',
//       projectId: shiftData['ProjectId'],
//       totalEstimatedTime: shiftData['TotalEstimatedTime'],
//       jobImageUrl: '',
//       jobRoles: [],
//     );

//     final shift = shiftData['Shift'];

//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => Employeeshiftview(
//           job: job,
//           shiftId: shift['ShiftId'],
//           employeeId: employeeId!,
//           scheduledStartTime: shift['StartTime'],
//           scheduledEndTime: shift['EndTime'],
//           imagePickerService: RealImagePickerService(),
//           locationService: RealLocationService(),
//         ),
//       ),
//     );
//   }

//   void onQueryChanged(String query) {
//     setState(() {
//       if (query.isEmpty) {
//         filteredJobs = List.from(allJobs);
//       } else {
//         filteredJobs = allJobs.where((job) {
//           return job.title.toLowerCase().contains(query.toLowerCase());
//         }).toList();
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           Background(),
//           _isLoading
//               ? const Center(
//                   child: CircularProgressIndicator(color: Color(0xFF724584)),
//                 )
//               : Column(
//                   children: [
//                     Expanded(
//                       child: RefreshIndicator(
//                         key: _refreshKey,
//                         onRefresh: _refreshData,
//                         child: SingleChildScrollView(
//                           physics: const AlwaysScrollableScrollPhysics(),
//                           padding: EdgeInsets.fromLTRB(
//                             Responsive.isDesktop(context)
//                                 ? 100
//                                 : (Responsive.isTablet(context) ? 40 : 20),
//                             10,
//                             Responsive.isDesktop(context)
//                                 ? 100
//                                 : (Responsive.isTablet(context) ? 40 : 20),
//                             0,
//                           ),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Search(onQueryChanged: onQueryChanged),
//                               const SizedBox(height: 10),
//                               upcomingJobCard(),
//                               const SizedBox(height: 20),
//                               jobListCard(),
//                               const SizedBox(height: 80),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//         ],
//       ),
//     );
//   }

//   Widget jobListCard() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//           colors: [
//             Color.fromARGB(180, 42, 50, 67),
//             Color.fromARGB(180, 34, 40, 52),
//           ],
//         ),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             "TODAY'S SCHEDULED JOBS",
//             style: TextStyle(
//               color: Colors.white,
//               fontWeight: FontWeight.bold,
//               fontSize: 18,
//             ),
//           ),
//           const SizedBox(height: 16),
//           // Group jobs by JobId to avoid duplicates
//           if (jobs.isEmpty)
//             const Center(
//               child: Padding(
//                 padding: EdgeInsets.symmetric(vertical: 16.0),
//                 child: Text(
//                   "No jobs scheduled for today.",
//                   style: TextStyle(color: Colors.white60, fontSize: 14),
//                 ),
//               ),
//             )
//           else
//             ...jobs
//                 .fold<Map<int, Map<String, dynamic>>>({}, (map, job) {
//                   map[job['JobId']] = job;
//                   return map;
//                 })
//                 .values
//                 .map((job) => expandableJobCard(job)),
//         ],
//       ),
//     );
//   }

//   Widget expandableJobCard(Map<String, dynamic> job) {
//     final jobId = job['JobId'];
//     final isExpanded = expandedJobs[jobId] ?? false;
//     final shifts = jobShifts[jobId] ?? [];
//     final status = job['Status'] ?? 'Pending';
//     final estimatedTime = job['TotalEstimatedTime'] ?? 0;

//     IconData statusIcon;
//     Color statusColor;

//     switch (status.toLowerCase()) {
//       case 'active':
//         statusIcon = Icons.donut_large_sharp;
//         statusColor = Colors.amberAccent;
//         break;
//       case 'pending':
//         statusIcon = Icons.hourglass_top;
//         statusColor = Colors.red;
//         break;
//       case 'completed':
//       case 'done':
//         statusIcon = Icons.domain_verification_outlined;
//         statusColor = Colors.greenAccent;
//         break;
//       default:
//         statusIcon = Icons.info_outline;
//         statusColor = Colors.grey;
//     }

//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       decoration: BoxDecoration(
//         color: Color(0xFF1C2230),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Column(
//         children: [
//           // Main job card
//           InkWell(
//             onTap: () {
//               setState(() {
//                 expandedJobs[jobId] = !isExpanded;
//               });
//             },
//             child: Container(
//               padding: const EdgeInsets.all(16),
//               child: Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Icon(
//                     Icons.checklist_rtl,
//                     color: Color(0xFF3498DB),
//                     size: 24,
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           job['Title'] ?? 'No Title',
//                           overflow: TextOverflow.ellipsis,
//                           maxLines: 2,
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                             fontSize: 16,
//                           ),
//                         ),
//                         const SizedBox(height: 6),
//                         Text(
//                           "Estimated Time: $estimatedTime Hrs",
//                           style: const TextStyle(
//                               color: Colors.white60, fontSize: 14),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           "${shifts.length} shift${shifts.length != 1 ? 's' : ''} available",
//                           style: const TextStyle(
//                               color: Colors.white38, fontSize: 12),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Column(
//                     children: [
//                       Text(
//                         status,
//                         style: TextStyle(color: statusColor, fontSize: 12),
//                       ),
//                       const SizedBox(height: 4),
//                       Icon(statusIcon, color: statusColor, size: 28),
//                       const SizedBox(height: 8),
//                       Icon(
//                         isExpanded
//                             ? Icons.keyboard_arrow_up
//                             : Icons.keyboard_arrow_down,
//                         color: Colors.white70,
//                         size: 20,
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           // Expanded shifts list
//           if (isExpanded)
//             AnimatedContainer(
//               duration: const Duration(milliseconds: 300),
//               child: Container(
//                 decoration: const BoxDecoration(
//                   gradient: LinearGradient(
//                     colors: [
//                       Color.fromARGB(180, 53, 63, 84),
//                       Color.fromARGB(180, 34, 40, 52),
//                     ],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                   borderRadius: BorderRadius.only(
//                     bottomLeft: Radius.circular(12),
//                     bottomRight: Radius.circular(12),
//                   ),
//                 ),
//                 child: Column(
//                   children: shifts.map((shift) => shiftItem(shift)).toList(),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget shiftItem(Map<String, dynamic> shiftData) {
//     final shift = shiftData['Shift'];
//     // final shiftStart = shiftData['ShiftStart'] as DateTime;
//     final startTime = shift['StartTime'] ?? '';
//     final endTime = shift['EndTime'] ?? '';
//     // final location = shift['Location'] ?? 'No location';
//     // final date = DateTime.parse(shift['Date']);

//     return InkWell(
//       onTap: () => _navigateToShiftView(shiftData),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//         decoration: const BoxDecoration(
//           border: Border(
//             top: BorderSide(color: Colors.white12, width: 0.5),
//           ),
//         ),
//         child: Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(4),
//               decoration: BoxDecoration(
//                 color: const Color(0xFF3498DB).withValues(alpha: 0.2),
//                 borderRadius: BorderRadius.circular(6),
//               ),
//               child: Image.asset("assets/cShift.png",
//                   width: 28, height: 28, fit: BoxFit.contain),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     shift['TaskName'] ?? 'No Title',
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontWeight: FontWeight.w500,
//                       fontSize: 14,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     '$startTime - $endTime',
//                     style: const TextStyle(color: Colors.white70, fontSize: 12),
//                   ),
//                 ],
//               ),
//             ),
//             const Icon(
//               Icons.arrow_forward_ios,
//               color: Colors.white38,
//               size: 16,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget infoRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 2),
//       child: Row(
//         children: [
//           Text("$label: ", style: const TextStyle(color: Colors.white70)),
//           Expanded(
//               child: Text(value, style: const TextStyle(color: Colors.white))),
//         ],
//       ),
//     );
//   }

//   Widget upcomingJobCard() {
//     if (upcomingJob == null) {
//       return Container(
//         width: double.infinity,
//         padding: const EdgeInsets.all(20),
//         decoration: BoxDecoration(
//           color: Colors.black26,
//           borderRadius: BorderRadius.circular(12),
//         ),
//         child: Center(
//           child: const Text("No upcoming job scheduled.",
//               style: TextStyle(color: Colors.white70)),
//         ),
//       );
//     }

//     final shift = upcomingJob!['Shift'];
//     final taskName = upcomingJob!['Title'] ?? "Unnamed Job";
//     final location = shift['Location'] ?? "No location";
//     final startTime = shift['StartTime'] ?? "TBD";

//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//           colors: [
//             Color.fromARGB(180, 42, 50, 67),
//             Color.fromARGB(180, 34, 40, 52),
//           ],
//         ),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: const [
//               Text(
//                 "UPCOMING JOB",
//                 style: TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 18),
//               ),
//               Spacer(),
//               Icon(Icons.notifications_active, color: Color(0xFF00C8FF)),
//             ],
//           ),
//           const SizedBox(height: 20),
//           shiftInfoRowInline("Name", taskName),
//           shiftInfoRowInline("Location", location),
//           shiftInfoRowInline("Start Time", startTime),
//         ],
//       ),
//     );
//   }

//   Widget shiftInfoRowInline(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 80,
//             child: Text(
//               "$label:",
//               style: const TextStyle(
//                 color: Colors.white70,
//                 fontWeight: FontWeight.w500,
//                 fontSize: 14,
//               ),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontWeight: FontWeight.w600,
//                 fontSize: 14,
//               ),
//               overflow: TextOverflow.ellipsis,
//               maxLines: 2,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
