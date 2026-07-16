import 'package:shiftsmart/models/project.dart';

class Site {
  final int siteId;
  final String siteName;
  final String? address;
  // We keep these as String? so the rest of your app doesn't break
  final String? latitude;
  final String? longitude;
  final String? geoFenceType;
  final String? geoCoordinates;
  final double? radius;
  final int? projectId;
  final Project? project;

  Site({
    required this.siteId,
    required this.siteName,
    this.address,
    this.latitude,
    this.longitude,
    this.geoFenceType,
    this.geoCoordinates,
    this.radius,
    this.projectId,
    this.project,
  });

  factory Site.fromJson(Map<String, dynamic> json) {
    return Site(
      siteId: json['SiteId'] ?? json['siteId'] ?? 0,
      siteName: json['SiteName'] ?? json['siteName'] ?? '',
      address: json['Address'] ?? json['address'],
      // --- This is the fix ---
      // The server may return coordinates as separate fields or as a geoCoordinates string.
      latitude: _extractLatitude(json),
      longitude: _extractLongitude(json),
      // --- End of fix ---

      geoFenceType: json['GeoFenceType'] ?? json['geoFenceType'] ?? '',
      geoCoordinates: json['GeoCoordinates'] ?? json['geoCoordinates'] ?? '',
      // This logic was also made safer to prevent crashes
      radius: (json['Radius'] as num?)?.toDouble() ?? (json['radius'] as num?)?.toDouble(),
      projectId: json['ProjectId'] ?? json['projectId'] ?? 0,
      project: (json['Project'] ?? json['project']) != null 
          ? Project.fromJson(json['Project'] ?? json['project']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "projectId": projectId,
      "siteName": siteName,
      "address": address,
      // Your app already stores these as Strings, so this is correct
      "latitude": latitude,
      "longitude": longitude,
      "geoFenceType": geoFenceType,
      "geoCoordinates": geoCoordinates,
      "radius": radius,
    };
  }

  static String? _extractLatitude(Map<String, dynamic> json) {
    final latitude = json['Latitude']?.toString() ?? json['latitude']?.toString();
    final geoCoordinates = json['GeoCoordinates'] ?? json['geoCoordinates'];

    if (latitude != null && latitude.trim().isNotEmpty) {
      return latitude.trim();
    }

    if (geoCoordinates != null) {
      final coords = geoCoordinates.toString().split(RegExp(r'[ ,;]+'));
      if (coords.length >= 2) {
        return coords[0].trim();
      }
    }

    return null;
  }

  static String? _extractLongitude(Map<String, dynamic> json) {
    final longitude = json['Longitude']?.toString() ?? json['longitude']?.toString();
    final geoCoordinates = json['GeoCoordinates'] ?? json['geoCoordinates'];

    if (longitude != null && longitude.trim().isNotEmpty) {
      return longitude.trim();
    }

    if (geoCoordinates != null) {
      final coords = geoCoordinates.toString().split(RegExp(r'[ ,;]+'));
      if (coords.length >= 2) {
        return coords[1].trim();
      }
    }

    return null;
  }
}
