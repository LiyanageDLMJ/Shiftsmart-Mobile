import 'package:shiftsmart/utils/date_time_parser.dart';

class ChatMessage {
  final int messageId;
  final String message;
  final int senderId;
  final int receiverId;
  final DateTime sentAt;
  final DateTime createdAt;

  ChatMessage({
    required this.messageId,
    required this.message,
    required this.senderId,
    required this.receiverId,
    required this.sentAt,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      messageId: json['MessageId'],
      message: json['Message'],
      senderId: json['SenderId'],
      receiverId: json['ReceiverId'],
      sentAt: parseChatDateTime(json['SentAt']) ?? DateTime.now(),
      createdAt: parseChatDateTime(json['CreatedAt']) ?? DateTime.now(),
    );
  }
}
