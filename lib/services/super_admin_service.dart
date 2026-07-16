import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';

class SuperAdminService {
  final ApiClient _apiClient = ApiClient();
  final _storage = const FlutterSecureStorage();

  String get baseUrl => dotenv.env['BASE_URL'] ?? '';

  // Super Admin Keys
  String get createTenantKey => dotenv.env['SUPER_ADMIN_CREATE_TENANT_KEY'] ?? '';
  String get switchTenantKey => dotenv.env['TENANT_SWITCH_KEY'] ?? '';
  String get toggleFeatureKey => dotenv.env['ADMIN_TOGGLE_FEATURE_KEY'] ?? '';
  String get deactivateTenantKey => dotenv.env['SUPER_ADMIN_DEACTIVATE_TENANT_KEY'] ?? '';
  String get reactivateTenantKey => dotenv.env['SUPER_ADMIN_REACTIVATE_TENANT_KEY'] ?? '';
  String get getTenantDetailsKey => dotenv.env['SUPER_ADMIN_GET_TENANT_DETAILS_KEY'] ?? '';
  String get globalAnnouncementKey => dotenv.env['SUPER_ADMIN_GLOBAL_ANNOUNCEMENT_KEY'] ?? '';
  String get activeAnnouncementsKey => dotenv.env['GET_ACTIVE_ANNOUNCEMENTS_KEY'] ?? '';
  String get getAllTenantsKey => dotenv.env['SUPER_ADMIN_GET_ALL_TENANTS_KEY'] ?? '';
  String get softDeleteTenantKey => dotenv.env['SUPER_ADMIN_SOFT_DELETE_TENANT_KEY'] ?? '';
  String get restoreTenantKey => dotenv.env['SUPER_ADMIN_RESTORE_TENANT_KEY'] ?? '';
  String get recentlyDeletedTenantsKey => dotenv.env['SUPER_ADMIN_GET_RECENTLY_DELETED_TENANTS_KEY'] ?? '';
  String get impersonateUserKey => dotenv.env['SUPER_ADMIN_IMPERSONATE_USER_KEY'] ?? '';
  String get stopImpersonationKey => dotenv.env['SUPER_ADMIN_REVERSE_IMPERSONATE_KEY'] ?? '';
  String get announcementHistoryKey => dotenv.env['SUPER_ADMIN_ANNOUNCEMENT_HISTORY_KEY'] ?? '';
  String get deleteAnnouncementKey => dotenv.env['SUPER_ADMIN_DELETE_ANNOUNCEMENT_KEY'] ?? '';

