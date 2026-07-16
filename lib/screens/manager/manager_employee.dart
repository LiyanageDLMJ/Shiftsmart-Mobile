import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shiftsmart/providers/tenant_provider.dart';
import 'package:shiftsmart/models/employee.dart';
import 'package:shiftsmart/screens/manager/manager_view_employee.dart';
import 'package:shiftsmart/services/employee_service.dart';
import 'package:shiftsmart/utils/fullscreen_helper.dart';
import 'package:shiftsmart/widgets/background.dart';
import 'package:shiftsmart/widgets/premium_feature_gate.dart';
import 'package:shiftsmart/widgets/bottomnavbar.dart';

class Manageremployee extends StatefulWidget {
  const Manageremployee({super.key});

  @override
  State<Manageremployee> createState() => _ManageremployeeState();
}

class _ManageremployeeState extends State<Manageremployee> {
  List<Employee> allEmployees = [];
  List<Employee> filteredEmployees = [];

  bool _isLoading = true;
  String _lastTenant = '';

  @override
  void initState() {
    super.initState();
    enableFullScreen();
    fetchEmployee();
  }

  void onQueryChanged(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      filteredEmployees = query.isEmpty
          ? List.from(allEmployees)
          : allEmployees
              .where((emp) => [
                    _employeeName(emp),
                    emp.email,
                    emp.mobileNumber,
                    emp.jobRole,
                    emp.userRole,
                    emp.employmentStatus,
                  ].any((value) =>
                      value?.toLowerCase().contains(lowerQuery) ?? false))
              .toList();
    });
  }

  Future<void> fetchEmployee() async {
    try {
      final employees = await EmployeeService().fetchAllEmployees();
      debugPrint("Employees only: $employees");
      setState(() {
        allEmployees = employees;
        filteredEmployees = List.from(employees);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching employee: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TenantProvider>(
      builder: (context, tp, _) {
        if (tp.selectedOrganization != _lastTenant) {
          _lastTenant = tp.selectedOrganization;
          if (_lastTenant.isNotEmpty && mounted && !_isLoading) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              fetchEmployee();
            });
          }
        }

        if (!tp.isFeatureEnabled('employee_management') ||
            tp.isNavIndexBlocked(3)) {
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
                        featureName: 'Employee Management',
                        blockedEndpoint: '/api/employee/list',
                        customMessage:
                            'Contact your administrator to enable this module for your tenant.',
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

        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: Stack(children: [
            const Positioned.fill(child: Background()),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _employeeSearchSection(),
                    const SizedBox(height: 10),
                    Expanded(child: _employeeList()),
                  ],
                ),
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget _employeeSearchSection() {
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
            'EMPLOYEE LIST',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            onChanged: onQueryChanged,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search',
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

  Widget _employeeList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView.builder(
      itemCount: filteredEmployees.length,
      itemBuilder: (context, index) {
        final employee = filteredEmployees[index];

        return _employeeCard(employee);
      },
    );
  }

  Widget _employeeCard(Employee employee) {
    final status = _displayValue(employee.employmentStatus, 'Unknown');
    final statusColor = _statusColor(status);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _openEmployee(employee),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2433),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _employeeAvatar(employee),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          _employeeName(employee),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _roleBadge(_displayValue(employee.userRole, 'Employee')),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _detailText(
                          _displayValue(employee.jobRole, 'No job role')),
                      _statusBadge(status, statusColor),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.chevron_right, color: Color(0xFF3498DB), size: 24),
          ],
        ),
      ),
    );
  }

  Widget _employeeAvatar(Employee employee) {
    final imageProvider = _profileImageProvider(employee.profilePicture);

    return CircleAvatar(
      radius: 24,
      backgroundColor: const Color(0xFF263145),
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? const Icon(Icons.person, color: Color(0xFF58A6FF), size: 28)
          : null,
    );
  }

  Widget _roleBadge(String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF315FA8).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF4E86DF)),
      ),
      child: Text(
        role,
        style: const TextStyle(
          color: Color(0xFF8CB7FF),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _statusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _detailText(String text) {
    return Text(
      text,
      softWrap: true,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 13,
        height: 1.25,
      ),
    );
  }

  void _openEmployee(Employee employee) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Managerviewemployee(employee: employee),
      ),
    );
  }

  String _employeeName(Employee employee) {
    final parts = [
      employee.firstName,
      employee.middleName,
      employee.lastName,
    ].where((part) => part != null && part.trim().isNotEmpty);
    final name = parts.join(' ');
    return name.isEmpty ? 'Unknown Employee' : name;
  }

  String _displayValue(String? value, String fallback) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? fallback : trimmed;
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return const Color(0xFF8CE99A);
      case 'pending':
        return const Color(0xFFFFD43B);
      case 'inactive':
        return Colors.white54;
      default:
        return Colors.blueAccent;
    }
  }

  ImageProvider? _profileImageProvider(String? profilePicture) {
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
}

class NextOfKin {
  final String fullName;
  final String relationship;
  final String mobileNumber;

  NextOfKin({
    required this.fullName,
    required this.relationship,
    required this.mobileNumber,
  });

  factory NextOfKin.fromJson(Map<String, dynamic> json) {
    return NextOfKin(
      fullName: json['fullName'] ?? 'Unknown',
      relationship: json['relationship'] ?? 'Unknown',
      mobileNumber: json['mobileNumber'] ?? 'xxx-xxx-xxxx',
    );
  }
}
