import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shiftsmart/models/chat_list_item.dart';
import 'package:shiftsmart/models/message.dart';
import 'package:shiftsmart/models/search_employee.dart';
import 'package:shiftsmart/services/api_client.dart';
import 'package:shiftsmart/services/employee_service.dart';

class ChatService {
  final ApiClient _apiClient = ApiClient();
  final EmployeeService _employeeService = EmployeeService();

  // Standard Base URL
  final String baseUrl = dotenv.env['BASE_URL']!;

  //  SPECIAL URL FOR MESSAGES (From your Master List & .env)
  // If MESSAGE_BASE_URL is missing in .env, fallback to baseUrl
  String get messageBaseUrl => dotenv.env['MESSAGE_BASE_URL'] ?? baseUrl;

  // Keys
  String get searchEmpKey => dotenv.env['CHAT_SEARCH_EMPLOYEES_KEY'] ?? '';
  String get partiKey => dotenv.env['CHAT_GET_BY_EMPLOYEE_KEY'] ?? '';
  String get fetchMsgKey => dotenv.env['CHAT_GET_MESSAGES_KEY'] ?? '';
  String get sendMsgKey => dotenv.env['CHAT_SEND_MESSAGE_KEY'] ?? '';
  String get createChatKey => dotenv.env['CHAT_CREATE_KEY'] ?? '';
  String get chatAllKey => dotenv.env['CHAT_GET_ALL_KEY'] ?? '';

