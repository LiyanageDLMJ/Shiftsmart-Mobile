class Company {
  final int id;
  final String name;
  final String address;
  final String phoneNumber;
  final String ContactPerson;

  Company(
      {required this.id,
      required this.name,
      required this.address,
      required this.phoneNumber,
      required this.ContactPerson});

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['CompanyId'] ?? json['companyId'] ?? 0,
      name: (json['Name'] ?? json['name'] ?? '').toString(),
      address: (json['Address'] ?? json['address'] ?? '').toString(),
      phoneNumber:
          (json['ContactNumber'] ?? json['contactNumber'] ?? '').toString(),
      ContactPerson:
          (json['ContactPerson'] ?? json['contactPerson'] ?? '').toString(),
    );
  }
}
