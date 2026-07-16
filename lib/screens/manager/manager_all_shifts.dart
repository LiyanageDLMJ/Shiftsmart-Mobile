import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shiftsmart/models/shift.dart';
import 'package:shiftsmart/screens/manager/manager_create_shift.dart';
import 'package:shiftsmart/screens/manager/manager_shifts_view.dart';
import 'package:shiftsmart/services/shift_service.dart';
import 'package:shiftsmart/utils/fullscreen_helper.dart';
import 'package:shiftsmart/widgets/background.dart';
import 'package:shiftsmart/widgets/search.dart';
import 'package:shiftsmart/widgets/sidenav.dart';
import 'package:shiftsmart/widgets/uppernavbar.dart';
import 'package:provider/provider.dart';
import 'package:shiftsmart/providers/tenant_provider.dart';
import 'package:shiftsmart/widgets/premium_feature_gate.dart';

class Managerallshifts extends StatefulWidget {
  const Managerallshifts({super.key});

  @override
  State<Managerallshifts> createState() => _ManagerallshiftsState();
}

class _ManagerallshiftsState extends State<Managerallshifts> {
  // State Variables
  bool _isLoading = true;
  List<Shift> allShifts = [];
  List<Shift> filteredShifts = [];

  @override
  void initState() {
    super.initState();
    enableFullScreen();
    _loadData();
  }

  // Fetch all shifts from backend
  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);
    debugPrint(" [Managerallshifts] Loading shifts from backend...");
    try {
      final shifts = await ShiftService().fetchAllShifts();
      debugPrint(" [Managerallshifts] Received ${shifts.length} shifts from service.");
      if (mounted) {
        setState(() {
          allShifts = shifts;
          filteredShifts = List.from(allShifts);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint(" [Managerallshifts] Error loading data: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading data.')),
        );
      }
    }
  }

  // Filter list based on search query
  void onQueryChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredShifts = List.from(allShifts);
      } else {
        filteredShifts = allShifts.where((shift) {
          return shift.taskName.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  // Helper: Navigate to a screen and refresh list on return
  // Returns 'true' if data was modified
  Future<void> _navigateAndRefresh(Widget screen) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );

    // If result is true (meaning a shift was added/edited), refresh list
    if (result == true) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Consumer<TenantProvider>(
      builder: (context, tp, _) {
        if (!tp.isFeatureEnabled('shift_scheduling')) {
          return Stack(
            children: [
              const Positioned.fill(child: Background()),
              Scaffold(
                resizeToAvoidBottomInset: false,
                backgroundColor: Colors.transparent,
                appBar: const Uppernavbar(showBackButton: true),
                drawer: const Sidenav(),
                body: SafeArea(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: PremiumFeatureGate(
                        featureName: 'Shift Scheduling',
                        blockedEndpoint: '/api/shift/list',
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
          drawer: const Sidenav(),
          backgroundColor: const Color(0xFF1C2230),
          appBar: const Uppernavbar(
            showBackButton: true,
          ),
          body: Stack(
            children: [
              const Positioned.fill(child: Background()),
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Search(onQueryChanged: onQueryChanged),

                      // "Create Shift" Button Area
                      _createShift(),

                      const SizedBox(height: 16),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "SHIFT LIST",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Shift List
                      Expanded(
                        child: _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                    color: Color(0xFF724584)))
                            : _shiftList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Widget for "Create Shift" Header
  Widget _createShift() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromARGB(180, 42, 50, 67),
            Color.fromARGB(180, 34, 40, 52)
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Image.asset('assets/cShift.png', height: 30),
                const SizedBox(width: 12),
                const Flexible(
                  child: Text(
                    "CREATE SHIFT",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Add Button
          GestureDetector(
            onTap: () => _navigateAndRefresh(const Managercreateshift()),
            child: const Icon(Icons.add_box_outlined,
                color: Colors.blueAccent, size: 32),
          ),
        ],
      ),
    );
  }

  // Widget for the list of shifts
  Widget _shiftList() {
    if (filteredShifts.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadData,
        color: const Color(0xFF724584),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/cShift.png', height: 40, color: Colors.grey[600]),
                  const SizedBox(height: 16),
                  Text("No shifts found",
                      style: TextStyle(color: Colors.grey[400], fontSize: 16)),
                  const SizedBox(height: 8),
                  Text("Pull to refresh",
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF724584),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        itemCount: filteredShifts.length,
        itemBuilder: (context, index) {
          final shift = filteredShifts[index];
          return _buildStyledJobCard(context, shift);
        },
      ),
    );
  }

  // Individual Shift Card - Upgraded to match professional JOB LIST style
  Widget _buildStyledJobCard(BuildContext context, Shift shift) {
    String formattedStart = shift.startTime;
    String formattedEnd = shift.endTime;

    try {
      final inputFormat = DateFormat("HH:mm:ss");
      final displayFormat = DateFormat.jm();
      if (shift.startTime.contains(":")) {
        formattedStart = displayFormat.format(inputFormat.parse(shift.startTime));
      }
      if (shift.endTime.contains(":")) {
        formattedEnd = displayFormat.format(inputFormat.parse(shift.endTime));
      }
    } catch (e) {
      // Fallback
    }

    final String formattedDate = DateFormat('yyyy-MM-dd').format(shift.date);

    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ManagerShiftsView(shift: shift))),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF363E51), Color(0xFF191E26)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left Icon - Professional Style
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black26,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3), width: 1),
              ),
              child: Image.asset('assets/cShift.png', height: 24, color: Colors.blueAccent),
            ),
            const SizedBox(width: 16),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shift.taskName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 12, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(formattedDate,
                          style: const TextStyle(fontSize: 13, color: Colors.white70)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 12, color: Colors.white60),
                      const SizedBox(width: 4),
                      Text("$formattedStart - $formattedEnd",
                          style: const TextStyle(fontSize: 12, color: Colors.white60)),
                    ],
                  ),
                ],
              ),
            ),

            // Right Side: Status Badge & Actions
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (shift.status.toLowerCase() == "active" || shift.status.toLowerCase() == "scheduled") 
                        ? Colors.blueAccent.withValues(alpha: 0.2) 
                        : Colors.orangeAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (shift.status.toLowerCase() == "active" || shift.status.toLowerCase() == "scheduled") 
                          ? Colors.blueAccent 
                          : Colors.orangeAccent,
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    shift.status.toUpperCase(),
                    style: TextStyle(
                        color: (shift.status.toLowerCase() == "active" || shift.status.toLowerCase() == "scheduled") 
                            ? Colors.blueAccent 
                            : Colors.orangeAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => _navigateAndRefresh(Managercreateshift(shift: shift)),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.edit, color: Colors.white70, size: 18),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
