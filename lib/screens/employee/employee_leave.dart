// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
// import 'package:shiftsmart/providers/user_provider.dart';
// import 'package:shiftsmart/screens/employee/employee_leavecreate.dart';
// import 'package:shiftsmart/widgets/success_dialog.dart';
// import 'package:shiftsmart/services/leave_service.dart';
// import 'package:shiftsmart/utils/fullscreen_helper.dart';
// import 'package:shiftsmart/widgets/background.dart';
// import 'package:shiftsmart/widgets/emp_slidenav.dart';

// class Employeeleave extends StatefulWidget {
//   const Employeeleave({super.key});

//   @override
//   State<Employeeleave> createState() => _EmployeeleaveState();
// }

// class _EmployeeleaveState extends State<Employeeleave> {
//   final GlobalKey<RefreshIndicatorState> _refreshKey =
//       GlobalKey<RefreshIndicatorState>();

//   List<Map<String, dynamic>> _leaveRequests = [];
//   bool _isLoading = true;
//   int? _currentEmployeeId;
//   String _employeeName = '';
//   String _jobRole = '';

//   final LeaveService _leaveService = LeaveService();

//   @override
//   void initState() {
//     super.initState();
//     enableFullScreen();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _loadProfileAndFetch();
//     });
//   }

//   Future<void> _loadProfileAndFetch() async {
//     // Load name from UserProvider first, fallback to SharedPreferences
//     final userProfile =
//         Provider.of<UserProvider>(context, listen: false).userProfile;
//     final firstName = userProfile['firstName'] ?? '';
//     final lastName = userProfile['lastName'] ?? '';
//     final jobRole = userProfile['jobRole'] ?? '';

//     final prefs = await SharedPreferences.getInstance();
//     final savedName = prefs.getString('userName') ?? '';

//     setState(() {
//       _employeeName = (firstName.isNotEmpty || lastName.isNotEmpty)
//           ? '$firstName $lastName'.trim()
//           : savedName;
//       _jobRole = jobRole;
//     });

//     await _refreshData();
//   }

//   Future<int?> _resolveEmployeeId() async {
//     final prefs = await SharedPreferences.getInstance();
//     final storedId = prefs.getInt('employeeId') ?? prefs.getInt('userId');
//     if (storedId != null) return storedId;

//     final userProfile =
//         Provider.of<UserProvider>(context, listen: false).userProfile;
//     final dynamic profileId = userProfile['employeeId'] ??
//         userProfile['EmployeeId'] ??
//         userProfile['id'] ??
//         userProfile['Id'];

//     if (profileId is int) return profileId;
//     if (profileId is String) return int.tryParse(profileId);
//     return null;
//   }

//   Future<void> _refreshData() async {
//     setState(() => _isLoading = true);
//     await _fetchLeaveRequests();
//     if (mounted) setState(() => _isLoading = false);
//   }

//   Future<void> _fetchLeaveRequests() async {
//     final employeeId = await _resolveEmployeeId();

//     if (employeeId == null) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Employee ID not found!')),
//         );
//       }
//       return;
//     }

//     try {
//       final allRequests =
//           await _leaveService.fetchLeaveRequests(employeeId: employeeId);

//       if (mounted) {
//         final filteredRequests = allRequests
//             .where((r) => r.employeeId == employeeId)
//             .toList();

//         setState(() {
//           _currentEmployeeId = employeeId;
//           _leaveRequests = filteredRequests
//               .map((r) => {
//                     'LeaveRequestId': r.leaveRequestId,
//                     'EmployeeId': r.employeeId,
//                     'LeaveType': r.leaveType,
//                     'StartDate': r.startDate,
//                     'EndDate': r.endDate,
//                     'Reason': r.reason,
//                     'Status': r.status,
//                     'RequestedAt': r.requestedAt,
//                   })
//               .toList();
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error: $e')),
//         );
//       }
//     }
//   }

//   // ── Status helpers ────────────────────────────────────────────────────────

//   Color _statusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'approved':
//         return const Color(0xFF4CAF50);
//       case 'rejected':
//         return const Color(0xFFEF5350);
//       default:
//         return const Color(0xFFFFC107);
//     }
//   }

