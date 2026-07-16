import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftsmart/services/leave_service.dart';
import 'package:shiftsmart/services/notification_service.dart';
import 'package:shiftsmart/widgets/custom_date_picker.dart';
import 'package:shiftsmart/utils/fullscreen_helper.dart';
import 'package:shiftsmart/widgets/background.dart';

class Employeeleavecreate extends StatefulWidget {
  final List<Map<String, dynamic>> leaveRequests;

  const Employeeleavecreate({super.key, required this.leaveRequests});

  @override
  State<Employeeleavecreate> createState() => _EmployeeleavecreateState();
}

class _EmployeeleavecreateState extends State<Employeeleavecreate> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  String? _selectedLeaveType = 'Sick';

  @override
  void initState() {
    super.initState();
    enableFullScreen();
  }

  // Method to handle the leave request submission
  Future<void> _submitLeaveRequest() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final prefs = await SharedPreferences.getInstance();
    final employeeId = prefs.getInt('employeeId');

    if (employeeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Employee ID not found!')),
      );
      return;
    }

    final leaveRequestData = {
      "employeeId": employeeId,
      "leaveType": _selectedLeaveType,
      "startDate": _startDateController.text,
      "endDate": _endDateController.text,
      "reason": _reasonController.text.trim(),
    };

    // Fetch existing leave requests
    final existingLeaveRequests = widget.leaveRequests;

    // Check for overlapping dates with existing leave requests
    final newStartDate = DateTime.parse(_startDateController.text);
    final newEndDate = DateTime.parse(_endDateController.text);

    for (var leave in existingLeaveRequests) {
      final existingStartDate = leave['StartDate'] is String
          ? DateTime.parse(leave['StartDate'])
          : leave['StartDate'] as DateTime;
      final existingEndDate = leave['EndDate'] is String
          ? DateTime.parse(leave['EndDate'])
          : leave['EndDate'] as DateTime;

      final isOverlapping = !(newEndDate.isBefore(existingStartDate) ||
          newStartDate.isAfter(existingEndDate));

      final isNotRejected = leave['Status'].toLowerCase() != 'rejected';

      if (isOverlapping && isNotRejected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Your leave period overlaps with an existing leave request.'),
          ),
        );
        return;
      }
    }

    try {
      final success = await LeaveService().addLeaveRequest(leaveRequestData);

      if (success && _selectedLeaveType != null) {
        await NotificationService().sendLeaveRequeststoManager(
          employeeId,
          _selectedLeaveType,
          _startDateController.text,
          _endDateController.text,
          _reasonController.text.trim(),
        );

        // Clear fields
        _startDateController.clear();
        _endDateController.clear();
        _reasonController.clear();
        setState(() {
          _selectedLeaveType = null;
        });

        //  IMPORTANT CHANGE:
        // Pass 'true' back to the previous screen to trigger the Success Dialog
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit leave request')),
        );
      }
    } catch (e) {
      print("Submit error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error occurred: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        const Positioned.fill(child: Background()),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            padding: const EdgeInsets.all(16),
            constraints: BoxConstraints(
              maxHeight: screenHeight * 0.9,
              maxWidth: 500,
            ),
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
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  _headerSection(),
                  const SizedBox(height: 10),
                  _formSection(),
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

  Widget _headerSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 24,
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                "Apply for Leave",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
          Image.asset(
            'assets/Leave.png',
            color: const Color(0xFF3498DB),
            width: 30,
            height: 30,
          ),
        ],
      ),
    );
  }

  Widget _formSection() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _selectedLeaveType,
            style: const TextStyle(color: Color.fromARGB(255, 182, 182, 182)),
            dropdownColor: Colors.black,
            decoration: _inputDecoration("Leave Type"),
            onChanged: (value) {
              setState(() {
                _selectedLeaveType = value;
              });
            },
            items: ['Sick', 'Casual', 'Annual'].map((leaveType) {
              return DropdownMenuItem<String>(
                value: leaveType,
                child: Text(leaveType),
              );
            }).toList(),
            validator: (value) =>
                value == null ? 'Please select leave type' : null,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _startDateController,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration("Start Date"),
            validator: (value) =>
                value?.isEmpty ?? true ? 'Please enter start date' : null,
            onTap: () async {
              DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                  builder: datePickerThemeBuilder);
              if (picked != null) {
                final formattedDate = DateFormat('yyyy-MM-dd').format(picked);
                _startDateController.text = formattedDate;
              }
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _endDateController,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration("End Date"),
            validator: (value) =>
                value?.isEmpty ?? true ? 'Please enter end date' : null,
            onTap: () async {
              DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                  builder: datePickerThemeBuilder);
              if (picked != null) {
                final formattedDate = DateFormat('yyyy-MM-dd').format(picked);
                _endDateController.text = formattedDate;
              }
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _reasonController,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration("Reason"),
            validator: (value) =>
                value?.isEmpty ?? true ? 'Please enter reason' : null,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: _submitLeaveRequest,
                style: _elevatedStyle(),
                child: const Text(
                  'Apply',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color.fromARGB(245, 255, 255, 255)),
        filled: true,
        fillColor: Colors.white12,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.blue),
        ),
      );

  ButtonStyle _elevatedStyle() => ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      );
}
