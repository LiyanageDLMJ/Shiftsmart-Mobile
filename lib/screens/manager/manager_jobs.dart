import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shiftsmart/providers/tenant_provider.dart';
import 'package:shiftsmart/models/employee.dart';
import 'package:shiftsmart/models/job.dart';
import 'package:shiftsmart/models/shift.dart';
import 'package:shiftsmart/screens/manager/manager_create_job.dart';
import 'package:shiftsmart/screens/manager/manager_create_shift.dart';
import 'package:shiftsmart/screens/manager/manager_job_view.dart';
import 'package:shiftsmart/screens/manager/manager_shifts_view.dart';
import 'package:shiftsmart/screens/manager/manager_view_employee.dart';
import 'package:shiftsmart/services/employee_service.dart';
import 'package:shiftsmart/services/job_service.dart';
import 'package:shiftsmart/services/shift_service.dart';
import 'package:shiftsmart/services/project_service.dart';
import 'package:shiftsmart/utils/fullscreen_helper.dart';
import 'package:shiftsmart/widgets/background.dart';
import 'package:shiftsmart/widgets/premium_feature_gate.dart';
import 'package:shiftsmart/widgets/bottomnavbar.dart';
import 'package:shiftsmart/models/project.dart' as model;

class Managerjobs extends StatefulWidget {
  final int initialTabIndex;

  const Managerjobs({super.key, this.initialTabIndex = 0});

  @override
  State<Managerjobs> createState() => _ManagerjobsState();
}

class _ManagerjobsState extends State<Managerjobs>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {

  List<Job> allJobs = [];
  List<Job> filteredJobs = [];

  List<Shift> allShifts = [];
  List<Shift> filteredShifts = [];

