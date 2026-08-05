import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shiftsmart/services/employee_service.dart';

class SidenavProfileHeader extends StatefulWidget {
  final Map<String, dynamic> userProfile;
  final VoidCallback onTap;

  const SidenavProfileHeader({
    super.key,
    required this.userProfile,
    required this.onTap,
  });

  @override
  State<SidenavProfileHeader> createState() => _SidenavProfileHeaderState();
}

class _SidenavProfileHeaderState extends State<SidenavProfileHeader> {
  String? _resolvedImageUrl;
  String? _lastImageValue;
  int? _lastEmployeeId;

  @override
  Widget build(BuildContext context) {
    final imageValue = widget.userProfile['profilePicture'] ??
        widget.userProfile['ProfilePicture'];
    final employeeId = _employeeIdFrom(widget.userProfile);
    _resolveProfileImageUrl(employeeId, imageValue);
    final imageProvider = _profileImageProvider(
      _resolvedImageUrl ?? imageValue,
    );
    final fullName = _fullName(widget.userProfile);
    final role = _roleText(widget.userProfile);

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 52,
              backgroundColor: const Color(0xFFD7FFC0),
              backgroundImage: imageProvider,
              child: imageProvider == null
                  ? const Icon(
                      Icons.person,
                      color: Color(0xFF161622),
                      size: 62,
                    )
                  : null,
            ),
            const SizedBox(height: 14),
            Text(
              fullName,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                height: 1.15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              role,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF9A98A3),
                fontSize: 14,
                height: 1.15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  ImageProvider? _profileImageProvider(dynamic value) {
    final image = value?.toString().trim() ?? '';
    if (image.isEmpty) return null;

    if (image.startsWith('data:image')) {
      try {
        return MemoryImage(base64Decode(image.split(',').last));
      } catch (_) {
        return null;
      }
    }

    return NetworkImage(image);
  }

  int? _employeeIdFrom(Map<String, dynamic> profile) {
    final raw = profile['employeeId'] ??
        profile['EmployeeId'] ??
        profile['userId'] ??
        profile['UserId'];
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '');
  }

  void _resolveProfileImageUrl(int? employeeId, dynamic imageValue) {
    final image = imageValue?.toString().trim() ?? '';
    if (employeeId == null ||
        employeeId <= 0 ||
        image.isEmpty ||
        image.startsWith('data:image')) {
      return;
    }

    if (_lastEmployeeId == employeeId && _lastImageValue == image) return;
    _lastEmployeeId = employeeId;
    _lastImageValue = image;
    _resolvedImageUrl = null;

    EmployeeService().fetchProfilePictureDownloadUrl(employeeId).then((url) {
      if (!mounted || url == null || url.isEmpty) return;
      if (_lastEmployeeId != employeeId || _lastImageValue != image) return;
      setState(() => _resolvedImageUrl = url);
    });
  }

  String _fullName(Map<String, dynamic> profile) {
    final nameParts = [
      profile['firstName'] ?? profile['FirstName'],
      profile['middleName'] ?? profile['MiddleName'],
      profile['lastName'] ?? profile['LastName'],
    ]
        .map((part) => part?.toString().trim() ?? '')
        .where((part) => part.isNotEmpty)
        .toList();

    final fullName = nameParts.join(' ');
    if (fullName.isNotEmpty) return fullName;

    final directName =
        (profile['fullName'] ?? profile['FullName'])?.toString().trim() ?? '';
    if (directName.isNotEmpty) return directName;

    final username =
        (profile['userName'] ?? profile['UserName'])?.toString().trim() ?? '';
    if (username.isNotEmpty) return username;

    final email =
        (profile['email'] ?? profile['Email'])?.toString().trim() ?? '';
    if (email.isNotEmpty) return email;

    return 'No Name';
  }

  String _roleText(Map<String, dynamic> profile) {
    final jobRole =
        (profile['jobRole'] ?? profile['JobRole'])?.toString().trim() ?? '';
    if (jobRole.isNotEmpty) return jobRole;

    final userRole =
        (profile['userRole'] ?? profile['UserRole'])?.toString().trim() ?? '';
    if (userRole.isNotEmpty) return _titleCase(userRole);

    return 'No Position';
  }

  String _titleCase(String value) {
    return value
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}