//   Color _statusBg(String status) {
//     switch (status.toLowerCase()) {
//       case 'approved':
//         return const Color(0xFF4CAF50).withValues(alpha: 0.15);
//       case 'rejected':
//         return const Color(0xFFEF5350).withValues(alpha: 0.15);
//       default:
//         return const Color(0xFFFFC107).withValues(alpha: 0.15);
//     }
//   }

//   IconData _statusIcon(String status) {
//     switch (status.toLowerCase()) {
//       case 'approved':
//         return Icons.check_circle_outline;
//       case 'rejected':
//         return Icons.cancel_outlined;
//       default:
//         return Icons.hourglass_bottom_rounded;
//     }
//   }

//   String _statusLabel(String status) {
//     switch (status.toLowerCase()) {
//       case 'approved':
//         return 'Approved';
//       case 'rejected':
//         return 'Rejected';
//       default:
//         return 'Awaiting Approval';
//     }
//   }

//   Color _leaveTypeColor(String type) {
//     switch (type.toLowerCase()) {
//       case 'sick':
//         return const Color(0xFF42A5F5);
//       case 'annual':
//         return const Color(0xFF66BB6A);
//       case 'casual':
//         return const Color(0xFFAB47BC);
//       default:
//         return const Color(0xFF78909C);
//     }
//   }

//   // ── Delete ────────────────────────────────────────────────────────────────

