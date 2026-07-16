import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:shiftsmart/services/super_admin_service.dart';

/// Shared state that holds the currently selected tenant across
/// all manager screens. When [setTenant] is called (from the Dashboard
/// dropdown or the Bottomnavbar picker), every Consumer<TenantProvider>
/// widget rebuilds automatically.
class TenantProvider with ChangeNotifier {
  final SuperAdminService _superAdminService = SuperAdminService();

  Map<String, dynamic>? _selectedTenant; // Full tenant map from API
  String _selectedOrganization = ''; // Display name
  List<Map<String, dynamic>> _tenants = []; // All available tenants

  bool _isSwitching = false; // Switching-in-progress guard

  String _tenantNameFrom(Map<String, dynamic> tenant) {
    return (tenant['name'] ??
            tenant['Name'] ??
            tenant['tenantName'] ??
            tenant['TenantName'] ??
            tenant['organizationName'] ??
            '')
        .toString();
  }

  int? _tenantIdFrom(Map<String, dynamic> tenant) {
    final rawId = tenant['tenantId'] ??
        tenant['TenantId'] ??
        tenant['id'] ??
        tenant['ID'] ??
        tenant['tenantID'] ??
        tenant['TenantID'] ??
        tenant['tenant_id'];
    if (rawId is int) return rawId;
    return int.tryParse(rawId?.toString() ?? '');
  }

  List<Map<String, dynamic>> _dedupeTenants(List<Map<String, dynamic>> tenants) {
    final seenIds = <int>{};
    final seenNames = <String>{};
    final unique = <Map<String, dynamic>>[];

    for (final tenant in tenants) {
      final name = _tenantNameFrom(tenant).trim().toLowerCase();
      final id = _tenantIdFrom(tenant);
      if (id != null) {
        if (seenIds.contains(id)) continue;
        seenIds.add(id);
      }
      if (name.isNotEmpty) {
        if (seenNames.contains(name)) continue;
        seenNames.add(name);
      }
      unique.add(tenant);
    }

    return unique;
  }

  // ── Getters ──────────────────────────────────────────────────────────────
  Map<String, dynamic>? get selectedTenant => _selectedTenant;
  String get selectedOrganization => _selectedOrganization;
  List<Map<String, dynamic>> get tenants => List.unmodifiable(_tenants);
  bool get isSwitching => _isSwitching;
  bool get hasTenant => _selectedOrganization.isNotEmpty;

  // Feature flags – populated from the selected tenant's API data.
  // If the API doesn't return a feature list, ALL features default to enabled.
  Set<String> _enabledFeatures = {}; // empty = "all enabled" sentinel
  bool get allFeaturesEnabled => _enabledFeatures.isEmpty;

  // ── Blocked endpoints (403 tracking) ──────────────────────────────────────
  /// Endpoint paths that returned 403 Forbidden for the current tenant.
  final Set<String> _blockedEndpoints = {};
  Set<String> get blockedEndpoints => Set.unmodifiable(_blockedEndpoints);

  /// Record an endpoint as blocked (called from ApiClient on 403).
  void addBlockedEndpoint(String endpointPath) {
    final normalised = endpointPath.toLowerCase();
    if (_blockedEndpoints.add(normalised)) {
      notifyListeners();
    }
  }

  /// Clear all blocked endpoints (called on tenant switch).
  void clearBlockedEndpoints() {
    if (_blockedEndpoints.isNotEmpty) {
      _blockedEndpoints.clear();
      notifyListeners();
    }
  }

  /// Returns true when at least one blocked endpoint maps to the given
  /// bottom-nav index.
  ///
  /// Mapping:
  ///   0 = Dashboard  – no gating
  ///   1 = Projects   – /company/, /site/, /project/
  ///   2 = Jobs       – /job/
  ///   3 = Employees  – (none currently)
  ///   4 = Leave      – (none currently)
  bool isNavIndexBlocked(int index) {
    if (_blockedEndpoints.isEmpty) return false;
    switch (index) {
      case 1:
        return _blockedEndpoints.any((e) =>
            e.contains('/company/') ||
            e.contains('/site/') ||
            e.contains('/project/'));
      case 3:
        return _blockedEndpoints.any((e) => e.contains('/employee/'));
      case 4:
        return _blockedEndpoints.any((e) => e.contains('/leave/'));
      default:
        return false;
    }
  }

  /// Returns true if any blocked endpoint contains the given keyword.
  bool isEndpointBlocked(String keyword) {
    if (_blockedEndpoints.isEmpty) return false;
    final lowerKeyword = keyword.toLowerCase();
    return _blockedEndpoints.any((e) => e.contains(lowerKeyword));
  }

  /// Returns true when a feature is enabled for the current tenant.
  /// Returns true by default when no feature-list has been loaded yet.
  bool isFeatureEnabled(String featureKey) {
    if (_enabledFeatures.isEmpty) return true; // no restrictions loaded
    return _enabledFeatures.contains(featureKey.toLowerCase());
  }

  /// Explicitly update the feature list (called from SuperAdminManageFeatures
  /// after a successful toggle, so all screens react without a page reload).
  void setEnabledFeatures(Set<String> features) {
    _enabledFeatures = features.map((f) => f.toLowerCase()).toSet();
    notifyListeners();
  }

