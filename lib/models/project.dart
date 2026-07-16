import 'package:shiftsmart/models/site.dart';

class Project {
  final int projectId;
  final String name;
  final int estimatedTime;
  final String location;
  final String description;
  final String additionalRemark;
  final String projectDue;
  final String startDate;
  final String endDate;
  final String companyName;
  late String status;
  final List<Site> sites;

  Project({
    required this.projectId,
    required this.name,
    required this.estimatedTime,
    required this.location,
    required this.description,
    required this.additionalRemark,
    required this.projectDue,
    required this.startDate,
    required this.endDate,
    required this.companyName,
    required this.status,
    required this.sites, 
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      projectId: json['ProjectId'] ?? json['projectId'] ?? 0, 
      name: json['Name'] ?? json['name'] ?? 'Unnamed Project',
      estimatedTime: json['EstimatedTime'] ?? json['estimatedTime'] ?? 0,
      location: json['Location'] ?? json['location'] ?? 'Unknown Location',
      description: json['Description'] ?? json['description'] ?? 'No Description',
      additionalRemark: json['AdditionalRemarks'] ?? json['additionalRemarks'] ?? json['additionalRemark'] ?? 'No Remarks',
      projectDue: json['ProjectDue'] ?? json['projectDue'] ?? 'No Due Date',
      startDate: json['StartDate'] ?? json['startDate'] ?? 'No Start Date',
      endDate: json['EndDate'] ?? json['endDate'] ?? 'No End Date',
      companyName: json['CompanyName'] ?? json['companyName'] ?? 'No Company Name',
      status: json['Status'] ?? json['status'] ?? 'No Status',
      sites: ((json['Sites'] ?? json['sites']) as List<dynamic>?)
              ?.map((e) => Site.fromJson(e))
              .toList() ??
          [],
    );
  }
}
