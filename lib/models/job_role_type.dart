class JobRoleType {
  final int id;
  final String name;
  final List<String> requiredDocuments;

  JobRoleType({
    required this.id,
    required this.name,
    required this.requiredDocuments,
  });

  static JobRoleType unKnown() => JobRoleType(
        id: 0,
        name: 'UnKnown',
        requiredDocuments: [],
      );

  factory JobRoleType.fromJson(Map<String, dynamic> json) {
    // Safely extract required documents, handling nulls or different types
    List<String> docs = [];
    final docsRaw = json['RequiredDocuments'] ?? json['requiredDocuments'];
    if (docsRaw is String) {
      docs = docsRaw.isEmpty
          ? []
          : docsRaw.split(',').map((e) => e.trim()).toList();
    } else if (docsRaw != null) {
      docs = docsRaw.toString().split(',').map((e) => e.trim()).toList();
    }

    return JobRoleType(
      // Safely fall back through possible backend key names and default to 0
      id: _readInt(
              json['JobRoleTypeId'] ?? json['jobRoleTypeId'] ?? json['id']) ??
          0,

      // Safely fall back through possible backend key names and default to 'Unknown'
      name: json['JobRoleName'] ??
          json['jobRoleName'] ??
          json['name'] ??
          'Unknown Role',

      requiredDocuments: docs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'JobRoleTypeId': id,
      'JobRoleName': name,
      'RequiredDocuments': requiredDocuments.join(','),
    };
  }

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
