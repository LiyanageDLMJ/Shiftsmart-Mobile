import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shiftsmart/providers/tenant_provider.dart';
import 'package:shiftsmart/services/super_admin_service.dart';
import 'package:shiftsmart/utils/fullscreen_helper.dart';
import 'package:shiftsmart/widgets/background.dart';
import 'package:shiftsmart/widgets/uppernavbar.dart';
import 'package:shiftsmart/widgets/sidenav.dart';

// ---------------------------------------------------------------------------
// Feature definition – each entry maps a display name to the API feature key
// (the value sent to the toggle endpoint as `featureKey`).
// ---------------------------------------------------------------------------
class _FeatureDef {
  final String name;
  final String key;
  final String description;
  final IconData icon;

  const _FeatureDef({
    required this.name,
    required this.key,
    required this.description,
    required this.icon,
  });
}

const List<_FeatureDef> _allFeatures = [
  _FeatureDef(
    name: 'Job Management',
    key: 'job_management',
    description: 'Create, assign and track jobs across projects.',
    icon: Icons.work_outline_rounded,
  ),
  _FeatureDef(
    name: 'Shift Scheduling',
    key: 'shift_scheduling',
    description: 'Plan and publish employee shift rosters.',
    icon: Icons.schedule_rounded,
  ),
  _FeatureDef(
    name: 'Leave Management',
    key: 'leave_management',
    description: 'Handle leave requests, approvals and balances.',
    icon: Icons.event_busy_rounded,
  ),
  _FeatureDef(
    name: 'Attendance Tracking',
    key: 'attendance_tracking',
    description: 'Real-time clock-in / clock-out monitoring.',
    icon: Icons.fingerprint_rounded,
  ),
  _FeatureDef(
    name: 'Performance Reports',
    key: 'performance_reports',
    description: 'Employee performance analytics and scoring.',
    icon: Icons.bar_chart_rounded,
  ),
  _FeatureDef(
    name: 'Location Tracking',
    key: 'location_tracking',
    description: 'Live GPS tracking of field employees.',
    icon: Icons.location_on_rounded,
  ),
  _FeatureDef(
    name: 'Site Management',
    key: 'site_management',
    description: 'Manage multiple work sites and their details.',
    icon: Icons.domain_rounded,
  ),
  _FeatureDef(
    name: 'Notifications',
    key: 'notifications',
    description: 'Push & in-app notifications for all events.',
    icon: Icons.notifications_outlined,
  ),
  _FeatureDef(
    name: 'Project Management',
    key: 'project_management',
    description: 'Manage projects, work sites, and partner companies.',
    icon: Icons.inventory_2_rounded,
  ),
];

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------
class SuperAdminManageFeatures extends StatefulWidget {
  /// The tenant this screen is managing.
  /// Expected keys: 'name'/'Name', 'tenantId'/'TenantId'/'id'/'ID', etc.
  final Map<String, dynamic> tenant;

  const SuperAdminManageFeatures({super.key, required this.tenant});

  @override
  State<SuperAdminManageFeatures> createState() =>
      _SuperAdminManageFeaturesState();
}

