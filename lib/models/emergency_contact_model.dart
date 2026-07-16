import 'package:shiftsmart/utils/date_time_parser.dart';

class Contact {
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
  final String? bankAccountName;
  final String? bankAccountNumber;
  final String? bankBSB;
  final String? bankName;
  final String? employmentStatus;
  final String? jobRole;
  final String? userRole;
  final String? profilePicture;
  final List<NextOfKin> nextOfKins;

  const Contact({
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
    this.bankAccountName,
    this.bankAccountNumber,
    this.bankBSB,
    this.bankName,
    this.employmentStatus,
    this.jobRole,
    this.userRole,
    this.profilePicture,
    required this.nextOfKins,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    // Helper to handle both PascalCase and camelCase
    dynamic getVal(String key) => json[key] ?? json[key[0].toLowerCase() + key.substring(1)];

    return Contact(
      employeeId: getVal('EmployeeId') ?? 0,
      firstName: getVal('FirstName') ?? '',
      middleName: getVal('MiddleName'),
      lastName: getVal('LastName'),
      gender: getVal('Gender'),
      email: getVal('Email'),
      mobileNumber: getVal('MobileNumber'),
      street: getVal('Street'),
      city: getVal('City'),
      state: getVal('State'),
      postalCode: getVal('PostalCode'),
      country: getVal('Country'),
      dateOfBirth: getVal('DateOfBirth') != null
          ? parseServerDateTime(getVal('DateOfBirth').toString())
          : null,
      bankAccountName: getVal('BankAccountName'),
      bankAccountNumber: getVal('BankAccountNumber'),
      bankBSB: getVal('BankBSB'),
      bankName: getVal('BankName'),
      employmentStatus: getVal('EmploymentStatus'),
      jobRole: getVal('JobRole'),
      userRole: getVal('UserRole'),
      profilePicture: getVal('ProfilePicture'),
      nextOfKins: (getVal('NextOfKins') ?? getVal('NextOfKin') ?? getVal('ApprovedNextOfKin') ?? []) != null
          ? ((getVal('NextOfKins') ?? getVal('NextOfKin') ?? getVal('ApprovedNextOfKin') ?? []) as List<dynamic>)
              .map((kin) => NextOfKin.fromJson(kin))
              .toList()
          : [],
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
  final DateTime createdAt;
  final DateTime updatedAt;

  const NextOfKin({
    required this.nextOfKinId,
    required this.employeeId,
    required this.fullName,
    required this.relationship,
    required this.mobileNumber,
    required this.email,
    required this.address,
    required this.isPrimary,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NextOfKin.fromJson(Map<String, dynamic> json) {
    return NextOfKin(
      nextOfKinId: json['NextOfKinId'] ?? json['nextOfKinId'] ?? 0,
      employeeId: json['EmployeeId'] ?? json['employeeId'] ?? 0,
      fullName: json['FullName'] ?? json['fullName'] ?? '',
      relationship: json['Relationship'] ?? json['relationship'] ?? '',
      mobileNumber: json['MobileNumber'] ?? json['mobileNumber'] ?? '',
      email: json['Email'] ?? json['email'] ?? '',
      address: json['Address'] ?? json['address'] ?? '',
      isPrimary: json['IsPrimary'] ?? json['isPrimary'] ?? false,
      createdAt: json['CreatedAt'] != null
          ? parseServerDateTime(json['CreatedAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['UpdatedAt'] != null
          ? parseServerDateTime(json['UpdatedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
