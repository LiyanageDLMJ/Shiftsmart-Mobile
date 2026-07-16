import 'package:shiftsmart/utils/date_time_parser.dart';

class NotificationItem {
  final int id;
  final String type;
  final String subject;
  final String message;
  final String status;
  final DateTime createdAt;
  final int recipientId;
  final int? tenantId;

  NotificationItem({
    required this.id,
    required this.type,
    required this.subject,
    required this.message,
    required this.status,
    required this.createdAt,
    required this.recipientId,
    this.tenantId,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    dynamic value(String key) => json[key] ?? json[_lowerFirst(key)];
    final idValue = value('Id') ?? 0;
    final recipientIdValue = value('RecipientId') ?? 0;
    final tenantIdValue = value('TenantId') ??
        json['tenantID'] ??
        json['TenantID'] ??
        json['tenant_id'];

    return NotificationItem(
      id: idValue is int ? idValue : int.tryParse(idValue.toString()) ?? 0,
      type: value('Type')?.toString() ?? '',
      subject: value('Subject')?.toString() ?? '',
      message: value('Message')?.toString() ?? '',
      status: value('Status')?.toString() ?? '',
      createdAt: parseServerDateTime(value('CreatedAt')) ?? DateTime.now(),
      recipientId: recipientIdValue is int
          ? recipientIdValue
          : int.tryParse(recipientIdValue.toString()) ?? 0,
      tenantId:
          tenantIdValue == null ? null : int.tryParse(tenantIdValue.toString()),
    );
  }

  static String _lowerFirst(String key) {
    if (key.isEmpty) return key;
    return key[0].toLowerCase() + key.substring(1);
  }
}
