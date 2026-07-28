import 'dart:convert';
import 'package:shiftsmart/utils/date_time_parser.dart';
import 'package:flutter/material.dart';
import 'package:shiftsmart/models/shift.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_client.dart';

class ShiftService {
  final ApiClient _apiClient = ApiClient();

  // Load Base URL and API Keys from .env
  final String baseUrl =
      dotenv.env['SHIFT_BASE_URL'] ?? dotenv.env['BASE_URL'] ?? "";

  //  PROD ENDPOINT KEYS (from func-shifts)
  final String shiftCreateKey = dotenv.env['SHIFT_CREATE_KEY'] ?? "";
  final String shiftUpdateKey = dotenv.env['SHIFT_UPDATE_KEY'] ?? "";
  final String shiftGetAllKey = dotenv.env['SHIFT_GET_ALL_KEY'] ?? "";
  final String shiftGetByEmployeeKey =
      dotenv.env['SHIFT_GET_BY_EMPLOYEE_KEY'] ?? "";
  final String shiftDeleteKey = dotenv.env['SHIFT_DELETE_KEY'] ?? "";
  final String shiftRespondKey = dotenv.env['SHIFT_RESPOND_KEY'] ?? '';
  final String shiftSwapRequestKey = dotenv.env['SHIFT_SWAP_REQUEST_KEY'] ?? '';
  final String shiftCompleteKey = dotenv.env['SHIFT_COMPLETE_KEY'] ?? '';

  ShiftService() {
    if (baseUrl.isEmpty) debugPrint(" ShiftService: SHIFT_BASE_URL is missing");
  }

  // ===========================================================================
  // EMPLOYEE FUNCTIONS (View, Respond, Swap)
  // ===========================================================================

  // 1. Fetch Shifts assigned to a specific Employee (Returns Shift Objects)
  Future<List<Shift>> fetchShiftsByEmployeeId(int employeeId) async {
    final String url =
        '$baseUrl/shift/employee/$employeeId?code=$shiftGetByEmployeeKey';

    try {
      final response =
          await _apiClient.get(url, useAuth: true, showDialog: false);

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((data) => Shift.fromJson(data)).toList();
      } else {
        debugPrint(
            "Failed to load employee shifts. Status: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Exception in fetchShiftsByEmployeeId: $e");
      return [];
    }
  }