class _SuperAdminManageFeaturesState extends State<SuperAdminManageFeatures>
    with SingleTickerProviderStateMixin {
  final SuperAdminService _service = SuperAdminService();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  bool _isLoading = true;
  bool _isTenantActive = true;

  // feature key → enabled state
  final Map<String, bool> _featureState = {};
  // feature key → currently toggling
  final Map<String, bool> _toggling = {};

  bool _deactivating = false;

  // ── Helpers ───────────────────────────────────────────────────────────────
  String get _tenantName =>
      (widget.tenant['name'] ??
          widget.tenant['Name'] ??
          widget.tenant['tenantName'] ??
          widget.tenant['TenantName'] ??
          'Unknown Tenant')
          .toString();

  int get _tenantId {
    final raw = widget.tenant['tenantId'] ??
        widget.tenant['TenantId'] ??
        widget.tenant['id'] ??
        widget.tenant['ID'];
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  @override
  void initState() {
    super.initState();
    enableFullScreen();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeInOut);

    _loadTenantDetails();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadTenantDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final details = await _service.getTenantDetails(_tenantId);
      if (!mounted) return;

      if (details != null) {
        // Resolve active status
        final status = (details['status'] ?? details['Status'] ?? '').toString();
        _isTenantActive = status.toLowerCase() == 'active' ||
            status.toLowerCase() == 'true' ||
            status == '1';

        // Resolve enabled features from the API response
        final rawFeatures = details['enabledFeatures'] ??
            details['EnabledFeatures'] ??
            details['features'] ??
            details['Features'];

        final List<String> enabledKeys = [];
        if (rawFeatures is List) {
          for (final f in rawFeatures) {
            enabledKeys.add(f.toString().toLowerCase());
          }
        }

        for (final feat in _allFeatures) {
          _featureState[feat.key] = enabledKeys.isEmpty
              ? true // if API doesn't return feature list, default all enabled
              : enabledKeys.contains(feat.key);
        }
      } else {
        // Fallback: default all on
        for (final feat in _allFeatures) {
          _featureState[feat.key] = true;
        }
      }
    } catch (_) {
      for (final feat in _allFeatures) {
        _featureState[feat.key] = true;
      }
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
    _animController.forward();
  }

  Future<void> _toggleFeature(_FeatureDef feat, bool newValue) async {
    setState(() => _toggling[feat.key] = true);

    final success = await _service.toggleFeature({
      'tenantId': _tenantId,
      'featureKey': feat.key,
      'enabled': newValue,
    });

    if (!mounted) return;

    setState(() {
      _toggling[feat.key] = false;
      if (success) {
        _featureState[feat.key] = newValue;

        // — Propagate to TenantProvider so all screens react live —
        final enabled = _featureState.entries
            .where((e) => e.value)
            .map((e) => e.key)
            .toSet();
        context.read<TenantProvider>().setEnabledFeatures(enabled);

        _showSnack(
          newValue ? '${feat.name} enabled' : '${feat.name} disabled',
          newValue ? Colors.greenAccent : Colors.orangeAccent,
        );
      } else {
        _showSnack('Failed to update ${feat.name}. Try again.', Colors.redAccent);
      }
    });
  }

  Future<void> _handleTenantActiveToggle() async {
    final confirm = await _confirmDialog(
      title: _isTenantActive ? 'Deactivate Tenant?' : 'Reactivate Tenant?',
      message: _isTenantActive
          ? 'This will deactivate "$_tenantName". All users will lose access.'
          : 'This will reactivate "$_tenantName". Users will regain access.',
      confirmLabel: _isTenantActive ? 'Deactivate' : 'Reactivate',
      isDestructive: _isTenantActive,
    );
    if (confirm != true) return;

    setState(() => _deactivating = true);

    bool success;
    if (_isTenantActive) {
      success = await _service.deactivateTenant({'tenantId': _tenantId});
    } else {
      success = await _service.reactivateTenant({'tenantId': _tenantId});
    }

    if (!mounted) return;
    setState(() {
      _deactivating = false;
      if (success) {
        _isTenantActive = !_isTenantActive;
        _showSnack(
          _isTenantActive ? 'Tenant reactivated' : 'Tenant deactivated',
          _isTenantActive ? Colors.greenAccent : Colors.orangeAccent,
        );
      } else {
        _showSnack('Action failed. Please try again.', Colors.redAccent);
      }
    });
  }

  Future<bool?> _confirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C2230),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(message,
            style: const TextStyle(color: Colors.white70, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              confirmLabel,
              style: TextStyle(
                color: isDestructive ? Colors.redAccent : Colors.greenAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── UI ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const Sidenav(),
      backgroundColor: const Color(0xFF1C2230),
      appBar: const Uppernavbar(showBackButton: true),
      body: Stack(
        children: [
          const Positioned.fill(child: Background()),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF724584)),
            )
          else
            FadeTransition(
              opacity: _fadeAnim,
              child: RefreshIndicator(
                onRefresh: _loadTenantDetails,
                color: const Color(0xFF724584),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Hero tenant header ─────────────────────────────
                      _buildTenantHeader(),
                      const SizedBox(height: 20),

                      // ── Tenant active / deactivate card ───────────────
                      _buildTenantStatusCard(),
                      const SizedBox(height: 24),

                      // ── Section title: Features ───────────────────────
                      _buildSectionTitle('Premium Features'),
                      const SizedBox(height: 6),
                      const Text(
                        'Toggle features on or off for this tenant.',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                      const SizedBox(height: 14),

                      // ── Feature toggle grid ───────────────────────────
                      ..._allFeatures.map(_buildFeatureTile),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Tenant header ─────────────────────────────────────────────────────────
  Widget _buildTenantHeader() {
    final initials = _initials(_tenantName);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A3B5A), Color(0xFF1C2A45)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2DA6FF), Color(0xFF3C5AFF)],
              ),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tenantName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tenant ID: $_tenantId',
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 8),
                _buildStatusPill(),
              ],
            ),
          ),
          // Crown badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7A5C00), Color(0xFFB8880A)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.workspace_premium_rounded,
                    color: Color(0xFFFFD700), size: 14),
                SizedBox(width: 4),
                Text(
                  'SUPER ADMIN',
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (_isTenantActive ? Colors.green : Colors.orange).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (_isTenantActive ? Colors.greenAccent : Colors.orangeAccent)
              .withOpacity(0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: _isTenantActive ? Colors.greenAccent : Colors.orangeAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            _isTenantActive ? 'Active' : 'Deactivated',
            style: TextStyle(
              color: _isTenantActive ? Colors.greenAccent : Colors.orangeAccent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Tenant activate / deactivate card ─────────────────────────────────────
  Widget _buildTenantStatusCard() {
    final isActive = _isTenantActive;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isActive
              ? [
                  const Color.fromARGB(60, 255, 60, 60),
                  const Color.fromARGB(40, 180, 0, 0),
                ]
              : [
                  const Color.fromARGB(60, 0, 200, 80),
                  const Color.fromARGB(40, 0, 140, 50),
                ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive
              ? Colors.redAccent.withOpacity(0.4)
              : Colors.greenAccent.withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isActive ? Colors.redAccent : Colors.greenAccent)
                  .withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isActive
                  ? Icons.power_settings_new_rounded
                  : Icons.check_circle_outline_rounded,
              color: isActive ? Colors.redAccent : Colors.greenAccent,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isActive ? 'Deactivate Tenant' : 'Reactivate Tenant',
                  style: TextStyle(
                    color: isActive ? Colors.redAccent : Colors.greenAccent,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isActive
                      ? 'Disable all access for this tenant organisation.'
                      : 'Restore access for this tenant organisation.',
                  style:
                      const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _deactivating
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : GestureDetector(
                  onTap: _handleTenantActiveToggle,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: (isActive ? Colors.redAccent : Colors.greenAccent)
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive
                            ? Colors.redAccent.withOpacity(0.6)
                            : Colors.greenAccent.withOpacity(0.6),
                      ),
                    ),
                    child: Text(
                      isActive ? 'Deactivate' : 'Reactivate',
                      style: TextStyle(
                        color:
                            isActive ? Colors.redAccent : Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  // ── Feature toggle tile ───────────────────────────────────────────────────
  Widget _buildFeatureTile(_FeatureDef feat) {
    final isEnabled = _featureState[feat.key] ?? true;
    final isToggling = _toggling[feat.key] ?? false;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isEnabled
              ? [
                  const Color.fromARGB(180, 30, 42, 65),
                  const Color.fromARGB(160, 20, 30, 50),
                ]
              : [
                  const Color.fromARGB(140, 40, 30, 30),
                  const Color.fromARGB(120, 30, 20, 20),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEnabled
              ? const Color(0xFF2DA6FF).withOpacity(0.25)
              : Colors.redAccent.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isEnabled
                ? const Color(0xFF2DA6FF).withOpacity(0.12)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            feat.icon,
            color: isEnabled
                ? const Color(0xFF2DA6FF)
                : Colors.white30,
            size: 22,
          ),
        ),
        title: Text(
          feat.name,
          style: TextStyle(
            color: isEnabled ? Colors.white : Colors.white54,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                feat.description,
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
              if (!isEnabled) ...[
                const SizedBox(height: 6),
                // Premium Access badge inline
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7A5C00).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFFB8880A).withOpacity(0.5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_rounded,
                          color: Color(0xFFFFD700), size: 11),
                      SizedBox(width: 4),
                      Text(
                        'DISABLED — Manager cannot access this feature',
                        style: TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing: isToggling
            ? const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFF2DA6FF),
                ),
              )
            : Switch(
                value: isEnabled,
                onChanged: (val) => _toggleFeature(feat, val),
                activeThumbColor: const Color(0xFF2DA6FF),
                activeTrackColor: const Color(0xFF2DA6FF).withOpacity(0.3),
                inactiveThumbColor: Colors.white30,
                inactiveTrackColor: Colors.white12,
              ),
      ),
    );
  }

  // ── Section title ─────────────────────────────────────────────────────────
  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF2DA6FF), Color(0xFF3C5AFF)],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  // ── Utilities ─────────────────────────────────────────────────────────────
  String _initials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }
}