  bool _isLoading = true;
  Map<int, model.Project> projectMap = {};
  Map<int, Employee> employeeMap = {};
  String _lastTenant = '';
  late final TabController _tabController;
  final TextEditingController _jobSearchController = TextEditingController();
  final TextEditingController _shiftSearchController = TextEditingController();
  String _jobSearchQuery = '';
  String _shiftSearchQuery = '';
  int _currentTabIndex = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    _jobSearchController.dispose();
    _shiftSearchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    enableFullScreen();
    _currentTabIndex = widget.initialTabIndex;
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _tabController.addListener(_handleTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  DateTime? _parseDate(String value) {
    if (value.trim().isEmpty) return null;
    return DateTime.tryParse(value);
  }

  String _formatDisplayDate(String value) {
    final date = _parseDate(value);
    if (date == null) return 'No date';
    return DateFormat('d MMMM yyyy').format(date);
  }

  String _formatShiftDate(DateTime date) {
    return DateFormat('d MMMM yyyy').format(date);
  }

  String _formatShiftTime(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '--:--';

    try {
      return DateFormat('HH:mm').format(DateFormat('HH:mm:ss').parse(trimmed));
    } catch (_) {
      try {
        return DateFormat('HH:mm').format(DateFormat('HH:mm').parse(trimmed));
      } catch (_) {
        return trimmed;
      }
    }
  }

  Future<void> _openJobDetails(Job job) async {
    final result = await _showDetailsPopup(
      child: ManagerJobView(
        job: job,
        embedded: true,
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _openShiftDetails(Shift shift) async {
    final result = await _showDetailsPopup(
      child: ManagerShiftsView(
        shift: shift,
        embedded: true,
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<bool?> _showDetailsPopup({required Widget child}) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.68),
      builder: (dialogContext) {
        final size = MediaQuery.of(dialogContext).size;
        final dialogWidth = size.width - 16;
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: dialogWidth,
              maxHeight: size.height * 0.88,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Scrollbar(
                    child: SingleChildScrollView(
                      child: SizedBox(
                        width: dialogWidth,
                        child: child,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: _buildPopupCloseButton(dialogContext),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPopupCloseButton(BuildContext dialogContext) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Navigator.of(dialogContext).pop(false),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF20283A).withValues(alpha: 0.72),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.24),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.close_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    );
  }

  ({String text, Color backgroundColor, Color textColor})? _dueBadge(Job job) {
    final dueDate = _parseDate(job.jobDueDate);
    if (dueDate == null) return null;

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final dueOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final days = dueOnly.difference(todayOnly).inDays;

    if (days < 0) {
      return (
        text: 'Overdue',
        backgroundColor: const Color(0xFFC0392B),
        textColor: Colors.white,
      );
    }

    return (
      text: days == 0
          ? 'Today'
          : days == 1
              ? '1 day left'
              : '$days days left',
      backgroundColor: const Color(0xFFF1C232),
      textColor: Colors.black,
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'complete':
        return const Color(0xFF7BD88F);
      case 'active':
        return const Color(0xFFF1C232);
      case 'pending':
        return Colors.orangeAccent;
      case 'cancelled':
      case 'canceled':
        return Colors.redAccent;
      default:
        return Colors.blueAccent;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'complete':
        return Icons.check_circle;
      default:
        return Icons.sync;
    }
  }

  ImageProvider? _employeeProfileImage(Employee? employee) {
    final profilePicture = employee?.profilePicture?.trim();
    if (profilePicture == null || profilePicture.isEmpty) return null;

    if (profilePicture.startsWith('data:image')) {
      try {
        return MemoryImage(base64Decode(profilePicture.split(',').last));
      } catch (_) {
        return null;
      }
    }

    return NetworkImage(profilePicture);
  }

  String _employeeInitials(Employee? employee) {
    if (employee == null) return '';

    final firstName = employee.firstName.trim();
    final lastName = employee.lastName?.trim() ?? '';
    final initials = [
      if (firstName.isNotEmpty) firstName[0],
      if (lastName.isNotEmpty) lastName[0],
    ].join();

    return initials.toUpperCase();
  }

  void _openEmployeeProfile(Employee employee) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Managerviewemployee(employee: employee),
      ),
    );
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    await Future.wait([
      _fetchProjects(), // We need projects to filter jobs by tenant
      _fetchShifts(), // Load shifts
      _fetchEmployees(), // Load profiles for assigned shift employees
    ]);

    await _fetchJobs(); // Needs projects loaded first to filter

    setState(() => _isLoading = false);
  }

  Future<void> _fetchProjects() async {
    try {
      final projects = await ProjectService().fetchAllProjects();
      debugPrint(" managerJobs: Fetched ${projects.length} projects to map");
      setState(() {
        projectMap = {for (var p in projects) p.projectId: p};
      });
    } catch (e) {
      debugPrint(" managerJobs: Error loading projects: \$e");
    }
  }

  Future<void> _fetchJobs() async {
    final selectedOrg = context.read<TenantProvider>().selectedOrganization;
    try {
      final jobs = await JobService().fetchAllJobs();
      debugPrint(" managerJobs: Fetched ${jobs.length} total jobs from API");
      setState(() {
        allJobs = jobs;
        _lastTenant = selectedOrg;
        _applyFilters();
      });
    } catch (e) {
      debugPrint(" managerJobs: Error loading jobs: \$e");
    }
  }

  Future<void> _fetchShifts() async {
    try {
      final shifts = await ShiftService().fetchAllShifts();
      setState(() {
        allShifts = shifts;
        _applyFilters();
      });
    } catch (e) {
      debugPrint(" managerJobs: Error loading shifts: \$e");
    }
  }

  Future<void> _fetchEmployees() async {
    try {
      final employees = await EmployeeService().fetchAllEmployees();
      setState(() {
        employeeMap = {
          for (final employee in employees) employee.employeeId: employee
        };
      });
    } catch (e) {
      debugPrint(" managerJobs: Error loading employees: \$e");
    }
  }

  void _applyFilters() {
    debugPrint(
        " managerJobs: Applying filters. Total raw jobs: ${allJobs.length}, Tenant: '$_lastTenant', ProjectMap size: ${projectMap.length}");

    setState(() {
      // Jobs filter (tenant + search)
      List<Job> tempJobs = [];

      if (_lastTenant.isNotEmpty) {
        tempJobs = allJobs.where((j) {
          final proj = projectMap[j.projectId];
          if (proj == null) {
            debugPrint(
                " managerJobs: Job \${j.jobId} ('\${j.title}') filtered out because ProjectId \${j.projectId} not found in projectMap");
            return false;
          }
          bool match =
              proj.companyName.toLowerCase() == _lastTenant.toLowerCase();
          if (!match) {
            debugPrint(
                " managerJobs: Job \${j.jobId} ('\${j.title}') filtered out: Project company '\${proj.companyName}' != tenant '$_lastTenant'");
          }
          return match;
        }).toList();

        // FALLBACK: If filtering removed ALL jobs but allJobs was not empty,
        // show all jobs for debugging purposes.
        if (tempJobs.isEmpty && allJobs.isNotEmpty) {
          debugPrint(
              " managerJobs: WARNING: Tenant filter removed all jobs. Showing all raw jobs instead for debugging.");
          tempJobs = List.from(allJobs);
        }
      } else {
        tempJobs = List.from(allJobs);
      }

      filteredJobs = _jobSearchQuery.isEmpty
          ? tempJobs
          : tempJobs
              .where((j) =>
                  j.title.toLowerCase().contains(_jobSearchQuery.toLowerCase()))
              .toList();

      // Shifts filter (search)
      filteredShifts = _shiftSearchQuery.isEmpty
          ? List.from(allShifts)
          : allShifts
              .where((s) =>
                  s.taskName
                      .toLowerCase()
                      .contains(_shiftSearchQuery.toLowerCase()))
              .toList();
    });
  }

  void _handleTabChanged() {
    if (_currentTabIndex == _tabController.index) return;
    setState(() {
      _currentTabIndex = _tabController.index;
    });
  }

  void onQueryChanged(String query) {
    if (_currentTabIndex == 0) {
      _jobSearchQuery = query;
    } else {
      _shiftSearchQuery = query;
    }
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer<TenantProvider>(
      builder: (context, tp, _) {
        if (tp.selectedOrganization != _lastTenant) {
          _lastTenant = tp.selectedOrganization;
          if (_lastTenant.isNotEmpty && mounted && !_isLoading) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
          }
        }

        // ── Premium Feature Gate ──────────────────────────────────────────
        if (!tp.isFeatureEnabled('job_management')) {
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
                        featureName: 'Job Management',
                        blockedEndpoint: '/api/job/list',
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

        // ── Normal screen ─────────────────────────────────────────────
        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              const Background(),
              SafeArea(
                child: Column(
                  children: [
                    TabBar(
                      controller: _tabController,
                      labelColor: Colors.blueAccent,
                      unselectedLabelColor: Colors.white,
                      indicatorColor: Colors.blueAccent,
                      tabs: [
                        Tab(
                          icon: _buildTabIconWithCrown(
                            tp,
                            'job',
                            const Icon(Icons.build),
                          ),
                          text: "JOB ${filteredJobs.length}",
                        ),
                        Tab(
                          icon: _buildTabIconWithCrown(
                            tp,
                            'shift',
                            const Icon(Icons.access_time),
                          ),
                          text: "SHIFT ${filteredShifts.length}",
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        key: ValueKey(_currentTabIndex),
                        controller: _currentTabIndex == 0
                            ? _jobSearchController
                            : _shiftSearchController,
                        onChanged: onQueryChanged,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          hintStyle: const TextStyle(color: Colors.white54),
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.white54),
                          filled: true,
                          fillColor: const Color(0xFF2A3243),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF724584),
                              ),
                            )
                          : TabBarView(
                              controller: _tabController,
                              children: [
                                _buildJobView(tp),
                                _buildShiftView(tp),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabIconWithCrown(
      TenantProvider tp, String keyword, Icon baseIcon) {
    bool isBlocked = tp.isEndpointBlocked(keyword);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        baseIcon,
        if (isBlocked)
          Positioned(
            top: -4,
            right: -8,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7A5C00), Color(0xFFB8880A)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFB8880A).withValues(alpha: 0.5),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: Color(0xFFFFD700),
                size: 10,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildListHeader(
      String title, String countText, String buttonText, VoidCallback onAdd) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final titleAndCount = Wrap(
            spacing: 6,
            runSpacing: 2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              Text(countText,
                  style:
                      const TextStyle(color: Colors.blueAccent, fontSize: 13)),
            ],
          );

          final addButton = ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 16),
            label: Text(
              buttonText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          );

          final headerContent = constraints.maxWidth < 340
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleAndCount,
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: addButton,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: titleAndCount),
                    const SizedBox(width: 8),
                    addButton,
                  ],
                );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              headerContent,
              const SizedBox(height: 8),
              const Divider(color: Colors.white24, height: 1),
            ],
          );
        },
      ),
    );
  }

  Widget _buildJobView(TenantProvider tp) {
    if (tp.isEndpointBlocked('job')) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: PremiumFeatureGate(
          featureName: 'Job Management',
          blockedEndpoint: '/job/list',
          customMessage:
              'Contact your administrator to enable Job Management for your tenant.',
          onGotIt: () {
            if (!tp.isEndpointBlocked('shift')) {
              _tabController.animateTo(1);
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const Bottomnavbar(selectedIndex: 0),
                ),
              );
            }
          },
        ),
      );
    }

    return Column(
      children: [
        _buildListHeader(
            "JOB LIST", "Total: ${filteredJobs.length} Jobs", "Add Job",
            () async {
          final result = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const ManagerCreateJob()));
          if (result == true) _loadData();
        }),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: filteredJobs.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      const SizedBox(height: 160),
                      Center(
                        child: Image.asset('assets/cJob.png',
                            height: 30, color: Colors.white54),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text("No jobs found",
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 16)),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredJobs.length,
                    itemBuilder: (context, index) {
                      final job = filteredJobs[index];
                      return InkWell(
                        onTap: () => _openJobDetails(job),
                        child: _buildJobListItem(job),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildShiftView(TenantProvider tp) {
    if (tp.isEndpointBlocked('shift')) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: PremiumFeatureGate(
          featureName: 'Shift Management',
          blockedEndpoint: '/shift/list',
          customMessage:
              'Contact your administrator to enable Shift Management for your tenant.',
          onGotIt: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const Bottomnavbar(selectedIndex: 0),
              ),
            );
          },
        ),
      );
    }

    return Column(
      children: [
        _buildListHeader(
            "SHIFT LIST", "Total: ${filteredShifts.length} Shifts", "Add Shift",
            () async {
          final result = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const Managercreateshift()));
          if (result == true) _loadData();
        }),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: filteredShifts.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      const SizedBox(height: 160),
                      Center(
                        child: Image.asset('assets/cShift.png',
                            height: 30, color: Colors.white54),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text("No shifts found",
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 16)),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredShifts.length,
                    itemBuilder: (context, index) {
                      final shift = filteredShifts[index];
                      return InkWell(
                        onTap: () => _openShiftDetails(shift),
                        child: _buildShiftListItem(shift),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildJobListItem(Job job) {
    final statusColor = _statusColor(job.status);
    final dueBadge = _dueBadge(job);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2433),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(job.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.7)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_statusIcon(job.status), color: statusColor, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      job.status.trim().isEmpty ? 'Unknown' : job.status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.arrow_forward_ios,
                  color: Colors.white70, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                "Start Date : ${_formatDisplayDate(job.startDate)}",
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              if (dueBadge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: dueBadge.backgroundColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    dueBadge.text,
                    style: TextStyle(
                      color: dueBadge.textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              Text(
                "Due Date : ${_formatDisplayDate(job.jobDueDate)}",
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShiftProfileStack(Shift shift, {required bool isCompact}) {
    final assignedIds = _assignedEmployeeIdsForShift(shift);
    final visibleIds = assignedIds.take(4).toList();
    final profiles = visibleIds.isEmpty
        ? <Employee?>[null]
        : visibleIds.map((id) => employeeMap[id]).toList();
    final avatarSize = isCompact ? 44.0 : 42.0;
    final overlapOffset = avatarSize - 14;
    final extraCount = assignedIds.length - profiles.length;
    final itemCount = profiles.length + (extraCount > 0 ? 1 : 0);
    final stackWidth = avatarSize + (itemCount - 1) * overlapOffset;

    return SizedBox(
      width: stackWidth,
      height: avatarSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var index = 0; index < profiles.length; index++)
            Positioned(
              left: index * overlapOffset,
              child: _buildShiftProfileAvatar(
                profiles[index],
                size: avatarSize,
              ),
            ),
          if (extraCount > 0)
            Positioned(
              left: profiles.length * overlapOffset,
              child: _buildExtraEmployeeCount(extraCount, size: avatarSize),
            ),
        ],
      ),
    );
  }

  List<int> _assignedEmployeeIdsForShift(Shift shift) {
    final employeeIds = <int>{};

    for (final employeeId in shift.assignedEmployeeIds) {
      if (employeeId > 0) {
        employeeIds.add(employeeId);
      }
    }

    for (final response in shift.employeeResponses) {
      if (response.employeeId > 0) {
        employeeIds.add(response.employeeId);
      }
    }

    return employeeIds.toList();
  }

  Widget _buildExtraEmployeeCount(int count, {required double size}) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF31394D),
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(color: const Color(0xFF1E2433), width: 2),
      ),
      child: Text(
        '+$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildShiftProfileAvatar(Employee? employee, {required double size}) {
    final imageProvider = _employeeProfileImage(employee);
    final initials = _employeeInitials(employee);

    final avatar = Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: const Color(0xFF8C9AAF),
            borderRadius: BorderRadius.circular(size / 2),
          ),
          child: CircleAvatar(
            backgroundColor: const Color(0xFF627083),
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? initials.isNotEmpty
                    ? Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      )
                    : Icon(Icons.person,
                        color: const Color(0xFF4B8DFF), size: size * 0.62)
                : null,
          ),
        ),
        Positioned(
          right: -2,
          bottom: 1,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: const Color(0xFFF1C232),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF1E2433), width: 2),
            ),
          ),
        ),
      ],
    );

    if (employee == null) return avatar;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openEmployeeProfile(employee),
      child: avatar,
    );
  }

  Widget _buildShiftListItem(Shift shift) {
    final statusColor = _statusColor(shift.status);
    final statusText =
        shift.status.trim().isEmpty ? 'Unknown' : shift.status.trim();
    final startTime = _formatShiftTime(shift.startTime);
    final endTime = _formatShiftTime(shift.endTime);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2433),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 430;

          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                shift.taskName.trim().isEmpty
                    ? 'Untitled shift'
                    : shift.taskName.trim(),
                maxLines: isCompact ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 26,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    _formatShiftDate(shift.date),
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'Est. Time:  '),
                        TextSpan(
                          text: '$startTime - $endTime',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ],
          );

          final avatars = _buildShiftProfileStack(shift, isCompact: isCompact);

          final statusBadge = Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.14),
              border: Border.all(color: statusColor.withValues(alpha: 0.55)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_statusIcon(statusText), color: statusColor, size: 14),
                const SizedBox(width: 6),
                Text(
                  statusText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                details,
                const SizedBox(height: 12),
                Row(
                  children: [
                    avatars,
                    const SizedBox(width: 12),
                    statusBadge,
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios,
                        color: Colors.white70, size: 18),
                  ],
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: details),
              const SizedBox(width: 12),
              avatars,
              const SizedBox(width: 12),
              statusBadge,
              const SizedBox(width: 12),
              const Icon(Icons.arrow_forward_ios,
                  color: Colors.white70, size: 18),
            ],
          );
        },
      ),
    );
  }
}





