// import 'dart:convert';
// import 'package:flutter/material.dart';
// // import 'package:http/http.dart' as http; // Removed: We use ApiClient now
// import 'package:shiftsmart/models/leave_request.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'api_client.dart';

// class LeaveService {
//   // 1. Initialize the ApiClient
//   final ApiClient _apiClient = ApiClient();

//   //  PROD Endpoints from func-leave
//   final String baseUrl = dotenv.env['LEAVE_BASE_URL'] ?? dotenv.env['BASE_URL'] ?? "";
//   final String leaveRequestKey = dotenv.env['LEAVE_REQUEST_KEY'] ?? "";
//   final String leaveApproveKey = dotenv.env['LEAVE_APPROVE_KEY'] ?? "";
//   final String leaveGetAllKey = dotenv.env['LEAVE_GET_ALL_KEY'] ?? "";
//   final String leaveGetByEmployeeKey = dotenv.env['LEAVE_GET_BY_EMPLOYEE_KEY'] ?? dotenv.env['LEAVE_REQUEST_KEY'] ?? "";
//   final String leaveDeleteKey = dotenv.env['LEAVE_DELETE_KEY'] ?? "";
//   final String leaveBalanceKey = dotenv.env['LEAVE_BALANCE_KEY'] ?? "";

//   LeaveService() {
//     if (baseUrl.isEmpty) debugPrint(" LeaveService: LEAVE_BASE_URL is missing");
//   }

//   // --- ADD LEAVE REQUEST ---
//   Future<bool> addLeaveRequest(Map<String, dynamic> leaveData) async {
//     final String url = '$baseUrl/leave/request?code=$leaveRequestKey';

//     try {
//       final response = await _apiClient.post(
//         url,
//         body: leaveData,
//         useAuth: true, // Sends Bearer Token + Key
//       );

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         return true;
//       } else {
//         debugPrint('Failed to add leave request: ${response.body}');
//         return false;
//       }
//     } catch (e) {
//       debugPrint("Error adding leave request: $e");
//       return false;
//     }
//   }

//   // --- DELETE LEAVE REQUEST ---
//   Future<bool?> deleteLeaveRequest(int leaveId) async {
//     final String url = '$baseUrl/leave/delete/$leaveId?code=$leaveDeleteKey';

//     try {
//       final response = await _apiClient.delete(
//         url,
//         useAuth: true, // Sends Bearer Token + Key
//       );

//       if (response.statusCode == 200) {
//         return true;
//       } else {
//         debugPrint("Failed to delete leave: ${response.body}");
//         return false;
//       }
//     } catch (e) {
//       debugPrint("Error deleting the leave request: $e");
//       return null;
//     }
//   }

//   // --- FETCH ALL LEAVE REQUESTS ---
//   Future<List<LeaveRequest>> fetchLeaveRequests({int? employeeId}) async {
//     final String url;
//     if (employeeId != null) {
//       // Employee-only view should use the employee-specific request handler if available.
//       final uri = Uri.parse('$baseUrl/leave/request').replace(queryParameters: {
//         'code': leaveGetByEmployeeKey.isNotEmpty ? leaveGetByEmployeeKey : leaveRequestKey,
//         'employeeId': employeeId.toString(),
//         'EmployeeId': employeeId.toString(),
//       });
//       url = uri.toString();
//     } else {
//       final uri = Uri.parse('$baseUrl/leave/all').replace(queryParameters: {
//         'code': leaveGetAllKey,
//       });
//       url = uri.toString();
//     }

//     debugPrint(" LeaveService: Fetching from $url (employeeId filter: $employeeId)");

//     try {
//       final response = await _apiClient.get(
//         url,
//         useAuth: true,
//         showDialog: false, // Don't show premium gate dialog for leave endpoint, but let it track in TenantProvider
//       );

//       debugPrint(" LeaveService: Status ${response.statusCode}");

//       if (response.statusCode == 200) {
//         final dynamic jsonData = jsonDecode(response.body);
//         List<dynamic> rawList = [];

//         if (jsonData is List) {
//           rawList = jsonData;
//         } else if (jsonData is Map) {
//           // Handle common object wrappers used in Azure Functions
//           rawList = jsonData['leaves'] ??
//                     jsonData['data'] ??
//                     jsonData['leaveRequests'] ??
//                     jsonData['value'] ?? [];
//         }

//         debugPrint(" LeaveService: Fetched ${rawList.length} total records.");

//         final allRequests = rawList.map((item) => LeaveRequest.fromJson(item)).toList();

//         // Filter by employeeId client-side if provided
//         if (employeeId != null) {
//           final filtered = allRequests.where((r) => r.employeeId == employeeId).toList();
//           debugPrint(" LeaveService: Filtered to ${filtered.length} records for employee $employeeId.");
//           return filtered;
//         }