  /// Create a new tenant
  Future<Map<String, dynamic>?> createTenant(Map<String, dynamic> tenantData) async {
    final url = '$baseUrl/superadmin/tenants/create?code=$createTenantKey';
    try {
      final response = await _apiClient.post(url, body: tenantData, useAuth: true);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Switch to a target tenant
  Future<Map<String, dynamic>?> switchTenant(dynamic targetTenantId) async {
    final url = '$baseUrl/tenant/switch/$targetTenantId?code=$switchTenantKey';
    try {
      final response = await _apiClient.post(url, useAuth: true);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newToken = data['token'] ?? data['Token'];
        if (newToken != null) {
          await _storage.write(key: 'appToken', value: newToken);
        }
        return data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Toggle a feature for a tenant
  Future<bool> toggleFeature(Map<String, dynamic> featureData) async {
    final url = '$baseUrl/superadmin/features/toggle?code=$toggleFeatureKey';
    try {
      final response = await _apiClient.post(url, body: featureData, useAuth: true);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Deactivate a tenant
  Future<bool> deactivateTenant(Map<String, dynamic> data) async {
    final url = '$baseUrl/superadmin/tenants/deactivate?code=$deactivateTenantKey';
    try {
      final response = await _apiClient.post(url, body: data, useAuth: true);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Reactivate a tenant
  Future<bool> reactivateTenant(Map<String, dynamic> data) async {
    final url = '$baseUrl/superadmin/tenants/reactivate?code=$reactivateTenantKey';
    try {
      final response = await _apiClient.post(url, body: data, useAuth: true);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get specific tenant details
  Future<Map<String, dynamic>?> getTenantDetails(dynamic tenantId) async {
    final url = '$baseUrl/superadmin/tenants/$tenantId?code=$getTenantDetailsKey';
    try {
      final response = await _apiClient.get(url, useAuth: true);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Create a global announcement
  Future<Map<String, dynamic>?> createGlobalAnnouncement(Map<String, dynamic> announcementData) async {
    final url = '$baseUrl/superadmin/announcements/create?code=$globalAnnouncementKey';
    try {
      final response = await _apiClient.post(url, body: announcementData, useAuth: true);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get active announcements
  Future<List<dynamic>> getActiveAnnouncements({int? tenantId}) async {
    Uri uri = Uri.parse('$baseUrl/announcements/active');
    Map<String, String> queryParams = {'code': activeAnnouncementsKey};
    if (tenantId != null && tenantId != 0) queryParams['tenantId'] = tenantId.toString();
    
    uri = uri.replace(queryParameters: queryParams);

    try {
      final response = await _apiClient.get(uri.toString(), useAuth: true);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) return decoded;
        if (decoded is Map && (decoded['announcements'] != null || decoded['Announcements'] != null)) {
          return decoded['announcements'] ?? decoded['Announcements'];
        }
        return [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get all tenants
  Future<List<dynamic>> getAllTenants() async {
    final url = '$baseUrl/superadmin/tenants/all?code=$getAllTenantsKey';
    try {
      final response = await _apiClient.get(url, useAuth: true, showDialog: false);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded;
        } else if (decoded is Map && (decoded['tenants'] != null || decoded['Tenants'] != null)) {
          return decoded['tenants'] ?? decoded['Tenants'];
        }
        return [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Soft delete a tenant
  Future<bool> softDeleteTenant(dynamic tenantId) async {
    final url = '$baseUrl/superadmin/tenants/$tenantId/soft-delete?code=$softDeleteTenantKey';
    try {
      final response = await _apiClient.delete(url, useAuth: true);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Restore a deleted tenant
  Future<bool> restoreTenant(dynamic tenantId) async {
    final url = '$baseUrl/superadmin/tenants/$tenantId/restore?code=$restoreTenantKey';
    try {
      final response = await _apiClient.post(url, useAuth: true);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get recently deleted tenants (last 30 days)
  Future<List<dynamic>> getRecentlyDeletedTenants() async {
    final url = '$baseUrl/superadmin/tenants/deleted/recent?code=$recentlyDeletedTenantsKey';
    try {
      final response = await _apiClient.get(url, useAuth: true);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) return decoded;
        if (decoded is Map && (decoded['tenants'] != null || decoded['Tenants'] != null)) {
          return decoded['tenants'] ?? decoded['Tenants'];
        }
        return [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Impersonate a user
  Future<Map<String, dynamic>?> impersonateUser(Map<String, dynamic> impersonateData) async {
    final url = '$baseUrl/superadmin/impersonate?code=$impersonateUserKey';
    try {
      final response = await _apiClient.post(url, body: impersonateData, useAuth: true);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newToken = data['token'] ?? data['Token'];
        if (newToken != null) {
          await _storage.write(key: 'appToken', value: newToken);
        }
        return data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Stop impersonation
  Future<Map<String, dynamic>?> stopImpersonation() async {
    final url = '$baseUrl/superadmin/impersonate/stop?code=$stopImpersonationKey';
    try {
      final response = await _apiClient.post(url, useAuth: true);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newToken = data['token'] ?? data['Token'];
        if (newToken != null) {
          await _storage.write(key: 'appToken', value: newToken);
        }
        return data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get announcement history
  Future<List<dynamic>> getAnnouncementsHistory() async {
    final url = '$baseUrl/superadmin/announcements/history?code=$announcementHistoryKey';
    try {
      final response = await _apiClient.get(url, useAuth: true);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Delete an announcement
  Future<bool> deleteAnnouncement(int id) async {
    final url = '$baseUrl/superadmin/announcements/$id?code=$deleteAnnouncementKey';
    try {
      final response = await _apiClient.delete(url, useAuth: true);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
