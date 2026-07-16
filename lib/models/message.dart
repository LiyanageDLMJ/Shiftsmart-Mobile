import 'package:shiftsmart/utils/date_time_parser.dart';

class Message {
  final int messageId;
  final int senderId;
  final int receiverId;
  final String text;
  final DateTime createdAt;

  Message({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    final sentTime = parseChatDateTime(
      json['SentAt'] ??
          json['sentAt'] ??
          json['CreatedAt'] ??
          json['createdAt'] ??
          json['Timestamp'] ??
          json['timestamp'] ??
          json['MessageTime'] ??
          json['messageTime'] ??
          json['Date'] ??
          json['date'] ??
          '',
    );

    return Message(
      // Handle both PascalCase (Server) and camelCase (Local)
      messageId: json['MessageId'] ?? json['messageId'] ?? 0,
      senderId: json['SenderId'] ?? json['senderId'] ?? 0,
      receiverId: json['ReceiverId'] ?? json['receiverId'] ?? 0,
      text: json['Message'] ??
          json['message'] ??
          json['Text'] ??
          json['text'] ??
          json['LastMessage'] ??
          json['lastMessage'] ??
          json['Content'] ??
          json['content'] ??
          json['Msg'] ??
          json['msg'] ??
          '', // Check all possible keys
      createdAt: sentTime ?? DateTime.now(),
    );
  }
}