//         return allRequests;
//       } else if (response.statusCode == 403) {
//         debugPrint(" LeaveService: 403 Forbidden — leave feature may not be enabled for this tenant.");
//         debugPrint(" LeaveService: Response: ${response.body}");
//         return [];
//       } else {
//         debugPrint(" LeaveService: Failed to load leaves. Status: ${response.statusCode}");
//         debugPrint(" LeaveService: Server Response: ${response.body}");
//         return [];
//       }
//     } catch (e) {
//       debugPrint("Error fetching leave requests: $e");
//       return [];
//     }
//   }


//   // --- FETCH LEAVE BALANCE ---
//   Future<int?> fetchLeaveBalance(int employeeId) async {
//     final String url =
//         '$baseUrl/leave/balance/$employeeId?code=$leaveBalanceKey';

//     try {
//       final response = await _apiClient.get(
//         url,
//         useAuth: true,
//         showDialog: false,
//       );

//       if (response.statusCode == 200) {
//         final jsonData = jsonDecode(response.body);
//         return jsonData['RemainingLeaveDays'];
//       } else {
//         debugPrint("Failed to fetch balance: ${response.body}");
//         return null;
//       }
//     } catch (e) {
//       debugPrint("Error fetching leave balance: $e");
//       return null;
//     }
//   }

//   // --- UPDATE LEAVE STATUS (Approve/Reject) ---
//   Future<void> updateLeaveStatus(String id, String newStatus) async {
//     final String url = '$baseUrl/leave/approve/$id?code=$leaveApproveKey';
//     final body = {
//       "status": newStatus
//     }; // ApiClient handles jsonEncode automatically usually

//     try {
//       final response = await _apiClient.post(
//         url,
//         body: body,
//         useAuth: true, // Sends Bearer Token + Key
//       );

//       if (response.statusCode == 200) {
//         debugPrint("Leave status updated to: $newStatus");
//       } else {
//         debugPrint("Failed to update status: ${response.body}");
//         throw Exception("Failed to update leave status");
//       }
//     } catch (e) {
//       debugPrint("Error updating status: $e");
//       rethrow;
//     }
//   }
// }


import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shiftsmart/models/leave_request.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_client.dart';
 
class LeaveService {
  final ApiClient _apiClient = ApiClient();
 
  // PROD Endpoints from func-leave
  final String baseUrl =
      dotenv.env['LEAVE_BASE_URL'] ?? dotenv.env['BASE_URL'] ?? "";
  final String leaveRequestKey =
      dotenv.env['LEAVE_REQUEST_KEY'] ?? "";
  final String leaveApproveKey =
      dotenv.env['LEAVE_APPROVE_KEY'] ?? "";
  final String leaveGetAllKey =
      dotenv.env['LEAVE_GET_ALL_KEY'] ?? "";
  final String leaveDeleteKey =
      dotenv.env['LEAVE_DELETE_KEY'] ?? "";
  final String leaveBalanceKey =
      dotenv.env['LEAVE_BALANCE_KEY'] ?? "";
  final String leaveMyKey =
      dotenv.env['LEAVE_MY_KEY'] ?? "";
 
  LeaveService() {
    if (baseUrl.isEmpty) {
      debugPrint("LeaveService: LEAVE_BASE_URL is missing");
    }
  }
 
