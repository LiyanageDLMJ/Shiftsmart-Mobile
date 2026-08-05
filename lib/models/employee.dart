class Employee {
  final int employeeId;
  final String firstName;
  final String? middleName;
  final String? lastName;
  final String? gender;
  final String? email;
  final String? mobileNumber;
  final String? street;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  final DateTime? dateOfBirth;
  final String? employmentStatus;
  final String? employmentType;
  final String? jobRole;
  final String? userRole;
  final String? profilePicture;
  final String? bankAccountName;
  final String? bankAccountNumber;
  final String? bankBSB;
  final String? bankName;
  final List<NextOfKin> nextOfKins;

  Employee({
    required this.employeeId,
    required this.firstName,
    this.middleName,
    this.lastName,
    this.gender,
    this.email,
    this.mobileNumber,
    this.street,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    this.dateOfBirth,
    this.employmentStatus,
    this.employmentType,
    this.jobRole,
    this.userRole,
    this.profilePicture,
    this.bankAccountName,
    this.bankAccountNumber,
    this.bankBSB,
    this.bankName,
    this.nextOfKins = const [],
  });

  Employee copyWith({
    String? profilePicture,
  }) {
    return Employee(
      employeeId: employeeId,
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      gender: gender,
      email: email,
      mobileNumber: mobileNumber,
      street: street,
      city: city,
      state: state,
      postalCode: postalCode,
      country: country,
      dateOfBirth: dateOfBirth,
      employmentStatus: employmentStatus,
      employmentType: employmentType,
      jobRole: jobRole,
      userRole: userRole,
      profilePicture: profilePicture ?? this.profilePicture,
      bankAccountName: bankAccountName,
      bankAccountNumber: bankAccountNumber,
      bankBSB: bankBSB,
      bankName: bankName,
      nextOfKins: nextOfKins,
    );
  }

  factory Employee.fromJson(Map<String, dynamic> json) {
    // Helper to safely get value regardless of casing
    T? getValue<T>(String key1, String key2) {
      return (json[key1] ?? json[key2]) as T?;
    }

    return Employee(
      // Check both 'employeeId' AND 'EmployeeId'
      employeeId: json['employeeId'] ?? json['EmployeeId'] ?? 0,

      firstName: getValue<String>('firstName', 'FirstName') ?? '',
      middleName: getValue<String>('middleName', 'MiddleName') ?? '',
      lastName: getValue<String>('lastName', 'LastName') ?? '',

      email: getValue<String>('email', 'Email'),
      profilePicture: getValue<String>('profilePicture', 'ProfilePicture'),
      userRole:
          getValue<String>('userRole', 'Role'), // API sends 'Role' sometimes

      gender: getValue<String>('gender', 'Gender'),
      mobileNumber: getValue<String>('mobileNumber', 'MobileNumber'),
      street: getValue<String>('street', 'Street'),
      city: getValue<String>('city', 'City'),
      state: getValue<String>('state', 'State'),
      postalCode: getValue<String>('postalCode', 'PostalCode'),
      country: getValue<String>('country', 'Country'),

      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'])
          : (json['DateOfBirth'] != null
              ? DateTime.tryParse(json['DateOfBirth'])
              : null),

      employmentStatus:
          getValue<String>('employmentStatus', 'EmploymentStatus'),
      employmentType: getValue<String>('employmentType', 'EmploymentType'),
      jobRole: getValue<String>('jobRole', 'JobRole'),

      bankAccountName: getValue<String>('bankAccountName', 'BankAccountName'),
      bankAccountNumber:
          getValue<String>('bankAccountNumber', 'BankAccountNumber'),
      bankBSB: getValue<String>('bankBSB', 'BankBSB'),
      bankName: getValue<String>('bankName', 'BankName'),

      nextOfKins: ((json['nextOfKins'] ??
                  json['NextOfKins'] ??
                  json['NextOfKin'] ??
                  json['nextOfKin'] ??
                  json['ApprovedNextOfKin']) as List<dynamic>?)
              ?.map((kinJson) => NextOfKin.fromJson(kinJson))
              .toList() ??
          [],
    );
  }
}

class NextOfKin {
  final int nextOfKinId;
  final int employeeId;
  final String fullName;
  final String relationship;
  final String mobileNumber;
  final String email;
  final String address;
  final bool isPrimary;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  NextOfKin({
    required this.nextOfKinId,
    required this.employeeId,
    required this.fullName,
    required this.relationship,
    required this.mobileNumber,
    required this.email,
    required this.address,
    required this.isPrimary,
    this.createdAt,
    this.updatedAt,
  });

  factory NextOfKin.fromJson(Map<String, dynamic> json) {
    return NextOfKin(
      nextOfKinId: json['nextOfKinId'] ?? json['NextOfKinId'] ?? 0,
      employeeId: json['employeeId'] ?? json['EmployeeId'] ?? 0,
      fullName: json['fullName'] ?? json['FullName'] ?? '',
      relationship: json['relationship'] ?? json['Relationship'] ?? '',
      mobileNumber: json['mobileNumber'] ?? json['MobileNumber'] ?? '',
      email: json['email'] ?? json['Email'] ?? '',
      address: json['address'] ?? json['Address'] ?? '',
      isPrimary: json['isPrimary'] ?? json['IsPrimary'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }
}
