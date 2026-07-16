// Job Role models
class JobRole {
  int jobRoleTypeId;
  int estimatedTime;
  int numberOfRoles;
  String notes;
  String roleName;

  JobRole({
    required this.jobRoleTypeId,
    required this.estimatedTime,
    required this.numberOfRoles,
    required this.notes,
    required this.roleName,
  });

  // Factory constructor to create JobRole from JSON
  factory JobRole.fromJson(Map<String, dynamic> json) {
    return JobRole(
      jobRoleTypeId:
          _readInt(json['JobRoleTypeId'] ?? json['jobRoleTypeId']) ?? 0,
      estimatedTime:
          _readInt(json['EstimatedTime'] ?? json['estimatedTime']) ?? 8,
      numberOfRoles:
          _readInt(json['NumberOfRoles'] ?? json['numberOfRoles']) ?? 1,
      notes: (json['Notes'] ?? json['notes'] ?? '').toString(),
      roleName: (json['RoleName'] ??
              json['JobRoleName'] ??
              json['roleName'] ??
              json['jobRoleName'] ??
              '')
          .toString(),
    );
  }

  // Convert JobRole to JSON
  Map<String, dynamic> toJson() {
    return {
      'jobRoleTypeId': jobRoleTypeId,
      'estimatedTime': estimatedTime,
      'numberOfRoles': numberOfRoles,
      'notes': notes,
    };
  }

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
