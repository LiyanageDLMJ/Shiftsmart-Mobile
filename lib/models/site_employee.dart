// import 'dart:math';
// import 'package:shiftsmart/models/site.dart';

// class SiteEmployee {
//   final int employeeId;
//   final String name;
//   final double? distance;
//   final double? clockInLat;
//   final double? clockInLng;
//   final bool isInside;
//   final String? clockInTime;

//   SiteEmployee({
//     required this.employeeId,
//     required this.name,
//     this.distance,
//     this.clockInLat,
//     this.clockInLng,
//     required this.isInside,
//     this.clockInTime,
//   });

//   factory SiteEmployee.fromJson(Map<String, dynamic> json, Site site) {
//     final lat = json['Latitude']?.toDouble();
//     final lng = json['Longitude']?.toDouble();

//     double? distance;
//     bool isInside = false;

//     final siteLat =
//         site.latitude != null ? double.tryParse(site.latitude!) : null;
//     final siteLng =
//         site.longitude != null ? double.tryParse(site.longitude!) : null;

//     print(' Site Coordinates: ${site.latitude}, ${site.longitude}');
//     print(' Parsed Site LatLng: $siteLat, $siteLng');

//     if (lat != null &&
//         lng != null &&
//         siteLat != null &&
//         siteLng != null &&
//         site.radius != null) {
//       distance = _calculateDistance(lat, lng, siteLat, siteLng);
//       isInside =
//           distance <= (site.radius! / 1000); // Convert radius from meters to km
//     }

//     return SiteEmployee(
//       employeeId: json['EmployeeId'],
//       name: json['EmployeeName'] ?? 'Employee ${json['EmployeeId']}',
//       clockInLat: lat,
//       clockInLng: lng,
//       distance: distance,
//       isInside: isInside,
//       clockInTime: json['ClockInTime'],
//     );
//   }

//   static double _calculateDistance(
//       double lat1, double lon1, double lat2, double lon2) {
//     const p = 0.017453292519943295; // Math.PI / 180
//     final a = 0.5 -
//         cos((lat2 - lat1) * p) / 2 +
//         cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
//     return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
//   }
// }

import 'dart:math';
import 'package:shiftsmart/models/site.dart';

class SiteEmployee {
  final int employeeId;
  final String name;
  final double? distance;
  final double? clockInLat;
  final double? clockInLng;
  final bool isInside;
  final String? clockInTime;
  final String? profilePicture;

  SiteEmployee({
    required this.employeeId,
    required this.name,
    this.distance,
    this.clockInLat,
    this.clockInLng,
    required this.isInside,
    this.clockInTime,
    this.profilePicture,
  });

  factory SiteEmployee.fromJson(Map<String, dynamic> json, Site site) {
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    // 1. Handle Field Names from "Active Locations" Endpoint (Attendance App)
    // The Attendance endpoint usually returns 'FullName', Projects returned 'EmployeeName'
    final name = (json['FullName'] ??
            json['fullName'] ??
            json['EmployeeName'] ??
            json['employeeName'] ??
            json['Name'] ??
            json['name'] ??
            'Unknown Employee')
        .toString();

    // 2. Handle Profile Picture
    // React code uses 'profilePicture' (camelCase) or from the object.
    // We will check multiple possibilities.
    final profilePic = json['ProfilePicture'] ??
        json['profilePicture'] ??
        json['ProfileImage'] ??
        json['profileImage'];

    final lat = parseDouble(json['Latitude'] ??
        json['latitude'] ??
        json['ClockInLat'] ??
        json['clockInLat'] ??
        json['CurrentLatitude'] ??
        json['currentLatitude']);
    final lng = parseDouble(json['Longitude'] ??
        json['longitude'] ??
        json['ClockInLng'] ??
        json['clockInLng'] ??
        json['CurrentLongitude'] ??
        json['currentLongitude']);

    // 3. Handle Pre-calculated Distance/Fence from Backend
    // The Attendance endpoint might calculate this for us (React code suggests it does)
    bool parseBool(dynamic value) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) return value.toLowerCase() == 'true';
      return false;
    }

    bool isInside = parseBool(json['IsInsideFence'] ?? json['isInsideFence']);
    double? distance = parseDouble(json['DistanceMetersFromSite'] ??
        json['distanceMetersFromSite'] ??
        json['Distance'] ??
        json['distance']);

    // If backend didn't provide calculation, do it manually
    if (json['IsInsideFence'] == null &&
        json['isInsideFence'] == null &&
        lat != null &&
        lng != null &&
        site.latitude != null &&
        site.longitude != null) {
      final siteLat = parseDouble(site.latitude);
      final siteLng = parseDouble(site.longitude);

      if (siteLat != null && siteLng != null) {
        // Calculate distance in KM
        double distKm = _calculateDistance(lat, lng, siteLat, siteLng);

        // If distance wasn't provided by API, use this
        distance ??=
            distKm; // keep as KM for internal logic if needed, or convert to M

        // Convert radius to KM
        double radiusInKm = (site.radius ?? 0) / 1000.0;
        isInside = distKm <= radiusInKm;
      }
    } else if (distance != null) {
      // If API gave us distance in meters, convert to KM for consistency if needed
      // But usually we just want to display it.
      // Let's store it as KM to match the UI logic: (dist * 1000).toStringAsFixed(0)
      distance = distance / 1000.0;
    }

    return SiteEmployee(
      employeeId: json['EmployeeId'] ?? 0,
      name: name,
      clockInLat: lat,
      clockInLng: lng,
      distance: distance,
      isInside: isInside,
      clockInTime: (json['ClockInTime'] ?? json['clockInTime'])?.toString(),
      profilePicture: profilePic,
    );
  }

  static double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }
}
