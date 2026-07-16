import 'package:shiftsmart/utils/date_time_parser.dart';

class ChatParticipant {
  final int chatParticipantId;
  final int employee1Id;
  final int employee2Id;
  final DateTime createdAt;

  // Optional (populated later)
  String? lastMessage;
  DateTime? lastSentAt;

  ChatParticipant({
    required this.chatParticipantId,
    required this.employee1Id,
    required this.employee2Id,
    required this.createdAt,
    this.lastMessage,
    this.lastSentAt,
  });

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      // Handle both PascalCase (C# Default) and camelCase (JSON Standard)
      chatParticipantId:
          json['ChatParticipantId'] ?? json['chatParticipantId'] ?? 0,
      employee1Id: json['Employee1Id'] ?? json['employee1Id'] ?? 0,
      employee2Id: json['Employee2Id'] ?? json['employee2Id'] ?? 0,
      createdAt: parseChatDateTime(json['CreatedAt'] ?? json['createdAt']) ??
          DateTime.now(),
    );
  }

  int getOtherParticipant(int currentUserId) {
    return currentUserId == employee1Id ? employee2Id : employee1Id;
  }
}
