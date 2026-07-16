// class ProfileUpdateRequest {
//   final String employeeId;
//   final String firstName;
//   final String lastName;
//   final String nic;
//   final String mobileNumber;
//   final String position;
//   final String address;
//   final String email;
//   final String dateOfBirth;
//   final String status;
//   final String requestStatus; // "pending", "approved", "rejected"
//   final String? rejectionReason;
//   final DateTime requestDate;

//   ProfileUpdateRequest({
//     required this.employeeId,
//     required this.firstName,
//     required this.lastName,
//     required this.nic,
//     required this.mobileNumber,
//     required this.position,
//     required this.address,
//     required this.email,
//     required this.dateOfBirth,
//     required this.status,
//     this.requestStatus = "pending",
//     this.rejectionReason,
//     required this.requestDate,
//   });

//   Map<String, dynamic> toJson() {
//     return {
//       'employeeId': employeeId,
//       'firstName': firstName,
//       'lastName': lastName,
//       'nic': nic,
//       'mobileNumber': mobileNumber,
//       'position': position,
//       'address': address,
//       'email': email,
//       'dateOfBirth': dateOfBirth,
//       'status': status,
//       'requestStatus': requestStatus,
//       'rejectionReason': rejectionReason,
//       'requestDate': requestDate.toIso8601String(),
//     };
//   }

//   factory ProfileUpdateRequest.fromJson(Map<String, dynamic> json) {
//     return ProfileUpdateRequest(
//       employeeId: json['employeeId'] ?? '',
//       firstName: json['firstName'] ?? '',
//       lastName: json['lastName'] ?? '',
//       nic: json['nic'] ?? '',
//       mobileNumber: json['mobileNumber'] ?? '',
//       position: json['position'] ?? '',
//       address: json['address'] ?? '',
//       email: json['email'] ?? '',
//       dateOfBirth: json['dateOfBirth'] ?? '',
//       status: json['status'] ?? '',
//       requestStatus: json['requestStatus'] ?? 'pending',
//       rejectionReason: json['rejectionReason'],
//       requestDate: json['requestDate'] != null
//           ? DateTime.parse(json['requestDate'])
//           : DateTime.now(),
//     );
//   }

//   // Helper method to create a request from current profile data
//   factory ProfileUpdateRequest.fromProfile(Map<String, dynamic> profile) {
//     return ProfileUpdateRequest(
//       employeeId: profile['employeeId'] ?? '',
//       firstName: profile['firstName'] ?? '',
//       lastName: profile['lastName'] ?? '',
//       nic: profile['nic'] ?? '',
//       mobileNumber: profile['mobileNumber'] ?? '',
//       position: profile['position'] ?? '',
//       address: profile['address'] ?? '',
//       email: profile['email'] ?? '',
//       dateOfBirth: profile['dateOfBirth'] ?? '',
//       status: profile['status'] ?? '',
//       requestDate: DateTime.now(),
//     );
//   }
// }