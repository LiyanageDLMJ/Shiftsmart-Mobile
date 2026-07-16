import 'package:shiftsmart/utils/date_time_parser.dart';

class ChatListItem {
  final int chatId;
  final int partnerId;
  final String partnerName;
  final String? partnerPhoto;
  final String lastMessage;
  final DateTime? lastMessageTime;

  ChatListItem({
    required this.chatId,
    required this.partnerId,
    required this.partnerName,
    this.partnerPhoto,
    required this.lastMessage,
    this.lastMessageTime,
  });

  factory ChatListItem.fromJson(Map<String, dynamic> json) {
    final lastTime = parseChatDateTime(
      json['lastMessageTime'] ??
          json['LastMessageTime'] ??
          json['SentAt'] ??
          json['sentAt'] ??
          json['CreatedAt'] ??
          json['createdAt'] ??
          json['Timestamp'] ??
          json['timestamp'] ??
          '',
    );

    return ChatListItem(
      // Check for all possible ID keys (ChatId, ChatParticipantId, etc.)
      chatId: json['ChatParticipantId'] ??
          json['chatParticipantId'] ??
          json['chatId'] ??
          json['ChatId'] ??
          0,
      partnerId: json['partnerId'] ?? json['PartnerId'] ?? 0,

      // The backend sends the full name directly here:
      partnerName: json['partnerName'] ?? json['PartnerName'] ?? 'Unknown',

      partnerPhoto: json['partnerPhoto'] ?? json['PartnerPhoto'],
      lastMessage: json['lastMessage'] ?? json['LastMessage'] ?? '',

      lastMessageTime: lastTime,
    );
  }
}