//   Future<void> _deleteLeave(Map<String, dynamic> leave) async {
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         backgroundColor: const Color(0xFF1E2533),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: const Text('Delete Leave Request',
//             style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//         content: const Text('Are you sure you want to delete this request?',
//             style: TextStyle(color: Colors.white70)),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(ctx, false),
//             child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
//           ),
//           TextButton(
//             onPressed: () => Navigator.pop(ctx, true),
//             child: const Text('Delete',
//                 style: TextStyle(color: Color(0xFFEF5350), fontWeight: FontWeight.bold)),
//           ),
//         ],
//       ),
//     );

//     if (confirm == true) {
//       final success =
//           await _leaveService.deleteLeaveRequest(leave['LeaveRequestId']);
//       if (success == true && mounted) {
//         _refreshData();
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           SuccessDialog.show(
//             context,
//             title: 'Request Deleted',
//             message: 'The leave request has been removed.',
//             buttonText: 'OK',
//           );
//         });
//       } else if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Failed to delete request')),
//         );
//       }
//     }
//   }

//   // ── View Details bottom sheet ─────────────────────────────────────────────

//   void _showDetails(Map<String, dynamic> leave) {
//     final status = leave['Status'] ?? 'Pending';
//     final startDate = leave['StartDate'] as DateTime;
//     final endDate = leave['EndDate'] as DateTime;
//     final days = endDate.difference(startDate).inDays + 1;

//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       isScrollControlled: true,
//       builder: (_) => Container(
//         decoration: const BoxDecoration(
//           color: Color(0xFF1A2035),
//           borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//         ),
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Handle bar
//             Center(
//               child: Container(
//                 width: 40,
//                 height: 4,
//                 decoration: BoxDecoration(
//                   color: Colors.white24,
//                   borderRadius: BorderRadius.circular(2),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//             // Title
//             Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(10),
//                   decoration: BoxDecoration(
//                     color: _leaveTypeColor(leave['LeaveType']).withValues(alpha: 0.2),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Icon(Icons.layers_outlined,
//                       color: _leaveTypeColor(leave['LeaveType']), size: 22),
//                 ),
//                 const SizedBox(width: 14),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(leave['LeaveType'],
//                         style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold)),
//                     Text('$days day${days != 1 ? 's' : ''}',
//                         style: const TextStyle(
//                             color: Colors.white54, fontSize: 13)),
//                   ],
//                 ),
//                 const Spacer(),
//                 // Status badge
//                 Container(
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                   decoration: BoxDecoration(
//                     color: _statusBg(status),
//                     borderRadius: BorderRadius.circular(20),
//                     border: Border.all(
//                         color: _statusColor(status).withValues(alpha: 0.5)),
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Icon(_statusIcon(status),
//                           color: _statusColor(status), size: 14),
//                       const SizedBox(width: 5),
//                       Text(_statusLabel(status),
//                           style: TextStyle(
//                               color: _statusColor(status),
//                               fontSize: 12,
//                               fontWeight: FontWeight.bold)),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 24),
//             _detailRow(Icons.calendar_today_outlined, 'Start Date',
//                 DateFormat('dd MMM yyyy').format(startDate)),
//             const SizedBox(height: 12),
//             _detailRow(Icons.event_outlined, 'End Date',
//                 DateFormat('dd MMM yyyy').format(endDate)),
//             const SizedBox(height: 12),
//             _detailRow(Icons.access_time_outlined, 'Applied On',
//                 DateFormat('dd MMM yyyy').format(leave['RequestedAt'] as DateTime)),
//             const SizedBox(height: 12),
//             _detailRow(Icons.notes_outlined, 'Reason', leave['Reason'] ?? '—'),
//             const SizedBox(height: 28),
//             // Action Buttons
//             Row(
//               children: [
//                 Expanded(
//                   child: OutlinedButton.icon(
//                     onPressed: () {
//                       Navigator.pop(context);
//                       _deleteLeave(leave);
//                     },
//                     icon: const Icon(Icons.delete_outline,
//                         color: Color(0xFFEF5350), size: 18),
//                     label: const Text('Delete',
//                         style: TextStyle(color: Color(0xFFEF5350))),
//                     style: OutlinedButton.styleFrom(
//                       side: const BorderSide(color: Color(0xFFEF5350)),
//                       shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12)),
//                       padding: const EdgeInsets.symmetric(vertical: 14),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: ElevatedButton.icon(
//                     onPressed: () => Navigator.pop(context),
//                     icon: const Icon(Icons.close, size: 18),
//                     label: const Text('Close'),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF2A3447),
//                       foregroundColor: Colors.white,
//                       shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12)),
//                       padding: const EdgeInsets.symmetric(vertical: 14),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 8),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _detailRow(IconData icon, String label, String value) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Icon(icon, color: Colors.white38, size: 18),
//         const SizedBox(width: 10),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(label,
//                   style: const TextStyle(color: Colors.white38, fontSize: 12)),
//               const SizedBox(height: 2),
//               Text(value,
//                   style: const TextStyle(color: Colors.white, fontSize: 14)),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   // ── Build ─────────────────────────────────────────────────────────────────

//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       children: [
//         const Positioned.fill(child: Background()),
//         Scaffold(
//           backgroundColor: Colors.transparent,
//           drawer: const EmpSidenav(),
//           body: _isLoading
//               ? const Center(
//                   child:
//                       CircularProgressIndicator(color: Color(0xFF3498DB)))
//               : Column(
//                   children: [
//                     Expanded(
//                       child: RefreshIndicator(
//                         key: _refreshKey,
//                         onRefresh: _refreshData,
//                         color: const Color(0xFF3498DB),
//                         child: CustomScrollView(
//                           slivers: [
//                             SliverToBoxAdapter(
//                               child: Padding(
//                                 padding: const EdgeInsets.fromLTRB(
//                                     20, 12, 20, 0),
//                                 child: Column(
//                                   crossAxisAlignment:
//                                       CrossAxisAlignment.start,
//                                   children: [
//                                     _applyButton(),
//                                     const SizedBox(height: 16),
//                                     // Section header
//                                     Row(
//                                       children: [
//                                         const Icon(Icons.history,
//                                             color: Colors.white54, size: 18),
//                                         const SizedBox(width: 8),
//                                         Text(
//                                           'My Leave History (${_leaveRequests.length})',
//                                           style: const TextStyle(
//                                               color: Colors.white54,
//                                               fontSize: 13,
//                                               letterSpacing: 0.3),
//                                         ),
//                                       ],
//                                     ),
//                                     const SizedBox(height: 10),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                             _leaveRequests.isEmpty
//                                 ? SliverFillRemaining(
//                                     child: _emptyState(),
//                                   )
//                                 : SliverPadding(
//                                     padding: const EdgeInsets.fromLTRB(
//                                         20, 0, 20, 20),
//                                     sliver: SliverList(
//                                       delegate: SliverChildBuilderDelegate(
//                                         (ctx, i) {
//                                           final reversed = _leaveRequests
//                                               .reversed
//                                               .toList();
//                                           return _leaveCard(reversed[i]);
//                                         },
//                                         childCount: _leaveRequests.length,
//                                       ),
//                                     ),
//                                   ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//         ),
//       ],
//     );
//   }

//   // ── Apply Button ──────────────────────────────────────────────────────────

//   Widget _applyButton() {
//     return Container(
//       margin: const EdgeInsets.only(top: 8),
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [Color(0xFF1C3553), Color(0xFF0D1B2A)],
//         ),
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//               color: const Color(0xFF3498DB).withValues(alpha: 0.15),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: const Icon(Icons.calendar_month_outlined,
//                 color: Color(0xFF3498DB), size: 22),
//           ),
//           const SizedBox(width: 14),
//           const Text(
//             'APPLY FOR LEAVE',
//             style: TextStyle(
//               color: Colors.white,
//               fontWeight: FontWeight.bold,
//               fontSize: 15,
//               letterSpacing: 0.5,
//             ),
//           ),
//           const Spacer(),
//           GestureDetector(
//             onTap: () async {
//               final myRequests = _leaveRequests
//                   .where((r) => r['EmployeeId'] == _currentEmployeeId)
//                   .toList();

//               final result = await showGeneralDialog(
//                 context: context,
//                 barrierColor: Colors.black,
//                 barrierDismissible: true,
//                 barrierLabel: 'Apply Leave',
//                 transitionDuration: const Duration(milliseconds: 300),
//                 pageBuilder: (_, __, ___) =>
//                     Employeeleavecreate(leaveRequests: myRequests),
//               );

//               _refreshData();

//               if (result == true && mounted) {
//                 WidgetsBinding.instance.addPostFrameCallback((_) {
//                   SuccessDialog.show(
//                     context,
//                     title: 'Application Sent',
//                     message:
//                         'Your leave request has been submitted successfully.',
//                     buttonText: 'OK',
//                   );
//                 });
//               }
//             },
//             child: Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: const Color(0xFF3498DB).withValues(alpha: 0.15),
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: const Icon(Icons.add,
//                   color: Color(0xFF3498DB), size: 22),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── Leave Card ────────────────────────────────────────────────────────────

//   Widget _leaveCard(Map<String, dynamic> leave) {
//     final status = leave['Status'] ?? 'Pending';
//     final startDate = leave['StartDate'] as DateTime;
//     final endDate = leave['EndDate'] as DateTime;
//     final leaveType = leave['LeaveType'] ?? '';

//     return Container(
//       margin: const EdgeInsets.only(bottom: 14),
//       decoration: BoxDecoration(
//         color: const Color(0xFF151D2E),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.35),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           // ── Card header ────────────────────────────────────────────────
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Row(
//               children: [
//                 // Avatar
//                 Container(
//                   width: 46,
//                   height: 46,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: const Color(0xFF1E3A5F),
//                     border: Border.all(
//                         color: const Color(0xFF3498DB).withValues(alpha: 0.4),
//                         width: 1.5),
//                   ),
//                   child: const Icon(Icons.person_outline,
//                       color: Color(0xFF3498DB), size: 24),
//                 ),
//                 const SizedBox(width: 12),
//                 // Name + job
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         _employeeName.isNotEmpty ? _employeeName : 'Employee',
//                         style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 15,
//                             fontWeight: FontWeight.bold),
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       if (_jobRole.isNotEmpty)
//                         Text(
//                           _jobRole,
//                           style: const TextStyle(
//                               color: Colors.white54, fontSize: 12),
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                     ],
//                   ),
//                 ),
//                 // Status badge
//                 Container(
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//                   decoration: BoxDecoration(
//                     color: _statusBg(status),
//                     borderRadius: BorderRadius.circular(20),
//                     border: Border.all(
//                         color: _statusColor(status).withValues(alpha: 0.5)),
//                   ),
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Icon(_statusIcon(status),
//                           color: _statusColor(status), size: 13),
//                       const SizedBox(width: 5),
//                       Text(
//                         _statusLabel(status),
//                         style: TextStyle(
//                           color: _statusColor(status),
//                           fontSize: 11,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // Divider
//           Divider(
//               height: 1,
//               thickness: 1,
//               color: Colors.white.withValues(alpha: 0.06)),

//           // ── Card body ──────────────────────────────────────────────────
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//             child: Column(
//               children: [
//                 // Type row
//                 Row(
//                   children: [
//                     Icon(Icons.layers_outlined,
//                         color: _leaveTypeColor(leaveType), size: 18),
//                     const SizedBox(width: 8),
//                     const Text('Type:  ',
//                         style:
//                             TextStyle(color: Colors.white54, fontSize: 13)),
//                     Text(
//                       leaveType,
//                       style: TextStyle(
//                           color: _leaveTypeColor(leaveType),
//                           fontSize: 13,
//                           fontWeight: FontWeight.bold),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 8),
//                 // Date range row
//                 Row(
//                   children: [
//                     const Icon(Icons.calendar_today_outlined,
//                         color: Colors.white38, size: 16),
//                     const SizedBox(width: 8),
//                     Text(
//                       '${DateFormat('dd MMM yyyy').format(startDate)}  →  ${DateFormat('dd MMM yyyy').format(endDate)}',
//                       style: const TextStyle(
//                           color: Colors.white70, fontSize: 13),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),

//           // ── View Details button ────────────────────────────────────────
//           InkWell(
//             onTap: () => _showDetails(leave),
//             borderRadius: const BorderRadius.vertical(
//                 bottom: Radius.circular(16)),
//             child: Container(
//               width: double.infinity,
//               padding: const EdgeInsets.symmetric(vertical: 13),
//               decoration: BoxDecoration(
//                 color: const Color(0xFF1A2640),
//                 borderRadius: const BorderRadius.vertical(
//                     bottom: Radius.circular(16)),
//               ),
//               child: const Center(
//                 child: Text(
//                   'View Details',
//                   style: TextStyle(
//                     color: Color(0xFF3498DB),
//                     fontSize: 14,
//                     fontWeight: FontWeight.bold,
//                     letterSpacing: 0.3,
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── Empty state ───────────────────────────────────────────────────────────

//   Widget _emptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               color: Colors.white.withValues(alpha: 0.05),
//               shape: BoxShape.circle,
//             ),
//             child: const Icon(Icons.history,
//                 color: Colors.white24, size: 48),
//           ),
//           const SizedBox(height: 16),
//           const Text('No leave history found',
//               style: TextStyle(color: Colors.white54, fontSize: 16)),
//           const SizedBox(height: 6),
//           const Text('Tap + to apply for leave',
//               style: TextStyle(color: Colors.white30, fontSize: 13)),
//         ],
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shiftsmart/providers/user_provider.dart';
import 'package:shiftsmart/screens/employee/employee_leavecreate.dart';
import 'package:shiftsmart/widgets/success_dialog.dart';
import 'package:shiftsmart/services/leave_service.dart';
import 'package:shiftsmart/utils/fullscreen_helper.dart';
import 'package:shiftsmart/widgets/background.dart';
import 'package:shiftsmart/widgets/emp_slidenav.dart';
 
class Employeeleave extends StatefulWidget {
  const Employeeleave({super.key});
 
  @override
  State<Employeeleave> createState() => _EmployeeleaveState();
}
 
class _EmployeeleaveState extends State<Employeeleave> {
  final GlobalKey<RefreshIndicatorState> _refreshKey =
      GlobalKey<RefreshIndicatorState>();
 
  List<Map<String, dynamic>> _leaveRequests = [];
  bool _isLoading = true;
  // FIX: Added _hasError flag so the UI can show a proper error state instead
  // of silently showing an empty list when the network call fails.
  bool _hasError = false;
  int? _currentEmployeeId;
  String _employeeName = '';
  String _jobRole = '';
 
  final LeaveService _leaveService = LeaveService();
 
  @override
  void initState() {
    super.initState();
    enableFullScreen();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileAndFetch();
    });
  }
 
  Future<void> _loadProfileAndFetch() async {
    final userProfile =
        Provider.of<UserProvider>(context, listen: false).userProfile;
    final firstName = userProfile['firstName'] ?? '';
    final lastName = userProfile['lastName'] ?? '';
    final jobRole = userProfile['jobRole'] ?? '';
 
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('userName') ?? '';
 
    setState(() {
      _employeeName = (firstName.isNotEmpty || lastName.isNotEmpty)
          ? '$firstName $lastName'.trim()
          : savedName;
      _jobRole = jobRole;
    });
 
    await _refreshData();
  }
 
  Future<int?> _resolveEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();
    final storedId = prefs.getInt('employeeId') ?? prefs.getInt('userId');
    if (storedId != null) return storedId;
 
    final userProfile =
        Provider.of<UserProvider>(context, listen: false).userProfile;
    final dynamic profileId = userProfile['employeeId'] ??
        userProfile['EmployeeId'] ??
        userProfile['id'] ??
        userProfile['Id'];
 
    if (profileId is int) return profileId;
    if (profileId is String) return int.tryParse(profileId);
    return null;
  }
 
  // FIX: _refreshData now properly resets _hasError and guarantees
  // _isLoading is set to false in a finally block, even if an exception
  // propagates out of _fetchLeaveRequests.
  Future<void> _refreshData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
 
    try {
      await _fetchLeaveRequests();
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
 
  Future<void> _fetchLeaveRequests() async {
    final employeeId = await _resolveEmployeeId();
 
    if (employeeId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Employee ID not found!')),
        );
      }
      return;
    }
 
    // Use the specialized 'my' endpoint for fetching leave history.
    final requests = await _leaveService.fetchMyLeaveRequests();
 
    if (mounted) {
      setState(() {
        _currentEmployeeId = employeeId;
        _leaveRequests = requests
            .map((r) => {
                  'LeaveRequestId': r.leaveRequestId,
                  'EmployeeId': r.employeeId,
                  'LeaveType': r.leaveType,
                  'StartDate': r.startDate,
                  'EndDate': r.endDate,
                  'Reason': r.reason,
                  'Status': r.status,
                  'RequestedAt': r.requestedAt,
                })
            .toList();
        
        // Sort newest requests first
        _leaveRequests.sort((a, b) => 
          (b['RequestedAt'] as DateTime).compareTo(a['RequestedAt'] as DateTime));
      });
    }
  }
 
  // ── Status helpers ────────────────────────────────────────────────────────
 
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF4CAF50);
      case 'rejected':
        return const Color(0xFFEF5350);
      default:
        return const Color(0xFFFFC107);
    }
  }
 
  Color _statusBg(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF4CAF50).withValues(alpha: 0.15);
      case 'rejected':
        return const Color(0xFFEF5350).withValues(alpha: 0.15);
      default:
        return const Color(0xFFFFC107).withValues(alpha: 0.15);
    }
  }
 
  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle_outline;
      case 'rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.hourglass_bottom_rounded;
    }
  }
 
  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Awaiting Approval';
    }
  }
 
  Color _leaveTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'sick':
        return const Color(0xFF42A5F5);
      case 'annual':
        return const Color(0xFF66BB6A);
      case 'casual':
        return const Color(0xFFAB47BC);
      default:
        return const Color(0xFF78909C);
    }
  }
 
  // ── Delete ────────────────────────────────────────────────────────────────
 
  Future<void> _deleteLeave(Map<String, dynamic> leave) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2533),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Leave Request',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
            'Are you sure you want to delete this request?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(
                    color: Color(0xFFEF5350),
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
 
    if (confirm != true) return;
 
    // FIX: Guard mounted before any async gap below.
    final success =
        await _leaveService.deleteLeaveRequest(leave['LeaveRequestId']);
 
    if (!mounted) return;
 
    if (success == true) {
      await _refreshData();
      if (!mounted) return;
      SuccessDialog.show(
        context,
        title: 'Request Deleted',
        message: 'The leave request has been removed.',
        buttonText: 'OK',
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete request')),
      );
    }
  }
 
  // ── View Details bottom sheet ─────────────────────────────────────────────
 
  void _showDetails(Map<String, dynamic> leave) {
    final status = leave['Status'] ?? 'Pending';
    final startDate = leave['StartDate'] as DateTime;
    final endDate = leave['EndDate'] as DateTime;
    final days = endDate.difference(startDate).inDays + 1;
 
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A2035),
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Title row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _leaveTypeColor(leave['LeaveType'])
                        .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.layers_outlined,
                      color: _leaveTypeColor(leave['LeaveType']),
                      size: 22),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(leave['LeaveType'],
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    Text('$days day${days != 1 ? 's' : ''}',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 13)),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusBg(status),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color:
                            _statusColor(status).withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon(status),
                          color: _statusColor(status), size: 14),
                      const SizedBox(width: 5),
                      Text(_statusLabel(status),
                          style: TextStyle(
                              color: _statusColor(status),
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _detailRow(Icons.calendar_today_outlined, 'Start Date',
                DateFormat('dd MMM yyyy').format(startDate)),
            const SizedBox(height: 12),
            _detailRow(Icons.event_outlined, 'End Date',
                DateFormat('dd MMM yyyy').format(endDate)),
            const SizedBox(height: 12),
            _detailRow(
                Icons.access_time_outlined,
                'Applied On',
                DateFormat('dd MMM yyyy')
                    .format(leave['RequestedAt'] as DateTime)),
            const SizedBox(height: 12),
            _detailRow(
                Icons.notes_outlined, 'Reason', leave['Reason'] ?? '—'),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteLeave(leave);
                    },
                    icon: const Icon(Icons.delete_outline,
                        color: Color(0xFFEF5350), size: 18),
                    label: const Text('Delete',
                        style: TextStyle(color: Color(0xFFEF5350))),
                    style: OutlinedButton.styleFrom(
                      side:
                          const BorderSide(color: Color(0xFFEF5350)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Close'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A3447),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
                height:
                    MediaQuery.of(context).viewInsets.bottom + 8),
          ],
        ),
      ),
    );
  }
 
  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white38, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 12)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
 
  // ── Build ─────────────────────────────────────────────────────────────────
 
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: Background()),
        Scaffold(
          backgroundColor: Colors.transparent,
          drawer: const EmpSidenav(currentScreen: 'Leave'),
          // FIX: Wrap body in SafeArea so content never renders under the
          // status bar when fullscreen mode is active.
          body: SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF3498DB)))
                // FIX: Show a dedicated error state instead of an empty list
                // when the fetch failed.
                : _hasError
                    ? _errorState()
                    : Column(
                        children: [
                          Expanded(
                            child: RefreshIndicator(
                              key: _refreshKey,
                              onRefresh: _refreshData,
                              color: const Color(0xFF3498DB),
                              child: CustomScrollView(
                                slivers: [
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.fromLTRB(
                                              20, 12, 20, 0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _applyButton(),
                                          const SizedBox(height: 16),
                                          Row(
                                            children: [
                                              const Icon(Icons.history,
                                                  color: Colors.white54,
                                                  size: 18),
                                              const SizedBox(width: 8),
                                              Text(
                                                'My Leave History (${_leaveRequests.length})',
                                                style: const TextStyle(
                                                    color: Colors.white54,
                                                    fontSize: 13,
                                                    letterSpacing: 0.3),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                        ],
                                      ),
                                    ),
                                  ),
                                  _leaveRequests.isEmpty
                                      // FIX: Wrap empty state in a
                                      // SliverToBoxAdapter + ConstrainedBox
                                      // so the CustomScrollView can still
                                      // over-scroll and trigger
                                      // RefreshIndicator.
                                      ? SliverToBoxAdapter(
                                          child: ConstrainedBox(
                                            constraints: BoxConstraints(
                                              minHeight:
                                                  MediaQuery.of(context)
                                                          .size
                                                          .height *
                                                      0.5,
                                            ),
                                            child: _emptyState(),
                                          ),
                                        )
                                      : SliverPadding(
                                          padding:
                                              const EdgeInsets.fromLTRB(
                                                  20, 0, 20, 20),
                                          sliver: SliverList(
                                            delegate:
                                                SliverChildBuilderDelegate(
                                              (ctx, i) => _leaveCard(_leaveRequests[i]),
                                              childCount: _leaveRequests.length,
                                            ),
                                          ),
                                        ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
          ),
        ),
      ],
    );
  }
 
  // ── Apply Button ──────────────────────────────────────────────────────────
  // FIX: Wrap the entire container in InkWell/GestureDetector, not just the
  // '+' icon — the whole card should be tappable, but only the '+' icon
  // triggers the dialog (which is the intended UX).  The tap target is now
  // the full card for accessibility while the visual affordance stays on +.
  Widget _applyButton() {
    return GestureDetector(
      onTap: _openApplyLeaveDialog,
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1C3553), Color(0xFF0D1B2A)],
          ),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    const Color(0xFF3498DB).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.calendar_month_outlined,
                  color: Color(0xFF3498DB), size: 22),
            ),
            const SizedBox(width: 14),
            const Text(
              'APPLY FOR LEAVE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    const Color(0xFF3498DB).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add,
                  color: Color(0xFF3498DB), size: 22),
            ),
          ],
        ),
      ),
    );
  }
 
  Future<void> _openApplyLeaveDialog() async {
    // FIX: Extracted into its own method — reusable and keeps _applyButton
    // clean.  Pass only the current employee's requests (already filtered).
    final result = await showGeneralDialog(
      context: context,
      barrierColor: Colors.black,
      barrierDismissible: true,
      barrierLabel: 'Apply Leave',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) =>
          Employeeleavecreate(leaveRequests: _leaveRequests),
    );
 
    // Always refresh — even on dismiss the list might have changed.
    await _refreshData();
 
    if (result == true && mounted) {
      SuccessDialog.show(
        context,
        title: 'Application Sent',
        message: 'Your leave request has been submitted successfully.',
        buttonText: 'OK',
      );
    }
  }
 
  // ── Leave Card ────────────────────────────────────────────────────────────
 
  Widget _leaveCard(Map<String, dynamic> leave) {
    final status = leave['Status'] ?? 'Pending';
    final startDate = leave['StartDate'] as DateTime;
    final endDate = leave['EndDate'] as DateTime;
    final leaveType = leave['LeaveType'] ?? '';
 
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF151D2E),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [

 
          // ── Card body ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.layers_outlined,
                        color: _leaveTypeColor(leaveType), size: 18),
                    const SizedBox(width: 8),
                    const Text('Type:  ',
                        style: TextStyle(
                            color: Colors.white54, fontSize: 13)),
                    Text(
                      leaveType,
                      style: TextStyle(
                          color: _leaveTypeColor(leaveType),
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _statusBg(status),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color:
                                _statusColor(status).withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_statusIcon(status),
                              color: _statusColor(status), size: 13),
                          const SizedBox(width: 5),
                          Text(
                            _statusLabel(status),
                            style: TextStyle(
                              color: _statusColor(status),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: Colors.white38, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '${DateFormat('dd MMM yyyy').format(startDate)}  →  ${DateFormat('dd MMM yyyy').format(endDate)}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
 
          // ── View Details button ──────────────────────────────────────
          InkWell(
            onTap: () => _showDetails(leave),
            borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: const BoxDecoration(
                color: Color(0xFF1A2640),
                borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(16)),
              ),
              child: const Center(
                child: Text(
                  'View Details',
                  style: TextStyle(
                    color: Color(0xFF3498DB),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
 
  // ── Empty state ───────────────────────────────────────────────────────────
 
  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history,
                color: Colors.white24, size: 48),
          ),
          const SizedBox(height: 16),
          const Text('No leave history found',
              style:
                  TextStyle(color: Colors.white54, fontSize: 16)),
          const SizedBox(height: 6),
          const Text('Tap the card above to apply for leave',
              style:
                  TextStyle(color: Colors.white30, fontSize: 13)),
        ],
      ),
    );
  }
 
  // ── Error state ───────────────────────────────────────────────────────────
  // FIX: New widget — shown when _hasError is true so the user knows something
  // went wrong and can pull-to-refresh manually.
  Widget _errorState() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: const Color(0xFF3498DB),
      child: ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.wifi_off_outlined,
                        color: Colors.white24, size: 48),
                  ),
                  const SizedBox(height: 16),
                  const Text('Failed to load leave history',
                      style: TextStyle(
                          color: Colors.white54, fontSize: 16)),
                  const SizedBox(height: 6),
                  const Text('Pull down to try again',
                      style: TextStyle(
                          color: Colors.white30, fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
 