  // 2. Fetch Shifts assigned to a specific Employee (Returns Raw JSON)
  Future<List<Map<String, dynamic>>> fetchShiftsByEmployeeIdRaw(
      int employeeId) async {
    final String url =
        '$baseUrl/shift/employee/$employeeId?code=$shiftGetByEmployeeKey';
    try {
      final response =
          await _apiClient.get(url, useAuth: true, showDialog: false);
      debugPrint(
          " ShiftService Status (EmpId $employeeId): ${response.statusCode}");
      debugPrint(
          " ShiftService Body snippet: ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        debugPrint(
            " ShiftService: Found ${jsonData.length} shifts for employee.");
        return jsonData.cast<Map<String, dynamic>>();
      } else {
        debugPrint(
            " ShiftService: Failed to fetch shifts for employee. Status: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint(" ShiftService: Exception in fetchShiftsByEmployeeIdRaw: $e");
      return [];
    }
  }

  // 3. Respond to a Shift Assignment (Accept or Decline)
  Future<bool> respondToShift(int shiftId, String action,
      {String? reason}) async {
    final String url = '$baseUrl/shift/respond?code=$shiftRespondKey';

    final body = {
      "ShiftId": shiftId,
      "Action": action, // "Accept" or "Decline"
      "Reason": reason // Required if action is "Decline"
    };

    try {
      final response = await _apiClient.post(url, body: body, useAuth: true);

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint("Respond failed: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Exception in respondToShift: $e");
      return false;
    }
  }

  // 4. Request a Shift Swap
  Future<bool> requestSwap(int shiftId) async {
    final String url = '$baseUrl/shift/swap/$shiftId?code=$shiftSwapRequestKey';

    try {
      final response = await _apiClient.patch(url, body: {}, useAuth: true);

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint("Swap request failed: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Exception in requestSwap: $e");
      return false;
    }
  }

  // 5. Complete Shift
  Future<bool> completeShift(int shiftId) async {
    final String url =
        '$baseUrl/shift/complete/$shiftId?code=$shiftCompleteKey';

    try {
      final response = await _apiClient.post(url, body: {}, useAuth: true);

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint("Complete shift failed: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Exception in completeShift: $e");
      return false;
    }
  }

  // 6. Helper: Fetch and Filter Shifts for a specific Job & Employee
  Future<List<Map<String, dynamic>>> fetchShiftsForJobAndEmployee({
    required int employeeId,
    required int jobId,
  }) async {
    try {
      final allShifts = await fetchShiftsByEmployeeIdRaw(employeeId);
      final jobShifts = allShifts.where((shift) {
        return shift['JobId'].toString() == jobId.toString();
      }).toList();

      jobShifts.sort((a, b) {
        final dateA = parseServerDateTime(a['Date']) ?? DateTime(0);
        final dateB = parseServerDateTime(b['Date']) ?? DateTime(0);
        if (dateA != dateB) return dateA.compareTo(dateB);
        return a['StartTime'].compareTo(b['StartTime']);
      });

      return jobShifts;
    } catch (e) {
      debugPrint("Exception in fetchShiftsForJobAndEmployee: $e");
      return [];
    }
  }

  // ===========================================================================
  //  MANAGER / ADMIN FUNCTIONS (Create, Update, View All)
  // ===========================================================================

  // 7. Fetch All Shifts (Master List for Managers)
  Future<List<Shift>> fetchAllShifts() async {
    final url = '$baseUrl/shift/getall?code=$shiftGetAllKey';

    try {
      final response =
          await _apiClient.get(url, useAuth: true, showDialog: false);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData is List) {
          debugPrint(" Fetched ${jsonData.length} shifts successfully.");
          return jsonData.map<Shift>((data) => Shift.fromJson(data)).toList();
        } else {
          debugPrint(" Unexpected JSON format for fetchAllShifts: $jsonData");
          return [];
        }
      } else {
        debugPrint(
            " Failed to fetch all shifts. Status: ${response.statusCode}, Body: ${response.body}");
        return [];
      }
    } catch (e) {
      debugPrint(" Exception in fetchAllShifts: $e");
      return [];
    }
  }

  // 8. Fetch All Raw Shifts (Legacy/Dashboard use)
  Future<List<Map<String, dynamic>>> fetchAllRawShifts() async {
    final url = '$baseUrl/shift/getall?code=$shiftGetAllKey';

    try {
      final response =
          await _apiClient.get(url, useAuth: true, showDialog: false);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData is List) {
          return jsonData.cast<Map<String, dynamic>>();
        }
      }
    } catch (e) {
      debugPrint("Exception in fetchAllRawShifts: $e");
    }
    return [];
  }

  // 9. Create New Shift
  Future<bool> addShift(Map<String, dynamic> shiftData) async {
    final String url = '$baseUrl/shift/create?code=$shiftCreateKey';
    final createPayload = _normalizeCreatePayload(shiftData);

    try {
      final response =
          await _apiClient.post(url, body: createPayload, useAuth: true);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        debugPrint(
            'Failed to add shift. Status: ${response.statusCode}, Body: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Exception in addShift: $e');
      return false;
    }
  }

  Map<String, dynamic> _normalizeCreatePayload(Map<String, dynamic> shiftData) {
    final payload = Map<String, dynamic>.from(shiftData);

    if (payload['ShiftId'] == null || payload['ShiftId'] == 0) {
      payload.remove('ShiftId');
    }

    // Send payload intact to preserve valid ISODate formatting
    return payload;
  }

  Map<String, dynamic> _normalizeUpdatePayload(
      int id, Map<String, dynamic> shiftData) {
    final payload = Map<String, dynamic>.from(shiftData)..['ShiftId'] = id;
    final assignedEmployeeIds =
        _readEmployeeIds(payload['AssignedEmployeeIds'] ?? payload['EmployeeIds']);

    final startDate = payload['StartDate']?.toString();
    if (startDate != null && startDate.isNotEmpty) {
      payload['Date'] = startDate;
    }

    payload['StartTime'] = _timeOnly(payload['StartTime']);
    payload['EndTime'] = _timeOnly(payload['EndTime']);

    if (assignedEmployeeIds.isNotEmpty) {
      payload['AssignedEmployeeIds'] = assignedEmployeeIds;
      payload['EmployeeIds'] = assignedEmployeeIds;
      payload['Assignments'] = assignedEmployeeIds
          .map((employeeId) => {
                'EmployeeId': employeeId,
                'Status': 'Pending',
              })
          .toList();
    }

    return payload;
  }

  List<int> _readEmployeeIds(dynamic value) {
    if (value is List) {
      return value
          .map((id) {
            if (id is int) return id;
            if (id is num) return id.toInt();
            return int.tryParse(id.toString()) ?? 0;
          })
          .where((id) => id > 0)
          .toSet()
          .toList();
    }

    if (value is String && value.trim().isNotEmpty) {
      return value
          .split(',')
          .map((id) => int.tryParse(id.trim()) ?? 0)
          .where((id) => id > 0)
          .toSet()
          .toList();
    }

    return [];
  }

  String _timeOnly(dynamic value) {
    var time = value?.toString().trim() ?? '';
    if (time.contains('T')) time = time.split('T').last;
    if (time.endsWith('Z')) time = time.substring(0, time.length - 1);
    if (time.contains('.')) time = time.split('.').first;
    if (time.length >= 8) return time.substring(0, 8);
    if (RegExp(r'^\d{1,2}:\d{2}$').hasMatch(time)) return "$time:00";
    return time;
  }

  // 10. Update Existing Shift
  Future<bool> updateShift(int id, Map<String, dynamic> shiftData) async {
    final updateUrl = '$baseUrl/shift/update/$id?code=$shiftUpdateKey';
    final payload = _normalizeUpdatePayload(id, shiftData);

    try {
      final response =
          await _apiClient.put(updateUrl, body: payload, useAuth: true);

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        await _verifyUpdatedAssignments(id, payload);
        return true;
      }

      final message = response.body.trim().isNotEmpty
          ? response.body.trim()
          : 'Status code: ${response.statusCode}';
      debugPrint('Failed to update shift: $message');
      throw Exception(message);
    } catch (e) {
      debugPrint('Exception in updateShift: $e');
      rethrow;
    }
  }

  Future<void> _verifyUpdatedAssignments(
      int shiftId, Map<String, dynamic> payload) async {
    final expectedEmployeeIds = _readEmployeeIds(payload['AssignedEmployeeIds']);
    if (expectedEmployeeIds.isEmpty) return;

    final latestShifts = await fetchAllShifts();
    Shift? latestShift;
    for (final shift in latestShifts) {
      if (shift.shiftId == shiftId) {
        latestShift = shift;
        break;
      }
    }

    if (latestShift == null) return;

    final actualEmployeeIds = _assignedEmployeeIdsForShift(latestShift);
    if (!_sameIdSet(expectedEmployeeIds, actualEmployeeIds)) {
      throw Exception(
        'Shift details were updated, but assigned employees did not change. '
        'Please update the Shift_UpdateHandler backend to replace assignment records.',
      );
    }
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

  bool _sameIdSet(List<int> expected, List<int> actual) {
    final expectedSet = expected.toSet();
    final actualSet = actual.toSet();

    return expectedSet.length == actualSet.length &&
        expectedSet.every(actualSet.contains);
  }

  // 11. Delete Shift
  Future<bool> deleteShift(int id) async {
    final deleteUrl = '$baseUrl/shift/delete/$id?code=$shiftDeleteKey';

    try {
      final response = await _apiClient.delete(deleteUrl, useAuth: true);
      debugPrint(' Delete response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        debugPrint(
            'Failed to delete shift (${response.statusCode}): ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Exception in deleteShift: $e');
      return false;
    }
  }
}