  // ─── ADD LEAVE REQUEST ────────────────────────────────────────────────────
  // FIX: Uses LEAVE_REQUEST_KEY (POST /leave/request) — correct.
  Future<bool> addLeaveRequest(Map<String, dynamic> leaveData) async {
    final String url = '$baseUrl/leave/request?code=$leaveRequestKey';
 
    try {
      final response = await _apiClient.post(
        url,
        body: leaveData,
        useAuth: true,
      );
 
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        debugPrint('Failed to add leave request: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint("Error adding leave request: $e");
      return false;
    }
  }
 
  // ─── DELETE LEAVE REQUEST ─────────────────────────────────────────────────
  // FIX: Uses LEAVE_DELETE_KEY correctly. Returns null on exception so the
  // caller can distinguish "network error" from a clean false.
  Future<bool?> deleteLeaveRequest(int leaveId) async {
    final String url = '$baseUrl/leave/delete/$leaveId?code=$leaveDeleteKey';
 
    try {
      final response = await _apiClient.delete(
        url,
        useAuth: true,
      );
 
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        debugPrint("Failed to delete leave: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Error deleting the leave request: $e");
      return null;
    }
  }
 
  // ─── FETCH ALL / BY-EMPLOYEE LEAVE REQUESTS ───────────────────────────────
  // FIX 1: Always use GET /leave/all with LEAVE_GET_ALL_KEY — the
  //         /leave/request endpoint is a POST (write) endpoint and must never
  //         be called with GET for reads.
  // FIX 2: Remove the bogus server-side employeeId query params that were
  //         being sent to the write endpoint; filter purely client-side after
  //         receiving the full list from the read endpoint.
  // FIX 3: Removed the now-unused LEAVE_GET_BY_EMPLOYEE_KEY variable (it was
  //         not present in the .env anyway).
  Future<List<LeaveRequest>> fetchLeaveRequests({int? employeeId}) async {
    final uri = Uri.parse('$baseUrl/leave/all').replace(queryParameters: {
      'code': leaveGetAllKey,
    });
    final String url = uri.toString();
 
    debugPrint(
        "LeaveService: Fetching from $url (employeeId filter: $employeeId)");
 
    try {
      final response = await _apiClient.get(
        url,
        useAuth: true,
        showDialog: false,
      );
 
      debugPrint("LeaveService: Status ${response.statusCode}");
 
      if (response.statusCode == 200) {
        final dynamic jsonData = jsonDecode(response.body);
        List<dynamic> rawList = [];
 
        if (jsonData is List) {
          rawList = jsonData;
        } else if (jsonData is Map) {
          rawList = (jsonData['leaves'] ??
                  jsonData['data'] ??
                  jsonData['leaveRequests'] ??
                  jsonData['value'] ??
                  []) as List<dynamic>;
        }
 
        debugPrint(
            "LeaveService: Fetched ${rawList.length} total records.");
 
        final allRequests =
            rawList.map((item) => LeaveRequest.fromJson(item)).toList();
 
        // Client-side filter — safe because we own the full list from the
        // correct read endpoint.
        if (employeeId != null) {
          final filtered =
              allRequests.where((r) => r.employeeId == employeeId).toList();
          debugPrint(
              "LeaveService: Filtered to ${filtered.length} records for employee $employeeId.");
          return filtered;
        }
 
        return allRequests;
      } else if (response.statusCode == 403) {
        debugPrint(
            "LeaveService: 403 Forbidden — leave feature may not be enabled for this tenant.");
        debugPrint("LeaveService: Response: ${response.body}");
        return [];
      } else {
        debugPrint(
            "LeaveService: Failed to load leaves. Status: ${response.statusCode}");
        debugPrint("LeaveService: Server Response: ${response.body}");
        return [];
      }
    } catch (e) {
      debugPrint("Error fetching leave requests: $e");
      return [];
    }
  }
 
  // ─── FETCH LEAVE BALANCE ──────────────────────────────────────────────────
  Future<int?> fetchLeaveBalance(int employeeId) async {
    final String url =
        '$baseUrl/leave/balance/$employeeId?code=$leaveBalanceKey';
 
    try {
      final response = await _apiClient.get(
        url,
        useAuth: true,
        showDialog: false,
      );
 
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return jsonData['RemainingLeaveDays'] as int?;
      } else {
        debugPrint("Failed to fetch balance: ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("Error fetching leave balance: $e");
      return null;
    }
  }
 
  // ─── UPDATE LEAVE STATUS (Approve / Reject) ───────────────────────────────
  // FIX: Changed from POST to PATCH — approval/rejection is a partial update
  // on an existing resource.  If your Azure Function only accepts POST, change
  // _apiClient.patch → _apiClient.post here (and nowhere else).
  Future<void> updateLeaveStatus(
    int id,
    String newStatus, {
    String? rejectionReason,
  }) async {
    final String url = '$baseUrl/leave/approve/$id?code=$leaveApproveKey';
    final body = <String, dynamic>{"status": newStatus};

    final trimmedReason = rejectionReason?.trim() ?? '';
    if (trimmedReason.isNotEmpty) {
      body['RejectionReason'] = trimmedReason;
    }
 
    try {
      final response = await _apiClient.post(
        url,
        body: body,
        useAuth: true,
      );
 
      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint("Leave status updated to: $newStatus");
      } else {
        debugPrint("Failed to update status: ${response.statusCode} - ${response.body}");
        throw Exception("Failed to update leave status");
      }
    } catch (e) {
      debugPrint("Error updating status: $e");
      rethrow;
    }
  }
 
  // ─── FETCH MY LEAVE REQUESTS ──────────────────────────────────────────────
  // Fetches leave history for the currently authenticated employee using the
  // specialized /leave/my endpoint.
  Future<List<LeaveRequest>> fetchMyLeaveRequests() async {
    final uri = Uri.parse('$baseUrl/leave/my').replace(queryParameters: {
      'code': leaveMyKey,
    });
    final String url = uri.toString();
 
    debugPrint("LeaveService: Fetching my leaves from $url");
 
    try {
      final response = await _apiClient.get(
        url,
        useAuth: true,
        showDialog: false,
      );
 
      debugPrint("LeaveService: Status ${response.statusCode}");
 
      if (response.statusCode == 200) {
        final dynamic jsonData = jsonDecode(response.body);
        List<dynamic> rawList = [];
 
        if (jsonData is List) {
          rawList = jsonData;
        } else if (jsonData is Map) {
          rawList = (jsonData['leaves'] ??
                  jsonData['data'] ??
                  jsonData['leaveRequests'] ??
                  jsonData['value'] ??
                  []) as List<dynamic>;
        }
 
        debugPrint(
            "LeaveService: Fetched ${rawList.length} records from 'my' endpoint.");
        return rawList.map((item) => LeaveRequest.fromJson(item)).toList();
      } else {
        debugPrint(
            "LeaveService: Failed to load my leaves. Status: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Error fetching my leave requests: $e");
      return [];
    }
  }
}