  // --- 1. FETCH CHAT LIST ---
  Future<List<ChatListItem>> fetchChatList() async {
    final url = '$messageBaseUrl/chat/all?code=$chatAllKey';
    debugPrint(" Fetching Chat List"); // Log added

    try {
      final response = await _apiClient.get(url, useAuth: true);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return Future.wait(
          data
              .whereType<Map<String, dynamic>>()
              .map(_chatListItemFromJsonWithSignedPhoto),
        );
      }
      debugPrint(" Chat List Error: ${response.statusCode}");
      return [];
    } catch (e) {
      debugPrint(" Error fetching chats: $e");
      return [];
    }
  }

  // --- 2. SEARCH EMPLOYEES ---
  Future<List<SearchEmployee>> searchEmployees(String query) async {
    final encodedQuery = Uri.encodeComponent(query);
    final url =
        '$messageBaseUrl/chat/search?query=$encodedQuery&code=$searchEmpKey';

    try {
      final response = await _apiClient.get(url, useAuth: true);
      debugPrint(" ChatService Search Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final dynamic decodedResponse = jsonDecode(response.body);

        // Handle both List and Map ({ count, results }) response formats
        List<dynamic> data = [];
        if (decodedResponse is List) {
          data = decodedResponse;
        } else if (decodedResponse is Map &&
            decodedResponse.containsKey('results')) {
          data = decodedResponse['results'];
        }

        debugPrint(" ChatService: Found ${data.length} employees.");
        return Future.wait(
          data
              .whereType<Map<String, dynamic>>()
              .map(_searchEmployeeFromJsonWithSignedPhoto),
        );
      }
      return [];
    } catch (e) {
      debugPrint(" Error searching employees: $e");
      return [];
    }
  }

  Future<ChatListItem> _chatListItemFromJsonWithSignedPhoto(
    Map<String, dynamic> json,
  ) async {
    final item = ChatListItem.fromJson(json);
    final signedUrl = await _signedProfilePictureUrl(
      item.partnerId,
      item.partnerPhoto,
    );
    return signedUrl == null ? item : item.copyWith(partnerPhoto: signedUrl);
  }

  Future<SearchEmployee> _searchEmployeeFromJsonWithSignedPhoto(
    Map<String, dynamic> json,
  ) async {
    final employee = SearchEmployee.fromJson(json);
    final signedUrl = await _signedProfilePictureUrl(
      employee.employeeId,
      employee.profilePicture,
    );
    return signedUrl == null
        ? employee
        : employee.copyWith(profilePicture: signedUrl);
  }

  Future<String?> _signedProfilePictureUrl(
    int employeeId,
    String? currentValue,
  ) async {
    final value = currentValue?.trim() ?? '';
    if (employeeId <= 0 || value.isEmpty || value.startsWith('data:image')) {
      return null;
    }

    final signedUrl =
        await _employeeService.fetchProfilePictureDownloadUrl(employeeId);
    if (signedUrl == null || signedUrl.isEmpty) return null;
    return signedUrl;
  }

  Future<List<SearchEmployee>> fetchDefaultSearchEmployees() async {
    const seedQueries = [
      '@',
      'a',
      'b',
      'c',
      'd',
      'e',
      'f',
      'g',
      'h',
      'i',
      'j',
      'k',
      'l',
      'm',
      'n',
      'o',
      'p',
      'q',
      'r',
      's',
      't',
      'u',
      'v',
      'w',
      'x',
      'y',
      'z',
    ];

    final responses = await Future.wait(seedQueries.map(searchEmployees));
    final byId = <int, SearchEmployee>{};

    for (final employees in responses) {
      for (final employee in employees) {
        byId[employee.employeeId] = employee;
      }
    }

    final employees = byId.values.toList()
      ..sort((a, b) {
        final first = '${a.firstName} ${a.lastName}'.trim().toLowerCase();
        final second = '${b.firstName} ${b.lastName}'.trim().toLowerCase();
        return first.compareTo(second);
      });

    return employees;
  }

  // --- 3. FETCH MESSAGES (FIXED URL & LOGS) ---
  Future<List<Message>> fetchMessages(int chatParticipantId) async {
    final url =
        '$messageBaseUrl/chat/messages/$chatParticipantId?code=$fetchMsgKey';
    try {
      final response = await _apiClient.get(url, useAuth: true);
      debugPrint(" ChatService: Message fetch status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final dynamic decodedResponse = jsonDecode(response.body);

        List<dynamic> data = [];
        if (decodedResponse is List) {
          data = decodedResponse;
        } else if (decodedResponse is Map) {
          // Check common keys like 'results', 'messages', 'data'
          data = decodedResponse['results'] ??
              decodedResponse['messages'] ??
              decodedResponse['data'] ??
              [];
        }

        debugPrint(" ChatService: Found ${data.length} messages.");
        return data.map((m) => Message.fromJson(m)).toList();
      } else {
        debugPrint(
            " ChatService Error: ${response.statusCode} - ${response.body}");
        return [];
      }
    } catch (e) {
      debugPrint(" Error fetching messages: $e");
      return [];
    }
  }

  // --- 4. SEND MESSAGE (Added Logs) ---
  Future<bool> sendMessage({
    required int chatParticipantId,
    required int senderId,
    required int receiverId,
    required String text,
  }) async {
    final url = '$messageBaseUrl/chat/send/$chatParticipantId?code=$sendMsgKey';

    final body = {
      'SenderId': senderId,
      'ReceiverId': receiverId,
      'Message': text,
    };

    try {
      final response = await _apiClient.post(url, body: body, useAuth: true);

      if (response.statusCode == 200) {
        debugPrint(" Message Sent!");
        return true;
      } else {
        debugPrint(" Send Failed: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint(" Error sending message: $e");
      return false;
    }
  }

  // --- 5. CREATE CHAT ---
  Future<bool> createChat({
    required int senderId,
    required int receiverId,
    required String message,
  }) async {
    final url = '$messageBaseUrl/chat/create?code=$createChatKey';
    final body = {
      'SenderId': senderId,
      'ReceiverId': receiverId,
      'Message': message,
    };
    try {
      final response = await _apiClient.post(url, body: body, useAuth: true);
      debugPrint(" Create Chat Status: ${response.statusCode}");
      return response.statusCode == 200;
    } catch (e) {
      debugPrint(" Error creating chat: $e");
      return false;
    }
  }
}
