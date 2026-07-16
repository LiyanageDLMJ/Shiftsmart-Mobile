import 'package:flutter/material.dart';
import 'package:shiftsmart/screens/manager/super_admin_manage_features.dart';
import 'package:shiftsmart/services/super_admin_service.dart';
import 'package:shiftsmart/utils/fullscreen_helper.dart';
import 'package:shiftsmart/widgets/background.dart';
import 'package:shiftsmart/widgets/uppernavbar.dart';
import 'package:shiftsmart/widgets/sidenav.dart';

/// A read-only detail view for the selected tenant (organisation).
/// Receives the basic tenant map from the Manager Dashboard and enriches it
/// by fetching full details from the SuperAdminService.
class ManagerTenantDetails extends StatefulWidget {
  /// The tenant map selected from the dashboard dropdown.
  /// Expected keys: 'name'/'Name', 'tenantId'/'TenantId'/'id'/'ID', etc.
  final Map<String, dynamic> tenant;

  const ManagerTenantDetails({super.key, required this.tenant});

  @override
  State<ManagerTenantDetails> createState() => _ManagerTenantDetailsState();
}

class _ManagerTenantDetailsState extends State<ManagerTenantDetails>
    with SingleTickerProviderStateMixin {
  final SuperAdminService _superAdminService = SuperAdminService();

  bool _isLoading = true;
  Map<String, dynamic>? _details;
  String? _errorMessage;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    enableFullScreen();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );

    _loadDetails();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Resolve tenant ID from all common key variants
    final tenantId = widget.tenant['tenantId'] ??
        widget.tenant['TenantId'] ??
        widget.tenant['id'] ??
        widget.tenant['ID'];

    if (tenantId == null) {
      // Fall back to showing whatever the dashboard already provided
      setState(() {
        _details = widget.tenant;
        _isLoading = false;
      });
      _animController.forward();
      return;
    }

    try {
      final details = await _superAdminService.getTenantDetails(
        int.tryParse(tenantId.toString()) ?? 0,
      );
      if (!mounted) return;
      setState(() {
        _details = details ?? widget.tenant;
        _isLoading = false;
      });
      _animController.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _details = widget.tenant;
        _errorMessage = 'Could not load full details – showing cached data.';
        _isLoading = false;
      });
      _animController.forward();
    }
  }

  // -----------------------------------------------------------------------
  // Helper: resolve a value from multiple possible key names
  // -----------------------------------------------------------------------
  String _get(List<String> keys, {String fallback = '—'}) {
    if (_details == null) return fallback;
    for (final k in keys) {
      final v = _details![k];
      if (v != null && v.toString().trim().isNotEmpty) return v.toString();
    }
    return fallback;
  }

  // -----------------------------------------------------------------------
  // UI
  // -----------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final name = _get(['name', 'Name', 'tenantName', 'TenantName']);

    return Scaffold(
      drawer: const Sidenav(),
      backgroundColor: const Color(0xFF1C2230),
      appBar: const Uppernavbar(showBackButton: true),
      floatingActionButton: _details == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SuperAdminManageFeatures(
                      tenant: _details ?? widget.tenant,
                    ),
                  ),
                );
              },
              backgroundColor: const Color(0xFF2DA6FF),
              icon: const Icon(Icons.tune_rounded, color: Colors.white),
              label: const Text(
                'Manage Features',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
      body: Stack(
        children: [
          const Positioned.fill(child: Background()),
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF724584)),
                )
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: RefreshIndicator(
                    onRefresh: _loadDetails,
                    color: const Color(0xFF724584),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Header card ─────────────────────────────
                          _buildHeaderCard(name),
                          const SizedBox(height: 20),

                          // ── Warning banner (if any) ──────────────────
                          if (_errorMessage != null) _buildWarningBanner(),

                          // ── Section: Basic information ───────────────
                          _buildSectionTitle('Organisation Information'),
                          const SizedBox(height: 10),
                          _buildInfoCard([
                            _InfoRow(
                              icon: Icons.business_rounded,
                              label: 'Organisation Name',
                              value: name,
                            ),
                            _InfoRow(
                              icon: Icons.badge_outlined,
                              label: 'Tenant ID',
                              value: _get([
                                'tenantId',
                                'TenantId',
                                'id',
                                'ID',
                              ]),
                            ),
                            _InfoRow(
                              icon: Icons.domain_rounded,
                              label: 'Domain / Subdomain',
                              value: _get(['domain', 'Domain', 'subdomain', 'Subdomain']),
                            ),
                            _InfoRow(
                              icon: Icons.language_rounded,
                              label: 'Industry',
                              value: _get(['industry', 'Industry', 'sector', 'Sector']),
                            ),
                          ]),

                          const SizedBox(height: 20),

                          // ── Section: Contact details ─────────────────
                          _buildSectionTitle('Contact Details'),
                          const SizedBox(height: 10),
                          _buildInfoCard([
                            _InfoRow(
                              icon: Icons.email_outlined,
                              label: 'Email',
                              value: _get(['email', 'Email', 'contactEmail', 'ContactEmail']),
                            ),
                            _InfoRow(
                              icon: Icons.phone_outlined,
                              label: 'Phone',
                              value: _get(['phone', 'Phone', 'contactPhone', 'ContactPhone', 'phoneNumber', 'PhoneNumber']),
                            ),
                            _InfoRow(
                              icon: Icons.location_on_outlined,
                              label: 'Address',
                              value: _get(['address', 'Address', 'location', 'Location']),
                            ),
                            _InfoRow(
                              icon: Icons.public_outlined,
                              label: 'Country',
                              value: _get(['country', 'Country']),
                            ),
                          ]),

                          const SizedBox(height: 20),

                          // ── Section: Status & Subscription ───────────
                          _buildSectionTitle('Status & Subscription'),
                          const SizedBox(height: 10),
                          _buildStatusCard(),

                          const SizedBox(height: 20),

                          // ── Manage Features shortcut card ─────────────
                          _buildManageFeaturesCard(),

                          const SizedBox(height: 20),

                          // ── Section: Admin contact ───────────────────
                          _buildSectionTitle('Admin Contact'),
                          const SizedBox(height: 10),
                          _buildInfoCard([
                            _InfoRow(
                              icon: Icons.person_outline_rounded,
                              label: 'Admin Name',
                              value: _get([
                                'adminName',
                                'AdminName',
                                'ownerName',
                                'OwnerName',
                                'contactName',
                                'ContactName',
                              ]),
                            ),
                            _InfoRow(
                              icon: Icons.alternate_email_rounded,
                              label: 'Admin Email',
                              value: _get([
                                'adminEmail',
                                'AdminEmail',
                                'ownerEmail',
                                'OwnerEmail',
                              ]),
                            ),
                          ]),

                          const SizedBox(height: 20),

                          // ── Section: Timestamps ──────────────────────
                          _buildSectionTitle('Timeline'),
                          const SizedBox(height: 10),
                          _buildInfoCard([
                            _InfoRow(
                              icon: Icons.calendar_today_outlined,
                              label: 'Created At',
                              value: _formatDate(_get(['createdAt', 'CreatedAt', 'createdDate', 'CreatedDate'])),
                            ),
                            _InfoRow(
                              icon: Icons.update_rounded,
                              label: 'Last Updated',
                              value: _formatDate(_get(['updatedAt', 'UpdatedAt', 'modifiedAt', 'ModifiedAt'])),
                            ),
                            _InfoRow(
                              icon: Icons.event_available_outlined,
                              label: 'Subscription Expiry',
                              value: _formatDate(_get([
                                'subscriptionExpiry',
                                'SubscriptionExpiry',
                                'expiryDate',
                                'ExpiryDate',
                                'planExpiry',
                              ])),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  // ── Hero header card ────────────────────────────────────────────────────
  Widget _buildHeaderCard(String name) {
    final initials = _initials(name);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2DA6FF), Color(0xFF3C5AFF)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3C5AFF).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar circle
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white38, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                _buildStatusPill(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill() {
    final status = _get(['status', 'Status', 'isActive', 'IsActive'], fallback: '');
    final bool isActive = status.toLowerCase() == 'true' ||
        status.toLowerCase() == 'active' ||
        status.toLowerCase() == '1';

    final label = isActive ? 'Active' : (status.isEmpty ? 'Unknown' : status);
    final color = isActive ? Colors.greenAccent : Colors.orangeAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.6), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Section title ───────────────────────────────────────────────────────
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

  // ── Info card ───────────────────────────────────────────────────────────
  Widget _buildInfoCard(List<_InfoRow> rows) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromARGB(180, 42, 50, 67),
            Color.fromARGB(180, 28, 34, 52),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10, width: 1),
      ),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final i = entry.key;
          final row = entry.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(row.icon, color: const Color(0xFF2DA6FF), size: 20),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            row.label,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            row.value,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (i < rows.length - 1)
                Divider(color: Colors.white.withOpacity(0.07), height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── Status & subscription card ──────────────────────────────────────────
  Widget _buildStatusCard() {
    final status = _get(['status', 'Status'], fallback: '');
    final isActive = status.toLowerCase() == 'active' ||
        status.toLowerCase() == 'true' ||
        status.toLowerCase() == '1';

    final plan = _get([
      'subscriptionPlan',
      'SubscriptionPlan',
      'plan',
      'Plan',
      'tier',
      'Tier',
    ]);
    final maxUsers = _get([
      'maxUsers',
      'MaxUsers',
      'userLimit',
      'UserLimit',
    ]);
    final region = _get(['region', 'Region', 'timezone', 'Timezone']);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromARGB(180, 42, 50, 67),
            Color.fromARGB(180, 28, 34, 52),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Active / Inactive toggle badge
          Row(
            children: [
              const Icon(Icons.power_settings_new_rounded,
                  color: Color(0xFF2DA6FF), size: 20),
              const SizedBox(width: 14),
              const Text(
                'Account Status',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: (isActive ? Colors.green : Colors.orange)
                      .withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (isActive ? Colors.greenAccent : Colors.orangeAccent)
                        .withOpacity(0.6),
                  ),
                ),
                child: Text(
                  isActive ? 'Active' : (status.isEmpty ? 'Unknown' : status),
                  style: TextStyle(
                    color:
                        isActive ? Colors.greenAccent : Colors.orangeAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          Divider(color: Colors.white.withOpacity(0.07), height: 24),

          // Plan
          _statusRow(Icons.workspace_premium_outlined, 'Subscription Plan', plan),
          const SizedBox(height: 14),
          _statusRow(Icons.people_outline, 'Max Users', maxUsers),
          const SizedBox(height: 14),
          _statusRow(Icons.public_rounded, 'Region / Timezone', region),
        ],
      ),
    );
  }

  Widget _statusRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF2DA6FF), size: 20),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }

  // ── Manage Features shortcut card ──────────────────────────────────────
  Widget _buildManageFeaturesCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SuperAdminManageFeatures(
              tenant: _details ?? widget.tenant,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(180, 30, 42, 65),
              Color.fromARGB(160, 20, 30, 50),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2DA6FF).withOpacity(0.35)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF2DA6FF).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: Color(0xFF2DA6FF),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Premium Features',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Enable or disable modules for this tenant.',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF2DA6FF),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // ── Warning banner ──────────────────────────────────────────────────────
  Widget _buildWarningBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orangeAccent.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.orangeAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.orangeAccent, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ── Utilities ───────────────────────────────────────────────────────────
  String _initials(String name) {
    if (name == '—' || name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  String _formatDate(String raw) {
    if (raw == '—' || raw.isEmpty) return '—';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }
}

// ── Simple data class ────────────────────────────────────────────────────
class _InfoRow {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});
}
