class SearchEmployee {
  final int employeeId;
  final String firstName;
  final String lastName;
  final String? email;
  final String? profilePicture;
  final String role;

  SearchEmployee({
    required this.employeeId,
    required this.firstName,
    required this.lastName,
    this.email,
    this.profilePicture,
    required this.role,
  });

  factory SearchEmployee.fromJson(Map<String, dynamic> json) {
    return SearchEmployee(
      // Handle both casing styles (PascalCase vs camelCase) just to be safe
      employeeId: json['employeeId'] ?? json['EmployeeId'] ?? 0,
      firstName: json['firstName'] ?? json['FirstName'] ?? "Unknown",
      lastName: json['lastName'] ?? json['LastName'] ?? "",
      email: json['email'] ?? json['Email'],
      profilePicture: json['profilePicture'] ?? json['ProfilePicture'],
      role: json['role'] ?? json['Role'] ?? "Employee",
    );
  }
}
