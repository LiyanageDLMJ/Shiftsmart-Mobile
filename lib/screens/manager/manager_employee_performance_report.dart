// lib/screens/manager/ManagerEmployeePerformanceReport.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shiftsmart/models/employee.dart';
// import 'package:shiftsmart/models/report_employee.dart'; // This import is removed
import 'package:shiftsmart/screens/manager/manager_employee_performance_view_weekly_report.dart';
import 'package:shiftsmart/services/employee_service.dart';
import 'package:shiftsmart/services/performance_report_service.dart';
import 'package:shiftsmart/utils/fullscreen_helper.dart';
import 'package:shiftsmart/widgets/background.dart';
import 'package:shiftsmart/widgets/search.dart';
import 'package:shiftsmart/widgets/sidenav.dart';
import 'package:shiftsmart/widgets/uppernavbar.dart';

class ManagerEmployeePerformanceReport extends StatefulWidget {
  const ManagerEmployeePerformanceReport({super.key});

  @override
  State<ManagerEmployeePerformanceReport> createState() =>
      _ManagerEmployeePerformanceReportState();
}

class _ManagerEmployeePerformanceReportState
    extends State<ManagerEmployeePerformanceReport> {
  List<Employee> allEmployees = [];
  List<Employee> filteredEmployees = [];
  bool _isLoading = true;
  bool _isGeneratingReport = false;

  @override
  void initState() {
    super.initState();
    enableFullScreen();
    fetchEmployee();
  }

  Future<void> fetchEmployee() async {
    try {
      final employees = await EmployeeService().fetchAllEmployees();
      setState(() {
        allEmployees = employees;
        filteredEmployees = List.from(employees);
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching employee: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void onQueryChanged(String query) {
    setState(() {
      filteredEmployees = query.isEmpty
          ? List.from(allEmployees)
          : allEmployees
              .where((emp) =>
                  emp.firstName.toLowerCase().contains(query.toLowerCase()) ||
                  (emp.lastName ?? '')
                      .toLowerCase()
                      .contains(query.toLowerCase()))
              .toList();
    });
  }

  // UPDATED: Dialog now only shows Custom Date Report
  void _showReportOptionsDialog(Employee employee) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A3243),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Generate Report for ${employee.firstName}'),
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          contentPadding: const EdgeInsets.all(20.0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- REMOVED OVERALL REPORT OPTION ---
              // _buildOptionTile(
              //   icon: Icons.bar_chart,
              //   title: 'Overall Report',
              //   subtitle: 'A summary of all-time performance.',
              //   onTap: () {
              //     Navigator.pop(context);
              //     _generateOverallReport(employeeId: employee.employeeId);
              //   },
              // ),
              // const SizedBox(height: 12),
              // --- END OF REMOVAL ---

              // Option 2: Custom Date Report (This remains)
              _buildOptionTile(
                icon: Icons.calendar_today,
                title: 'Custom Date Report',
                subtitle: 'Select a specific date range.',
                onTap: () {
                  Navigator.pop(context); // Close the options dialog
                  _showDateRangePickerDialog(employee);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  // This helper widget is unchanged
  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }

  void _showDateRangePickerDialog(Employee employee) {
    // ... (This function is unchanged)
    final TextEditingController startDateController = TextEditingController();
    final TextEditingController endDateController = TextEditingController();
    String? dateRangeError;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2A3243),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text('Select Date Range'),
              titleTextStyle: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: startDateController,
                    readOnly: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Start Date',
                      labelStyle: const TextStyle(color: Colors.white70),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today,
                            color: Colors.white70),
                        onPressed: () async {
                          await _selectDate(context, startDateController);
                          setDialogState(() => dateRangeError = null);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: endDateController,
                    readOnly: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'End Date',
                      labelStyle: const TextStyle(color: Colors.white70),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today,
                            color: Colors.white70),
                        onPressed: () async {
                          await _selectDate(context, endDateController);
                          setDialogState(() => dateRangeError = null);
                        },
                      ),
                    ),
                  ),
                  if (dateRangeError != null) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        dateRangeError!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.white)),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  child: const Text('Generate'),
                  onPressed: () {
                    if (startDateController.text.isEmpty ||
                        endDateController.text.isEmpty) {
                      setDialogState(() {
                        dateRangeError =
                            "Please select both start and end dates.";
                      });
                      return;
                    }

                    final startDate = DateFormat('yyyy-MM-dd')
                        .parseStrict(startDateController.text);
                    final endDate = DateFormat('yyyy-MM-dd')
                        .parseStrict(endDateController.text);

                    if (endDate.isBefore(startDate)) {
                      setDialogState(() {
                        dateRangeError =
                            "End Date cannot be earlier than Start Date.";
                      });
                      return;
                    }

                    Navigator.pop(context); // Close the dialog
                    _generateDateRangeReport(
                      employeeId: employee.employeeId,
                      startDate: startDateController.text,
                      endDate: endDateController.text,
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    // ... (This function is unchanged)
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(pickedDate);
    }
  }

  // --- REMOVED OVERALL REPORT GENERATION FUNCTION ---
  // Future<void> _generateOverallReport({required int employeeId}) async {
  //   ...
  // }
  // --- END OF REMOVAL ---

  // UPDATED: This function now calls the correct service method
  Future<void> _generateDateRangeReport({
    required int employeeId,
    required String startDate,
    required String endDate,
  }) async {
    setState(() => _isGeneratingReport = true);
    try {
      // --- THIS IS THE FIX ---
      // Call the correct function from the service
      final report = await PerformanceReportService().generateDateRangeReport(
        employeeId: employeeId,
        startDate: startDate,
        endDate: endDate,
      );
      // --- END OF FIX ---

      Navigator.push(
        context,
        MaterialPageRoute(
          // Still navigate to the same WeeklyReport view screen
          builder: (context) => ManagerEmployeePerformanceViewWeeklyReport(
            data: report,
            allEmployees: allEmployees,
          ),
        ),
      );
    } catch (e) {
      // Use the new helper function
      _showSnackBar("Error fetching date range report: ${e.toString()}");
    } finally {
      setState(() => _isGeneratingReport = false);
    }
  }

  // NEW: Added helper function
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    // ... (This function is unchanged)
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFF1C2230),
      appBar: const Uppernavbar(showBackButton: true),
      drawer: const Sidenav(),
      body: Stack(
        children: [
          const Positioned(child: Background()),
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 15),
                      Search(onQueryChanged: onQueryChanged),
                      const SizedBox(height: 10),
                      const Text(
                        "Generate Employee Performance Report",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _employeeList(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_isGeneratingReport)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text("Generating Report...",
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _employeeList() {
    // ... (This function is unchanged)
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredEmployees.length,
      itemBuilder: (context, index) {
        final employee = filteredEmployees[index];
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.person, color: Color(0xFF3498DB), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${employee.firstName} ${employee.lastName ?? ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      employee.employmentStatus ?? 'Employee',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => _showReportOptionsDialog(employee),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: Color.fromARGB(255, 19, 129, 180),
                      size: 20,
                    ),
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}