  // ── Load tenants from backend ─────────────────────────────────────────────
  Future<void> loadTenants() async {
    try {
      // Try to load from cache first for instant UI
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('cached_tenants');
      if (cached != null && _tenants.isEmpty) {
        _tenants = List<Map<String, dynamic>>.from(jsonDecode(cached));
        notifyListeners();
      }

      final fetched = await _superAdminService.getAllTenants();
      if (fetched.isNotEmpty) {
        _tenants = _dedupeTenants(
          fetched.map((t) => t as Map<String, dynamic>).toList(),
        );
        await prefs.setString('cached_tenants', jsonEncode(_tenants));
      }

      // Auto-select first tenant if none is selected
      if (_selectedOrganization.isEmpty && _tenants.isNotEmpty) {
        final first = _tenants.first;
        _selectedOrganization = (first['name'] ??
                first['Name'] ??
                first['tenantName'] ??
                first['TenantName'] ??
                first['organizationName'] ??
                'Unnamed')
            .toString();
        _selectedTenant = first;
        await _saveSelectedTenant(first);
        _parseFeatures(first);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('[TenantProvider] Error loading tenants: $e');
    }
  }

  void setTenants(List<Map<String, dynamic>> tenants) {
    _tenants = _dedupeTenants(tenants);
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('cached_tenants', jsonEncode(_tenants));
    });

    // Auto-select first tenant if none is currently selected
    if (_selectedOrganization.isEmpty && _tenants.isNotEmpty) {
      final first = _tenants.first;
      _selectedOrganization = (first['name'] ??
              first['Name'] ??
              first['tenantName'] ??
              first['TenantName'] ??
              first['organizationName'] ??
              'Unnamed')
          .toString();
      _selectedTenant = first;
      _saveSelectedTenant(first);
      _parseFeatures(first);
    }
    notifyListeners();
  }

  // ── Initialise from current token (call once after login) ─────────────────
  void initFromCurrentTenant(
      String tenantName, Map<String, dynamic>? tenantMap) {
    _selectedOrganization = tenantName;
    _selectedTenant = tenantMap;
    _saveSelectedTenant(tenantMap);
    _parseFeatures(tenantMap);

    // Ensure this tenant is in our list so it shows up in the UI dropdown
    if (tenantMap != null) {
      final exists = _tenants.any((t) =>
          _tenantNameFrom(t).toLowerCase() == tenantName.toLowerCase());
      if (!exists) {
        _tenants = _dedupeTenants([..._tenants, tenantMap]);
      }
    }

    notifyListeners();
  }

  // ── Switch tenant (calls backend + notifies listeners) ───────────────────
  Future<bool> switchTenant(Map<String, dynamic> tenant) async {
    final name = (tenant['name'] ??
            tenant['Name'] ??
            tenant['tenantName'] ??
            tenant['TenantName'] ??
            tenant['organizationName'] ??
            'Unnamed')
        .toString();
    final tenantId = tenant['tenantId'] ??
        tenant['TenantId'] ??
        tenant['id'] ??
        tenant['ID'];

    // Optimistically update display name so UI is instant
    _selectedOrganization = name;
    _selectedTenant = tenant;
    _saveSelectedTenant(tenant);
    _isSwitching = true;
    _blockedEndpoints.clear(); // reset on tenant switch
    notifyListeners();

    bool success = false;
    if (tenantId != null) {
      try {
        final result = await _superAdminService.switchTenant(tenantId);
        if (result != null) {
          success = true;
          // Use the canonical name from the backend if available
          final backendName = (result['tenantName'] ??
                  result['TenantName'] ??
                  result['name'] ??
                  result['Name'])
              ?.toString();
          if (backendName != null && backendName.isNotEmpty) {
            _selectedOrganization = backendName;
          }
        }
      } catch (e) {
        debugPrint('[TenantProvider] switchTenant error: $e');
      }
    }

    _isSwitching = false;
    if (success && tenantId != null) {
      // Reload full tenant details to get feature list
      try {
        final details = await _superAdminService.getTenantDetails(
          int.tryParse(tenantId.toString()) ?? 0,
        );
        if (details != null) {
          _selectedTenant = details;
          _saveSelectedTenant(details);
          _parseFeatures(details);
        }
      } catch (_) {}
    }
    notifyListeners();
    return success;
  }

  // ── Parse enabledFeatures from a tenant map ───────────────────────────────
  void _parseFeatures(Map<String, dynamic>? map) {
    if (map == null) {
      _enabledFeatures = {};
      return;
    }
    final raw = map['enabledFeatures'] ??
        map['EnabledFeatures'] ??
        map['features'] ??
        map['Features'];
    if (raw is List && raw.isNotEmpty) {
      _enabledFeatures = raw.map((f) => f.toString().toLowerCase()).toSet();
    } else {
      _enabledFeatures = {}; // empty = all enabled
    }
  }

  Future<void> _saveSelectedTenant(Map<String, dynamic>? tenant) async {
    if (tenant == null) return;
    final rawId = tenant['tenantId'] ??
        tenant['TenantId'] ??
        tenant['id'] ??
        tenant['ID'] ??
        tenant['tenantID'] ??
        tenant['TenantID'] ??
        tenant['tenant_id'];
    final tenantId =
        rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');

    final tenantName = (tenant['name'] ??
            tenant['Name'] ??
            tenant['tenantName'] ??
            tenant['TenantName'] ??
            tenant['organizationName'] ??
            '')
        .toString();

    final prefs = await SharedPreferences.getInstance();
    if (tenantId != null && tenantId != 0) {
      await prefs.setInt('selectedTenantId', tenantId);
      await prefs.setInt('currentTenantId', tenantId);
      await prefs.setInt('tenantId', tenantId);
    }
    if (tenantName.isNotEmpty) {
      await prefs.setString('selectedTenantName', tenantName);
    }
  }

  // ── Utility: find tenant map by organisation name ─────────────────────────
  Map<String, dynamic>? findTenantByName(String name) {
    try {
      return _tenants.firstWhere(
        (t) =>
            (t['name'] ?? t['Name'] ?? '').toString().toLowerCase() ==
            name.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }
}
